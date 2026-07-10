# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 16:07 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 44,501 / UAT 44,410 (diff +91)
- T3 EXCEPT: 5920 PROD-not-UAT, 5829 UAT-not-PROD
- T4 (47,901 shared keys), mismatching columns: `Job Role Skills and Experience`=5,026, `Job Role Description`=4,251, `Job Role Modified Date`=7
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
