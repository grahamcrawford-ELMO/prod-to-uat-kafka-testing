# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 16:43 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 42,654 / UAT 41,837 (diff +817)
- T3 EXCEPT: 5435 PROD-not-UAT, 5435 UAT-not-PROD
- T4 (41,641 shared keys), mismatching columns: `Job Role Skills and Experience`=4,332, `Job Role Description`=3,759, `Job Role Modified Date`=388, `Job Role Title`=231, `Job Role Identifier`=227
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
