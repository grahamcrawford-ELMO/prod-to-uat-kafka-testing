# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 12:28 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT | ✅ | ❌ | ❌ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT — DIFFS FOUND
- T1 counts: PROD 28,178,016 / UAT 26,554,468 (diff +1,623,548)
- T2 key diff: 1657736 in PROD-only, 34188 in UAT-only; grain unique: True
- T3 EXCEPT: 1681168 PROD-not-UAT, 57620 UAT-not-PROD
- T4 (28,795,654 shared keys), mismatching columns: `Enrolment Assignment Rule`=18,907, `Enrolment Completion Date`=9,309, `Enrolment Modified Date`=9,118, `Enrolment Status`=9,020, `Enrolment Retrain Open Date`=7,387, `Enrolment Start Date`=6,856, `Enrolment Retrain Date`=6,577, `Enrolment Is Enrolment Overdue`=5,174, `Enrolment Retrain Open In Period`=4,214, `Enrolment Overdue Days`=4,068, `Enrolment Retrain Overdue Days`=2,052, `Enrolment Is Retrain Overdue`=1,896, `Enrolment Method`=1,817, `Enrolment Retrain In Period`=1,403, `Enrolment Due Date`=281
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_*.csv`
