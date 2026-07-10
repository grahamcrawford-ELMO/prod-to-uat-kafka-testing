# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 13:42 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| RECRUITMENT_APPLICATION_JOB_OFFER | ✅ | · | ✅ | ❌ | · | — | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |

## Details

### RECRUITMENT_APPLICATION_JOB_OFFER — DIFFS FOUND
- T1 counts: PROD 366,243 / UAT 365,899 (diff +344)
- T3 EXCEPT: 880 PROD-not-UAT, 536 UAT-not-PROD
- T4 (387,134 shared keys), mismatching columns: `Job Offer Status`=254, `Job Offer Response Status`=231, `Job Offer Accepted Date`=203, `Job Offer Location`=182, `Job Offer Manager Full Name`=76, `Job Offer User Message`=68, `Job Offer Responded by`=57, `Job Offer Withdrawn Reason`=42, `Job Offer Requester Full Name`=24, `Job Offer Start Date`=18, `Job Offer Department`=9, `Job Offer Candidate Response Message`=9
- Sample mismatch rows: `samples/RECRUITMENT_APPLICATION_JOB_OFFER_*.csv`
