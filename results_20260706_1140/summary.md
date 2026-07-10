# Kafka Migration Testing — Learning workstream

Run: 2026-07-06 11:40 (DRY RUN — no queries executed)

| Table | T0 | T1 | T2 | T3 | T4 | T5 | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| LEARNING_ASSIGNMENT_RULE | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: GRAIN/KAFKA_IMPORT. |
| LEARNING_COST | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: GRAIN. |
| LEARNING_COURSE | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: GRAIN/KAFKA_IMPORT. |
| LEARNING_CPD_PLAN | · | · | — | · | — | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |
| LEARNING_ENROLMENT | · | · | · | · | · | · | **DIFFS FOUND** |  |
| LEARNING_ENROLMENT_ACTIVITY | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |
| LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: GRAIN. |
| LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |
| LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |
| LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: GRAIN/KAFKA_IMPORT. |
| LEARNING_ENROLMENT_COMPLETION_HISTORY | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |
| LEARNING_ENROLMENT_OMITTED | · | · | · | · | · | · | **DIFFS FOUND** | expected blocked: KAFKA_IMPORT. |

## Details

### LEARNING_ASSIGNMENT_RULE — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_COST — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_COURSE — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_CPD_PLAN — DIFFS FOUND
- T1: no result
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_ACTIVITY — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_COMPLETION_HISTORY — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD

### LEARNING_ENROLMENT_OMITTED — DIFFS FOUND
- T1: no result
- T2 key diff: None in PROD-only, None in UAT-only; grain unique: True
- T3 EXCEPT: None PROD-not-UAT, None UAT-not-PROD
