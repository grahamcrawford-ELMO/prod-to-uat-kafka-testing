# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 12:57 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION | ✅ | ❌ | ❌ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION — DIFFS FOUND
- T1 counts: PROD 112,175 / UAT 103,734 (diff +8,441)
- T2 key diff: 8448 in PROD-only, 7 in UAT-only; grain unique: True
- T3 EXCEPT: 8512 PROD-not-UAT, 71 UAT-not-PROD
- T4 (106,024 shared keys), mismatching columns: `File Submission Reviewed By Name`=42, `File Submission Reviewed Date`=42, `File Submission Note`=33
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION_*.csv`
