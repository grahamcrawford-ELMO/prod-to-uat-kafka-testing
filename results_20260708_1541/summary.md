# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 15:41 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| GENERAL_JOB_ROLE | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### GENERAL_JOB_ROLE — DIFFS FOUND
- T1 counts: PROD 42,653 / UAT 41,837 (diff +816)
- T3 EXCEPT: 1243 PROD-not-UAT, 427 UAT-not-PROD
- T4 (48,080 shared keys), mismatching columns: `Job Role Skills and Experience`=5,040, `Job Role Description`=4,260, `Job Role Modified Date`=402, `Job Role Title`=231, `Job Role Identifier`=227
- Sample mismatch rows: `samples/GENERAL_JOB_ROLE_*.csv`
