
            SELECT column_name, ordinal_position, data_type
            FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_CANDIDATE'
            ORDER BY ordinal_position

----------------


            SELECT column_name, ordinal_position, data_type
            FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
            WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_CANDIDATE'
            ORDER BY ordinal_position

----------------


            SELECT COALESCE(p.column_name, u.column_name) AS column_name,
                   p.ordinal_position, u.ordinal_position, p.data_type, u.data_type
            FROM (SELECT * FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_CANDIDATE') p
            FULL JOIN (SELECT * FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS
                  WHERE table_schema = 'BI' AND table_name = 'RECRUITMENT_CANDIDATE') u
              ON p.column_name = u.column_name
            WHERE p.column_name IS NULL OR u.column_name IS NULL
               OR p.ordinal_position != u.ordinal_position
               OR p.data_type != u.data_type
            ORDER BY COALESCE(p.ordinal_position, u.ordinal_position)

----------------


            SELECT p.n, u.n, p.n - u.n
            FROM (SELECT COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) p,
                 (SELECT COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) u

----------------


                SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM PROD_DB.BI.RECRUITMENT_CANDIDATE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------


                SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", COUNT(*) AS n FROM UAT_DB.BI.RECRUITMENT_CANDIDATE
                GROUP BY ALL HAVING COUNT(*) > 1
                ORDER BY n DESC LIMIT 100

----------------

WITH prod AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT 'in_prod_not_uat' AS direction, COUNT(*) FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat)
UNION ALL
SELECT 'in_uat_not_prod', COUNT(*) FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod)

----------------

SELECT COUNT(*) FROM (SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

SELECT COUNT(*) FROM (SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)

----------------

SELECT * FROM (SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region MINUS SELECT t."CANDIDATE_ID", t."Candidate Is External", t."CLIENT_NAME", t."CLIENT_REGION" FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region) LIMIT 25

----------------

WITH prod AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM prod EXCEPT SELECT * FROM uat) LIMIT 25

----------------

WITH prod AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM PROD_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region),
     uat AS (SELECT t."CANDIDATE_ID" AS "CANDIDATE_ID",
       t."Candidate Is External" AS "Candidate Is External",
       NULLIF(t."Candidate First Name", '') AS "Candidate First Name",
       NULLIF(t."Candidate Last Name", '') AS "Candidate Last Name",
       NULLIF(t."Candidate Full Name", '') AS "Candidate Full Name",
       NULLIF(t."Candidate Username", '') AS "Candidate Username",
       t."Candidate Is Active" AS "Candidate Is Active",
       t."Candidate Is Notified" AS "Candidate Is Notified",
       t."Candidate Is Onboarding" AS "Candidate Is Onboarding",
       NULLIF(t."Candidate Employee Number", '') AS "Candidate Employee Number",
       NULLIF(t."Candidate State", '') AS "Candidate State",
       NULLIF(t."Candidate Country", '') AS "Candidate Country",
       t."Candidate Start Date" AS "Candidate Start Date",
       t."Candidate End Date" AS "Candidate End Date",
       NULLIF(t."Candidate Home Phone", '') AS "Candidate Home Phone",
       NULLIF(t."Candidate Work Phone", '') AS "Candidate Work Phone",
       NULLIF(t."Candidate Mobile Number", '') AS "Candidate Mobile Number",
       t."Candidate Expiry Date" AS "Candidate Expiry Date",
       NULLIF(t."Candidate Email", '') AS "Candidate Email",
       t."Candidate Created Date" AS "Candidate Created Date",
       t."Candidate Modified Date" AS "Candidate Modified Date",
       t."Candidate Last Login Date" AS "Candidate Last Login Date",
       t."Candidate Last Logout Date" AS "Candidate Last Logout Date",
       NULLIF(t."Candidate Timezone", '') AS "Candidate Timezone",
       NULLIF(t."Candidate Source", '') AS "Candidate Source",
       NULLIF(t."Candidate Role", '') AS "Candidate Role",
       NULLIF(t."CLIENT_NAME", '') AS "CLIENT_NAME",
       NULLIF(t."CLIENT_REGION", '') AS "CLIENT_REGION"
       FROM UAT_DB.BI.RECRUITMENT_CANDIDATE t  INNER JOIN UAT_DB.BI.TEMP_ACTIVE_TENANTS AS act ON t.client_name = act.client_name AND t.client_region = act.client_region)
SELECT * FROM (SELECT * FROM uat EXCEPT SELECT * FROM prod) LIMIT 25

----------------

SELECT COUNT(*) AS shared_keys,
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate First Name",''), NULLIF(u."Candidate First Name",''))) AS "Candidate First Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Last Name",''), NULLIF(u."Candidate Last Name",''))) AS "Candidate Last Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Full Name",''), NULLIF(u."Candidate Full Name",''))) AS "Candidate Full Name",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Username",''), NULLIF(u."Candidate Username",''))) AS "Candidate Username",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Is Active", u."Candidate Is Active")) AS "Candidate Is Active",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Is Notified", u."Candidate Is Notified")) AS "Candidate Is Notified",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Is Onboarding", u."Candidate Is Onboarding")) AS "Candidate Is Onboarding",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Employee Number",''), NULLIF(u."Candidate Employee Number",''))) AS "Candidate Employee Number",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate State",''), NULLIF(u."Candidate State",''))) AS "Candidate State",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Country",''), NULLIF(u."Candidate Country",''))) AS "Candidate Country",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Start Date", u."Candidate Start Date")) AS "Candidate Start Date",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate End Date", u."Candidate End Date")) AS "Candidate End Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Home Phone",''), NULLIF(u."Candidate Home Phone",''))) AS "Candidate Home Phone",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Work Phone",''), NULLIF(u."Candidate Work Phone",''))) AS "Candidate Work Phone",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Mobile Number",''), NULLIF(u."Candidate Mobile Number",''))) AS "Candidate Mobile Number",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Expiry Date", u."Candidate Expiry Date")) AS "Candidate Expiry Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Email",''), NULLIF(u."Candidate Email",''))) AS "Candidate Email",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Created Date", u."Candidate Created Date")) AS "Candidate Created Date",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Modified Date", u."Candidate Modified Date")) AS "Candidate Modified Date",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Last Login Date", u."Candidate Last Login Date")) AS "Candidate Last Login Date",
       COUNT_IF(NOT EQUAL_NULL(p."Candidate Last Logout Date", u."Candidate Last Logout Date")) AS "Candidate Last Logout Date",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Timezone",''), NULLIF(u."Candidate Timezone",''))) AS "Candidate Timezone",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Source",''), NULLIF(u."Candidate Source",''))) AS "Candidate Source",
       COUNT_IF(NOT EQUAL_NULL(NULLIF(p."Candidate Role",''), NULLIF(u."Candidate Role",''))) AS "Candidate Role"
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Expiry Date" AS prod_value, u."Candidate Expiry Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Expiry Date", u."Candidate Expiry Date")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Last Login Date" AS prod_value, u."Candidate Last Login Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Last Login Date", u."Candidate Last Login Date")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Last Logout Date" AS prod_value, u."Candidate Last Logout Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Last Logout Date", u."Candidate Last Logout Date")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Role" AS prod_value, u."Candidate Role" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Candidate Role",''), NULLIF(u."Candidate Role",''))
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Modified Date" AS prod_value, u."Candidate Modified Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Modified Date", u."Candidate Modified Date")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Full Name" AS prod_value, u."Candidate Full Name" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Candidate Full Name",''), NULLIF(u."Candidate Full Name",''))
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Start Date" AS prod_value, u."Candidate Start Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Start Date", u."Candidate Start Date")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Is Active" AS prod_value, u."Candidate Is Active" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate Is Active", u."Candidate Is Active")
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate Mobile Number" AS prod_value, u."Candidate Mobile Number" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(NULLIF(p."Candidate Mobile Number",''), NULLIF(u."Candidate Mobile Number",''))
LIMIT 5

----------------

SELECT "CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION", p."Candidate End Date" AS prod_value, u."Candidate End Date" AS uat_value
FROM PROD_DB.BI.RECRUITMENT_CANDIDATE p
JOIN UAT_DB.BI.RECRUITMENT_CANDIDATE u USING ("CANDIDATE_ID", "Candidate Is External", "CLIENT_NAME", "CLIENT_REGION")
WHERE NOT EQUAL_NULL(p."Candidate End Date", u."Candidate End Date")
LIMIT 5