# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 13:26 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT_COMPLETION_HISTORY | ✅ | ❌ | ❌ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT_COMPLETION_HISTORY — DIFFS FOUND
- T1 counts: PROD 33,206,860 / UAT 29,620,098 (diff +3,586,762)
- T2 key diff: 3600392 in PROD-only, 13630 in UAT-only; grain unique: True
- T3 EXCEPT: 12900291 PROD-not-UAT, 9313529 UAT-not-PROD
- T4 (10,510,794 shared keys), mismatching columns: `Enrolment Completion History Content`=10,507,509, `Enrolment Completion History Start Date`=378, `Enrolment Completion History Completion Date`=24, `Enrolment Completion History Course Title`=20
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_COMPLETION_HISTORY_*.csv`
