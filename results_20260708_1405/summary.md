# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 14:07 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| RECRUITMENT_APPLICATION_QUESTION_ANSWER | ✅ | · | ✅ | ❌ | ❌ | — | **DIFFS FOUND** |  |

## Details

### RECRUITMENT_APPLICATION_QUESTION_ANSWER — DIFFS FOUND
- T1 counts: PROD 59,940,296 / UAT 59,984,442 (diff -44,146)
- T3 EXCEPT: 22870811 PROD-not-UAT, 22914957 UAT-not-PROD
- T4 (61,972,091 shared keys), mismatching columns: `Questions Question`=16,300,579, `Questions Answer`=10,413,530
- Sample mismatch rows: `samples/RECRUITMENT_APPLICATION_QUESTION_ANSWER_*.csv`
