# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 12:50 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT | ✅ | ❌ | ⚠️ | ❌ | — | — | **ERROR** |  |

## Details

### LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT — ERROR
- T1 counts: PROD 8,288,879 / UAT 8,178,575 (diff +110,304)
- T3 EXCEPT: 2823137 PROD-not-UAT, 2712864 UAT-not-PROD
- Sample mismatch rows: `samples/LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT_*.csv`
