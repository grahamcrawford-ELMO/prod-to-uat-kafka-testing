
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'CLIENT_MANAGER_ACCESS_CONFIG'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'CLIENT_MANAGER_ACCESS_CONFIG'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'CLIENT_MANAGER_ACCESS_CONFIG') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'CLIENT_MANAGER_ACCESS_CONFIG') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

WITH prod AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ID" AS "ID",
       NULLIF(t."MODULE", '') AS "MODULE",
       NULLIF(t."NAME", '') AS "NAME",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION",
       NULLIF(t."VALUE", '') AS "VALUE"
       FROM UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."MODULE",''), NULLIF(u."MODULE",''))) AS "MODULE",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."NAME",''), NULLIF(u."NAME",''))) AS "NAME",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."VALUE",''), NULLIF(u."VALUE",''))) AS "VALUE"
FROM PROD_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG p
JOIN UAT_DB.BI.CLIENT_MANAGER_ACCESS_CONFIG u USING ("ID", "CLIENT_NAME", "CLIENT_REGION")