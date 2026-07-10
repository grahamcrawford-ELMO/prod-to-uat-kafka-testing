# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 17:25 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT | ✅ | · | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT — DIFFS FOUND
- T1 counts: PROD 28,073,438 / UAT 28,049,038 (diff +24,400)
- T3 EXCEPT: 3103936 PROD-not-UAT, 3103936 UAT-not-PROD
- T4 (28,028,230 shared keys), mismatching columns: `Enrolment Overdue Days`=2,376,949, `Enrolment Retrain Overdue Days`=746,102, `Enrolment Modified Date`=36,764, `Enrolment Status`=34,535, `Enrolment Completion Date`=27,858, `Enrolment Start Date`=25,237, `Enrolment Is Enrolment Overdue`=20,481, `Enrolment Retrain Open Date`=15,095, `Enrolment Retrain Date`=14,351, `Enrolment Assignment Rule`=10,866, `Enrolment Method`=9,645, `Enrolment Is Retrain Overdue`=9,169, `Enrolment Due Date`=5,192, `Enrolment Retrain Open In Period`=3,599, `Enrolment Retrain In Period`=1,840
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_*.csv`
