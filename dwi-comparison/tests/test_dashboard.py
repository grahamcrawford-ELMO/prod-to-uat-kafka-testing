#!/usr/bin/env python3
"""Offline tests for dashboard.py - no AWS, no Snowflake, no browser.

Builds results.json fixtures covering every verdict class in both modes (plus a
legacy BI payload), generates dashboard.html, and asserts on the rendered HTML.

The dashboard is a rendering layer over results.json, so the failure mode that
matters is a payload key it silently ignores - a real difference then displays as
"agree". These tests pin the field names each tier actually emits.

    python tests/test_dashboard.py
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

FAILED = []


def check(label, got, want=True):
    ok = got == want
    print(f"  [{'ok ' if ok else 'FAIL'}] {label}"
          + ("" if ok else f": {got!r} (expected {want!r})"))
    if not ok:
        FAILED.append(label)
    return ok


def contains(label, haystack, needle, want=True):
    return check(label, needle in haystack, want)


# --------------------------------------------------------------------------
# fixtures
# --------------------------------------------------------------------------

def csv_rows():
    return [
        {   # clean
            "view": "learning_enrolment", "client": "acme", "mode": "csv",
            "redshift_run": "20260729223000", "snowflake_run": "20260729224500",
            "verdict": "PASS", "notes": [],
            "tiers": {
                "C0": {"status": "PASS", "present": {"redshift": True, "snowflake": True}},
                "C1": {"status": "PASS", "drift": [], "redshift_columns": 8, "snowflake_columns": 8,
                       "only_in_redshift": [], "only_in_snowflake": []},
                "C2": {"status": "PASS", "redshift_rows": 40, "snowflake_rows": 40, "diff": 0,
                       "denominator": 40},
                "C3": {"status": "PASS", "key_columns": ["id", "client_name", "client_region"],
                       "key_diff": {"in_redshift_not_snowflake": 0, "in_snowflake_not_redshift": 0},
                       "shared_keys": 40, "duplicate_keys": {"redshift": 0, "snowflake": 0}},
                "C4": {"status": "PASS", "shared_keys": 40, "mismatched_columns": {}},
                "C5": {"status": "PASS", "redshift_fingerprint": "abc123",
                       "snowflake_fingerprint": "abc123"},
            },
        },
        {   # column diffs, one with an accepted where-predicate residual
            "view": "learning_course", "client": "acme", "mode": "csv",
            "redshift_run": "20260729223000", "snowflake_run": "20260729224500",
            "verdict": "DIFFS FOUND", "notes": [],
            "tiers": {
                "C0": {"status": "PASS", "present": {"redshift": True, "snowflake": True}},
                "C1": {"status": "PASS", "drift": []},
                "C2": {"status": "PASS", "redshift_rows": 40, "snowflake_rows": 40, "diff": 0},
                "C3": {"status": "PASS", "shared_keys": 40,
                       "key_diff": {"in_redshift_not_snowflake": 0, "in_snowflake_not_redshift": 0},
                       "key_columns": ["id"]},
                "C4": {"status": "FAIL", "shared_keys": 40,
                       "mismatched_columns": {"expiry_date": 400, "score": 6},
                       "column_status": {"expiry_date": "FAIL", "score": "FAIL"},
                       "residual_mismatches": {"expiry_date": 2},
                       "accepted_where": {"expiry_date": "r == '' and s == '1970-01-01'"},
                       "column_sample_columns": ["id", "REDSHIFT value", "SNOWFLAKE value"],
                       "column_samples": {"score": [["1", "87.5", "91.25"]]}},
                "C5": {"status": "SKIPPED", "reason": "content diffs present"},
            },
        },
        {   # header rename -> hard stop
            "view": "learning_module", "client": "acme", "mode": "csv",
            "verdict": "HEADER DRIFT", "notes": ["Header/column-order drift."],
            "tiers": {
                "C0": {"status": "PASS", "present": {"redshift": True, "snowflake": True}},
                "C1": {"status": "FAIL", "only_in_redshift": ["status"],
                       "only_in_snowflake": ["state"],
                       "drift": [{"column": "status", "redshift_ord": 5, "snowflake_ord": None,
                                  "snowflake_column_at_position": "state"}]},
            },
        },
        {   # missing on one side
            "view": "learning_transcript", "client": "acme", "mode": "csv",
            "verdict": "BLOCKED", "notes": ["Extract missing on: snowflake."],
            "tiers": {"C0": {"status": "FAIL",
                             "present": {"redshift": True, "snowflake": False}}},
        },
        {   # accepted within threshold
            "view": "learning_assignment_rule", "client": "acme", "mode": "csv",
            "verdict": "PASS (DIFFS ACCEPTED)", "notes": [],
            "tiers": {
                "C0": {"status": "PASS", "present": {"redshift": True, "snowflake": True}},
                "C1": {"status": "PASS", "drift": []},
                "C2": {"status": "ACCEPTED", "redshift_rows": 40, "snowflake_rows": 39,
                       "diff": 1, "denominator": 40, "threshold_pct": 5.0},
                "C3": {"status": "ACCEPTED", "shared_keys": 39, "denominator": 40,
                       "threshold_pct": 5.0, "key_columns": ["id"],
                       "key_diff": {"in_redshift_not_snowflake": 1,
                                    "in_snowflake_not_redshift": 0}},
                "C4": {"status": "PASS", "shared_keys": 39, "mismatched_columns": {}},
                "C5": {"status": "SKIPPED", "reason": "differences were accepted within threshold"},
            },
        },
    ]


def dwi_rows():
    return [
        {   # clean
            "view": "DWI_LEARNING_ENROLMENT", "mode": "dwi", "verdict": "PASS", "notes": [],
            "tiers": {
                "D0": {"status": "PASS", "drift": [], "queries": ["SELECT 1"]},
                "D1": {"status": "PASS", "grain_unique": True, "grain_usable": True,
                       "dups": {"prod": {"dup_key_count": 0}, "uat": {"dup_key_count": 0}},
                       "sample_columns": ["ID", "n"], "sample_rows": {}},
                "D2": {"status": "PASS", "prod_rows": 40, "uat_rows": 40, "diff": 0,
                       "key_columns": ["ID"],
                       "key_diff": {"in_prod_not_uat": 0, "in_uat_not_prod": 0}},
                "D3": {"status": "PASS", "shared_keys": 40, "mismatched_columns": {},
                       "sql": "SELECT COUNT(*)"},
                "D4": {"status": "PASS", "distinct_fingerprints": 1},
            },
        },
        {   # schema drift halts the ladder
            "view": "DWI_LEARNING_COURSE", "mode": "dwi", "verdict": "D0 DRIFT",
            "notes": ["Schema drift - content tiers withheld."],
            "tiers": {"D0": {"status": "FAIL", "queries": ["SELECT 1"],
                             "drift": [{"column": "STATUS", "prod_ord": 5, "uat_ord": None,
                                        "prod_type": "TEXT", "uat_type": None}]}},
        },
        {   # non-unique grain -> D3 withheld
            "view": "DWI_LEARNING_COSTS", "mode": "dwi", "verdict": "DIFFS FOUND",
            "notes": ["Grain is NOT unique."],
            "tiers": {
                "D0": {"status": "PASS", "drift": []},
                "D1": {"status": "FAIL", "grain_unique": False, "grain_usable": False,
                       "denominator": 40,
                       "dups": {"prod": {"dup_key_count": 3}, "uat": {"dup_key_count": 2}},
                       "sample_columns": ["ID", "n"],
                       "sample_rows": {"prod": [["1", 3]], "uat": [["2", 2]]}},
                "D2": {"status": "PASS", "prod_rows": 40, "uat_rows": 40, "diff": 0},
                "D3": {"status": "SKIPPED", "reason": "no usable grain - join would fan out"},
                "D4": {"status": "PASS", "distinct_fingerprints": 1},
            },
        },
        {   # query error
            "view": "DWI_HRCORE_TERMINATION", "mode": "dwi", "verdict": "ERROR", "notes": [],
            "tiers": {"D0": {"status": "ERROR",
                             "error": "ProgrammingError: 002003 object does not exist"}},
        },
    ]


def legacy_bi_rows():
    """The BI harness emits a bare list with T0-T4 and names row delta row_diff."""
    return [{
        "table": "LEARNING_ASSIGNMENT_RULE", "verdict": "DIFFS FOUND", "runtime_seconds": 12.4,
        "tiers": {
            "T0": {"status": "PASS", "drift": []},
            "T1": {"status": "PASS", "grain_unique": True,
                   "dups": {"prod": {"dup_key_count": 0}, "uat": {"dup_key_count": 0}}},
            "T2": {"status": "FAIL", "prod_rows": 900, "uat_rows": 880, "row_diff": 20,
                   "denominator": 900, "key_columns": ["ID"],
                   "key_diff": {"in_prod_not_uat": 20, "in_uat_not_prod": 0}},
            "T3": {"status": "FAIL", "shared_keys": 880,
                   "mismatched_columns": {"EXPIRY_DATE": 400},
                   "column_status": {"EXPIRY_DATE": "FAIL"}},
            "T4": {"status": "SKIPPED", "reason": "content diffs found"},
        },
        "notes": ["Grain from CRT-6248."],
    }]


def build(base: Path, stamp: str, payload):
    d = base / f"results_{stamp}"
    d.mkdir(parents=True, exist_ok=True)
    (d / "results.json").write_text(json.dumps(payload, indent=1))
    return d


def generate(base: Path):
    out = base / "dashboard.html"
    r = subprocess.run([sys.executable, str(ROOT / "dashboard.py"),
                        "--dir", str(base), "--out", str(out)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise AssertionError(f"dashboard.py failed: {r.stderr.strip()}")
    return out.read_text(encoding="utf-8")


def embedded(html):
    m = re.search(r"const RUNS = (\[.*?\]);\n", html, re.S)
    assert m, "RUNS payload not found in generated HTML"
    return json.loads(m.group(1))


# --------------------------------------------------------------------------
# tests
# --------------------------------------------------------------------------

def test_1_generates_and_embeds():
    print("\n1. generates a self-contained page with the payload embedded")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": dwi_rows(),
                                      "dry_run": False, "generated": "2026-07-30T09:30:00"})
        html = generate(base)
        check("template placeholder substituted", "/*__DATA__*/null" not in html)
        check("no external resource is fetched",
              not re.search(r'(src|href)="https?://', html))
        check("single script block (payload did not break out)",
              html.count("</script>") == 1)
        runs = embedded(html)
        check("one run embedded", len(runs) == 1)
        check("csv rows carried", len(runs[0]["csv"]) == 5)
        check("dwi rows carried", len(runs[0]["dwi"]) == 4)


def test_2_both_modes_get_their_own_board():
    print("\n2. each mode renders its own board, tiers and side labels")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": dwi_rows(), "dry_run": False})
        html = generate(base)
        contains("csv board title", html, "S3 CSV comparison")
        contains("dwi board title", html, "Warehouse comparison")
        contains("csv scope", html, "Redshift extract vs Snowflake extract")
        contains("dwi scope", html, "UAT_DB.EDP_DWI vs PROD_DB.EDP_DWI")
        # tier vocabularies must not be shared between modes
        contains("csv tier ids defined", html, '"C0","C1","C2","C3","C4","C5"')
        contains("dwi tier ids defined", html, '"D0","D1","D2","D3","D4"')
        contains("csv side labels", html, 'left:"REDSHIFT", right:"SNOWFLAKE"')
        contains("dwi side labels", html, 'left:"PROD", right:"UAT"')


def test_3_every_verdict_class_survives_the_round_trip():
    print("\n3. every verdict class is carried into the page")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": dwi_rows(), "dry_run": False})
        runs = embedded(generate(base))
        verdicts = {r["verdict"] for r in runs[0]["csv"] + runs[0]["dwi"]}
        for v in ("PASS", "DIFFS FOUND", "HEADER DRIFT", "BLOCKED",
                  "PASS (DIFFS ACCEPTED)", "D0 DRIFT", "ERROR"):
            check(f"verdict present: {v}", v in verdicts)


def test_4_diff_detail_reaches_the_page():
    print("\n4. the detail that explains a diff is present, not just the status")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": dwi_rows(), "dry_run": False})
        html = generate(base)
        contains("mismatching column name", html, "expiry_date")
        contains("residual count for where-predicate", html, '"expiry_date": 2')
        contains("where predicate text", html, "1970-01-01")
        contains("sample values", html, "91.25")
        contains("rename target column", html, "state")
        contains("error text", html, "002003 object does not exist")
        contains("dwi sql", html, "SELECT COUNT(*)")


def test_5_residual_is_rendered_separately_from_raw_count():
    print("\n5. an accepted pattern and a genuine diff are not conflated")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": [], "dry_run": False})
        html = generate(base)
        # the renderer must have a branch that reports residual instead of raw %
        contains("residual wording exists in renderer", html, "residual</b> after the accepted pattern")


def test_6_dry_run_is_not_reported_as_pass():
    print("\n6. a dry run is labelled, not reported as PASS")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        dry_csv = [dict(r, verdict="DRY",
                        tiers={k: dict(v, status="DRY") for k, v in r["tiers"].items()})
                   for r in csv_rows()]
        build(base, "20260730_1000", {"csv": dry_csv, "dwi": [], "dry_run": True})
        html = generate(base)
        runs = embedded(html)
        check("dry_run flag carried", runs[0]["dry_run"] is True)
        check("no PASS verdict in a dry run",
              all(r["verdict"] == "DRY" for r in runs[0]["csv"]))
        contains("dry banner markup present", html, "drybanner")
        contains("dry tiers show SQL only, not placeholder counters", html,
                 "Nothing executed - any counter in the payload is a default")


def test_7_history_across_runs():
    print("\n7. history spans every run in the folder")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        first = csv_rows()
        second = [dict(r) for r in csv_rows()]
        second[0]["verdict"] = "DIFFS FOUND"       # a regression between runs
        build(base, "20260729_0915", {"csv": first, "dwi": [], "dry_run": False})
        build(base, "20260730_0930", {"csv": second, "dwi": [], "dry_run": False})
        html = generate(base)
        runs = embedded(html)
        check("both runs collected", len(runs) == 2)
        check("runs are ordered oldest first", runs[0]["label"] < runs[1]["label"]
              or runs[0]["ts"] < runs[1]["ts"])
        check("regression visible between runs",
              runs[0]["csv"][0]["verdict"] != runs[1]["csv"][0]["verdict"])


def test_8_legacy_bi_payload_still_renders():
    print("\n8. the BI harness's own results.json still renders")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260727_0800", legacy_bi_rows())   # bare list, not a dict
        html = generate(base)
        runs = embedded(html)
        check("legacy list normalised into bi bucket", len(runs[0]["bi"]) == 1)
        check("csv bucket empty", runs[0]["csv"] == [])
        contains("bi board title", html, "BI model comparison")
        contains("T-tier vocabulary", html, '"T0","T1","T2","T3","T4"')


def test_9_row_delta_field_name_difference():
    print("\n9. row_diff (BI) and diff (this harness) both register")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        build(base, "20260727_0800", legacy_bi_rows())
        html = generate(base)
        # A real 900-vs-880 gap must never render via the "counts agree" branch.
        # The renderer has to fall back through diff -> row_diff -> subtraction.
        contains("renderer falls back across both field names", html,
                 "tier.diff ?? tier.row_diff ??")
        runs = embedded(html)
        t2 = runs[0]["bi"][0]["tiers"]["T2"]
        check("legacy payload uses row_diff", "row_diff" in t2 and "diff" not in t2)
        check("delta is non-zero so it must not read as agreeing", t2["row_diff"] == 20)


def test_a_empty_and_malformed_inputs():
    print("\n10. empty and malformed inputs are handled")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        r = subprocess.run([sys.executable, str(ROOT / "dashboard.py"), "--dir", str(base)],
                           capture_output=True, text=True)
        check("exits non-zero when there is nothing to render", r.returncode != 0)
        contains("says so", r.stdout + r.stderr, "No results_")

        # a corrupt run must be skipped, not fatal
        bad = base / "results_20260101_0000"
        bad.mkdir()
        (bad / "results.json").write_text("{not json")
        build(base, "20260730_0930", {"csv": csv_rows(), "dwi": [], "dry_run": False})
        runs = embedded(generate(base))
        check("corrupt run skipped, valid run kept", len(runs) == 1)

        # a run with both modes empty carries no rows
        build(base, "20260731_0930", {"csv": [], "dwi": [], "dry_run": False})
        runs = embedded(generate(base))
        check("empty run excluded rather than shown blank", len(runs) == 1)


def test_b_html_escaping():
    print("\n11. payload content cannot break out of the page")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        nasty = csv_rows()
        nasty[0]["view"] = "</script><script>alert(1)</script>"
        nasty[0]["notes"] = ["<img src=x onerror=alert(2)>"]
        build(base, "20260730_0930", {"csv": nasty, "dwi": [], "dry_run": False})
        html = generate(base)
        check("still a single script block", html.count("</script>") == 1)
        contains("closing tag neutralised in the data island", html, "<\\/script>")
        runs = embedded(html)
        check("value survives intact for the escaping renderer",
              runs[0]["csv"][0]["view"] == "</script><script>alert(1)</script>")


def main():
    for fn in (test_1_generates_and_embeds,
               test_2_both_modes_get_their_own_board,
               test_3_every_verdict_class_survives_the_round_trip,
               test_4_diff_detail_reaches_the_page,
               test_5_residual_is_rendered_separately_from_raw_count,
               test_6_dry_run_is_not_reported_as_pass,
               test_7_history_across_runs,
               test_8_legacy_bi_payload_still_renders,
               test_9_row_delta_field_name_difference,
               test_a_empty_and_malformed_inputs,
               test_b_html_escaping):
        fn()
    total = 11
    print(f"\n{total - len(set(FAILED)) if FAILED else total}/{total} test groups passed"
          if not FAILED else f"\nFAILURES: {len(FAILED)} -> {FAILED}")
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
