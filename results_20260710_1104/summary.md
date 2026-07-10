# Kafka Migration Testing — Learning workstream

Run: 2026-07-10 11:04 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 42,670 / UAT 42,735 (diff -65)
- T3 EXCEPT: 5207 PROD-not-UAT, 5207 UAT-not-PROD
- T4 (42,539 shared keys), mismatching columns: `Job Role Skills and Experience`=4,349, `Job Role Description`=3,892, `Job Role Modified Date`=3
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
