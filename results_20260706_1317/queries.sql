
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Quiz Submission ID" AS "Quiz Submission ID",
       t."QUESTION_ID" AS "QUESTION_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."Quiz Submission Marked By User", '') AS "Quiz Submission Marked By User",
       t."Quiz Submission Score" AS "Quiz Submission Score",
       NULLIF(t."Quiz Submission Feedback", '') AS "Quiz Submission Feedback",
       t."Quiz Submission Submitted Date" AS "Quiz Submission Submitted Date",
       t."Quiz Submission Marked Date" AS "Quiz Submission Marked Date",
       NULLIF(t."Quiz Submission Status", '') AS "Quiz Submission Status",
       NULLIF(t."Quiz Submission Answer", '') AS "Quiz Submission Answer",
       NULLIF(t."Quiz Submission Question", '') AS "Quiz Submission Question",
       NULLIF(t."Quiz Submission Section", '') AS "Quiz Submission Section",
       NULLIF(t."Quiz Submission Name", '') AS "Quiz Submission Name",
       NULLIF(t."Quiz Submission Introduction", '') AS "Quiz Submission Introduction",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."ENROLMENT_ACTIVITY_ID", u."ENROLMENT_ACTIVITY_ID")) AS "ENROLMENT_ACTIVITY_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Marked By User",''), NULLIF(u."Quiz Submission Marked By User",''))) AS "Quiz Submission Marked By User",
       COUNT_IF(NOT EQUAL_NULL(p."Quiz Submission Score", u."Quiz Submission Score")) AS "Quiz Submission Score",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Feedback",''), NULLIF(u."Quiz Submission Feedback",''))) AS "Quiz Submission Feedback",
       COUNT_IF(NOT EQUAL_NULL(p."Quiz Submission Submitted Date", u."Quiz Submission Submitted Date")) AS "Quiz Submission Submitted Date",
       COUNT_IF(NOT EQUAL_NULL(p."Quiz Submission Marked Date", u."Quiz Submission Marked Date")) AS "Quiz Submission Marked Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Status",''), NULLIF(u."Quiz Submission Status",''))) AS "Quiz Submission Status",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Answer",''), NULLIF(u."Quiz Submission Answer",''))) AS "Quiz Submission Answer",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Question",''), NULLIF(u."Quiz Submission Question",''))) AS "Quiz Submission Question",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Section",''), NULLIF(u."Quiz Submission Section",''))) AS "Quiz Submission Section",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Name",''), NULLIF(u."Quiz Submission Name",''))) AS "Quiz Submission Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Quiz Submission Introduction",''), NULLIF(u."Quiz Submission Introduction",''))) AS "Quiz Submission Introduction"
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION u USING ("Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION")