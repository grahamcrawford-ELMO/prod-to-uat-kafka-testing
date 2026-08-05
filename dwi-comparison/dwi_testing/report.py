"""Reporting - tracker-ready summary.md, machine-readable results.json,
queries.sql for audit, and per-column sample CSVs.

Deliberately the same output shape as the BI harness so the results can be
pasted into the same tracker/Confluence page.
"""

from __future__ import annotations

import csv
import datetime as dt
import json
from pathlib import Path

from .common import ACC, BLOCKED, ERR, FAIL, PASS, SKIP

ICON = {PASS: "PASS", FAIL: "FAIL", SKIP: "skip", ERR: "ERR",
        ACC: "ACC", BLOCKED: "BLOCK", "DRY": "dry", None: "-"}

CSV_COLUMNS = ("C0", "C1", "C2", "C3", "C4", "C5")
DWI_COLUMNS = ("D0", "D1", "D2", "D3", "D4")


def _matrix(results, tier_names, title, id_cols):
    lines = [f"## {title}", "",
             "| " + " | ".join(id_cols) + " | " + " | ".join(tier_names) + " | Verdict | Notes |",
             "|" + "---|" * (len(id_cols) + len(tier_names) + 2)]
    for r in results:
        t = r.get("tiers", {})
        cells = [ICON.get(t.get(k, {}).get("status"), "-") for k in tier_names]
        ids = [str(r.get(c.lower().replace(" ", "_"), "")) for c in id_cols]
        notes = "; ".join(r.get("notes", []))
        lines.append("| " + " | ".join(ids) + " | " + " | ".join(cells)
                     + f" | **{r.get('verdict')}** | {notes} |")
    lines.append("")
    return lines


def write_reports(csv_results, dwi_results, out_dir, dry_run=False, queries=None):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    payload = {"generated": dt.datetime.now().isoformat(timespec="seconds"),
               "dry_run": dry_run, "csv": csv_results, "dwi": dwi_results}
    (out / "results.json").write_text(json.dumps(payload, indent=2, default=str))

    lines = ["# DWI Migration Testing - Snowflake vs Redshift",
             f"\nRun: {dt.datetime.now():%Y-%m-%d %H:%M}"
             + ("  (DRY RUN - nothing executed)" if dry_run else ""), ""]

    if csv_results:
        lines += ["Legend: C0 file presence, C1 header parity, C2 row counts, "
                  "C3 key-set diff, C4 column-level diff, C5 fingerprint.", ""]
        lines += _matrix(csv_results, CSV_COLUMNS,
                         "S3 CSV comparison (Redshift extract vs Snowflake extract)",
                         ["Client", "View"])
    if dwi_results:
        lines += ["Legend: D0 schema parity, D1 grain uniqueness, D2 key-set diff, "
                  "D3 column-level diff, D4 fingerprint.", ""]
        lines += _matrix(dwi_results, DWI_COLUMNS,
                         "Warehouse comparison (UAT_DB.EDP_DWI vs PROD_DB.EDP_DWI)",
                         ["View"])

    # Grain coverage: which views still have no grain configured. Without this
    # a 127-view run looks green while the row-level tiers never ran.
    def _nog(rows):
        return [r for r in rows
                if any("No grain set" in n for n in (r.get("notes") or []))]

    # Count each mode against its OWN denominator. A view that never reached
    # grain resolution (blocked, or a dry run that short-circuits) is not
    # evidence either way, so it is excluded rather than counted as covered.
    parts, nog = [], []
    for rows, lbl in ((csv_results, "csv"), (dwi_results, "dwi")):
        n = _nog(rows)
        if n:
            parts.append(f"{len(n)} of {len(rows)} `{lbl}`")
            nog += n
    if nog:
        lines += [
            "## Grain coverage\n",
            f"**{' and '.join(parts)} views have no grain configured.** For these, "
            "the row-level tiers (C3/C4, D1/D3) were skipped: schema parity, row "
            "counts and the fingerprint still ran, but a row that changed in place "
            "without altering the row count is only caught by the fingerprint, "
            "which cannot say *which* row. Fill in `grain:` in config.yaml to "
            "close the gap.\n",
            "<details><summary>Views awaiting a grain ("
            f"{len(nog)})</summary>\n",
            *[f"- `{r.get('view')}`" + (f" ({r['client']})" if r.get("client") else "")
              for r in nog],
            "\n</details>\n",
        ]

    lines.append("## Details\n")
    for r in csv_results + dwi_results:
        head = f"### {r.get('view')}"
        if r.get("client"):
            head += f"  ({r['client']})"
        lines.append(f"{head} - {r.get('verdict')}")
        if r.get("redshift_run"):
            lines.append(f"- Run folders: Redshift `{r['redshift_run']}` vs "
                         f"Snowflake `{r['snowflake_run']}`")
        t = r.get("tiers", {})

        hdr = t.get("C1", {})
        if hdr.get("drift"):
            lines.append(f"- C1 header drift ({len(hdr['drift'])} column(s)):")
            for d in hdr["drift"][:15]:
                lines.append(f"  - `{d['column']}` redshift ord {d.get('redshift_ord')} / "
                             f"snowflake ord {d.get('snowflake_ord')}")
        for tier, label, a, b in (("C2", "C2 row counts", "redshift_rows", "snowflake_rows"),
                                  ("D2", "row counts", "prod_rows", "uat_rows")):
            d = t.get(tier, {})
            if d.get(a) is not None:
                lines.append(f"- {label}: {d[a]:,} vs {d[b]:,} (diff {d.get('diff', 0):+,})")
        for tier in ("C3", "D2"):
            d = t.get(tier, {})
            kd = d.get("key_diff")
            if kd:
                left, right = list(kd.items())[0], list(kd.items())[1]
                lines.append(f"- {tier} key diff: {left[1]} {left[0]}, {right[1]} {right[0]} "
                             f"(keys: {', '.join(d.get('key_columns', []))})")
        for tier in ("C4", "D3"):
            d = t.get(tier, {})
            mc = d.get("mismatched_columns")
            if mc:
                residual = d.get("residual_mismatches", {})
                statuses = d.get("column_status", {})
                where_cols = sorted((c for c in mc if c in residual), key=lambda c: -residual[c])
                other = sorted((c for c in mc if c not in residual), key=lambda c: -mc[c])
                top = (where_cols + other)[:15]

                def fmt(c):
                    bits = f"`{c}`={mc[c]:,}"
                    if c in residual:
                        bits += f" (residual {residual[c]:,})"
                    st = statuses.get(c)
                    if st and st != FAIL:
                        bits += f" [{st}]"
                    return bits

                lines.append(f"- {tier} ({d.get('shared_keys', 0):,} shared keys), "
                             f"mismatching columns: " + ", ".join(fmt(c) for c in top))
                for c, w in (d.get("accepted_where") or {}).items():
                    lines.append(f"  - accepted `where` on `{c}`: `{w}`")
        for w in (t.get("C2", {}).get("warnings") or []):
            lines.append(f"- ! {w}")
        for n in r.get("notes", []):
            lines.append(f"- ! {n}")
        lines.append("")

    (out / "summary.md").write_text("\n".join(lines), encoding="utf-8")

    if queries:
        (out / "queries.sql").write_text(";\n\n".join(queries) + ";\n", encoding="utf-8")

    sdir = out / "samples"
    for r in csv_results + dwi_results:
        for tier in ("C4", "D3"):
            d = r.get("tiers", {}).get(tier, {})
            for cname, rows in (d.get("column_samples") or {}).items():
                if not rows:
                    continue
                sdir.mkdir(exist_ok=True)
                safe_view = "".join(ch if ch.isalnum() else "_" for ch in str(r.get("view")))
                safe_col = "".join(ch if ch.isalnum() else "_" for ch in cname)
                prefix = f"{r['client']}_" if r.get("client") else ""
                with open(sdir / f"{prefix}{safe_view}_{tier}_{safe_col}.csv", "w",
                          newline="", encoding="utf-8") as f:
                    w = csv.writer(f)
                    w.writerow(d.get("column_sample_columns", []))
                    w.writerows(rows)
    return out / "summary.md"
