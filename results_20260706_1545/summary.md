# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 15:45 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ❌ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 44,501 / UAT 44,359 (diff +142)
- T2 key diff: 338 in PROD-only, 196 in UAT-only; grain unique: True
- T3 EXCEPT: 5988 PROD-not-UAT, 5846 UAT-not-PROD
- T4 (47,850 shared keys), mismatching columns: `Job Role Skills and Experience`=5,022, `Job Role Description`=4,273, `Job Role Modified Date`=59, `Job Role Title`=4, `Job Role Identifier`=4
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
