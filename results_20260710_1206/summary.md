# Kafka Migration Testing — Learning workstream

Run: 2026-07-10 12:07 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ASSIGNMENT_RULE | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** | expected blocked: GRAIN/KAFKA_IMPORT. |

## Details

### LEARNING_ASSIGNMENT_RULE — DIFFS FOUND
- T1 counts: PROD 82,030 / UAT 79,317 (diff +2,713)
- T3 EXCEPT: 4647 PROD-not-UAT, 4647 UAT-not-PROD
- T4 (79,042 shared keys), mismatching columns: `Assignment Rule Description`=4,611, `Assignment Rule Is Recommended Course`=31, `Assignment Rule Is Required Course`=6
- Sample mismatch rows: `samples/LEARNING_ASSIGNMENT_RULE_*.csv`
