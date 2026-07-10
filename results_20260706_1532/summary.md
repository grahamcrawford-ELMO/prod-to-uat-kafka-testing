# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 15:33 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| DOCUMENT_FORM_FIELD_MAPPING | ✅ | ❌ | ❌ | ❌ | — | — | **DIFFS FOUND** | expected blocked: GRAIN. Configured grain is NOT unique — extend it before trusting T2b/T4. |

## Details

### DOCUMENT_FORM_FIELD_MAPPING — DIFFS FOUND
- T1 counts: PROD 1,132,056 / UAT 1,075,347 (diff +56,709)
- T2 key diff: 61732 in PROD-only, 4038 in UAT-only; grain unique: False
- T3 EXCEPT: 292874 PROD-not-UAT, 236165 UAT-not-PROD
- ⚠ Configured grain is NOT unique — extend it before trusting T2b/T4.
- Sample mismatch rows: `samples/DOCUMENT_FORM_FIELD_MAPPING_*.csv`
