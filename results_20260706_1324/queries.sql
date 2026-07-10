
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_COMPLETION_HISTORY'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_COMPLETION_HISTORY'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_COMPLETION_HISTORY') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_COMPLETION_HISTORY') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Enrolment Completion History ID", "ENROLMENT_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Enrolment Completion History ID", "ENROLMENT_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Enrolment Completion History ID" AS "Enrolment Completion History ID",
       t."USER_ID" AS "USER_ID",
       t."COURSE_ID" AS "COURSE_ID",
       t."ENROLMENT_ID" AS "ENROLMENT_ID",
       NULLIF(t."Enrolment Completion History Course Title", '') AS "Enrolment Completion History Course Title",
       NULLIF(t."Enrolment Completion History Content", '') AS "Enrolment Completion History Content",
       t."Enrolment Completion History Completion Date" AS "Enrolment Completion History Completion Date",
       t."Enrolment Completion History Start Date" AS "Enrolment Completion History Start Date",
       t."Enrolment Completion History Is Active Enrolment" AS "Enrolment Completion History Is Active Enrolment",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."USER_ID", u."USER_ID")) AS "USER_ID",
       COUNT_IF(NOT EQUAL_NULL(p."COURSE_ID", u."COURSE_ID")) AS "COURSE_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Completion History Course Title",''), NULLIF(u."Enrolment Completion History Course Title",''))) AS "Enrolment Completion History Course Title",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Enrolment Completion History Content",''), NULLIF(u."Enrolment Completion History Content",''))) AS "Enrolment Completion History Content",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Completion History Completion Date", u."Enrolment Completion History Completion Date")) AS "Enrolment Completion History Completion Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Completion History Start Date", u."Enrolment Completion History Start Date")) AS "Enrolment Completion History Start Date",
       COUNT_IF(NOT EQUAL_NULL(p."Enrolment Completion History Is Active Enrolment", u."Enrolment Completion History Is Active Enrolment")) AS "Enrolment Completion History Is Active Enrolment"
FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY u USING ("Enrolment Completion History ID", "ENROLMENT_ID", "CLIENT_NAME", "CLIENT_REGION")