
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
       t."COURSE_ID" AS "COURSE_ID",
       NULLIF(t."Assignment Rule Name", '') AS "Assignment Rule Name",
       NULLIF(t."Assignment Rule Description", '') AS "Assignment Rule Description",
       t."Assignment Rule Created Date" AS "Assignment Rule Created Date",
       t."Assignment Rule Modified Date" AS "Assignment Rule Modified Date",
       t."Assignment Rule Is Active" AS "Assignment Rule Is Active",
       t."Assignment Rule Is Confirmed" AS "Assignment Rule Is Confirmed",
       t."Assignment Rule Is Required Course" AS "Assignment Rule Is Required Course",
       t."Assignment Rule Is Recommended Course" AS "Assignment Rule Is Recommended Course",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25