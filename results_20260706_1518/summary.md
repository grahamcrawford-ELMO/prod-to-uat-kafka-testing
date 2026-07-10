# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 15:18 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| CLIENT_MANAGER_ACCESS_CONFIG | ✅ | ❌ | ❌ | ❌ | ✅ | — | **DIFFS FOUND** |  |

## Details

### CLIENT_MANAGER_ACCESS_CONFIG — DIFFS FOUND
- T1 counts: PROD 1,422 / UAT 1,414 (diff +8)
- T2 key diff: 11 in PROD-only, 3 in UAT-only; grain unique: True
- T3 EXCEPT: 11 PROD-not-UAT, 3 UAT-not-PROD
- Sample mismatch rows: `samples/CLIENT_MANAGER_ACCESS_CONFIG_*.csv`
