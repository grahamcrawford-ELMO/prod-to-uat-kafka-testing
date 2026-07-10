# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 13:38 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| RECRUITMENT_APPLICATION_INTERVIEW | ✅ | ❌ | ✅ | ❌ | ❌ | — | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |

## Details

### RECRUITMENT_APPLICATION_INTERVIEW — DIFFS FOUND
- T1 counts: PROD 761,114 / UAT 760,224 (diff +890)
- T3 EXCEPT: 17821 PROD-not-UAT, 16931 UAT-not-PROD
- T4 (800,997 shared keys), mismatching columns: `Interview Email`=16,983, `Interview Due Date`=614, `Interview Modified Date`=489, `Interview Status`=451, `Interview End Date`=389, `Interview Interviewer`=210, `Interview Notified Date`=14, `Interview Timezone`=11, `Interview Is Notified`=3
- Sample mismatch rows: `samples/RECRUITMENT_APPLICATION_INTERVIEW_*.csv`
