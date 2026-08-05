"""In-warehouse comparison ladder - UAT_DB.EDP_DWI vs PROD_DB.EDP_DWI.

Same Snowflake-side approach as the BI harness, retargeted at EDP_DWI and at a
cross-database pair rather than two schemas in UAT_DB:

  D0  schema parity      (INFORMATION_SCHEMA full join)   - hard stop
  D1  grain uniqueness   (both sides; needs grain)
  D2  key-set diff       (both directions; needs grain)
  D3  column-level diff  (COUNT_IF(NOT EQUAL_NULL(...)) over shared keys)
  D4  fingerprint        (HASH_AGG)

Two differences from the BI ladder that matter here:

  * No active-tenants join by default. The BI comparison joins
    UAT_DB.BI.TEMP_ACTIVE_TENANTS because both sides live in UAT_DB. Comparing
    UAT_DB to PROD_DB means that table only exists on one side, so the join is
    opt-in via csv/dwi config (tenant_join / active_tenants) and off unless a
    table is configured for it.
  * Grain defaults to ID + CLIENT_NAME + CLIENT_REGION, the common DWI shape,
    with per-view overrides. The BI grains from CRT-6248 do not apply.

Requires a role that can see both databases; USE SECONDARY ROLES is honoured
from config exactly as in the BI runner.
"""

from __future__ import annotations

from .common import (
    ACC, BLOCKED, DWI_TIERS, ERR, FAIL, PASS, SKIP,
    accept_diff_map, accepted_columns_map, col_map, verdict_from, within_threshold,
)

TEXT_TYPES = {"TEXT"}


class DwiComparer:
    def __init__(self, conn, cfg, dry_run=False):
        self.conn = conn
        self.cfg = cfg
        self.dwi = cfg.get("dwi") or {}
        self.defaults = cfg.get("defaults") or {}
        self.dry_run = dry_run
        self.sql_log = []

    # -- helpers ------------------------------------------------------------

    def q(self, sql, fetch=True):
        self.sql_log.append(sql)
        if self.dry_run:
            return []
        cur = self.conn.cursor()
        try:
            cur.execute(sql)
            return cur.fetchall() if fetch else []
        finally:
            cur.close()

    def split_side(self, spec):
        spec = str(spec)
        if "." in spec:
            db, schema = spec.split(".", 1)
            return db, schema
        return spec, self.dwi.get("schema", "EDP_DWI")

    def fq(self, spec, table):
        db, schema = self.split_side(spec)
        return f"{db}.{schema}.{table}"

    @property
    def prod(self):
        return self.dwi.get("prod_db", "PROD_DB.EDP_DWI")

    @property
    def uat(self):
        return self.dwi.get("uat_db", "UAT_DB.EDP_DWI")

    def view_cfg(self, table):
        for v in (self.dwi.get("views") or []):
            if str(v.get("name", "")).upper() == table.upper():
                return v
        return {"name": table}

    def threshold(self):
        return float(self.defaults.get("diff_threshold_pct", 0) or 0)

    def grain_cols(self, tbl_cfg, available):
        """Quoted grain columns that exist on both sides."""
        if "grain" in tbl_cfg:
            grain = tbl_cfg.get("grain")
        else:
            grain = self.dwi.get("default_grain")
        # No grain is invented. Unset/null/empty -> key-based tiers skip.
        if not grain:
            return None, []
        upper = {c.upper(): c for c in available}
        present = [upper[str(c).upper()] for c in grain if str(c).upper() in upper]
        missing = [str(c) for c in grain if str(c).upper() not in upper]
        return ([f'"{c}"' for c in present] or None), missing

    def tenants_join(self, alias, tbl_cfg):
        """Opt-in active-tenants join.

        Off by default: the tenants table lives in one database only, so joining
        it across a UAT/PROD pair would silently filter one side.
        """
        act = tbl_cfg.get("active_tenants") or self.dwi.get("active_tenants")
        if not act or tbl_cfg.get("tenant_join", self.dwi.get("tenant_join", False)) is False:
            return ""
        return (f" INNER JOIN {act} AS act ON {alias}.client_name = act.client_name "
                f"AND {alias}.client_region = act.client_region")

    def columns(self, spec, table):
        db, schema = self.split_side(spec)
        return self.q(f"""
            SELECT column_name, ordinal_position, data_type
            FROM {db}.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = '{schema}' AND table_name = '{table}'
            ORDER BY ordinal_position""")

    def projection(self, cols, tbl_cfg, alias=None):
        override = tbl_cfg.get("projection_override")
        if override:
            return override
        nullif_text = tbl_cfg.get("nullif_text", self.defaults.get("nullif_text", True))
        trim_text = tbl_cfg.get("trim_text", self.defaults.get("trim_text", False))
        drop = set(col_map(tbl_cfg, "exclude_columns")) | set(accepted_columns_map(tbl_cfg))
        parts = []
        for name, _o, dtype in cols:
            if name in drop:
                continue
            ref = f'{alias + "." if alias else ""}"{name}"'
            if dtype in TEXT_TYPES:
                expr = f"TRIM({ref})" if trim_text else ref
                if nullif_text:
                    expr = f"NULLIF({expr}, '')"
                parts.append(f'{expr} AS "{name}"')
            else:
                parts.append(f'{ref} AS "{name}"')
        return ",\n       ".join(parts)

    # -- tiers --------------------------------------------------------------

    def d0(self, table):
        pdb, pschema = self.split_side(self.prod)
        udb, uschema = self.split_side(self.uat)
        rows = self.q(f"""
            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM {pdb}.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = '{pschema}' AND table_name = '{table}') p
            FULL JOIN (SELECT * FROM {udb}.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = '{uschema}' AND table_name = '{table}') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)""")
        drift = [{"column": r[0], "prod_ord": r[1], "uat_ord": r[2],
                  "prod_type": r[3], "uat_type": r[4]} for r in rows]
        return {"status": PASS if not drift else FAIL, "drift": drift}

    def row_counts(self, table, tbl_cfg):
        prod, uat = self.fq(self.prod, table), self.fq(self.uat, table)
        rows = self.q(f"""
            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM {prod} t {self.tenants_join('t', tbl_cfg)}) p,
                 (SELECT COUNT(*) AS n FROM {uat} t {self.tenants_join('t', tbl_cfg)}) u""")
        pn, un, diff = rows[0] if rows else (None, None, None)
        return {"prod_rows": pn, "uat_rows": un, "diff": diff}

    def d1(self, table, key_cols, tbl_cfg, totals=None):
        n = int(self.defaults.get("sample_rows", 25))
        out = {"dups": {}, "sample_columns": [k.strip('"') for k in key_cols] + ["n"],
               "sample_rows": {}}
        tkeys = ", ".join("t." + c for c in key_cols)
        for env, db in (("prod", self.prod), ("uat", self.uat)):
            rows = self.q(f"""
                SELECT {tkeys}, COUNT(*) AS n
                FROM {self.fq(db, table)} t {self.tenants_join('t', tbl_cfg)}
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT {max(n, 100)}""")
            out["dups"][env] = {"dup_key_count": len(rows)}
            if rows:
                out["sample_rows"][env] = [list(r) for r in rows[:n]]
        clean = all(v["dup_key_count"] == 0 for v in out["dups"].values())
        denom = max(totals or (0,)) if totals else 0
        worst = max(v["dup_key_count"] for v in out["dups"].values())
        out["status"] = PASS if clean else (ACC if within_threshold(worst, denom, self.threshold()) else FAIL)
        out["grain_unique"] = clean
        out["grain_usable"] = clean or out["status"] == ACC
        return out

    def d2(self, table, key_cols, tbl_cfg, totals=None, row_counts=None):
        n = int(self.defaults.get("sample_rows", 25))
        out = {}
        if row_counts:
            out.update({k: row_counts.get(k) for k in ("prod_rows", "uat_rows", "diff")})
        if not key_cols:
            out["status"] = SKIP
            out["reason"] = "no grain resolved"
            return out

        def key_select(db):
            return (f"SELECT {', '.join('t.' + c for c in key_cols)} "
                    f"FROM {self.fq(db, table)} t {self.tenants_join('t', tbl_cfg)}")

        kd, ks = {}, {}
        for direction, a, b in (("in_prod_not_uat", self.prod, self.uat),
                                ("in_uat_not_prod", self.uat, self.prod)):
            rows = self.q(f"SELECT COUNT(*) FROM ({key_select(a)} MINUS {key_select(b)})")
            kd[direction] = rows[0][0] if rows else None
            if kd[direction]:
                srows = self.q(f"SELECT * FROM ({key_select(a)} MINUS {key_select(b)}) LIMIT {n}")
                ks[direction] = [list(r) for r in srows]
        out["key_diff"] = kd
        out["key_columns"] = [k.strip('"') for k in key_cols]
        if ks:
            out["key_samples"] = ks
        denom = max(totals or (0,)) if totals else 0
        worst = max([v or 0 for v in kd.values()] + [0])
        clean = all((v or 0) == 0 for v in kd.values())
        out["status"] = PASS if clean else (ACC if within_threshold(worst, denom, self.threshold()) else FAIL)
        out["threshold_pct"] = self.threshold() or None
        return out

    def d3(self, table, cols, key_cols, tbl_cfg):
        prod, uat = self.fq(self.prod, table), self.fq(self.uat, table)
        key_set = set(key_cols)
        excluded = col_map(tbl_cfg, "exclude_columns")
        accepted = accepted_columns_map(tbl_cfg)
        nullif_text = tbl_cfg.get("nullif_text", self.defaults.get("nullif_text", True))
        trim_text = tbl_cfg.get("trim_text", self.defaults.get("trim_text", False))

        exprs, diff_cols, residual_exprs = [], [], []
        for name, _o, dtype in cols:
            qn = f'"{name}"'
            if qn in key_set or name in excluded:
                continue
            diff_cols.append(name)
            p, u = f"p.{qn}", f"u.{qn}"
            if dtype in TEXT_TYPES:
                if trim_text:
                    p, u = f"TRIM({p})", f"TRIM({u})"
                if nullif_text:
                    p, u = f"NULLIF({p},'')", f"NULLIF({u},'')"
            mismatch = f"NOT EQUAL_NULL({p}, {u})"
            exprs.append(f"COUNT_IF({mismatch}) AS {qn}")
            where_tpl = (accepted.get(name) or {}).get("where")
            if where_tpl:
                where_sql = where_tpl.replace("prod_value", p).replace("uat_value", u)
                residual_exprs.append(
                    (name, f'COUNT_IF({mismatch} AND NOT ({where_sql})) AS "{name}__residual"'))

        if not exprs:
            # Every column is either a grain column or excluded - there is
            # nothing left to diff, and emitting SQL would produce a dangling
            # comma. Real cause in dry-run: the column list is unknown.
            return {"status": SKIP,
                    "reason": ("no comparable columns (all columns are grain or excluded)"
                               if not self.dry_run else
                               "column list unavailable in dry-run - D3 SQL shown once connected")}

        act = self.tenants_join("p", tbl_cfg)
        sql = ("SELECT COUNT(*) AS shared_keys,\n       "
               + ",\n       ".join(exprs + [e for _, e in residual_exprs])
               + f"\nFROM {prod} p\nJOIN {uat} u USING ({', '.join(key_cols)})"
               + (f"\n{act}" if act else ""))
        rows = self.q(sql)
        if not rows:
            return {"status": ERR if not self.dry_run else "DRY", "sql": sql}
        vals = rows[0]
        shared = vals[0]
        main = vals[1:1 + len(diff_cols)]
        resid_vals = vals[1 + len(diff_cols):]
        per_col = {c: v for c, v in zip(diff_cols, main) if v and v > 0}
        residual = {name: v for (name, _), v in zip(residual_exprs, resid_vals)}

        col_status, reasons, accepted_where = {}, {}, {}
        for c, v in per_col.items():
            entry = accepted.get(c)
            if entry and entry.get("where"):
                accepted_where[c] = entry["where"]
                r = residual.get(c, v)
                base = entry.get("reason") or "marked as accepted in config"
                if r == 0:
                    col_status[c] = "ACCEPTED_MARKED"
                    reasons[c] = f"{base} - where-clause explains all {v:,} diffs"
                elif within_threshold(r, shared, self.threshold()):
                    col_status[c] = "ACCEPTED_THRESHOLD"
                    reasons[c] = f"{base} - explains {v - r:,} of {v:,}; remaining {r:,} within threshold"
                else:
                    col_status[c] = FAIL
                    reasons[c] = f"{base} - explains {v - r:,} of {v:,}; {r:,} unexplained remain"
            elif entry:
                col_status[c] = "ACCEPTED_MARKED"
                reasons[c] = entry.get("reason") or "marked as accepted in config"
            elif within_threshold(v, shared, self.threshold()):
                col_status[c] = "ACCEPTED_THRESHOLD"
            else:
                col_status[c] = FAIL

        status = (PASS if not per_col else
                  FAIL if any(s == FAIL for s in col_status.values()) else ACC)
        out = {"status": status, "shared_keys": shared, "mismatched_columns": per_col,
               "column_status": col_status, "accepted_reasons": reasons,
               "accepted_where": accepted_where, "residual_mismatches": residual,
               "excluded_columns": excluded, "threshold_pct": self.threshold() or None,
               "sql": sql}

        if per_col:
            cap = int(self.defaults.get("t3_sample_columns", 20))
            per_n = int(self.defaults.get("t3_samples_per_column", 15))
            dtypes = {name: dt for name, _o, dt in cols}
            key_list = ", ".join(key_cols)
            pkeys = ", ".join("p." + c for c in key_cols)
            where_cols = sorted((c for c in per_col if c in residual), key=lambda c: -residual[c])
            other = sorted((c for c in per_col if c not in residual), key=lambda c: -per_col[c])
            ranked = where_cols + other[: max(cap - len(where_cols), 0)]
            samples = {}
            for cname in ranked:
                qn = f'"{cname}"'
                pe, ue = f"p.{qn}", f"u.{qn}"
                if dtypes.get(cname) in TEXT_TYPES:
                    if trim_text:
                        pe, ue = f"TRIM({pe})", f"TRIM({ue})"
                    if nullif_text:
                        pe, ue = f"NULLIF({pe},'')", f"NULLIF({ue},'')"
                clause = f"NOT EQUAL_NULL({pe}, {ue})"
                entry = accepted.get(cname)
                if entry and entry.get("where"):
                    excl = entry["where"].replace("prod_value", pe).replace("uat_value", ue)
                    clause += f"\n  AND NOT ({excl})"
                srows = self.q(
                    f"SELECT {pkeys}, p.{qn} AS prod_value, u.{qn} AS uat_value\n"
                    f"FROM {prod} p\nJOIN {uat} u USING ({key_list})"
                    + (f"\n{act}" if act else "")
                    + f"\nWHERE {clause}\nLIMIT {per_n}")
                samples[cname] = [list(r) for r in srows]
            out["column_samples"] = samples
            out["column_sample_columns"] = [k.strip('"') for k in key_cols] + ["PROD value", "UAT value"]
        return out

    def d4(self, table, cols, tbl_cfg):
        prod, uat = self.fq(self.prod, table), self.fq(self.uat, table)
        proj = self.projection(cols, tbl_cfg, alias="t")
        rows = self.q(f"""SELECT HASH_AGG(*) FROM (SELECT {proj} FROM {prod} t {self.tenants_join('t', tbl_cfg)})
UNION
SELECT HASH_AGG(*) FROM (SELECT {proj} FROM {uat} t {self.tenants_join('t', tbl_cfg)})""")
        return {"status": PASS if len(rows) == 1 else FAIL if rows else ERR,
                "distinct_fingerprints": len(rows)}

    # -- ladder -------------------------------------------------------------

    def run_table(self, table):
        tbl_cfg = self.view_cfg(table)
        res = {"view": table, "mode": "dwi", "tiers": {}, "verdict": None, "notes": []}
        tiers = res["tiers"]
        accept = accept_diff_map(tbl_cfg, DWI_TIERS, notes=res["notes"])

        prod_cols = self.columns(self.prod, table)
        uat_cols = self.columns(self.uat, table)
        if not self.dry_run:
            if not prod_cols and not uat_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("View absent in BOTH databases.")
                return res
            if not uat_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("View absent in UAT_DB.EDP_DWI - not yet deployed.")
                return res
            if not prod_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("View absent in PROD_DB.EDP_DWI (unexpected - raise it).")
                return res

        def record(name, fn, *a, **k):
            start = len(self.sql_log)
            try:
                out = fn(*a, **k)
            except Exception as e:  # noqa: BLE001
                out = {"status": ERR, "error": f"{type(e).__name__}: {e}"}
            out["queries"] = self.sql_log[start:]
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
                    + (f": {reason}" if reason else ""))
            tiers[name] = out
            print(f"  {name}: {out['status']}")
            return out

        d0 = record("D0", self.d0, table)
        if d0["status"] in (FAIL, ERR) and not self.dry_run:
            res["verdict"] = "D0 DRIFT" if d0["status"] == FAIL else ERR
            res["notes"].append("Schema drift - content tiers withheld until schemas agree.")
            return res

        available = [c[0] for c in (prod_cols or uat_cols)]
        if self.dry_run and not available:
            # No INFORMATION_SCHEMA result when not connected: assume the
            # configured grain exists so D1/D3 SQL can still be previewed.
            cfg_grain = tbl_cfg.get("grain", self.dwi.get("default_grain"))
            available = list(cfg_grain or [])
            prod_cols = prod_cols or [(c, i + 1, "TEXT") for i, c in enumerate(available)]
        key_cols, missing = self.grain_cols(tbl_cfg, available)
        if not key_cols and not missing:
            res["notes"].append(
                "No grain set for this view - D1/D3 skipped. D0/D2/D4 still apply. "
                "Fill in `grain:` in config.yaml to enable row-level diffs.")
        if missing and not self.dry_run:
            used = [k.strip('"') for k in key_cols] if key_cols else "no grain"
            res["notes"].append(
                f"Grain column(s) {', '.join(missing)} absent from {table} - using {used}.")

        try:
            rc = self.row_counts(table, tbl_cfg)
        except Exception as e:  # noqa: BLE001
            rc = {"error": f"{type(e).__name__}: {e}"}
            res["notes"].append(f"Row-count query failed: {rc['error']}")
        totals = (rc.get("prod_rows") or 0, rc.get("uat_rows") or 0)
        print(f"  row counts: PROD {rc.get('prod_rows')} / UAT {rc.get('uat_rows')}")

        if key_cols:
            d1 = record("D1", self.d1, table, key_cols, tbl_cfg, totals)
            grain_ok = d1.get("grain_usable", False)
            if not d1.get("grain_unique", True):
                res["notes"].append("Grain is NOT unique - extend it before trusting D2/D3.")
        else:
            tiers["D1"] = {"status": SKIP, "reason": "no grain resolved"}
            grain_ok = False

        record("D2", self.d2, table, key_cols, tbl_cfg, totals, rc)

        run_d3 = bool(key_cols and grain_ok) or (self.dry_run and key_cols)
        if run_d3:
            d3 = record("D3", self.d3, table, prod_cols, key_cols, tbl_cfg)
            content = d3["status"]
        else:
            tiers["D3"] = {"status": SKIP,
                           "reason": "no usable grain - join would fan out"}
            content = tiers["D2"].get("status")

        # The fingerprint only means something when EVERY content tier is clean.
        # Gating on D3 alone let a failing/accepted D2 through: HASH_AGG would then
        # differ by construction and contradict D2 rather than add information.
        content_tiers = [tiers[t].get("status") for t in ("D2", "D3") if t in tiers]
        all_clean = all(st in (PASS, SKIP) for st in content_tiers)
        if all_clean or self.defaults.get("always_fingerprint") or self.dry_run:
            record("D4", self.d4, table, prod_cols, tbl_cfg)
        else:
            accepted_only = not any(st == FAIL for st in content_tiers)
            tiers["D4"] = {"status": SKIP, "reason": (
                "differences were accepted within threshold - fingerprints differ by "
                "construction, so D4 adds nothing" if accepted_only else
                "content diffs present - fingerprints would differ by construction")}

        res["verdict"] = verdict_from(
            (v.get("status") for v in tiers.values()),
            has_accepted_columns=bool(accepted_columns_map(tbl_cfg)),
            dry_run=self.dry_run,
            no_grain=not key_cols,
        )
        return res
