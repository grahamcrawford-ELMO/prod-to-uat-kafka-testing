
            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI_PRD' AND table_name = 'LEARNING_ASSIGNMENT_RULE'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI_PRD' AND table_name = 'LEARNING_ASSIGNMENT_RULE') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ASSIGNMENT_RULE') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT COALESCE(p.client_name, u.client_name)   AS client_name,
                       COALESCE(p.client_region, u.client_region) AS client_region,
                       COALESCE(p.n, 0) AS prod_rows, COALESCE(u.n, 0) AS uat_rows,
                       COALESCE(p.n, 0) - COALESCE(u.n, 0) AS diff
                FROM (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                      GROUP BY 1, 2) p
                FULL JOIN (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                      GROUP BY 1, 2) u
                  ON p.client_name = u.client_name AND p.client_region = u.client_region
                WHERE COALESCE(p.n, 0) != COALESCE(u.n, 0)
                ORDER BY ABS(COALESCE(p.n, 0) - COALESCE(u.n, 0)) DESC
                LIMIT 1000

----------------


                SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION", COUNT(*) AS n
                FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 1000

----------------


                SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION", COUNT(*) AS n
                FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 1000

----------------

WITH shared_keys AS (
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
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
       FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
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
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 1000

----------------

SELECT COUNT(*) FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 1000

----------------

WITH shared_keys AS (
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
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
       FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
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
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 100

----------------

WITH shared_keys AS (
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Assignment Rule ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Assignment Rule ID" AS "Assignment Rule ID",
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
       FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
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
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Assignment Rule ID", sk."Assignment Rule ID") AND EQUAL_NULL(t."COURSE_ID", sk."COURSE_ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 100

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Assignment Rule Name",''), NULLIF(u."Assignment Rule Name",''))) AS "Assignment Rule Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Assignment Rule Description",''), NULLIF(u."Assignment Rule Description",''))) AS "Assignment Rule Description",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Created Date", u."Assignment Rule Created Date")) AS "Assignment Rule Created Date",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Modified Date", u."Assignment Rule Modified Date")) AS "Assignment Rule Modified Date",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Is Active", u."Assignment Rule Is Active")) AS "Assignment Rule Is Active",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Is Confirmed", u."Assignment Rule Is Confirmed")) AS "Assignment Rule Is Confirmed",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Is Required Course", u."Assignment Rule Is Required Course")) AS "Assignment Rule Is Required Course",
       COUNT_IF(NOT EQUAL_NULL(p."Assignment Rule Is Recommended Course", u."Assignment Rule Is Recommended Course")) AS "Assignment Rule Is Recommended Course"
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region

----------------

SELECT p."Assignment Rule ID", p."COURSE_ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Assignment Rule Created Date" AS prod_value, u."Assignment Rule Created Date" AS uat_value
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(p."Assignment Rule Created Date", u."Assignment Rule Created Date")
LIMIT 5

----------------

SELECT p."Assignment Rule ID", p."COURSE_ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Assignment Rule Modified Date" AS prod_value, u."Assignment Rule Modified Date" AS uat_value
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(p."Assignment Rule Modified Date", u."Assignment Rule Modified Date")
LIMIT 5

----------------

SELECT p."Assignment Rule ID", p."COURSE_ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Assignment Rule Description" AS prod_value, u."Assignment Rule Description" AS uat_value
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(NULLIF(p."Assignment Rule Description",''), NULLIF(u."Assignment Rule Description",''))
LIMIT 5

----------------

SELECT p."Assignment Rule ID", p."COURSE_ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Assignment Rule Is Recommended Course" AS prod_value, u."Assignment Rule Is Recommended Course" AS uat_value
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(p."Assignment Rule Is Recommended Course", u."Assignment Rule Is Recommended Course")
LIMIT 5

----------------

SELECT p."Assignment Rule ID", p."COURSE_ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Assignment Rule Is Required Course" AS prod_value, u."Assignment Rule Is Required Course" AS uat_value
FROM UAT_DB.BI_PRD.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(p."Assignment Rule Is Required Course", u."Assignment Rule Is Required Course")
LIMIT 5