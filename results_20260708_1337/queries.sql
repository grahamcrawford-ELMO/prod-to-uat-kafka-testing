
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_INTERVIEW'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_INTERVIEW'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_INTERVIEW') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_INTERVIEW') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

WITH prod AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Interview ID", t."INTERVIEW_ASSIGNMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Interview ID" AS "Interview ID",
       t."REQUISITION_ID" AS "REQUISITION_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       t."INTERVIEWER_USER_ID" AS "INTERVIEWER_USER_ID",
       t."INTERVIEW_ASSIGNMENT_ID" AS "INTERVIEW_ASSIGNMENT_ID",
       NULLIF(t."Interview Title", '') AS "Interview Title",
       NULLIF(t."Interview Status", '') AS "Interview Status",
       t."Interview Modified Date" AS "Interview Modified Date",
       NULLIF(t."Interview Guide Title", '') AS "Interview Guide Title",
       t."Interview Is Notified" AS "Interview Is Notified",
       t."Interview Notified Date" AS "Interview Notified Date",
       NULLIF(t."Interview Subject", '') AS "Interview Subject",
       NULLIF(t."Interview Email", '') AS "Interview Email",
       NULLIF(t."Interview Timezone", '') AS "Interview Timezone",
       t."Interview Due Date" AS "Interview Due Date",
       t."Interview End Date" AS "Interview End Date",
       NULLIF(t."Interview Interviewer", '') AS "Interview Interviewer",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."REQUISITION_ID", u."REQUISITION_ID")) AS "REQUISITION_ID",
       COUNT_IF(NOT EQUAL_NULL(p."JOB_APPLICATION_ID", u."JOB_APPLICATION_ID")) AS "JOB_APPLICATION_ID",
       COUNT_IF(NOT EQUAL_NULL(p."INTERVIEWER_USER_ID", u."INTERVIEWER_USER_ID")) AS "INTERVIEWER_USER_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Title",''), NULLIF(u."Interview Title",''))) AS "Interview Title",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Status",''), NULLIF(u."Interview Status",''))) AS "Interview Status",
       COUNT_IF(NOT EQUAL_NULL(p."Interview Modified Date", u."Interview Modified Date")) AS "Interview Modified Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Guide Title",''), NULLIF(u."Interview Guide Title",''))) AS "Interview Guide Title",
       COUNT_IF(NOT EQUAL_NULL(p."Interview Is Notified", u."Interview Is Notified")) AS "Interview Is Notified",
       COUNT_IF(NOT EQUAL_NULL(p."Interview Notified Date", u."Interview Notified Date")) AS "Interview Notified Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Subject",''), NULLIF(u."Interview Subject",''))) AS "Interview Subject",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Email",''), NULLIF(u."Interview Email",''))) AS "Interview Email",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Timezone",''), NULLIF(u."Interview Timezone",''))) AS "Interview Timezone",
       COUNT_IF(NOT EQUAL_NULL(p."Interview Due Date", u."Interview Due Date")) AS "Interview Due Date",
       COUNT_IF(NOT EQUAL_NULL(p."Interview End Date", u."Interview End Date")) AS "Interview End Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Interview Interviewer",''), NULLIF(u."Interview Interviewer",''))) AS "Interview Interviewer"
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Email" AS prod_value, u."Interview Email" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Interview Email",''), NULLIF(u."Interview Email",''))
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Due Date" AS prod_value, u."Interview Due Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Interview Due Date", u."Interview Due Date")
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Modified Date" AS prod_value, u."Interview Modified Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Interview Modified Date", u."Interview Modified Date")
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Status" AS prod_value, u."Interview Status" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Interview Status",''), NULLIF(u."Interview Status",''))
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview End Date" AS prod_value, u."Interview End Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Interview End Date", u."Interview End Date")
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Interviewer" AS prod_value, u."Interview Interviewer" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Interview Interviewer",''), NULLIF(u."Interview Interviewer",''))
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Notified Date" AS prod_value, u."Interview Notified Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Interview Notified Date", u."Interview Notified Date")
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Timezone" AS prod_value, u."Interview Timezone" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Interview Timezone",''), NULLIF(u."Interview Timezone",''))
LIMIT 5

----------------

SELECT "Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION", p."Interview Is Notified" AS prod_value, u."Interview Is Notified" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_INTERVIEW u USING ("Interview ID", "INTERVIEW_ASSIGNMENT_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Interview Is Notified", u."Interview Is Notified")
LIMIT 5