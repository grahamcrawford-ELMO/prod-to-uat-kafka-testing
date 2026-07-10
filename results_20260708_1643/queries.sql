
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'GENERAL_JOB_ROLE'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'GENERAL_JOB_ROLE'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'GENERAL_JOB_ROLE') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'GENERAL_JOB_ROLE') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT COALESCE(p.client_name, u.client_name)   AS client_name,
                       COALESCE(p.client_region, u.client_region) AS client_region,
                       COALESCE(p.n, 0) AS prod_rows, COALESCE(u.n, 0) AS uat_rows,
                       COALESCE(p.n, 0) - COALESCE(u.n, 0) AS diff
                FROM (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                      GROUP BY 1, 2) p
                FULL JOIN (SELECT t.client_name, t.client_region, COUNT(*) AS n
                      FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                      GROUP BY 1, 2) u
                  ON p.client_name = u.client_name AND p.client_region = u.client_region
                WHERE COALESCE(p.n, 0) != COALESCE(u.n, 0)
                ORDER BY ABS(COALESCE(p.n, 0) - COALESCE(u.n, 0)) DESC
                LIMIT 1000

----------------


                SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION", COUNT(*) AS n
                FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 1000

----------------


                SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION", COUNT(*) AS n
                FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 1000

----------------

WITH shared_keys AS (
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 1000

----------------

SELECT COUNT(*) FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 1000

----------------

WITH shared_keys AS (
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 100

----------------

WITH shared_keys AS (
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       INTERSECT
       SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION")),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region
       JOIN shared_keys sk ON EQUAL_NULL(t."Job Role ID", sk."Job Role ID") AND EQUAL_NULL(t."CLIENT_NAME", sk."CLIENT_NAME") AND EQUAL_NULL(t."CLIENT_REGION", sk."CLIENT_REGION"))
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 100

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Role Title",''), NULLIF(u."Job Role Title",''))) AS "Job Role Title",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Role Description",''), NULLIF(u."Job Role Description",''))) AS "Job Role Description",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Role Identifier",''), NULLIF(u."Job Role Identifier",''))) AS "Job Role Identifier",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Role Skills and Experience",''), NULLIF(u."Job Role Skills and Experience",''))) AS "Job Role Skills and Experience",
       COUNT_IF(NOT EQUAL_NULL(p."Job Role Created Date", u."Job Role Created Date")) AS "Job Role Created Date",
       COUNT_IF(NOT EQUAL_NULL(p."Job Role Modified Date", u."Job Role Modified Date")) AS "Job Role Modified Date"
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region

----------------

SELECT p."Job Role ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Job Role Skills and Experience" AS prod_value, u."Job Role Skills and Experience" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Skills and Experience",''), NULLIF(u."Job Role Skills and Experience",''))
LIMIT 5

----------------

SELECT p."Job Role ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Job Role Description" AS prod_value, u."Job Role Description" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Description",''), NULLIF(u."Job Role Description",''))
LIMIT 5

----------------

SELECT p."Job Role ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Job Role Modified Date" AS prod_value, u."Job Role Modified Date" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(p."Job Role Modified Date", u."Job Role Modified Date")
LIMIT 5

----------------

SELECT p."Job Role ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Job Role Title" AS prod_value, u."Job Role Title" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Title",''), NULLIF(u."Job Role Title",''))
LIMIT 5

----------------

SELECT p."Job Role ID", p."CLIENT_NAME", p."CLIENT_REGION", p."Job Role Identifier" AS prod_value, u."Job Role Identifier" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
 INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON p.client_name = act.client_name AND p.client_region = act.client_region
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Identifier",''), NULLIF(u."Job Role Identifier",''))
LIMIT 5