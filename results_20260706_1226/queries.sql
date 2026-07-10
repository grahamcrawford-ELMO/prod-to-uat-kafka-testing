
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Enrolment Id", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Enrolment Id", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Id", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Id", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Id", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Id", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Id" AS "Enrolment Id",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Enrolment Method", '') AS "Enrolment Method",
       NULLIF(t."Enrolment Status", '') AS "Enrolment Status",
       t."Enrolment Cost" AS "Enrolment Cost",
       t."Enrolment First Enrolled Date" AS "Enrolment First Enrolled Date",
       t."Enrolment Due Date" AS "Enrolment Due Date",
       t."Enrolment Start Date" AS "Enrolment Start Date",
       t."Enrolment Completion Date" AS "Enrolment Completion Date",
       t."Enrolment Created Date" AS "Enrolment Created Date",
       t."Enrolment Modified Date" AS "Enrolment Modified Date",
       NULLIF(t."Enrolment Assignment Rule", '') AS "Enrolment Assignment Rule",
       NULLIF(t."Enrolment Retrain In Period", '') AS "Enrolment Retrain In Period",
       NULLIF(t."Enrolment Retrain Open In Period", '') AS "Enrolment Retrain Open In Period",
       t."Enrolment Retrain Date" AS "Enrolment Retrain Date",
       t."Enrolment Retrain Open Date" AS "Enrolment Retrain Open Date",
       t."Enrolment Is Retrain Overdue" AS "Enrolment Is Retrain Overdue",
       t."Enrolment Is Enrolment Overdue" AS "Enrolment Is Enrolment Overdue",
       t."Enrolment Overdue Days" AS "Enrolment Overdue Days",
       t."Enrolment Retrain Overdue Days" AS "Enrolment Retrain Overdue Days",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."USER_ID", u."USER_ID")) AS "USER_ID",
       COUNT_IF(NOT EQUAL_NULL(p."COURSE_ID", u."COURSE_ID")) AS "COURSE_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Method",''), NULLIF(u."Enrolment Method",''))) AS "Enrolment Method",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Status",''), NULLIF(u."Enrolment Status",''))) AS "Enrolment Status",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Cost", u."Enrolment Cost")) AS "Enrolment Cost",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment First Enrolled Date", u."Enrolment First Enrolled Date")) AS "Enrolment First Enrolled Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Due Date", u."Enrolment Due Date")) AS "Enrolment Due Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Start Date", u."Enrolment Start Date")) AS "Enrolment Start Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Completion Date", u."Enrolment Completion Date")) AS "Enrolment Completion Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Created Date", u."Enrolment Created Date")) AS "Enrolment Created Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Modified Date", u."Enrolment Modified Date")) AS "Enrolment Modified Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Assignment Rule",''), NULLIF(u."Enrolment Assignment Rule",''))) AS "Enrolment Assignment Rule",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Retrain In Period",''), NULLIF(u."Enrolment Retrain In Period",''))) AS "Enrolment Retrain In Period",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Retrain Open In Period",''), NULLIF(u."Enrolment Retrain Open In Period",''))) AS "Enrolment Retrain Open In Period",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Retrain Date", u."Enrolment Retrain Date")) AS "Enrolment Retrain Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Retrain Open Date", u."Enrolment Retrain Open Date")) AS "Enrolment Retrain Open Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Is Retrain Overdue", u."Enrolment Is Retrain Overdue")) AS "Enrolment Is Retrain Overdue",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Is Enrolment Overdue", u."Enrolment Is Enrolment Overdue")) AS "Enrolment Is Enrolment Overdue",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Overdue Days", u."Enrolment Overdue Days")) AS "Enrolment Overdue Days",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Retrain Overdue Days", u."Enrolment Retrain Overdue Days")) AS "Enrolment Retrain Overdue Days"
FROM PROD_DB.BI.LEARNING_ENROLMENT p
JOIN UAT_DB.BI.LEARNING_ENROLMENT u USING ("Enrolment Id", "CLIENT_NAME", "CLIENT_REGION")