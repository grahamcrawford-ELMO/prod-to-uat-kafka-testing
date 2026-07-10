
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_JOB_OFFER'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_JOB_OFFER'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_JOB_OFFER') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_APPLICATION_JOB_OFFER') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

WITH prod AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."Job Offer ID", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."Job Offer ID" AS "Job Offer ID",
       t."JOB_APPLICATION_ID" AS "JOB_APPLICATION_ID",
       NULLIF(t."Job Offer Manager Full Name", '') AS "Job Offer Manager Full Name",
       NULLIF(t."Job Offer Requester Full Name", '') AS "Job Offer Requester Full Name",
       NULLIF(t."Job Offer Department", '') AS "Job Offer Department",
       NULLIF(t."Job Offer Location", '') AS "Job Offer Location",
       t."Job Offer Salary" AS "Job Offer Salary",
       t."Job Offer Start Date" AS "Job Offer Start Date",
       t."Job Offer Submitted Date" AS "Job Offer Submitted Date",
       NULLIF(t."Job Offer Status", '') AS "Job Offer Status",
       NULLIF(t."Job Offer Response Status", '') AS "Job Offer Response Status",
       NULLIF(t."Job Offer Withdrawn Reason", '') AS "Job Offer Withdrawn Reason",
       t."Job Offer Accepted Date" AS "Job Offer Accepted Date",
       NULLIF(t."Job Offer Candidate Response Message", '') AS "Job Offer Candidate Response Message",
       NULLIF(t."Job Offer Responded by", '') AS "Job Offer Responded by",
       NULLIF(t."Job Offer User Message", '') AS "Job Offer User Message",
       NULLIF(t."Job Offer Job Type", '') AS "Job Offer Job Type",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(p."JOB_APPLICATION_ID", u."JOB_APPLICATION_ID")) AS "JOB_APPLICATION_ID",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Manager Full Name",''), NULLIF(u."Job Offer Manager Full Name",''))) AS "Job Offer Manager Full Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Requester Full Name",''), NULLIF(u."Job Offer Requester Full Name",''))) AS "Job Offer Requester Full Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Department",''), NULLIF(u."Job Offer Department",''))) AS "Job Offer Department",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Location",''), NULLIF(u."Job Offer Location",''))) AS "Job Offer Location",
       COUNT_IF(NOT EQUAL_NULL(p."Job Offer Salary", u."Job Offer Salary")) AS "Job Offer Salary",
       COUNT_IF(NOT EQUAL_NULL(p."Job Offer Start Date", u."Job Offer Start Date")) AS "Job Offer Start Date",
       COUNT_IF(NOT EQUAL_NULL(p."Job Offer Submitted Date", u."Job Offer Submitted Date")) AS "Job Offer Submitted Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Status",''), NULLIF(u."Job Offer Status",''))) AS "Job Offer Status",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Response Status",''), NULLIF(u."Job Offer Response Status",''))) AS "Job Offer Response Status",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Withdrawn Reason",''), NULLIF(u."Job Offer Withdrawn Reason",''))) AS "Job Offer Withdrawn Reason",
       COUNT_IF(NOT EQUAL_NULL(p."Job Offer Accepted Date", u."Job Offer Accepted Date")) AS "Job Offer Accepted Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Candidate Response Message",''), NULLIF(u."Job Offer Candidate Response Message",''))) AS "Job Offer Candidate Response Message",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Responded by",''), NULLIF(u."Job Offer Responded by",''))) AS "Job Offer Responded by",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer User Message",''), NULLIF(u."Job Offer User Message",''))) AS "Job Offer User Message",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Job Offer Job Type",''), NULLIF(u."Job Offer Job Type",''))) AS "Job Offer Job Type"
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Status" AS prod_value, u."Job Offer Status" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Status",''), NULLIF(u."Job Offer Status",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Response Status" AS prod_value, u."Job Offer Response Status" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Response Status",''), NULLIF(u."Job Offer Response Status",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Accepted Date" AS prod_value, u."Job Offer Accepted Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Job Offer Accepted Date", u."Job Offer Accepted Date")
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Location" AS prod_value, u."Job Offer Location" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Location",''), NULLIF(u."Job Offer Location",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Manager Full Name" AS prod_value, u."Job Offer Manager Full Name" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Manager Full Name",''), NULLIF(u."Job Offer Manager Full Name",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer User Message" AS prod_value, u."Job Offer User Message" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer User Message",''), NULLIF(u."Job Offer User Message",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Responded by" AS prod_value, u."Job Offer Responded by" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Responded by",''), NULLIF(u."Job Offer Responded by",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Withdrawn Reason" AS prod_value, u."Job Offer Withdrawn Reason" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Withdrawn Reason",''), NULLIF(u."Job Offer Withdrawn Reason",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Requester Full Name" AS prod_value, u."Job Offer Requester Full Name" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Job Offer Requester Full Name",''), NULLIF(u."Job Offer Requester Full Name",''))
LIMIT 5

----------------

SELECT "Job Offer ID", "CLIENT_NAME", "CLIENT_REGION", p."Job Offer Start Date" AS prod_value, u."Job Offer Start Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER p
JOIN UAT_DB.BI.RECRUITMENT_APPLICATION_JOB_OFFER u USING ("Job Offer ID", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Job Offer Start Date", u."Job Offer Start Date")
LIMIT 5