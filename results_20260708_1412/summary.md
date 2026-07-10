# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 14:12 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| RECRUITMENT_APPLICATION_TIME_TO_HIRE | ✅ | ❌ | ✅ | ❌ | · | — | **DIFFS FOUND** | expected blocked: GRAIN. |

## Details

### RECRUITMENT_APPLICATION_TIME_TO_HIRE — DIFFS FOUND
- T1 counts: PROD 271,553 / UAT 271,267 (diff +286)
- T3 EXCEPT: 446 PROD-not-UAT, 160 UAT-not-PROD
- T4 (286,432 shared keys), mismatching columns: `Time to Hire Days`=213, `Time to Hire Hours`=213
- Sample mismatch rows: `samples/RECRUITMENT_APPLICATION_TIME_TO_HIRE_*.csv`
