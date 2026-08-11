"""CSV comparison ladder - Redshift extract vs Snowflake extract in S3.

Mirrors the shape of the BI T0-T4 ladder so results read the same way:

  C0  file presence      - view present in both run folders
  C1  header parity      - same column names, same order  (hard stop)
  C2  row counts         - total rows per side
  C3  key-set diff       - which keys are present on only one side (needs grain)
  C4  column-level diff  - per-column mismatch counts over shared keys
  C5  fingerprint        - order-independent hash of the whole normalised set

Ladder rules:
  - Missing on one side -> BLOCKED, stop.
  - C1 drift -> FAIL and stop; every content tier below would be meaningless.
  - No grain -> C3/C4 skipped, C5 still runs as the only content signal.
  - C5 only runs when the content check is clean (or always_fingerprint).

Comparison is streaming and single-pass per file: rows are reduced to a
{key: row} dict of normalised values, so memory scales with the extract rather
than with the whole schema.
"""

from __future__ import annotations

from .common import (
    ACC, BLOCKED, CSV_TIERS, ERR, FAIL, PASS, SKIP,
    Normaliser, accept_diff_map, accepted_columns_map, col_map,
    evaluate_where, verdict_from, within_threshold,
)

import hashlib


def _key_sort(key):
    """Sort a grain-key tuple that may hold None in some positions.

    A grain column can be NULL for some rows and populated for others (e.g. a
    UNION'd view where one branch has no matching value), so two keys tying on
    an earlier column can need to compare None against a string on a later
    one - which raises TypeError in Python 3. Sorting on (is_none, value) per
    column keeps None keys ordered (before real values) without ever
    comparing across types.
    """
    return tuple((v is None, v) for v in key)


class CsvComparer:
    def __init__(self, source, cfg, dry_run=False):
        self.source = source
        self.cfg = cfg
        self.defaults = cfg.get("defaults") or {}
        self.csv_cfg = cfg.get("csv") or {}
        self.dry_run = dry_run

    # -- config helpers -----------------------------------------------------

    def view_cfg(self, view):
        for v in (self.csv_cfg.get("views") or []):
            if str(v.get("name", "")).lower() == view.lower():
                return v
        return {"name": view}

    def threshold(self):
        return float(self.defaults.get("diff_threshold_pct", 0) or 0)

    def normaliser(self, vcfg):
        opts = dict(self.csv_cfg.get("normalisation") or {})
        opts.update(vcfg.get("normalisation") or {})
        return Normaliser(opts)

    def grain_for(self, view, header):
        """Per-view grain if set, else the mode default, else None.

        Returns only the grain columns that actually exist in the header - a
        grain naming an absent column would silently key every row identically.
        """
        vcfg = self.view_cfg(view)
        if "grain" in vcfg:
            grain = vcfg.get("grain")
        else:
            grain = self.csv_cfg.get("default_grain")
        # No grain is invented. An unset, null or empty grain means the key-based
        # tiers are skipped for this view rather than silently keyed on a guess.
        if not grain:
            return None, []
        grain = [str(c).lower() for c in grain]
        present = [c for c in grain if c in header]
        missing = [c for c in grain if c not in header]
        return (present or None), missing

    # -- loading ------------------------------------------------------------

    def _load(self, run, view, vcfg, norm, grain):
        """Stream one CSV into {key: normalised_row}, plus counts.

        Duplicate keys are counted rather than silently overwritten - a
        non-unique grain makes C3/C4 unreliable and must surface.
        """
        header, rows = self.source.read_csv(run, view)
        drop = set(col_map(vcfg, "exclude_columns"))
        keep = [c for c in header if c not in drop]
        idx = {c: i for i, c in enumerate(header)}
        key_idx = [idx[c] for c in (grain or []) if c in idx]

        data, dups, total, ragged = {}, 0, 0, 0
        for raw in rows:
            total += 1
            if len(raw) != len(header):
                ragged += 1
                raw = (raw + [None] * len(header))[: len(header)]
            vals = {c: norm(raw[idx[c]], c) for c in keep}
            if key_idx:
                key = tuple(norm(raw[i], header[i]) for i in key_idx)
                if key in data:
                    dups += 1
                else:
                    data[key] = vals
            else:
                data[len(data)] = vals
        return {
            "header": header, "kept": keep, "rows": data,
            "total": total, "dup_keys": dups, "ragged": ragged,
        }

    # -- tiers --------------------------------------------------------------

    def c1_header(self, left, right):
        lh, rh = left["header"], right["header"]
        drift = []
        for i, name in enumerate(lh):
            if i >= len(rh):
                drift.append({"column": name, "redshift_ord": i + 1, "snowflake_ord": None})
            elif rh[i] != name:
                drift.append({
                    "column": name, "redshift_ord": i + 1,
                    "snowflake_ord": (rh.index(name) + 1 if name in rh else None),
                    "snowflake_column_at_position": rh[i],
                })
        for j, name in enumerate(rh[len(lh):], start=len(lh) + 1):
            drift.append({"column": name, "redshift_ord": None, "snowflake_ord": j})
        return {
            "status": PASS if not drift else FAIL,
            "drift": drift,
            "redshift_columns": len(lh),
            "snowflake_columns": len(rh),
            "only_in_redshift": sorted(set(lh) - set(rh)),
            "only_in_snowflake": sorted(set(rh) - set(lh)),
        }

    def c2_row_counts(self, left, right):
        rn, sn = left["total"], right["total"]
        diff = rn - sn
        denom = max(rn, sn)
        out = {"redshift_rows": rn, "snowflake_rows": sn, "diff": diff,
               "threshold_pct": self.threshold() or None, "denominator": denom or None}
        if diff == 0:
            out["status"] = PASS
        elif within_threshold(abs(diff), denom, self.threshold()):
            out["status"] = ACC
        else:
            out["status"] = FAIL
        for side, d in (("redshift", left), ("snowflake", right)):
            if d["ragged"]:
                out.setdefault("warnings", []).append(
                    f"{side}: {d['ragged']} row(s) had a column count != header - padded/truncated"
                )
        return out

    def c3_key_diff(self, left, right, grain):
        if not grain:
            return {"status": SKIP, "reason": "no grain resolved for this view"}
        n = int(self.defaults.get("sample_rows", 25))
        lk, rk = set(left["rows"]), set(right["rows"])
        only_l, only_r = sorted(lk - rk, key=_key_sort), sorted(rk - lk, key=_key_sort)
        denom = max(len(lk), len(rk))
        worst = max(len(only_l), len(only_r))
        out = {
            "key_columns": grain,
            "key_diff": {"in_redshift_not_snowflake": len(only_l),
                         "in_snowflake_not_redshift": len(only_r)},
            "shared_keys": len(lk & rk),
            "duplicate_keys": {"redshift": left["dup_keys"], "snowflake": right["dup_keys"]},
            "threshold_pct": self.threshold() or None,
            "denominator": denom or None,
        }
        if only_l:
            out.setdefault("key_samples", {})["in_redshift_not_snowflake"] = [list(k) for k in only_l[:n]]
        if only_r:
            out.setdefault("key_samples", {})["in_snowflake_not_redshift"] = [list(k) for k in only_r[:n]]
        if worst == 0:
            out["status"] = PASS
        elif within_threshold(worst, denom, self.threshold()):
            out["status"] = ACC
        else:
            out["status"] = FAIL
        if left["dup_keys"] or right["dup_keys"]:
            out["grain_unique"] = False
            out["note"] = ("Grain is not unique in this extract - C4 counts cover first "
                           "occurrence per key only. Extend the grain for this view.")
        else:
            out["grain_unique"] = True
        return out

    def c4_column_diff(self, left, right, grain, vcfg, norm):
        """Per-column mismatch counts over shared keys, with accepted-column handling."""
        if not grain:
            return {"status": SKIP, "reason": "no grain resolved - cannot align rows"}
        shared = sorted(set(left["rows"]) & set(right["rows"]), key=_key_sort)
        if not shared:
            return {"status": SKIP, "reason": "no shared keys between the two extracts",
                    "shared_keys": 0}

        accepted = accepted_columns_map(vcfg)
        excluded = col_map(vcfg, "exclude_columns")
        cols = [c for c in left["kept"] if c in right["kept"] and c not in set(grain)]

        per_col = {c: 0 for c in cols}
        residual = {c: 0 for c in cols if accepted.get(c, {}).get("where")}
        per_n = int(self.defaults.get("csv_samples_per_column",
                                      self.defaults.get("t3_samples_per_column", 15)))
        samples = {c: [] for c in cols}

        for key in shared:
            lrow, rrow = left["rows"][key], right["rows"][key]
            for c in cols:
                lv, rv = lrow.get(c), rrow.get(c)
                if lv == rv:
                    continue
                per_col[c] += 1
                explained = False
                where = accepted.get(c, {}).get("where")
                if where:
                    explained = evaluate_where(where, lv, rv)
                    if not explained:
                        residual[c] += 1
                if len(samples[c]) < per_n and not explained:
                    samples[c].append(list(key) + [lv, rv])

        mismatched = {c: n for c, n in per_col.items() if n}
        col_status, reasons, accepted_where = {}, {}, {}
        shared_n = len(shared)
        for c, n in mismatched.items():
            entry = accepted.get(c)
            if entry and entry.get("where"):
                accepted_where[c] = entry["where"]
                r = residual.get(c, n)
                base = entry.get("reason") or "marked as accepted in config"
                if r == 0:
                    col_status[c] = "ACCEPTED_MARKED"
                    reasons[c] = f"{base} - where-clause explains all {n:,} diffs"
                elif within_threshold(r, shared_n, self.threshold()):
                    col_status[c] = "ACCEPTED_THRESHOLD"
                    reasons[c] = (f"{base} - explains {n - r:,} of {n:,} diffs; "
                                  f"remaining {r:,} within threshold")
                else:
                    col_status[c] = FAIL
                    reasons[c] = (f"{base} - explains {n - r:,} of {n:,} diffs; "
                                  f"{r:,} unexplained differences remain")
            elif entry:
                col_status[c] = "ACCEPTED_MARKED"
                reasons[c] = entry.get("reason") or "marked as accepted in config"
            elif within_threshold(n, shared_n, self.threshold()):
                col_status[c] = "ACCEPTED_THRESHOLD"
            else:
                col_status[c] = FAIL

        if not mismatched:
            status = PASS
        elif any(s == FAIL for s in col_status.values()):
            status = FAIL
        else:
            status = ACC

        cap = int(self.defaults.get("csv_sample_columns",
                                    self.defaults.get("t3_sample_columns", 20)))
        where_cols = sorted(residual, key=lambda c: -residual[c])
        other = sorted((c for c in mismatched if c not in residual), key=lambda c: -mismatched[c])
        ranked = where_cols + other[: max(cap - len(where_cols), 0)]

        return {
            "status": status,
            "shared_keys": shared_n,
            "mismatched_columns": mismatched,
            "column_status": col_status,
            "accepted_reasons": reasons,
            "accepted_where": accepted_where,
            "residual_mismatches": residual,
            "excluded_columns": excluded,
            "threshold_pct": self.threshold() or None,
            "column_samples": {c: samples[c] for c in ranked if samples.get(c)},
            "column_sample_columns": list(grain) + ["REDSHIFT value", "SNOWFLAKE value"],
        }

    def c5_fingerprint(self, left, right):
        def digest(d):
            h = hashlib.sha256()
            cols = d["kept"]
            for line in sorted("\x1f".join("" if (v := r.get(c)) is None else str(v) for c in cols)
                               for r in d["rows"].values()):
                h.update(line.encode("utf-8"))
                h.update(b"\x1e")
            return h.hexdigest()

        lf, rf = digest(left), digest(right)
        return {"status": PASS if lf == rf else FAIL,
                "redshift_fingerprint": lf[:16], "snowflake_fingerprint": rf[:16]}

    # -- ladder -------------------------------------------------------------

    def run_view(self, client, view, rs_run, sf_run):
        vcfg = self.view_cfg(view)
        res = {"client": client, "view": view, "mode": "csv",
               "redshift_run": rs_run.timestamp, "snowflake_run": sf_run.timestamp,
               "tiers": {}, "verdict": None, "notes": []}
        tiers = res["tiers"]
        accept = accept_diff_map(vcfg, CSV_TIERS, notes=res["notes"])

        present = {"redshift": view in rs_run.files, "snowflake": view in sf_run.files}
        tiers["C0"] = {"status": PASS if all(present.values()) else FAIL, "present": present}
        if not all(present.values()):
            res["verdict"] = BLOCKED
            missing = [s for s, ok in present.items() if not ok]
            res["notes"].append(f"Extract missing on: {', '.join(missing)}.")
            return res

        norm = self.normaliser(vcfg)
        try:
            rs_head, _ = self.source.read_csv(rs_run, view)
            grain, missing_grain = self.grain_for(view, rs_head)
            if missing_grain:
                res["notes"].append(
                    f"Grain column(s) {', '.join(missing_grain)} not in this extract - "
                    f"using {grain or 'no grain'}."
                )
            if not grain:
                res["notes"].append(
                    "No grain set for this view - C3/C4 skipped. C0/C1/C2/C5 still "
                    "apply. Fill in `grain:` in config.yaml to enable row-level diffs."
                )
            left = self._load(rs_run, view, vcfg, norm, grain)
            right = self._load(sf_run, view, vcfg, norm, grain)
        except Exception as e:  # noqa: BLE001
            tiers["C1"] = {"status": ERR, "error": f"{type(e).__name__}: {e}"}
            res["verdict"] = ERR
            return res

        def record(name, out):
            if self.dry_run:
                out["status"] = "DRY"
            elif name in accept and out.get("status") in (FAIL, ACC):
                was_fail = out["status"] == FAIL
                out["status"] = ACC
                out["accepted_via_config"] = True
                reason = accept[name]
                if reason:
                    out["accept_reason"] = reason
                res["notes"].append(
                    f"{name} diff {'accepted via config override' if was_fail else 'was within threshold; reason on file'}"
                    + (f": {reason}" if reason else "")
                )
            tiers[name] = out
            return out

        c1 = record("C1", self.c1_header(left, right))
        if c1["status"] == FAIL:
            res["verdict"] = "HEADER DRIFT"
            res["notes"].append("Header/column-order drift - content tiers withheld until headers agree.")
            return res

        record("C2", self.c2_row_counts(left, right))
        c3 = record("C3", self.c3_key_diff(left, right, grain))
        if c3.get("grain_unique") is False:
            res["notes"].append(c3.get("note", "Grain is not unique in this extract."))
        c4 = record("C4", self.c4_column_diff(left, right, grain, vcfg, norm))

        # The fingerprint only means something when EVERY content tier is clean.
        # If a row-count or key-set difference was accepted within threshold, the
        # fingerprints differ by construction, so running C5 would contradict
        # that acceptance rather than add information.
        content_tiers = [tiers[t].get("status") for t in ("C2", "C3", "C4") if t in tiers]
        all_clean = all(st in (PASS, SKIP) for st in content_tiers)
        if all_clean or self.defaults.get("always_fingerprint") or self.dry_run:
            record("C5", self.c5_fingerprint(left, right))
        else:
            accepted_only = not any(st == FAIL for st in content_tiers)
            tiers["C5"] = {"status": SKIP, "reason": (
                "differences were accepted within threshold - fingerprints differ by "
                "construction, so C5 adds nothing" if accepted_only else
                "content diffs present - fingerprints would differ by construction")}

        res["verdict"] = verdict_from(
            (v.get("status") for v in tiers.values()),
            has_accepted_columns=bool(accepted_columns_map(vcfg)),
            dry_run=self.dry_run,
            no_grain=not grain,
        )
        return res
