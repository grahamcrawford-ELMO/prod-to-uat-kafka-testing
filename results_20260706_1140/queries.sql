
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

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE p
JOIN UAT_DB.BI.LEARNING_ASSIGNMENT_RULE u USING ("Assignment Rule ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ASSIGNMENT_RULE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_COST'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_COST'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_COST') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_COST') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Learning Cost ID", "USER_LEARNING_COST_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_COST
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Learning Cost ID", "USER_LEARNING_COST_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_COST
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Learning Cost ID", t."USER_LEARNING_COST_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Learning Cost ID", t."USER_LEARNING_COST_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Learning Cost ID", t."USER_LEARNING_COST_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Learning Cost ID", t."USER_LEARNING_COST_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_COST p
JOIN UAT_DB.BI.LEARNING_COST u USING ("Learning Cost ID", "USER_LEARNING_COST_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_COST t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_COURSE'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_COURSE'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_COURSE') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_COURSE') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Course ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_COURSE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Course ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_COURSE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Course ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Course ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Course ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Course ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_COURSE p
JOIN UAT_DB.BI.LEARNING_COURSE u USING ("Course ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_COURSE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_CPD_PLAN'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_CPD_PLAN'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_CPD_PLAN') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_CPD_PLAN') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_CPD_PLAN t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


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

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT p
JOIN UAT_DB.BI.LEARNING_ENROLMENT u USING ("Enrolment Id", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Enrolment Activity ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Enrolment Activity ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Activity ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Activity ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Enrolment Activity ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Activity ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY u USING ("Enrolment Activity ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT u USING ("ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_ACKNOWLEDGEMENT t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Face to Face Signup Signup ID", "Face to Face Session ID", "COURSE_MODULE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Face to Face Signup Signup ID", "Face to Face Session ID", "COURSE_MODULE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Face to Face Signup Signup ID", t."Face to Face Session ID", t."COURSE_MODULE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Face to Face Signup Signup ID", t."Face to Face Session ID", t."COURSE_MODULE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Face to Face Signup Signup ID", t."Face to Face Session ID", t."COURSE_MODULE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Face to Face Signup Signup ID", t."Face to Face Session ID", t."COURSE_MODULE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP u USING ("Face to Face Signup Signup ID", "Face to Face Session ID", "COURSE_MODULE_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_F2F_SESSION_SIGNUP t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


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

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION u USING ("File Submission ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_FILE_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Quiz Submission ID", t."QUESTION_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION u USING ("Quiz Submission ID", "QUESTION_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_ACTIVITY_QUIZ_SUBMISSION t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


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

SELECT COUNT(*) FROM (SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Enrolment Completion History ID", t."ENROLMENT_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY u USING ("Enrolment Completion History ID", "ENROLMENT_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_COMPLETION_HISTORY t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------


            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_OMITTED'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_OMITTED'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_OMITTED') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'LEARNING_ENROLMENT_OMITTED') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "USER_ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "USER_ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

SELECT COUNT(*) FROM (SELECT t."USER_ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."USER_ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT COUNT(*) FROM (SELECT t."USER_ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."USER_ID", t."COURSE_ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

WITH prod AS (SELECT 
       FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT 
       FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) AS shared_keys,
       
FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED p
JOIN UAT_DB.BI.LEARNING_ENROLMENT_OMITTED u USING ("USER_ID", "COURSE_ID", "CLIENT_NAME", "CLIENT_REGION")

----------------


SELECT HASH_AGG(*) FROM (SELECT  FROM PROD_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
UNION
SELECT HASH_AGG(*) FROM (SELECT  FROM UAT_DB.BI.LEARNING_ENROLMENT_OMITTED t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)