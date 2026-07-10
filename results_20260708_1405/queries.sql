
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_QUESTION_ANSWER'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_QUESTION_ANSWER'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_QUESTION_ANSWER') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_QUESTION_ANSWER') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

WITH prod AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."JOB_APPLICATION_ID", t."ANSWER_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."ANSWER_ID" AS "ANSWER_ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Questions Category", '') AS "Questions Category",
       NULLIF(t."Questions Question", '') AS "Questions Question",
       NULLIF(t."Questions Answer", '') AS "Questions Answer",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Questions Category",''), NULLIF(u."Questions Category",''))) AS "Questions Category",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Questions Question",''), NULLIF(u."Questions Question",''))) AS "Questions Question",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Questions Answer",''), NULLIF(u."Questions Answer",''))) AS "Questions Answer"
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER u USING ("JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------

SELECT "JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION", p."Questions Question" AS prod_value, u."Questions Question" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER u USING ("JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Questions Question",''), NULLIF(u."Questions Question",''))
LIMIT 5

----------------

SELECT "JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION", p."Questions Answer" AS prod_value, u."Questions Answer" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_QUESTION_ANSWER u USING ("JOB_APPLICATION_ID", "ANSWER_ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Questions Answer",''), NULLIF(u."Questions Answer",''))
LIMIT 5