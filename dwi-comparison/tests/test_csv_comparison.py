"""Offline tests for the CSV ladder - no AWS, no Snowflake.

FakeS3 implements just the three calls S3Source uses (list_objects_v2 with and
without Delimiter, get_object) over an in-memory {key: bytes} dict, so the
whole discovery + comparison path is exercised without network access.

Run:  python tests/test_csv_comparison.py
"""

from __future__ import annotations

import copy
import io
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dwi_testing.common import (
    ACC, BLOCKED, FAIL, PASS, SKIP, Normaliser, evaluate_where, verdict_from)
from dwi_testing.csv_ladder import CsvComparer
from dwi_testing.s3_source import S3Source, pair_runs

BUCKET = "p-elmo-data-cap"
RS = "landing/data-warehouse-integration"
SF = "landing/data-warehouse-integration/snowflake_outbound"


class FakeS3:
    def __init__(self, objects):
        self.objects = objects

    def list_objects_v2(self, Bucket, Prefix, Delimiter=None, ContinuationToken=None):
        keys = [k for k in self.objects if k.startswith(Prefix)]
        if Delimiter:
            prefixes = set()
            for k in keys:
                rest = k[len(Prefix):]
                if Delimiter in rest:
                    prefixes.add(Prefix + rest.split(Delimiter, 1)[0] + Delimiter)
            return {"CommonPrefixes": [{"Prefix": p} for p in sorted(prefixes)],
                    "IsTruncated": False}
        return {"Contents": [{"Key": k} for k in sorted(keys)], "IsTruncated": False}

    def get_object(self, Bucket, Key):
        return {"Body": io.BytesIO(self.objects[Key].encode("utf-8"))}


BASE_CFG = {
    "defaults": {"diff_threshold_pct": 0.0, "sample_rows": 10,
                 "csv_sample_columns": 10, "csv_samples_per_column": 5},
    "csv": {
        "redshift_base": f"s3://{BUCKET}/{RS}",
        "snowflake_base": f"s3://{BUCKET}/{SF}",
        "clients": ["uat1"],
        "default_grain": ["id", "client_name", "client_region"],
        "normalisation": {"trim_text": True, "blank_as_null": True,
                          "null_tokens": ["", "null", "\\N"],
                          "normalise_booleans": True, "normalise_timestamps": True},
        "views": [{"name": "learning_enrolment"}],
    },
}


def build(rs_rows, sf_rows, rs_ts="20260729223000", sf_ts="20260729224500",
          view="learning_enrolment", extra=None):
    objs = {
        f"{RS}/uat1/{rs_ts}/{view}.csv": rs_rows,
        f"{SF}/uat1/{sf_ts}/{view}.csv": sf_rows,
    }
    objs.update(extra or {})
    source = S3Source(FakeS3(objs), BASE_CFG["csv"])
    rs, sf = pair_runs(source, "uat1")
    return CsvComparer(source, BASE_CFG), rs, sf


def check(label, got, want):
    status = "ok " if got == want else "FAIL"
    print(f"  [{status}] {label}: {got!r}" + ("" if got == want else f" (expected {want!r})"))
    return got == want


def test_1_identical():
    print("identical extracts -> PASS all the way to the fingerprint")
    rows = 'id,client_name,client_region,status\n1,uat1,SYD,Complete\n2,uat1,SYD,In Progress\n'
    c, rs, sf = build(rows, rows)
    r = c.run_view("uat1", "learning_enrolment", rs, sf)
    ok = check("verdict", r["verdict"], PASS)
    ok &= check("C1 header", r["tiers"]["C1"]["status"], PASS)
    ok &= check("C2 rows", r["tiers"]["C2"]["status"], PASS)
    ok &= check("C4 columns", r["tiers"]["C4"]["status"], PASS)
    ok &= check("C5 fingerprint", r["tiers"]["C5"]["status"], PASS)
    return ok


def test_2_known_quirks_absorbed():
    print("pipeline rendering quirks (blank vs NULL, .000 timestamps, bool spelling, numeric scale)")
    rs = ('id,client_name,client_region,notes,modified,is_active,score\n'
          '1,uat1,SYD,,2026-07-29 10:00:00,1,45.6357000\n')
    sf = ('id,client_name,client_region,notes,modified,is_active,score\n'
          '1,uat1,SYD,NULL,2026-07-29 10:00:00.000+00:00,true,45.6357\n')
    # 1 == true only for columns declared as boolean; see test_2b.
    cfg = {**BASE_CFG, "csv": {**BASE_CFG["csv"],
                               "normalisation": {**BASE_CFG["csv"]["normalisation"],
                                                 "boolean_columns": ["is_active"]}}}
    source = S3Source(FakeS3({
        f"{RS}/uat1/20260729223000/learning_enrolment.csv": rs,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": sf,
    }), cfg["csv"])
    r_, s_ = pair_runs(source, "uat1")
    r = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", r_, s_)
    ok = check("verdict", r["verdict"], PASS)
    ok &= check("mismatching columns", r["tiers"]["C4"]["mismatched_columns"], {})
    return ok


def test_2b_numeric_ids_not_coerced_to_bool():
    print("an id of 1 must never normalise to 'true' - that would corrupt the join key")
    n = Normaliser({"normalise_booleans": True})
    ok = check("id 1 stays 1", n("1", "id"), "1")
    ok &= check("id 0 stays 0", n("0", "id"), "0")
    ok &= check("declared bool column maps 1 -> true",
                Normaliser({"boolean_columns": ["is_active"]})("1", "is_active"), "true")
    ok &= check("textual bool still maps without opt-in", n("TRUE", "flag"), "true")
    # The bug this guards: two rows with ids 1 and 0 must remain distinct keys.
    ok &= check("distinct numeric keys stay distinct", n("1", "id") != n("0", "id"), True)
    return ok


def test_3_real_diff_caught():
    print("a genuine value difference must FAIL, not be normalised away")
    rs = 'id,client_name,client_region,status\n1,uat1,SYD,Complete\n'
    sf = 'id,client_name,client_region,status\n1,uat1,SYD,In Progress\n'
    c, r_, s_ = build(rs, sf)
    r = c.run_view("uat1", "learning_enrolment", r_, s_)
    ok = check("verdict", r["verdict"], "DIFFS FOUND")
    ok &= check("C4 status", r["tiers"]["C4"]["status"], FAIL)
    ok &= check("status column counted", r["tiers"]["C4"]["mismatched_columns"], {"status": 1})
    ok &= check("sample captured",
                r["tiers"]["C4"]["column_samples"]["status"],
                [["1", "uat1", "SYD", "Complete", "In Progress"]])
    ok &= check("C5 withheld", r["tiers"]["C5"]["status"], SKIP)
    return ok


def test_4_header_drift_stops_ladder():
    print("column-order drift is a hard stop - content tiers withheld")
    rs = 'id,client_name,client_region,status\n1,uat1,SYD,Complete\n'
    sf = 'id,client_name,status,client_region\n1,uat1,Complete,SYD\n'
    c, r_, s_ = build(rs, sf)
    r = c.run_view("uat1", "learning_enrolment", r_, s_)
    ok = check("verdict", r["verdict"], "HEADER DRIFT")
    ok &= check("C1", r["tiers"]["C1"]["status"], FAIL)
    ok &= check("C4 not run", "C4" in r["tiers"], False)
    return ok


def test_5_key_set_diff():
    print("rows present on one side only are reported as a key-set diff")
    rs = 'id,client_name,client_region,status\n1,uat1,SYD,A\n2,uat1,SYD,B\n3,uat1,SYD,C\n'
    sf = 'id,client_name,client_region,status\n1,uat1,SYD,A\n2,uat1,SYD,B\n'
    c, r_, s_ = build(rs, sf)
    r = c.run_view("uat1", "learning_enrolment", r_, s_)
    c3 = r["tiers"]["C3"]
    ok = check("redshift-only keys", c3["key_diff"]["in_redshift_not_snowflake"], 1)
    ok &= check("snowflake-only keys", c3["key_diff"]["in_snowflake_not_redshift"], 0)
    ok &= check("shared keys", c3["shared_keys"], 2)
    ok &= check("C2 row counts FAIL", r["tiers"]["C2"]["status"], FAIL)
    ok &= check("C4 clean over shared keys", r["tiers"]["C4"]["status"], PASS)
    return ok


def test_6_threshold_accepts_small_drift():
    print("small drift within diff_threshold_pct becomes ACCEPTED, not FAIL")
    rs = "id,client_name,client_region,status\n" + "".join(
        f"{i},uat1,SYD,A\n" for i in range(1, 1001))
    sf = "id,client_name,client_region,status\n" + "".join(
        f"{i},uat1,SYD,A\n" for i in range(1, 1000))
    cfg = {**BASE_CFG, "defaults": {**BASE_CFG["defaults"], "diff_threshold_pct": 0.5}}
    source = S3Source(FakeS3({
        f"{RS}/uat1/20260729223000/learning_enrolment.csv": rs,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": sf,
    }), cfg["csv"])
    r_, s_ = pair_runs(source, "uat1")
    r = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", r_, s_)
    ok = check("C2 row counts", r["tiers"]["C2"]["status"], ACC)
    ok &= check("C3 key diff", r["tiers"]["C3"]["status"], ACC)
    ok &= check("verdict", r["verdict"], "PASS (DIFFS ACCEPTED)")
    return ok


def test_7_accepted_column_with_where():
    print("accepted_columns `where` explains the known pattern, residual still fails")
    rs = ('id,client_name,client_region,expiry_date\n'
          '1,uat1,SYD,1970-01-01 00:00:00\n'
          '2,uat1,SYD,2026-01-01 00:00:00\n')
    sf = ('id,client_name,client_region,expiry_date\n'
          '1,uat1,SYD,\n'
          '2,uat1,SYD,2027-06-30 00:00:00\n')
    cfg = {**BASE_CFG, "csv": {**BASE_CFG["csv"], "views": [{
        "name": "learning_enrolment",
        "accepted_columns": [{
            "column": "expiry_date",
            "reason": "Prod sentinel 1970-01-01 correctly nulled in UAT",
            "where": "date(prod_value) == '1970-01-01' and uat_value is None",
        }],
    }]}}
    source = S3Source(FakeS3({
        f"{RS}/uat1/20260729223000/learning_enrolment.csv": rs,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": sf,
    }), cfg["csv"])
    r_, s_ = pair_runs(source, "uat1")
    r = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", r_, s_)
    c4 = r["tiers"]["C4"]
    ok = check("total mismatches", c4["mismatched_columns"]["expiry_date"], 2)
    ok &= check("residual (unexplained)", c4["residual_mismatches"]["expiry_date"], 1)
    ok &= check("column status", c4["column_status"]["expiry_date"], FAIL)
    ok &= check("only the residual is sampled",
                c4["column_samples"]["expiry_date"],
                [["2", "uat1", "SYD", "2026-01-01 00:00:00", "2027-06-30 00:00:00"]])
    return ok


def test_8_encrypted_only_run_skipped():
    print("a run folder holding only .pgp falls back to an earlier plain-CSV run")
    rows = 'id,client_name,client_region,status\n1,uat1,SYD,A\n'
    objs = {
        f"{RS}/uat1/20260728223000/learning_enrolment.csv": rows,
        f"{RS}/uat1/20260729223000/learning_enrolment.csv.pgp": "binary",
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": rows,
    }
    source = S3Source(FakeS3(objs), BASE_CFG["csv"])
    rs, sf = pair_runs(source, "uat1")
    ok = check("skipped the encrypted run", rs.timestamp, "20260728223000")
    ok &= check("plain csv found", "learning_enrolment" in rs.files, True)
    return ok


def test_8b_encrypted_run_reads_processed_folder():
    print("a run holding only .pgp reads its plain CSV from processed/ at the same timestamp")
    rows = 'id,client_name,client_region,status\n1,uat1,SYD,A\n'
    objs = {
        f"{RS}/uat1/20260729223000/learning_enrolment.csv.pgp": "binary",
        f"{RS}/processed/uat1/20260729223000/learning_enrolment.csv": rows,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": rows,
    }
    source = S3Source(FakeS3(objs), BASE_CFG["csv"])
    rs, sf = pair_runs(source, "uat1")
    ok = check("kept the newest timestamp", rs.timestamp, "20260729223000")
    ok &= check("read from processed/", rs.prefix, f"{RS}/processed/uat1/20260729223000")
    ok &= check("plain csv found", "learning_enrolment" in rs.files, True)
    ok &= check("not reported encrypted_only", rs.encrypted_only, False)
    return ok


def test_8c_null_grain_column_does_not_crash_sort():
    print("a grain column that is NULL on some rows and set on others must not crash the sort")
    # id=1 ties on both sides; the tie-break column (sub_id) is None for one
    # row and a string for the other - exactly what a UNION'd DWI view like
    # dwi_learning_enrolment_completion_history produces when only one branch
    # populates that column.
    rows = ('id,sub_id,client_name,client_region,status\n'
            '1,A,uat1,SYD,Complete\n'
            '1,,uat1,SYD,InProgress\n')
    cfg = copy.deepcopy(BASE_CFG)
    cfg["csv"]["views"] = [{"name": "learning_enrolment",
                             "grain": ["id", "sub_id", "client_name", "client_region"]}]
    objs = {
        f"{RS}/uat1/20260729223000/learning_enrolment.csv": rows,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": rows,
    }
    source = S3Source(FakeS3(objs), cfg["csv"])
    rs, sf = pair_runs(source, "uat1")
    r = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", rs, sf)
    ok = check("no crash - verdict computed", r["verdict"] in (PASS, ACC, FAIL), True)
    ok &= check("C3 ran instead of erroring", r["tiers"]["C3"]["status"] in (PASS, ACC, FAIL), True)
    ok &= check("C4 ran instead of erroring", r["tiers"]["C4"]["status"] in (PASS, ACC, FAIL), True)
    return ok


def test_9_missing_view_blocked():
    print("view present on one side only -> BLOCKED at C0")
    rows = 'id,client_name,client_region,status\n1,uat1,SYD,A\n'
    objs = {
        f"{RS}/uat1/20260729223000/learning_enrolment.csv": rows,
        f"{RS}/uat1/20260729223000/learning_cpd_plan.csv": rows,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": rows,
    }
    source = S3Source(FakeS3(objs), BASE_CFG["csv"])
    rs, sf = pair_runs(source, "uat1")
    shared, only_rs, only_sf = source.shared_views(rs, sf)
    ok = check("shared views", shared, ["learning_enrolment"])
    ok &= check("redshift-only views", only_rs, ["learning_cpd_plan"])
    r = CsvComparer(source, BASE_CFG).run_view("uat1", "learning_cpd_plan", rs, sf)
    ok &= check("verdict", r["verdict"], BLOCKED)
    return ok


def test_a_duplicate_grain_surfaces():
    print("a non-unique grain is reported rather than silently overwriting rows")
    rs = ('id,client_name,client_region,status\n'
          '1,uat1,SYD,A\n1,uat1,SYD,B\n')
    sf = 'id,client_name,client_region,status\n1,uat1,SYD,A\n'
    c, r_, s_ = build(rs, sf)
    r = c.run_view("uat1", "learning_enrolment", r_, s_)
    ok = check("duplicate keys detected", r["tiers"]["C3"]["duplicate_keys"]["redshift"], 1)
    ok &= check("grain flagged non-unique", r["tiers"]["C3"]["grain_unique"], False)
    ok &= check("note raised", any("not unique" in n for n in r["notes"]), True)
    return ok


def test_b_where_predicate_sandboxed():
    print("a malicious/broken where predicate cannot execute or hide a diff")
    ok = check("import blocked", evaluate_where("__import__('os').system('echo hi')", "a", "b"), False)
    ok &= check("broken expr is False", evaluate_where("this is not python", "a", "b"), False)
    ok &= check("valid expr still works", evaluate_where("prod_value == 'a'", "a", "b"), True)
    return ok


def test_c_normaliser_switches():
    print("normalisation rules only apply when enabled")
    strict = Normaliser({"trim_text": False, "blank_as_null": False,
                         "normalise_booleans": False, "normalise_timestamps": False,
                         "null_tokens": []})
    ok = check("blank preserved", strict(""), "")
    ok &= check("bool preserved", strict("1"), "1")
    scaled = Normaliser({"numeric_scale": 2})
    ok &= check("scaled to 2dp", scaled("41.1675"), "41.17")
    return ok


def test_d_configured_view_absent_from_s3_is_blocked():
    """Ticket scope must be explicit: a configured view that neither pipeline
    unloaded is reported BLOCKED, never silently dropped from the report."""
    print("configured views missing from S3 are reported, not dropped")
    import argparse
    import runner as _runner

    hdr = "id,client_name,client_region\n1,acme,AU\n"
    objs = {}
    for v in ("learning_enrolment", "learning_course"):
        objs[f"{RS}/uat1/20260729223000/{v}.csv"] = hdr
        objs[f"{SF}/uat1/20260729224500/{v}.csv"] = hdr

    cfg = {
        "defaults": dict(BASE_CFG.get("defaults") or {}),
        "csv": dict(BASE_CFG["csv"],
                    clients=["uat1"],
                    views=[{"name": "learning_enrolment"},
                           {"name": "learning_course"},
                           {"name": "learning_costs"},
                           {"name": "learning_cpd_plan"}]),
    }
    saved = _runner.s3_client
    _runner.s3_client = lambda _cfg: FakeS3(objs)
    try:
        args = argparse.Namespace(clients=None, dry_run=False, views=None,
                                  redshift_run=None, snowflake_run=None)
        res = _runner.run_csv_mode(cfg, args, None)
    finally:
        _runner.s3_client = saved

    by_view = {r["view"]: r for r in res}
    ok = check("every configured view present", len(res), 4)
    ok &= check("compared view passes", by_view["learning_enrolment"]["verdict"], "PASS")
    ok &= check("absent view blocked", by_view["learning_costs"]["verdict"], "BLOCKED")
    ok &= check("absent view explains why",
                "neither pipeline unloaded" in by_view["learning_cpd_plan"]["notes"][0],
                True)
    return ok


def test_15_no_grain_is_partial_not_a_pass():
    """An unset grain must skip the row-level tiers AND be visible.

    Grain is never defaulted, so most views ship with `grain: []`. The danger is
    that skipping C3/C4 silently reports PASS. C5 still catches an in-place
    change, and the verdict must not read as a clean pass.
    """
    print("15. an unset grain is partial coverage, not a pass")
    hdr = "id,client_name,client_region,status\n"
    left = hdr + "1,acme,AU,active\n2,acme,AU,active\n"
    right = hdr + "1,acme,AU,active\n2,acme,AU,INACTIVE\n"
    ok = True
    for grain, name in (([], "empty list"), (None, "null")):
        cfg = copy.deepcopy(BASE_CFG)
        cfg["csv"].pop("default_grain", None)
        cfg["csv"]["views"] = [{"name": "learning_enrolment", "grain": grain}]
        objs = {f"{RS}/uat1/20260729010000/learning_enrolment.csv": left,
                f"{SF}/uat1/20260729020000/learning_enrolment.csv": right}
        source = S3Source(FakeS3(objs), cfg["csv"])
        rs, sf = pair_runs(source, "uat1")
        res = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", rs, sf)
        t = res["tiers"]
        ok &= check(f"C3 skipped ({name})", t["C3"]["status"], SKIP)
        ok &= check(f"C4 skipped ({name})", t["C4"]["status"], SKIP)
        ok &= check(f"C1/C2 still ran ({name})",
                    (t["C1"]["status"], t["C2"]["status"]), (PASS, PASS))
        ok &= check(f"C5 caught the in-place change ({name})", t["C5"]["status"], FAIL)
        ok &= check(f"not a clean PASS ({name})", res["verdict"] != PASS, True)
        ok &= check(f"gap is noted ({name})",
                    any("No grain set" in n for n in res["notes"]), True)

    # With a grain filled in, the same data is pinpointed to a row and column.
    cfg = copy.deepcopy(BASE_CFG)
    cfg["csv"]["views"] = [{"name": "learning_enrolment",
                            "grain": ["id", "client_name", "client_region"]}]
    objs = {f"{RS}/uat1/20260729010000/learning_enrolment.csv": left,
            f"{SF}/uat1/20260729020000/learning_enrolment.csv": right}
    source = S3Source(FakeS3(objs), cfg["csv"])
    rs, sf = pair_runs(source, "uat1")
    res = CsvComparer(source, cfg).run_view("uat1", "learning_enrolment", rs, sf)
    ok &= check("grain set -> C4 names the column",
                res["tiers"]["C4"].get("mismatched_columns"), {"status": 1})
    return ok


def test_16_no_grain_verdict_labels():
    """PASS (NO GRAIN) must be distinct from both PASS and PASS (DIFFS ACCEPTED)."""
    print("16. no-grain verdicts are labelled distinctly")
    ok = check("clean + no grain", verdict_from([PASS, SKIP], no_grain=True),
               "PASS (NO GRAIN)")
    ok &= check("clean + grain", verdict_from([PASS, SKIP]), PASS)
    ok &= check("accepted + no grain",
                verdict_from([PASS, ACC], no_grain=True), "PASS (DIFFS ACCEPTED, NO GRAIN)")
    ok &= check("a real diff still outranks it",
                verdict_from([FAIL, SKIP], no_grain=True), "DIFFS FOUND")
    ok &= check("dry run never passes", verdict_from(["DRY", SKIP], dry_run=True), "DRY")
    return ok


def test_17_per_view_client_scoping():
    """The syd_<tenant>_user_profile_data family is one view per tenant.

    Only the matching tenant's unload ever contains it, so running client
    `uat1` must not report the other 19 tenants' views as BLOCKED - that noise
    would bury genuine pipeline misses on every run.
    """
    print("test_17_per_view_client_scoping")
    import runner as R
    ok = True
    cfg = copy.deepcopy(BASE_CFG)
    cfg["csv"]["views"] = [
        {"name": "learning_enrolment"},
        {"name": "syd_uat1_user_profile_data", "clients": ["uat1"]},
        {"name": "syd_sonder_user_profile_data", "clients": ["sonder"]},
        {"name": "learning_activity_acknowledgement",
         "absent_note": "Named in CRT-6323 but no DWI_ view exists."},
    ]
    rows = "id,client_name,status\n1,uat1,active\n"
    objs = {
        f"{RS}/uat1/20260729132200/learning_enrolment.csv": rows,
        f"{SF}/uat1/20260729224500/learning_enrolment.csv": rows,
        f"{RS}/uat1/20260729132200/syd_uat1_user_profile_data.csv": rows,
        f"{SF}/uat1/20260729224500/syd_uat1_user_profile_data.csv": rows,
    }
    R.s3_client = lambda c: FakeS3(objs)

    class Args:
        clients = "uat1"
        dry_run = False
        redshift_run = None
        snowflake_run = None

    res = R.run_csv_mode(cfg, Args(), None)
    names = {r["view"] for r in res}
    ok &= check("other tenant's view excluded",
                "syd_sonder_user_profile_data" in names, False)
    ok &= check("own tenant's view compared",
                next(r["verdict"] for r in res
                     if r["view"] == "syd_uat1_user_profile_data").startswith("PASS"), True)
    ok &= check("phantom view still blocked",
                next(r["verdict"] for r in res
                     if r["view"] == "learning_activity_acknowledgement"), BLOCKED)
    ok &= check("phantom view uses its custom note",
                "CRT-6323" in next(r["notes"][0] for r in res
                                   if r["view"] == "learning_activity_acknowledgement"), True)

    # Scoping must not exclude the view from its OWN tenant's run.
    cfg2 = copy.deepcopy(cfg)
    cfg2["csv"]["clients"] = ["uat1", "sonder"]
    objs[f"{RS}/sonder/20260729132200/syd_sonder_user_profile_data.csv"] = rows
    objs[f"{SF}/sonder/20260729224500/syd_sonder_user_profile_data.csv"] = rows

    class ArgsSonder(Args):
        clients = "sonder"

    res2 = R.run_csv_mode(cfg2, ArgsSonder(), None)
    names2 = {r["view"] for r in res2}
    ok &= check("scoped view runs for its own tenant",
                "syd_sonder_user_profile_data" in names2, True)
    ok &= check("uat1's view excluded from sonder run",
                "syd_uat1_user_profile_data" in names2, False)
    return ok

def test_shared_views_and_grain_casing():
    """One canonical view list expanded into both modes.

    Casing is a silent-failure risk in both directions. Grain columns are
    matched against the real header / INFORMATION_SCHEMA and a name that does
    not exist is DROPPED, not raised - so a wrong case would quietly shrink the
    key instead of erroring. accepted_columns is worse: a key that never matches
    means a known-accepted column is reported as a genuine diff.
    """
    import yaml
    from dwi_testing.common import expand_shared_views
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cfg = yaml.safe_load(open(os.path.join(root, "config.yaml")))

    ok = check("config carries a single shared views list",
               bool(cfg.get("views")) and not (cfg.get("csv") or {}).get("views"),
               True)
    shared_n = len(cfg["views"])
    cfg = expand_shared_views(cfg)
    ok &= check("both modes expand to the shared count",
                (len(cfg["csv"]["views"]), len(cfg["dwi"]["views"])),
                (shared_n, shared_n))
    ok &= check("dwi names get the DWI_ prefix, csv names do not",
                all(v["name"].startswith("DWI_") for v in cfg["dwi"]["views"])
                and not any(v["name"].startswith("dwi_")
                            for v in cfg["csv"]["views"]), True)

    # accepted_columns must be cased per mode or it silently never matches:
    # the DWI ladder compares config keys to real Snowflake column names, so a
    # lowercase key means a known-accepted column is reported as a real diff.
    lower_bad = [v["name"] for v in cfg["csv"]["views"]
                 for e in (v.get("accepted_columns") or [])
                 if e["column"] != e["column"].lower()]
    upper_bad = [v["name"] for v in cfg["dwi"]["views"]
                 for e in (v.get("accepted_columns") or [])
                 if e["column"] != e["column"].upper()]
    ok &= check("csv accepted_columns are lowercase", lower_bad, [])
    ok &= check("dwi accepted_columns are UPPERCASE", upper_bad, [])

    # `clients` scopes an S3 unload; it is meaningless against a Snowflake view.
    ok &= check("clients scoping stays out of dwi mode",
                [v["name"] for v in cfg["dwi"]["views"] if v.get("clients")], [])
    ok &= check("clients scoping survives in csv mode",
                sum(1 for v in cfg["csv"]["views"] if v.get("clients")) > 0, True)

    # A per-mode override must still win, so split configs keep working.
    ov = {"views": [{"name": "a", "grain": ["id"]}],
          "csv": {"views": [{"name": "kept", "grain": ["x"]}]}, "dwi": {}}
    ov = expand_shared_views(ov)
    ok &= check("an explicit per-mode views list still wins",
                ([v["name"] for v in ov["csv"]["views"]],
                 [v["name"] for v in ov["dwi"]["views"]]),
                (["kept"], ["DWI_A"]))

    csv_v = {v["name"]: v.get("grain") or [] for v in cfg["csv"]["views"]}
    dwi_v = {v["name"]: v.get("grain") or [] for v in cfg["dwi"]["views"]}

    # CSV headers are lowercased by the Snowflake unload; DWI is Snowflake-cased.
    ok &= check("every csv grain column is lowercase",
                [n for n, g in csv_v.items() if any(c != c.lower() for c in g)], [])
    ok &= check("every dwi grain column is uppercase",
                [n for n, g in dwi_v.items() if any(c != c.upper() for c in g)], [])

    # Every filled grain carries the tenant keys.
    ok &= check("filled csv grains include both tenant keys",
                [n for n, g in csv_v.items()
                 if g and not {"client_name", "region"} <= set(g)], [])

    # dwi_work_pattern.sql aliases wpu.id as `assigment_id` - single m. Silently
    # "correcting" it would drop the column from the key, not raise.
    ok &= check("work_pattern keeps the misspelled assigment_id",
                "assigment_id" in csv_v.get("work_pattern", []), True)
    ok &= check("DWI_WORK_PATTERN keeps ASSIGMENT_ID",
                "ASSIGMENT_ID" in dwi_v.get("DWI_WORK_PATTERN", []), True)

    # origin_table is the DWI stand-in for the BI SOURCE_TABLE on UNION views.
    for v in ("hrcore_taxation", "hrcore_bank_account", "hrcore_employment_detail"):
        ok &= check("%s keys on origin_table (AU/UK UNION)" % v,
                    "origin_table" in csv_v.get(v, []), True)

    # The two modes must agree on which views got a grain - the whole point of
    # collapsing them into one list.
    csv_filled = {n for n, g in csv_v.items() if g}
    dwi_filled = {n[4:].lower() for n, g in dwi_v.items() if g}
    ok &= check("both modes filled the same view set",
                sorted(csv_filled ^ dwi_filled), [])
    return ok

if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items())
             if k.startswith("test_") and callable(v)]
    results = []
    for t in tests:
        try:
            results.append(bool(t()))
        except Exception as e:  # noqa: BLE001
            print(f"  [EXC ] {type(e).__name__}: {e}")
            results.append(False)
        print()
    passed = sum(1 for r in results if r)
    print(f"{passed}/{len(results)} test groups passed")
    sys.exit(0 if passed == len(results) else 1)
