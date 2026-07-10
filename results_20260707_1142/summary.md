# Kafka Migration Testing — Learning workstream

Run: 2026-07-07 11:43 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | · | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 44,506 / UAT 44,573 (diff -67)
- T3 EXCEPT: 132 PROD-not-UAT, 199 UAT-not-PROD
- T4 (48,072 shared keys), mismatching columns: `Job Role Skills and Experience`=5,029, `Job Role Description`=4,250, `Job Role Modified Date`=6, `Job Role Title`=1, `Job Role Identifier`=1
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
