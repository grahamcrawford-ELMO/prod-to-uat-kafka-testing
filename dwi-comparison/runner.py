#!/usr/bin/env python3
"""DWI Migration Testing harness (CRT-6323).

Two comparison modes, either or both per run:

  --mode csv   Redshift CSV extract  vs  Snowflake CSV extract, both in S3.
               Run folders are auto-discovered (latest per client on each side)
               because the two unload DAGs never share a timestamp; pin them
               with --redshift-run / --snowflake-run.

  --mode dwi   UAT_DB.EDP_DWI  vs  PROD_DB.EDP_DWI, in Snowflake.

  --mode both  Default.

Grain defaults to id + client_name + client_region (the common DWI shape), with
per-view overrides in config.yaml.

Usage:
  python runner.py --dry-run
  python runner.py --mode csv --clients uat1
  python runner.py --mode csv --views learning_enrolment,learning_course
  python runner.py --mode dwi --views DWI_LEARNING_ENROLMENT
  python runner.py --mode csv --clients uat1 --redshift-run 20260729223000 \
                              --snowflake-run 20260729224500
"""

from __future__ import annotations

import argparse
import datetime as dt
import sys
from pathlib import Path

# Run from any working directory, not just the repo root.
sys.path.insert(0, str(Path(__file__).resolve().parent))

import yaml

from dwi_testing.common import BLOCKED, ERR, expand_shared_views
from dwi_testing.connections import connect_snowflake, load_dotenv, s3_client
from dwi_testing.csv_ladder import CsvComparer
from dwi_testing.dwi_ladder import DwiComparer
from dwi_testing.report import write_reports
from dwi_testing.s3_source import S3Source, pair_runs


def parse_args(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config.yaml")
    ap.add_argument("--env-file", default=".env")
    ap.add_argument("--mode", choices=["csv", "dwi", "both"], default="both")
    ap.add_argument("--clients", help="comma-separated client names (CSV mode)")
    ap.add_argument("--views", help="comma-separated view subset (both modes)")
    ap.add_argument("--redshift-run", help="pin the Redshift run timestamp (CSV mode)")
    ap.add_argument("--snowflake-run", help="pin the Snowflake run timestamp (CSV mode)")
    ap.add_argument("--output-dir", default=None)
    ap.add_argument("--dry-run", action="store_true",
                    help="resolve config/SQL without connecting or reading S3")
    ap.add_argument("--fail-on-diff", action="store_true",
                    help="exit non-zero when any view reports diffs (for CI)")
    ap.add_argument("--no-dashboard", action="store_true",
                    help="skip regenerating dashboard.html after the run")
    return ap.parse_args(argv)


def subset_of(arg):
    """Comma-separated --views/--clients filter, case-insensitive.

    CSV view names are un-prefixed (learning_enrolment) while DWI names carry
    the DWI_ prefix (DWI_LEARNING_ENROLMENT). Both spellings are accepted in
    either mode so one --views list works for --mode both.
    """
    if not arg:
        return None
    out = set()
    for tok in arg.split(","):
        tok = tok.strip().lower()
        if not tok:
            continue
        out.add(tok)
        if tok.startswith("dwi_"):
            out.add(tok[4:])
        else:
            out.add("dwi_" + tok)
    return out


def view_in_scope(vcfg, client):
    """Per-view client scoping.

    The DWI_SYD_<client>_USER_PROFILE_DATA family is one view per tenant, so
    only that tenant's unload ever contains the matching CSV. Without scoping,
    running client `uat1` would report the other 19 tenants' views as BLOCKED
    on every run - noise that buries genuine pipeline misses.
    """
    scope = vcfg.get("clients")
    if not scope:
        return True
    return str(client).lower() in {str(c).lower() for c in scope}


def run_csv_mode(cfg, args, views_filter):
    csv_cfg = cfg.get("csv") or {}
    clients = [c for c in (csv_cfg.get("clients") or [])]
    wanted = subset_of(args.clients)
    if wanted:
        clients = [c for c in clients if str(c).lower() in wanted]
    if not clients:
        print("CSV mode: no clients configured/matched - skipping.")
        return []

    if args.dry_run:
        out = []
        for client in clients:
            for v in (csv_cfg.get("views") or []):
                name = str(v.get("name", "")).lower()
                if views_filter and name not in views_filter:
                    continue
                if not view_in_scope(v, client):
                    continue
                out.append({"client": client, "view": name, "mode": "csv",
                            "redshift_run": "(dry)", "snowflake_run": "(dry)",
                            "tiers": {k: {"status": "DRY"} for k in
                                      ("C0", "C1", "C2", "C3", "C4", "C5")},
                            "verdict": "DRY", "notes": []})
        return out

    source = S3Source(s3_client(cfg), csv_cfg)
    comparer = CsvComparer(source, cfg)
    results = []
    for client in clients:
        print(f"\n=== CSV: {client} ===")
        try:
            rs_run, sf_run = pair_runs(source, client, args.redshift_run, args.snowflake_run)
        except FileNotFoundError as e:
            results.append({"client": client, "view": "(all)", "mode": "csv",
                            "tiers": {}, "verdict": BLOCKED, "notes": [str(e)]})
            continue
        print(f"  redshift run {rs_run.timestamp} / snowflake run {sf_run.timestamp}")
        for run in (rs_run, sf_run):
            if run.encrypted_only:
                results.append({
                    "client": client, "view": "(all)", "mode": "csv",
                    "redshift_run": rs_run.timestamp, "snowflake_run": sf_run.timestamp,
                    "tiers": {}, "verdict": BLOCKED,
                    "notes": [f"{run.side} run {run.timestamp} holds only .pgp files - "
                              f"the encrypt task already ran. Re-run the unload, or point "
                              f"--{run.side}-run at a run folder that still has plain CSV."]})
                break
        else:
            shared, only_rs, only_sf = source.shared_views(rs_run, sf_run)
            targets = [v for v in shared if not views_filter or v in views_filter]
            for v in sorted(set(only_rs) | set(only_sf)):
                if views_filter and v not in views_filter:
                    continue
                results.append({
                    "client": client, "view": v, "mode": "csv",
                    "redshift_run": rs_run.timestamp, "snowflake_run": sf_run.timestamp,
                    "tiers": {"C0": {"status": "FAIL",
                                     "present": {"redshift": v in only_rs,
                                                 "snowflake": v in only_sf}}},
                    "verdict": BLOCKED,
                    "notes": [f"Only present on the "
                              f"{'Redshift' if v in only_rs else 'Snowflake'} side."]})
            # Views named in config but absent from BOTH sides would otherwise
            # vanish from the report entirely, since targets come from S3
            # discovery. Scope coverage must be explicit: a view the ticket
            # requires and nobody unloaded is BLOCKED, not silently omitted.
            configured = [(str(v.get("name", "")).lower(), v)
                          for v in (csv_cfg.get("views") or []) if v.get("name")]
            discovered = set(shared) | set(only_rs) | set(only_sf)
            for v, vcfg in configured:
                if v in discovered:
                    continue
                if views_filter and v not in views_filter:
                    continue
                if not view_in_scope(vcfg, client):
                    continue
                note = vcfg.get("absent_note") or (
                    "Configured for this ticket but not found in either run "
                    "folder - neither pipeline unloaded it.")
                results.append({
                    "client": client, "view": v, "mode": "csv",
                    "redshift_run": rs_run.timestamp, "snowflake_run": sf_run.timestamp,
                    "tiers": {"C0": {"status": "FAIL",
                                     "present": {"redshift": False, "snowflake": False}}},
                    "verdict": BLOCKED,
                    "notes": [note]})
            print(f"  {len(targets)} shared view(s) to compare")
            for view in targets:
                print(f"  -- {view}")
                try:
                    results.append(comparer.run_view(client, view, rs_run, sf_run))
                except Exception as e:  # noqa: BLE001
                    results.append({"client": client, "view": view, "mode": "csv",
                                    "tiers": {}, "verdict": ERR,
                                    "notes": [f"{type(e).__name__}: {e}"]})
    return results


def run_dwi_mode(cfg, args, views_filter):
    dwi_cfg = cfg.get("dwi") or {}
    views = [str(v.get("name")) for v in (dwi_cfg.get("views") or []) if v.get("name")]
    if views_filter:
        views = [v for v in views if v.lower() in views_filter]
    if not views:
        print("DWI mode: no views configured/matched - skipping.")
        return []

    conn = None if args.dry_run else connect_snowflake(cfg)
    comparer = DwiComparer(conn, cfg, dry_run=args.dry_run)
    results = []
    try:
        for view in views:
            print(f"\n=== DWI: {view} ===")
            results.append(comparer.run_table(view))
    finally:
        if conn:
            conn.close()
    return results, comparer.sql_log


def main(argv=None):
    args = parse_args(argv)
    load_dotenv(args.env_file, override=True)
    cfg = yaml.safe_load(Path(args.config).read_text())
    # One canonical `views:` list is expanded into both modes; a per-mode
    # `views:` list still wins so split configs keep working.
    cfg = expand_shared_views(cfg)
    views_filter = subset_of(args.views)
    out_dir = args.output_dir or f"results_{dt.datetime.now():%Y%m%d_%H%M}"

    csv_results, dwi_results, queries = [], [], []
    if args.mode in ("csv", "both"):
        csv_results = run_csv_mode(cfg, args, views_filter)
    if args.mode in ("dwi", "both"):
        dwi_results, queries = run_dwi_mode(cfg, args, views_filter)

    path = write_reports(csv_results, dwi_results, out_dir,
                         dry_run=args.dry_run, queries=queries)
    print(f"\nWrote {path}")

    if not args.no_dashboard:
        # The dashboard reads every results_*/ sibling, so it is rebuilt from the
        # parent of this run's output folder and picks up run history for free.
        try:
            from dashboard import collect_runs, TEMPLATE
            import json as _json
            base = Path(out_dir).resolve().parent
            runs = collect_runs(base)
            if runs:
                payload = _json.dumps(runs, default=str).replace("</", "<\\/")
                dash = base / "dashboard.html"
                dash.write_text(TEMPLATE.replace("/*__DATA__*/null", payload),
                                encoding="utf-8")
                print(f"Wrote {dash}  ({len(runs)} run(s))")
        except Exception as e:  # noqa: BLE001
            print(f"Dashboard not regenerated: {type(e).__name__}: {e}")

    bad = [r for r in (csv_results + dwi_results)
           if r.get("verdict") in ("DIFFS FOUND", "HEADER DRIFT", "D0 DRIFT", ERR)]
    if bad:
        print(f"{len(bad)} view(s) need attention: "
              + ", ".join(f"{r.get('view')}({r.get('verdict')})" for r in bad[:10]))
    if args.fail_on_diff and bad:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
