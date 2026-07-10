# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 13:12 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ASSIGNMENT_RULE | ✅ | ❌ | ❌ | ❌ | — | — | **DIFFS FOUND** | Configured grain is NOT unique — extend it before trusting T2b/T4. |

## Details

### LEARNING_ASSIGNMENT_RULE — DIFFS FOUND
- T1 counts: PROD 83,371 / UAT 82,125 (diff +1,246)
- T2 key diff: 1440 in PROD-only, 10 in UAT-only; grain unique: False
- T3 EXCEPT: 83371 PROD-not-UAT, 82125 UAT-not-PROD
- ⚠ Configured grain is NOT unique — extend it before trusting T2b/T4.
- Sample mismatch rows: `samples/LEARNING_ASSIGNMENT_RULE_*.csv`
