# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 13:19 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION | ✅ | ❌ | ❌ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION — DIFFS FOUND
- T1 counts: PROD 678,247 / UAT 615,097 (diff +63,150)
- T2 key diff: 63831 in PROD-only, 681 in UAT-only; grain unique: True
- T3 EXCEPT: 563416 PROD-not-UAT, 500266 UAT-not-PROD
- T4 (618,703 shared keys), mismatching columns: `Quiz Submission Question`=295,490, `Quiz Submission Introduction`=247,594, `Quiz Submission Feedback`=246,447, `Quiz Submission Answer`=219,112, `Quiz Submission Marked By User`=600, `Quiz Submission Score`=142, `Quiz Submission Marked Date`=142, `Quiz Submission Status`=142
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION_*.csv`
