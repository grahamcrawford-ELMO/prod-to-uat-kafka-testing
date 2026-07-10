
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "File Submission ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "File Submission ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."File Submission ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."File Submission ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."File Submission ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."File Submission ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."File Submission ID" AS "File Submission ID",
       t."USER_ID" AS "USER_ID",
       t."ENROLMENT_ACTIVITY_ID" AS "ENROLMENT_ACTIVITY_ID",
       NULLIF(t."File Submission Reviewed By Name", '') AS "File Submission Reviewed By Name",
       NULLIF(t."File Submission Note", '') AS "File Submission Note",
       t."File Submission Reviewed Date" AS "File Submission Reviewed Date",
       t."File Submission Submitted Date" AS "File Submission Submitted Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."USER_ID", u."USER_ID")) AS "USER_ID",
       COUNT_IF(NOT EQUAL_NULL(p."ENROLMENT_ACTIVITY_ID", u."ENROLMENT_ACTIVITY_ID")) AS "ENROLMENT_ACTIVITY_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."File Submission Reviewed By Name",''), NULLIF(u."File Submission Reviewed By Name",''))) AS "File Submission Reviewed By Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."File Submission Note",''), NULLIF(u."File Submission Note",''))) AS "File Submission Note",
       COUNT_IF(NOT EQUAL_NULL(p."File Submission Reviewed Date", u."File Submission Reviewed Date")) AS "File Submission Reviewed Date",
       COUNT_IF(NOT EQUAL_NULL(p."File Submission Submitted Date", u."File Submission Submitted Date")) AS "File Submission Submitted Date"
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION u USING ("File Submission ID", "CLIENT_NAME", "CLIENT_REGION")