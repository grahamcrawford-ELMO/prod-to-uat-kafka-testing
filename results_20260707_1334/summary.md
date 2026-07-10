# Kafka Migration Testing — Learning workstream

Run: 2026-07-07 13:35 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | · | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 41,766 / UAT 41,837 (diff -71)
- T3 EXCEPT: 137 PROD-not-UAT, 208 UAT-not-PROD
- T4 (48,072 shared keys), mismatching columns: `Job Role Skills and Experience`=5,029, `Job Role Description`=4,250, `Job Role Modified Date`=12, `Job Role Identifier`=5, `Job Role Title`=3
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
