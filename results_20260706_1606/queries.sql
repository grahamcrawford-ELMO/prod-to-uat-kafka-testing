
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


                SELECT "Job Role ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.GENERAL_JOB_ROLE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Job Role ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.GENERAL_JOB_ROLE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

WITH prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Role ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Role ID" AS "Job Role ID",
       NULLIF(t."Job Role Title", '') AS "Job Role Title",
       NULLIF(t."Job Role Description", '') AS "Job Role Description",
       NULLIF(t."Job Role Identifier", '') AS "Job Role Identifier",
       NULLIF(t."Job Role Skills and Experience", '') AS "Job Role Skills and Experience",
       t."Job Role Created Date" AS "Job Role Created Date",
       t."Job Role Modified Date" AS "Job Role Modified Date",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.GENERAL_JOB_ROLE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

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

----------------

SELECT "Job Role ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Role Skills and Experience" AS prod_value, u."Job Role Skills and Experience" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Skills and Experience",''), NULLIF(u."Job Role Skills and Experience",''))
LIMIT 5

----------------

SELECT "Job Role ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Role Description" AS prod_value, u."Job Role Description" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Role Description",''), NULLIF(u."Job Role Description",''))
LIMIT 5

----------------

SELECT "Job Role ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Role Modified Date" AS prod_value, u."Job Role Modified Date" AS uat_value
FROM PROD_DB.BI.GENERAL_JOB_ROLE p
JOIN UAT_DB.BI.GENERAL_JOB_ROLE u USING ("Job Role ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Job Role Modified Date", u."Job Role Modified Date")
LIMIT 5