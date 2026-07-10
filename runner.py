#!/usr/bin/env python3
"""
Kafka Migration Testing harness — runs the T0–T5 test ladder per table.

Implements the tiers from "Kafka Migration Testing" (EDATA):
  T0  schema parity            (INFORMATION_SCHEMA full join)
  T1  row counts               (active tenants only)
  T2a grain uniqueness         (both envs; needs grain)
  T3  key-set diff, both ways  (needs grain); full-row EXCEPT instead when
                                keyless or grain isn't usable, since T4
                                can't cover content drift in that case
  T4  column-level diff on shared keys (needs usable grain; runs whenever
                                grain is usable — no longer gated on T3)
  T5  aggregate fingerprint    (HASH_AGG; when the content check — T3 or
                                T4, whichever ran — is clean, or always_fingerprint)

Ladder logic per table:
  - If the table is missing on one side -> BLOCKED (likely Kafka import), stop.
  - If T0 returns rows -> FAIL and stop (everything below is unreliable).
  - T2/T4 are skipped when no grain is configured (keyless mode).
  - Every tier result is recorded even when a later tier fails.

Usage:
  python runner.py --config config.yaml [--tables LEARNING_ENROLMENT,...] [--dry-run]

Env vars: SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PRIVATE_KEY_PATH,
          SNOWFLAKE_PRIVATE_KEY_PASSPHRASE (optional)
"""

import argparse
import csv
import datetime as dt
import json
import os
import sys
from pathlib import Path

import yaml

TEXT_TYPES = {"TEXT"}  # Snowflake INFORMATION_SCHEMA reports all varchars as TEXT

PASS, FAIL, SKIP, ERR, BLOCKED = "PASS", "FAIL", "SKIPPED", "ERROR", "BLOCKED"
ACC = "ACCEPTED"  # differences exist but are within threshold / in accepted columns


def col_map(tbl_cfg, key):
    """Normalise exclude_columns / accepted_columns to {name: reason}."""
    out = {}
    for item in (tbl_cfg.get(key) or []):
        if isinstance(item, dict):
            out[item["column"]] = item.get("reason", "")
        else:
            out[str(item)] = ""
    return out


# ----------------------------------------------------------------------------
# Connection
# ----------------------------------------------------------------------------

def load_dotenv(path=".env", override=False):
    """Minimal .env loader — no extra dependency. Existing env vars win."""
    p = Path(path)
    if not p.exists():
        return
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key, val = key.strip(), val.strip().strip("'\"")
        if override:
            os.environ[key] = val
        else:
            os.environ.setdefault(key, val)


def connect(cfg):
    import snowflake.connector

    conn_cfg = cfg.get("connection") or {}
    params = dict(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        role=os.getenv("SNOWFLAKE_ROLE") or conn_cfg.get("role"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE") or conn_cfg.get("warehouse"),
        session_parameters={"QUERY_TAG": conn_cfg.get("query_tag", "kafka_migration_testing")},
    )
    if not params["account"] or not params["user"]:
        sys.exit("SNOWFLAKE_ACCOUNT and SNOWFLAKE_USER must be set (in .env or the environment).")

    authenticator = (os.getenv("SNOWFLAKE_AUTHENTICATOR") or "").lower()
    password = os.getenv("SNOWFLAKE_PASSWORD")
    key_path = os.getenv("SNOWFLAKE_PRIVATE_KEY_PATH")

    if authenticator == "externalbrowser":
        # SSO: opens the browser once; cache the token so re-runs don't re-prompt
        params["authenticator"] = "externalbrowser"
        params["client_store_temporary_credential"] = True
    elif password:
        params["password"] = password
    elif key_path:
        from cryptography.hazmat.primitives import serialization
        passphrase = os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")
        with open(key_path, "rb") as f:
            pkey = serialization.load_pem_private_key(
                f.read(), password=passphrase.encode() if passphrase else None
            )
        params["private_key"] = pkey.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    else:
        sys.exit("Set SNOWFLAKE_AUTHENTICATOR=externalbrowser, SNOWFLAKE_PASSWORD, "
                 "or SNOWFLAKE_PRIVATE_KEY_PATH (in .env or the environment).")

    conn = snowflake.connector.connect(**params)

    # Secondary roles: needed when no single role sees both databases.
    # Config accepts true (ALL), false/null (none), or a LIST of role names.
    # Prefer the list: 'ALL' can trip row-level-security scalar subqueries in
    # the BI views (error 090150) when multiple mapped roles are in session.
    sec = conn_cfg.get("use_secondary_roles", True)
    if sec:
        stmt = ("USE SECONDARY ROLES ALL" if sec is True
                else "USE SECONDARY ROLES " + ", ".join(sec))
        cur = conn.cursor()
        try:
            cur.execute(stmt)
        finally:
            cur.close()
    return conn


class Runner:
    def __init__(self, conn, cfg, out_dir, dry_run=False):
        self.conn = conn
        self.cfg = cfg
        self.env = cfg["environments"]
        self.defaults = cfg.get("defaults") or {}
        self.out_dir = Path(out_dir)
        self.dry_run = dry_run
        self.sql_log = []

    # -- helpers -------------------------------------------------------------

    def q(self, sql, fetch=True):
        """Run a query, log it, return list of tuples (or [] on dry run)."""
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
        """prod_db / uat_db accept 'DB' (schema from environments.schema)
        or a qualified 'DB.SCHEMA' (e.g. UAT_DB.BI_PRD, a static snapshot
        of the PROD BI schema). Returns (database, schema)."""
        spec = str(spec)
        if "." in spec:
            db, schema = spec.split(".", 1)
            return db, schema
        return spec, self.env["schema"]

    def fq(self, spec, table):
        db, schema = self.split_side(spec)
        return f"{db}.{schema}.{table}"

    def tenants_join(self, alias="t", tbl_cfg=None):
        if tbl_cfg is not None and tbl_cfg.get("tenant_join", True) is False:
            return ""
        act = self.env["active_tenants"]
        return (f" INNER JOIN {act} AS act ON {alias}.client_name = act.client_name "
                f"AND {alias}.client_region = act.client_region")

    def columns(self, spec, table):
        """[(name, ordinal, type)] from INFORMATION_SCHEMA, in position order."""
        db, schema = self.split_side(spec)
        rows = self.q(f"""
            SELECT column_name, ordinal_position, data_type
            FROM {db}.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = '{schema}' AND table_name = '{table}'
            ORDER BY ordinal_position""")
        return rows

    def projection(self, cols, tbl_cfg, alias=None):
        """Normalised projection: NULLIF/TRIM on TEXT columns, others raw."""
        override = tbl_cfg.get("projection_override")
        if override:
            return override
        nullif_text = tbl_cfg.get("nullif_text", self.defaults.get("nullif_text", True))
        trim_text = tbl_cfg.get("trim_text", self.defaults.get("trim_text", False))
        drop = set(col_map(tbl_cfg, "exclude_columns")) | set(col_map(tbl_cfg, "accepted_columns"))
        parts = []
        for name, _ord, dtype in cols:
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

    @staticmethod
    def kept_col_names(cols, tbl_cfg):
        """Column names actually present in the normalised projection —
        i.e. all columns minus exclude_columns and accepted_columns.
        MUST stay in lockstep with projection(); sample_columns built from
        anything else will mislabel sample rows."""
        drop = set(col_map(tbl_cfg, "exclude_columns")) | set(col_map(tbl_cfg, "accepted_columns"))
        return [name for name, _o, _d in cols if name not in drop]

    def threshold(self):
        return float(self.defaults.get("diff_threshold_pct", 0) or 0)

    def within(self, count, denom):
        """True if a non-zero difference is within the accepted threshold."""
        thr = self.threshold()
        return thr > 0 and denom and count and (100.0 * count / denom) <= thr

    @staticmethod
    def grain_cols(tbl_cfg):
        g = tbl_cfg.get("grain")
        return [f'"{c}"' for c in g] if g else None

    # -- tiers ---------------------------------------------------------------

    def probe_sides(self, table):
        """When a tier errors, check whether each side's view evaluates at all.
        Attributes errors raised inside the view definition (e.g. 090150
        single-row subquery) to the environment that throws them."""
        findings = []
        for env_name, db in (("PROD", self.env["prod_db"]), ("UAT", self.env["uat_db"])):
            try:
                self.q(f"SELECT 1 FROM {self.fq(db, table)} LIMIT 1")
            except Exception as e:  # noqa: BLE001
                findings.append(f"{env_name} side fails to evaluate: {type(e).__name__}: {e}")
        return findings

    def t0(self, table):
        pdb, pschema = self.split_side(self.env["prod_db"])
        udb, uschema = self.split_side(self.env["uat_db"])
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

    def t1(self, table, tbl_cfg):
        prod = self.fq(self.env["prod_db"], table)
        uat = self.fq(self.env["uat_db"], table)
        rows = self.q(f"""
            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)}) p,
                 (SELECT COUNT(*) AS n FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)}) u""")
        prod_n, uat_n, diff = rows[0] if rows else (None, None, None)
        st = ERR
        out = {"prod_rows": prod_n, "uat_rows": uat_n, "diff": diff,
               "threshold_pct": self.threshold() or None}
        if diff is not None:
            denom = max(prod_n or 0, uat_n or 0)
            st = PASS if diff == 0 else (ACC if self.within(abs(diff), denom) else FAIL)
        out["status"] = st
        # examples: which clients contribute to the difference, worst first
        if diff not in (None, 0) and tbl_cfg.get("tenant_join", True) is not False:
            n = self.defaults.get("sample_rows", 25)
            brows = self.q(f"""
                SELECT COALESCE(p.client_name, u.client_name)   AS client_name,
                       COALESCE(p.client_region, u.client_region) AS client_region,
                       COALESCE(p.n, 0) AS prod_rows, COALESCE(u.n, 0) AS uat_rows,
                       COALESCE(p.n, 0) - COALESCE(u.n, 0) AS diff
                FROM (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)}
                      GROUP BY 1, 2) p
                FULL JOIN (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)}
                      GROUP BY 1, 2) u
                  ON p.client_name = u.client_name AND p.client_region = u.client_region
                WHERE COALESCE(p.n, 0) != COALESCE(u.n, 0)
                ORDER BY ABS(COALESCE(p.n, 0) - COALESCE(u.n, 0)) DESC
                LIMIT {n}""")
            out["breakdown_columns"] = ["CLIENT_NAME", "CLIENT_REGION",
                                        "PROD rows", "UAT rows", "diff"]
            out["breakdown"] = [list(r) for r in brows]
        return out

    def t2(self, table, key_cols, tbl_cfg, totals=None):
        """Grain uniqueness only. Key-set membership moved to T3."""
        n = self.defaults.get("sample_rows", 25)
        keys = ", ".join(key_cols)
        out = {"dups": {}, "sample_columns": [k.strip('"') for k in key_cols] + ["n"],
               "sample_rows": {}}
        tkeys = ", ".join("t." + c for c in key_cols)
        for env_name, db in (("prod", self.env["prod_db"]), ("uat", self.env["uat_db"])):
            rows = self.q(f"""
                SELECT {tkeys}, COUNT(*) AS n
                FROM {self.fq(db, table)} t {self.tenants_join(tbl_cfg=tbl_cfg)}
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT {max(n, 100)}""")
            out["dups"][env_name] = {"dup_key_count": len(rows)}
            if rows:
                out["sample_rows"][env_name] = [list(r) for r in rows[:n]]
        dups_clean = all(v["dup_key_count"] == 0 for v in out["dups"].values())
        denom = max(totals or (0,)) if totals else 0
        worst = max(v["dup_key_count"] for v in out["dups"].values())
        out["status"] = (PASS if dups_clean else
                         ACC if self.within(worst, denom) else FAIL)
        out["threshold_pct"] = self.threshold() or None
        out["denominator"] = denom or None
        out["grain_unique"] = dups_clean
        # unique enough for key-based tests (T4 fan-out is marginal within threshold)
        out["grain_usable"] = dups_clean or out["status"] == ACC
        return out

    def t3(self, table, cols, tbl_cfg, totals=None, grain_ok=True):
        """Key-set membership diff, both directions.

        Full-row content comparison only happens here when there's no
        better check available for it:
          - keyless tables (no grain configured) — T4 is impossible, so the
            full-row EXCEPT stays here as the only content check.
          - keyed tables whose grain isn't usable (dup keys beyond
            threshold) — T4 is skipped too (the join would fan out), so the
            full-row EXCEPT (restricted to shared keys) stays as a fallback.
          - keyed tables with a usable grain — T4's per-column breakdown
            over the same shared-key population is strictly more
            informative, so the full-row EXCEPT is skipped here entirely;
            T3 is just the key-presence check in that case.
        """
        prod = self.fq(self.env["prod_db"], table)
        uat = self.fq(self.env["uat_db"], table)
        key_cols = self.grain_cols(tbl_cfg)
        n = self.defaults.get("sample_rows", 25)
        result = {"rows_scope": "shared_keys" if key_cols else "all"}

        key_diff = None
        if key_cols:
            def key_select(db):
                return (f"SELECT {', '.join('t.' + c for c in key_cols)} "
                        f"FROM {self.fq(db, table)} t {self.tenants_join(tbl_cfg=tbl_cfg)}")
            kd, ks = {}, {}
            pdb, udb = self.env["prod_db"], self.env["uat_db"]
            for direction, a, b in (("in_prod_not_uat", pdb, udb),
                                    ("in_uat_not_prod", udb, pdb)):
                crows = self.q(f"SELECT COUNT(*) FROM ({key_select(a)} MINUS {key_select(b)})")
                kd[direction] = crows[0][0] if crows else None
                if kd[direction]:
                    srows = self.q(f"SELECT * FROM ({key_select(a)} MINUS {key_select(b)}) LIMIT {n}")
                    ks[direction] = [list(r) for r in srows]
            result["key_diff"] = kd
            result["key_columns"] = [k.strip('"') for k in key_cols]
            if ks:
                result["key_samples"] = ks
            key_diff = kd

        if key_cols and grain_ok:
            # T4 covers content drift for this table — T3 is key-presence only.
            keys_clean = all((v or 0) == 0 for v in key_diff.values())
            denom = max(totals or (0,)) if totals else 0
            worst = max([v or 0 for v in key_diff.values()] + [0])
            result["status"] = (PASS if keys_clean else
                                (ACC if self.within(worst, denom) else FAIL))
            result["threshold_pct"] = self.threshold() or None
            result["denominator"] = denom or None
            result["full_row_check"] = "skipped — content drift covered by T4"
            return result

        # full-row EXCEPT — keyless mode, or keyed-but-ungrain-usable fallback
        proj = self.projection(cols, tbl_cfg, alias="t")
        if key_cols:
            tkeys = ", ".join("t." + c for c in key_cols)
            skjoin = " AND ".join(f"EQUAL_NULL(t.{c}, sk.{c})" for c in key_cols)
            cte = f"""WITH shared_keys AS (
       SELECT {tkeys} FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)}
       INTERSECT
       SELECT {tkeys} FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)}),
     prod AS (SELECT {proj}
       FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)}
       JOIN shared_keys sk ON {skjoin}),
     uat AS (SELECT {proj}
       FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)}
       JOIN shared_keys sk ON {skjoin})"""
        else:
            cte = f"""WITH prod AS (SELECT {proj}
       FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)}),
     uat AS (SELECT {proj}
       FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)})"""
        rows = self.q(f"""{cte}
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)""")
        counts = {r[0]: r[1] for r in rows}
        result["counts"] = counts
        result["cte"] = cte
        rows_clean = counts and all(v == 0 for v in counts.values())
        keys_clean = all((v or 0) == 0 for v in (key_diff or {}).values())
        denom = max(totals or (0,)) if totals else 0
        worst = max(list(counts.values()) +
                    [v or 0 for v in (key_diff or {}).values()] + [0])
        result["status"] = (PASS if rows_clean and keys_clean else
                            (ACC if self.within(worst, denom) else FAIL) if counts else ERR)
        result["threshold_pct"] = self.threshold() or None
        result["denominator"] = denom or None
        if not rows_clean and counts:
            ns = self.defaults.get("full_row_sample_rows",
                                  self.defaults.get("sample_rows", 25))
            samples = {}
            for direction, a, b in (("in_prod_not_uat", "prod", "uat"),
                                    ("in_uat_not_prod", "uat", "prod")):
                if counts.get(direction, 0) > 0:
                    srows = self.q(f"{cte}\nSELECT * FROM (SELECT * FROM {a} "
                                   f"EXCEPT SELECT * FROM {b}) LIMIT {ns}")
                    samples[direction] = [list(r) for r in srows]
            result["samples"] = samples
            result["sample_columns"] = self.kept_col_names(cols, tbl_cfg)
        return result

    def t4(self, table, cols, key_cols, tbl_cfg):
        prod = self.fq(self.env["prod_db"], table)
        uat = self.fq(self.env["uat_db"], table)
        key_set = set(key_cols)  # already quoted
        excluded = col_map(tbl_cfg, "exclude_columns")
        accepted = col_map(tbl_cfg, "accepted_columns")
        nullif_text = tbl_cfg.get("nullif_text", self.defaults.get("nullif_text", True))
        trim_text = tbl_cfg.get("trim_text", self.defaults.get("trim_text", False))
        exprs = []
        diff_cols = []
        for name, _ord, dtype in cols:
            qn = f'"{name}"'
            if qn in key_set or name in excluded:
                continue
            diff_cols.append(name)
            if dtype in TEXT_TYPES:
                p, u = f'p.{qn}', f'u.{qn}'
                if trim_text:
                    p, u = f"TRIM({p})", f"TRIM({u})"
                if nullif_text:
                    p, u = f"NULLIF({p},'')", f"NULLIF({u},'')"
                exprs.append(f'COUNT_IF(NOT EQUAL_NULL({p}, {u})) AS {qn}')
            else:
                exprs.append(f'COUNT_IF(NOT EQUAL_NULL(p.{qn}, u.{qn})) AS {qn}')
        act = self.tenants_join(alias="p", tbl_cfg=tbl_cfg)
        sql = (f"SELECT COUNT(*) AS shared_keys,\n       "
               + ",\n       ".join(exprs)
               + f"\nFROM {prod} p\nJOIN {uat} u USING ({', '.join(key_cols)})"
               + (f"\n{act}" if act else ""))
        rows = self.q(sql)
        if not rows:
            return {"status": ERR, "sql": sql}
        vals = rows[0]
        shared = vals[0]
        per_col = {c: v for c, v in zip(diff_cols, vals[1:]) if v and v > 0}
        # classify every mismatching column: accepted (marked) / accepted
        # (within threshold) / fail
        col_status, reasons = {}, {}
        for c, v in per_col.items():
            if c in accepted:
                col_status[c] = "ACCEPTED_MARKED"
                reasons[c] = accepted[c] or "marked as accepted in config"
            elif self.within(v, shared):
                col_status[c] = "ACCEPTED_THRESHOLD"
            else:
                col_status[c] = FAIL
        st = (PASS if not per_col else
              FAIL if any(s == FAIL for s in col_status.values()) else ACC)
        out = {"status": st, "shared_keys": shared,
               "mismatched_columns": per_col, "column_status": col_status,
               "accepted_reasons": reasons,
               "threshold_pct": self.threshold() or None,
               "excluded_columns": excluded, "sql": sql}
        # per-column examples: grain key + PROD vs UAT value, for the worst columns
        if per_col:
            cap_cols = self.defaults.get("t4_sample_columns", 10)
            per_n = self.defaults.get("t4_samples_per_column", 5)
            dtypes = {name: dt for name, _o, dt in cols}
            key_list = ", ".join(key_cols)
            pkey_list = ", ".join("p." + c for c in key_cols)
            col_samples = {}
            for cname, _cnt in sorted(per_col.items(), key=lambda x: -x[1])[:cap_cols]:
                qn = f'"{cname}"'
                pexpr, uexpr = f"p.{qn}", f"u.{qn}"
                if dtypes.get(cname) in TEXT_TYPES:
                    if trim_text:
                        pexpr, uexpr = f"TRIM({pexpr})", f"TRIM({uexpr})"
                    if nullif_text:
                        pexpr, uexpr = f"NULLIF({pexpr},'')", f"NULLIF({uexpr},'')"
                srows = self.q(
                    f"SELECT {pkey_list}, p.{qn} AS prod_value, u.{qn} AS uat_value\n"
                    f"FROM {prod} p\nJOIN {uat} u USING ({key_list})"
                    + (f"\n{act}" if act else "") +
                    f"\nWHERE NOT EQUAL_NULL({pexpr}, {uexpr})\nLIMIT {per_n}")
                col_samples[cname] = [list(r) for r in srows]
            out["column_samples"] = col_samples
            out["column_sample_columns"] = [k.strip('"') for k in key_cols] + ["PROD value", "UAT value"]
            if len(per_col) > cap_cols:
                out["column_samples_note"] = (
                    f"Examples shown for the top {cap_cols} of {len(per_col)} mismatching columns.")
        return out

    def t5(self, table, cols, tbl_cfg):
        prod = self.fq(self.env["prod_db"], table)
        uat = self.fq(self.env["uat_db"], table)
        proj = self.projection(cols, tbl_cfg, alias="t")
        rows = self.q(f"""
SELECT HASH_AGG(*) FROM (SELECT {proj} FROM {prod} t {self.tenants_join(tbl_cfg=tbl_cfg)})
UNION
SELECT HASH_AGG(*) FROM (SELECT {proj} FROM {uat} t {self.tenants_join(tbl_cfg=tbl_cfg)})""")
        # UNION dedupes: 1 row => equal fingerprints
        return {"status": PASS if len(rows) == 1 else FAIL if rows else ERR,
                "distinct_fingerprints": len(rows)}

    # -- ladder --------------------------------------------------------------

    def run_table(self, tbl_cfg):
        table = tbl_cfg["name"]
        res = {"table": table, "expected_blocked": tbl_cfg.get("expected_blocked", []),
               "tiers": {}, "verdict": None, "notes": []}
        tiers = res["tiers"]
        print(f"\n=== {table} ===")

        prod_cols = self.columns(self.env["prod_db"], table)
        uat_cols = self.columns(self.env["uat_db"], table)
        if not self.dry_run:
            if not prod_cols and not uat_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("Table absent in BOTH environments.")
                return res
            if not uat_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("Table absent in UAT — consistent with BLOCKED ON KAFKA IMPORT.")
                return res
            if not prod_cols:
                res["verdict"] = BLOCKED
                res["notes"].append("Table absent in PROD (unexpected — raise it).")
                return res

        def attempt(name, fn, *a, **k):
            sql_start = len(self.sql_log)
            try:
                out = fn(*a, **k)
            except Exception as e:  # noqa: BLE001 — record and continue
                out = {"status": ERR, "error": f"{type(e).__name__}: {e}"}
            out["queries"] = self.sql_log[sql_start:]
            if self.dry_run:
                out["status"] = "DRY"
            tiers[name] = out
            print(f"  {name}: {out['status']}")
            return out

        # T0 — stop the ladder on drift, per the plan
        t0 = attempt("T0", self.t0, table)
        if t0["status"] in (FAIL, ERR) and not self.dry_run:
            res["verdict"] = "T0 DRIFT" if t0["status"] == FAIL else ERR
            res["notes"].append("Schema drift — everything below is unreliable until schemas agree.")
            return res

        excluded = col_map(tbl_cfg, "exclude_columns")
        accepted = col_map(tbl_cfg, "accepted_columns")
        if excluded:
            res["excluded_columns"] = excluded
        if accepted:
            res["accepted_columns"] = accepted

        attempt("T1", self.t1, table, tbl_cfg)
        t1 = tiers["T1"]
        totals = (t1.get("prod_rows") or 0, t1.get("uat_rows") or 0)
        if not self.dry_run and tiers["T1"].get("uat_rows") == 0 and tiers["T1"].get("prod_rows", 0) > 0:
            res["notes"].append("UAT has zero rows — likely Kafka import not landed.")

        key_cols = self.grain_cols(tbl_cfg)
        if key_cols:
            t2 = attempt("T2", self.t2, table, key_cols, tbl_cfg, totals)
            if not self.dry_run and not t2.get("grain_unique", True):
                res["notes"].append("Configured grain is NOT unique — extend it before trusting T2b/T4.")
        else:
            tiers["T2"] = {"status": SKIP, "reason": "no grain configured"}
            print("  T2: SKIPPED (no grain)")

        grain_ok = tiers.get("T2", {}).get("grain_usable",
                   tiers.get("T2", {}).get("grain_unique", False))

        t3 = attempt("T3", self.t3, table, prod_cols, tbl_cfg, totals, grain_ok=grain_ok)

        # T4 is the content-drift check whenever the grain is usable — it no
        # longer waits for T3 to report a problem, since T3 is now just a
        # key-presence check in that case (see t3()'s docstring).
        run_t4 = bool(key_cols and grain_ok) or (self.dry_run and key_cols)
        if run_t4 and not tiers.get("T2", {}).get("grain_unique"):
            res["notes"].append("Grain has duplicate keys within threshold — "
                                "T4 counts may be slightly inflated by join fan-out.")
        if run_t4:
            attempt("T4", self.t4, table, prod_cols, key_cols, tbl_cfg)
        elif key_cols:
            tiers["T4"] = {"status": SKIP,
                           "reason": "no usable grain — cannot join on keys"}
        else:
            tiers["T4"] = {"status": SKIP, "reason": "no grain configured"}

        # Whichever tier actually performed the content comparison (T4 when
        # grain is usable, T3's full-row fallback otherwise) drives whether
        # T5's full-table fingerprint is worth running.
        content_status = tiers["T4"]["status"] if run_t4 else t3["status"]

        if content_status == ACC and "T5" not in tiers and not self.defaults.get("always_fingerprint"):
            tiers["T5"] = {"status": SKIP, "reason": "content diffs within threshold — fingerprints would differ by construction"}
        if "T5" not in tiers and (content_status == PASS or self.defaults.get("always_fingerprint") or self.dry_run):
            attempt("T5", self.t5, table, prod_cols, tbl_cfg)
        else:
            tiers["T5"] = {"status": SKIP, "reason": "content diffs found (T3/T4)"}

        # verdict
        statuses = {t: v.get("status") for t, v in tiers.items()}
        sts = set(statuses.values())
        if ERR in sts and not self.dry_run:
            for finding in self.probe_sides(table):
                res["notes"].append(finding)
        if ERR in sts:
            res["verdict"] = ERR
        elif FAIL in sts:
            res["verdict"] = "DIFFS FOUND"
        elif ACC in sts or accepted:
            res["verdict"] = "PASS (DIFFS ACCEPTED)"
        elif sts <= {PASS, SKIP, "DRY"}:
            res["verdict"] = PASS
        else:
            res["verdict"] = "DIFFS FOUND"
        return res


# ----------------------------------------------------------------------------
# Reporting
# ----------------------------------------------------------------------------

def write_reports(results, out_dir, dry_run):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "results.json").write_text(json.dumps(results, indent=2, default=str))

    lines = ["# Kafka Migration Testing — Learning workstream",
             f"\nRun: {dt.datetime.now():%Y-%m-%d %H:%M} "
             + ("(DRY RUN — no queries executed)" if dry_run else ""), "",
             "| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |",
             "|---|---|---|---|---|---|---|---|---|"]
    icon = {PASS: "✅", FAIL: "❌", SKIP: "—", ERR: "⚠️", None: "·"}
    for r in results:
        t = r["tiers"]
        cells = [icon.get(t.get(k, {}).get("status"), "·")
                 for k in ("T0", "T1", "T2", "T3", "T4", "T5")]
        notes = "; ".join(r["notes"])
        if r.get("expected_blocked"):
            notes = (f"expected blocked: {'/'.join(r['expected_blocked'])}. " + notes).strip()
        lines.append(f"| {r['table']} | " + " | ".join(cells)
                     + f" | **{r['verdict']}** | {notes} |")

    lines.append("\n## Details\n")
    for r in results:
        lines.append(f"### {r['table']} — {r['verdict']}")
        t1 = r["tiers"].get("T1", {})
        if "prod_rows" in t1:
            lines.append(f"- T1 counts: PROD {t1['prod_rows']:,} / UAT {t1['uat_rows']:,} "
                         f"(diff {t1['diff']:+,})" if t1["prod_rows"] is not None else "- T1: no result")
        t3 = r["tiers"].get("T3", {})
        if "key_diff" in t3:
            kd = t3["key_diff"]
            lines.append(f"- T3 key diff: {kd.get('in_prod_not_uat')} in PROD-only, "
                         f"{kd.get('in_uat_not_prod')} in UAT-only "
                         f"(keys: {', '.join(t3.get('key_columns', []))})")
        if "counts" in t3:
            c = t3["counts"]
            lines.append(f"- T3 full-row EXCEPT (fallback — no T4 coverage for this table): "
                         f"{c.get('in_prod_not_uat')} PROD-not-UAT, {c.get('in_uat_not_prod')} UAT-not-PROD")
        t4 = r["tiers"].get("T4", {})
        if t4.get("mismatched_columns"):
            top = sorted(t4["mismatched_columns"].items(), key=lambda x: -x[1])[:15]
            lines.append(f"- T4 ({t4['shared_keys']:,} shared keys), mismatching columns: "
                         + ", ".join(f"`{c}`={n:,}" for c, n in top))
        for n in r["notes"]:
            lines.append(f"- ⚠ {n}")
        if r["tiers"].get("T3", {}).get("samples"):
            lines.append(f"- Sample mismatch rows: `samples/{r['table']}_*.csv`")
        lines.append("")

    (out_dir / "summary.md").write_text("\n".join(lines), encoding="utf-8")

    # sample CSVs
    sdir = out_dir / "samples"
    for r in results:
        t3 = r["tiers"].get("T3", {})
        for direction, rows in (t3.get("samples") or {}).items():
            sdir.mkdir(exist_ok=True)
            with open(sdir / f"{r['table']}_{direction}.csv", "w", newline="",
                      encoding="utf-8") as f:
                w = csv.writer(f)
                w.writerow(t3.get("sample_columns", []))
                w.writerows(rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config.yaml")
    ap.add_argument("--env-file", default=".env", help="path to a .env file (default: ./.env)")
    ap.add_argument("--tables", help="comma-separated subset of table names")
    ap.add_argument("--output-dir", default=None)
    ap.add_argument("--dry-run", action="store_true",
                    help="generate + log SQL without connecting or executing")
    ap.add_argument("--skip-blocked", default=None,
                    help="comma-separated block types to skip (e.g. KAFKA_IMPORT,REMOVAL); "
                         "overrides defaults.skip_blocked in config")
    ap.add_argument("--run-all", action="store_true",
                    help="ignore skip_blocked and run every table")
    args = ap.parse_args()

    load_dotenv(args.env_file, override=True)
    cfg = yaml.safe_load(Path(args.config).read_text())
    out_dir = args.output_dir or f"results_{dt.datetime.now():%Y%m%d_%H%M}"

    subset = {t.strip().upper() for t in args.tables.split(",")} if args.tables else None
    tables = [t for t in cfg["tables"] if not subset or t["name"].upper() in subset]
    if not tables:
        sys.exit("No tables matched.")

    # Which blocked categories to skip. Precedence: --run-all > --skip-blocked >
    # defaults.skip_blocked. Explicitly named tables (--tables) are never skipped.
    if args.run_all:
        skip_types = set()
    elif args.skip_blocked is not None:
        skip_types = {s.strip().upper() for s in args.skip_blocked.split(",") if s.strip()}
    else:
        skip_types = {str(s).upper() for s in (cfg.get("defaults") or {}).get("skip_blocked", [])}

    runnable, skipped = [], []
    for t in tables:
        blocked = {str(b).upper() for b in (t.get("expected_blocked") or [])}
        if blocked & skip_types and not subset:
            skipped.append((t, sorted(blocked & skip_types)))
        else:
            runnable.append(t)
    for t, why in skipped:
        print(f"SKIP {t['name']}  (blocked: {', '.join(why)})")

    conn = None if (args.dry_run or not runnable) else connect(cfg)
    runner = Runner(conn, cfg, out_dir, dry_run=args.dry_run)
    try:
        results = [runner.run_table(t) for t in runnable]
    finally:
        if conn:
            conn.close()
    # skipped tables still appear in the report, marked BLOCKED
    by_name = {t["name"]: i for i, t in enumerate(cfg["tables"])}
    for t, why in skipped:
        results.append({"table": t["name"],
                        "expected_blocked": t.get("expected_blocked", []),
                        "tiers": {}, "verdict": BLOCKED,
                        "notes": [f"Skipped by config — blocked: {', '.join(why)}. "
                                  f"Run with --tables {t['name']} or --run-all to include."]})
    results.sort(key=lambda r: by_name.get(r["table"], 999))

    write_reports(results, out_dir, args.dry_run)
    Path(out_dir, "queries.sql").write_text(
        "\n\n----------------\n\n".join(runner.sql_log), encoding="utf-8")
    print(f"\nDone. Summary: {out_dir}/summary.md  |  Raw: {out_dir}/results.json")

    # Refresh the multi-run dashboard if the generator is alongside this script
    dash = Path(__file__).with_name("dashboard.py")
    if dash.exists() and not args.dry_run:
        import subprocess
        subprocess.run([sys.executable, str(dash)], check=False)


if __name__ == "__main__":
    main()