# Kafka Migration Testing — Learning workstream

Run: 2026-07-07 13:05 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT | ✅ | · | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT — DIFFS FOUND
- T1 counts: PROD 28,041,697 / UAT 28,037,855 (diff +3,842)
- T3 EXCEPT: 33773 PROD-not-UAT, 29931 UAT-not-PROD
- T4 (31,679,694 shared keys), mismatching columns: `Enrolment Assignment Rule`=95,722, `Enrolment Modified Date`=14,413, `Enrolment Completion Date`=10,339, `Enrolment Status`=10,282, `Enrolment Start Date`=7,463, `Enrolment Is Enrolment Overdue`=7,209, `Enrolment Retrain Open Date`=6,850, `Enrolment Retrain Date`=6,119, `Enrolment Overdue Days`=5,771, `Enrolment Due Date`=4,790, `Enrolment Retrain Open In Period`=3,572, `Enrolment Is Retrain Overdue`=2,967, `Enrolment Retrain Overdue Days`=2,757, `Enrolment Method`=1,534, `Enrolment Retrain In Period`=846
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_*.csv`
