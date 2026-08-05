-- ===========================================================================
-- EDP_DWI schema parity: PROD_DB.EDP_DWI  vs  UAT_DB.EDP_DWI
-- Standalone equivalent of the harness D0 tier, across every view at once.
--
-- Caveat: INFORMATION_SCHEMA shows only objects the CURRENT ROLE can see, so a
-- view reported as missing may be a grant gap rather than a real absence.
-- Run Q0 first to confirm shared_views sides return a plausible view count.
-- ===========================================================================

-- --- Q0: sanity check -------------------------------------------------------
SELECT 'PROD' AS side, COUNT(*) AS views
FROM PROD_DB.INFORMATION_SCHEMA.VIEWS WHERE table_schema = 'EDP_DWI'
UNION ALL
SELECT 'UAT', COUNT(*)
FROM UAT_DB.INFORMATION_SCHEMA.VIEWS WHERE table_schema = 'EDP_DWI';


-- --- Q1: object-level - views present on one side only ---------------------
WITH p AS (
    SELECT table_name FROM PROD_DB.INFORMATION_SCHEMA.VIEWS
    WHERE table_schema = 'EDP_DWI'
), u AS (
    SELECT table_name FROM UAT_DB.INFORMATION_SCHEMA.VIEWS
    WHERE table_schema = 'EDP_DWI'
)
SELECT COALESCE(p.table_name, u.table_name) AS view_name,
       IFF(p.table_name IS NULL, 'MISSING IN PROD', 'MISSING IN UAT') AS issue
FROM p FULL JOIN u ON p.table_name = u.table_name
WHERE p.table_name IS NULL OR u.table_name IS NULL
ORDER BY issue, view_name;


-- --- Q2: column-level drift (the main query) -------------------------------
-- One row per drifting column. Empty result = full schema parity.
WITH prod AS (
    SELECT c.table_name, c.column_name, c.ordinal_position, c.data_type,
           c.character_maximum_length AS len, c.numeric_precision AS prec,
           c.numeric_scale AS scale, c.is_nullable
    FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS c
    JOIN PROD_DB.INFORMATION_SCHEMA.VIEWS v
      ON v.table_schema = c.table_schema AND v.table_name = c.table_name
    WHERE c.table_schema = 'EDP_DWI'
), uat AS (
    SELECT c.table_name, c.column_name, c.ordinal_position, c.data_type,
           c.character_maximum_length AS len, c.numeric_precision AS prec,
           c.numeric_scale AS scale, c.is_nullable
    FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS c
    JOIN UAT_DB.INFORMATION_SCHEMA.VIEWS v
      ON v.table_schema = c.table_schema AND v.table_name = c.table_name
    WHERE c.table_schema = 'EDP_DWI'
), shared_views AS (
    SELECT p.table_name FROM PROD_DB.INFORMATION_SCHEMA.VIEWS p
    JOIN UAT_DB.INFORMATION_SCHEMA.VIEWS u
      ON p.table_name = u.table_name AND u.table_schema = 'EDP_DWI'
    WHERE p.table_schema = 'EDP_DWI'
)
SELECT COALESCE(p.table_name, u.table_name)   AS view_name,
       COALESCE(p.column_name, u.column_name) AS column_name,
       CASE
         WHEN p.column_name IS NULL THEN 'COLUMN ONLY IN UAT'
         WHEN u.column_name IS NULL THEN 'COLUMN ONLY IN PROD'
         WHEN p.data_type != u.data_type THEN 'TYPE CHANGED'
         WHEN NOT EQUAL_NULL(p.len, u.len)
           OR NOT EQUAL_NULL(p.prec, u.prec)
           OR NOT EQUAL_NULL(p.scale, u.scale) THEN 'PRECISION CHANGED'
         WHEN p.is_nullable != u.is_nullable THEN 'NULLABILITY CHANGED'
         ELSE 'POSITION CHANGED'
       END AS issue,
       p.ordinal_position AS prod_ord,
       u.ordinal_position AS uat_ord,
       p.data_type AS prod_type,
       u.data_type AS uat_type,
       p.len AS prod_len, u.len AS uat_len,
       p.prec AS prod_prec, u.prec AS uat_prec,
       p.scale AS prod_scale, u.scale AS uat_scale,
       p.is_nullable AS prod_nullable, u.is_nullable AS uat_nullable
FROM prod p
FULL JOIN uat u
  ON p.table_name = u.table_name AND p.column_name = u.column_name
WHERE COALESCE(p.table_name, u.table_name) IN (SELECT table_name FROM shared_views)
  AND (p.column_name IS NULL
   OR u.column_name IS NULL
   OR p.ordinal_position != u.ordinal_position
   OR p.data_type != u.data_type
   OR NOT EQUAL_NULL(p.len,   u.len)
   OR NOT EQUAL_NULL(p.prec,  u.prec)
   OR NOT EQUAL_NULL(p.scale, u.scale)
   OR p.is_nullable != u.is_nullable)
ORDER BY view_name, COALESCE(p.ordinal_position, u.ordinal_position);


-- --- Q3: one row per view - rollup for pasting into the ticket -------------
WITH prod AS (
    SELECT c.table_name, c.column_name, c.ordinal_position, c.data_type,
           c.character_maximum_length AS len, c.numeric_precision AS prec,
           c.numeric_scale AS scale, c.is_nullable
    FROM PROD_DB.INFORMATION_SCHEMA.COLUMNS c
    JOIN PROD_DB.INFORMATION_SCHEMA.VIEWS v
      ON v.table_schema = c.table_schema AND v.table_name = c.table_name
    WHERE c.table_schema = 'EDP_DWI'
), uat AS (
    SELECT c.table_name, c.column_name, c.ordinal_position, c.data_type,
           c.character_maximum_length AS len, c.numeric_precision AS prec,
           c.numeric_scale AS scale, c.is_nullable
    FROM UAT_DB.INFORMATION_SCHEMA.COLUMNS c
    JOIN UAT_DB.INFORMATION_SCHEMA.VIEWS v
      ON v.table_schema = c.table_schema AND v.table_name = c.table_name
    WHERE c.table_schema = 'EDP_DWI'
), shared_views AS (
    SELECT p.table_name FROM PROD_DB.INFORMATION_SCHEMA.VIEWS p
    JOIN UAT_DB.INFORMATION_SCHEMA.VIEWS u
      ON p.table_name = u.table_name AND u.table_schema = 'EDP_DWI'
    WHERE p.table_schema = 'EDP_DWI'
), j AS (
    SELECT COALESCE(p.table_name, u.table_name) AS view_name,
           p.column_name AS pcol, u.column_name AS ucol,
           p.ordinal_position AS pord, u.ordinal_position AS uord,
           p.data_type AS ptype, u.data_type AS utype,
           p.len AS plen, u.len AS ulen, p.prec AS pprec, u.prec AS uprec,
           p.scale AS pscale, u.scale AS uscale,
           p.is_nullable AS pnull, u.is_nullable AS unull
    FROM prod p
    FULL JOIN uat u
      ON p.table_name = u.table_name AND p.column_name = u.column_name
    WHERE COALESCE(p.table_name, u.table_name) IN (SELECT table_name FROM shared_views)
)
SELECT view_name,
       COUNT_IF(pcol IS NOT NULL) AS prod_cols,
       COUNT_IF(ucol IS NOT NULL) AS uat_cols,
       COUNT_IF(pcol IS NULL)     AS only_in_uat,
       COUNT_IF(ucol IS NULL)     AS only_in_prod,
       COUNT_IF(pcol IS NOT NULL AND ucol IS NOT NULL AND ptype != utype) AS type_changed,
       COUNT_IF(pcol IS NOT NULL AND ucol IS NOT NULL AND ptype = utype
                AND (NOT EQUAL_NULL(plen, ulen) OR NOT EQUAL_NULL(pprec, uprec)
                     OR NOT EQUAL_NULL(pscale, uscale)))                  AS precision_changed,
       COUNT_IF(pcol IS NOT NULL AND ucol IS NOT NULL AND pnull != unull)  AS nullability_changed,
       COUNT_IF(pcol IS NOT NULL AND ucol IS NOT NULL AND pord != uord)    AS position_changed,
       IFF(COUNT_IF(pcol IS NULL OR ucol IS NULL OR ptype != utype
                    OR NOT EQUAL_NULL(plen, ulen) OR NOT EQUAL_NULL(pprec, uprec)
                    OR NOT EQUAL_NULL(pscale, uscale)
                    OR pnull != unull OR pord != uord) = 0,
           'PASS', 'DRIFT') AS d0_verdict
FROM j
GROUP BY view_name
ORDER BY d0_verdict, view_name;
