# Kafka Migration Testing — Learning workstream

Run: 2026-07-08 14:18 

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| RECRUITMENT_CANDIDATE | ✅ | · | · | ❌ | ❌ | — | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. Configured grain is NOT unique — extend it before trusting T2b/T4.; Grain has duplicate keys within threshold — T4 counts may be slightly inflated by join fan-out. |

## Details

### RECRUITMENT_CANDIDATE — DIFFS FOUND
- T1 counts: PROD 9,058,760 / UAT 9,063,611 (diff -4,851)
- T3 EXCEPT: 2710138 PROD-not-UAT, 2714989 UAT-not-PROD
- T4 (10,192,054 shared keys), mismatching columns: `Candidate Expiry Date`=3,064,857, `Candidate Last Login Date`=1,904,580, `Candidate Last Logout Date`=646,443, `Candidate Role`=189,205, `Candidate Modified Date`=28,710, `Candidate Full Name`=12,193, `Candidate Start Date`=8,662, `Candidate Is Active`=3,233, `Candidate Mobile Number`=2,925, `Candidate End Date`=2,285, `Candidate State`=1,785, `Candidate Country`=1,785, `Candidate Email`=1,279, `Candidate Home Phone`=729, `Candidate Is Notified`=475
- ⚠ Configured grain is NOT unique — extend it before trusting T2b/T4.
- ⚠ Grain has duplicate keys within threshold — T4 counts may be slightly inflated by join fan-out.
- Sample mismatch rows: `samples/RECRUITMENT_CANDIDATE_*.csv`
