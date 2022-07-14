IF OBJECT_ID('@results_database_schema.dus_overview', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_overview;

CREATE TABLE @results_database_schema.dus_overview (
  concept_id			    BIGINT			  NOT NULL,
	total_records			  BIGINT			  NOT NULL, 
	total_person_cnt		BIGINT			  NOT NULL,
	field_name          VARCHAR(50)	  NOT NULL,
	tot_spec            BIGINT			  NOT NULL, 
	pct_spec            FLOAT         NOT NULL
);

@insertConcepts

CREATE TABLE #TOTALS (
  concept_id		BIGINT	NOT NULL,
  tot_rc			  BIGINT	NOT NULL,
  tot_pc			  BIGINT	NOT NULL
)
;

INSERT INTO #TOTALS (
	concept_id, 
	tot_rc, 
	tot_pc
)
SELECT c.concept_id, COUNT(*) tot_rc, COUNT(DISTINCT person_id) tot_pc
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
;

-- Get drug values specified
CREATE TABLE #DATA_SPEC (
  concept_id	    BIGINT			 NOT NULL ,
  field_name      VARCHAR(255) NOT NULL,
  tot_spec			  BIGINT	     NOT NULL
)
;

INSERT INTO #DATA_SPEC (
	concept_id,
	field_name,
	tot_spec
)
SELECT 
	c.concept_id, 
	'drug_exposure_start_date' field_name,
	SUM(CASE WHEN de.drug_exposure_start_date IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
--UNION ALL
--SELECT 
--	c.concept_id, 
--	'drug_exposure_start_datetime' field_name,
--	SUM(CASE WHEN de.drug_exposure_start_datetime IS NOT NULL THEN 1 ELSE 0 END) tot_spec
--FROM @cdm_database_schema.drug_exposure de
--INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
--GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_exposure_end_date' field_name,
	SUM(CASE WHEN de.drug_exposure_end_date IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
--UNION ALL
--SELECT 
--	c.concept_id, 
--	'drug_exposure_end_datetime' field_name,
--	SUM(CASE WHEN de.drug_exposure_end_datetime IS NOT NULL THEN 1 ELSE 0 END) tot_spec
--FROM @cdm_database_schema.drug_exposure de
--INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
--GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_type_concept_id' field_name,
	SUM(CASE WHEN de.drug_type_concept_id IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'quantity' field_name,
	SUM(CASE WHEN de.quantity IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'days_supply' field_name,
	SUM(CASE WHEN de.days_supply IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'sig' field_name,
	SUM(CASE WHEN de.sig IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
;

INSERT INTO @results_database_schema.dus_overview (
  concept_id,
	total_records, 
	total_person_cnt,
	field_name,
	tot_spec, 
	pct_spec
)
SELECT 
	c.concept_id, 
	ISNULL(res.total_records, 0) total_records,
	ISNULL(res.total_person_cnt, 0) total_person_cnt,
	ISNULL(res.field_name, '') field_name,
	ISNULL(res.tot_spec, 0) tot_spec,
	ISNULL(res.pct_spec, 0) pct_spec
FROM #Concepts c
LEFT JOIN (
  SELECT
    d.concept_id,
  	ISNULL(t.tot_rc, 0) total_records, 
  	ISNULL(t.tot_pc, 0) total_person_cnt,
  	d.field_name,
  	d.tot_spec,
  	(d.tot_spec*1.0 / t.tot_rc) pct_spec
  FROM #DATA_SPEC d
  INNER JOIN #totals t ON d.concept_id = t.concept_id
) res ON c.concept_id = res.concept_id
;

IF OBJECT_ID('@results_database_schema.dus_dist', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_dist;

CREATE TABLE @results_database_schema.dus_dist (
  concept_id			    BIGINT			  NOT NULL,
  field_name          VARCHAR(50)   NOT NULL,
  field_val           VARCHAR(MAX)  NOT NULL,
	total_records			  BIGINT			  NOT NULL, 
	total_person_cnt		BIGINT			  NOT NULL
);

INSERT INTO @results_database_schema.dus_dist (
  concept_id,
  field_name,
  field_val,
	total_records, 
	total_person_cnt
)
SELECT 
	c.concept_id, 
	'days_supply' field_name,
	CAST(days_supply as VARCHAR(MAX)) field_value,
	COUNT(*) total_records,
	COUNT(DISTINCT person_id) total_person_cnt
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
WHERE days_supply IS NOT NULL
GROUP BY c.concept_id, days_supply
UNION ALL
SELECT 
	c.concept_id, 
	'quantity' field_name,
	CAST(quantity AS VARCHAR(MAX)) field_value,
	COUNT(*) total_records,
	COUNT(DISTINCT person_id) total_person_cnt
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
WHERE quantity IS NOT NULL
GROUP BY c.concept_id, quantity
UNION ALL
SELECT 
	c.concept_id, 
	'sig' field_name,
	sig field_value,
	COUNT(*) total_records,
	COUNT(DISTINCT person_id) total_person_cnt
FROM @cdm_database_schema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
WHERE sig IS NOT NULL
GROUP BY c.concept_id, sig
;

IF OBJECT_ID('@results_database_schema.dus_data_presence', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_data_presence;

CREATE TABLE @results_database_schema.dus_data_presence (
  concept_id			    BIGINT			  NOT NULL,
  field_1_name        VARCHAR(50)   NOT NULL,
  field_1_pres        INT           NOT NULL,
  field_2_name        VARCHAR(50)   NULL,
  field_2_pres        INT           NULL,
  field_3_name        VARCHAR(50)   NULL,
  field_3_pres        INT           NULL,
  field_4_name        VARCHAR(50)   NULL,
  field_4_pres        INT           NULL,
  field_5_name        VARCHAR(50)   NULL,
  field_5_pres        INT           NULL,
	rec_cnt			        BIGINT			  NOT NULL, 
	rec_cnt_total			  BIGINT			  NOT NULL, 
	rec_cnt_pct         FLOAT         NOT NULL,
	person_cnt          BIGINT        NOT NULL,
	person_cnt_total    BIGINT        NOT NULL,
	person_cnt_pct      FLOAT         NOT NULL
);

-- This query counts all the combinations of days_supply, quantity and sig for each of the drug concepts
INSERT INTO @results_database_schema.dus_data_presence (
	concept_id,
	field_1_name,
	field_1_pres,
	field_2_name,
	field_2_pres,
	field_3_name,
	field_3_pres,
	rec_cnt,
	rec_cnt_total,
	rec_cnt_pct,
	person_cnt,
	person_cnt_total,
	person_cnt_pct
)
SELECT
	c.concept_id,
	c.field_1_name,
	c.field_1_pres,
	c.field_2_name,
	c.field_2_pres,
	c.field_3_name,
	c.field_3_pres,
	c.cnt rec_cnt,
	t.total_records rec_cnt_total,
	(c.cnt*1.0 / t.total_records) * 100 rec_cnt_pct,
	c.person_cnt,
	t.total_person_cnt person_cnt_total,
	(c.person_cnt*1.0 / t.total_person_cnt) * 100 person_cnt_pct
FROM (
	SELECT 
		c.concept_id,
		'days_supply' field_1_name,
		CASE WHEN de.days_supply IS NOT NULL THEN 1 ELSE 0 END field_1_pres,
		'quantity' field_2_name,
		CASE WHEN de.quantity IS NOT NULL THEN 1 ELSE 0 END field_2_pres,
		'sig' field_3_name,
		CASE WHEN de.sig IS NOT NULL THEN 1 ELSE 0 END field_3_pres,
		COUNT(*) cnt,
		COUNT(DISTINCT de.person_id) person_cnt
	FROM @cdm_database_schema.drug_exposure de
	INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
	GROUP BY 
		c.concept_id, 
		CASE WHEN de.days_supply IS NOT NULL THEN 1 ELSE 0 END,
		CASE WHEN de.quantity IS NOT NULL THEN 1 ELSE 0 END,
		CASE WHEN de.sig IS NOT NULL THEN 1 ELSE 0 END
) c
INNER JOIN (
	SELECT 
		de.drug_concept_id  concept_id,
		COUNT(*) total_records,
		COUNT(DISTINCT de.person_id) total_person_cnt
	FROM @cdm_database_schema.drug_exposure de
	INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
	GROUP BY 
		de.drug_concept_id
) t ON t.concept_id = c.concept_id
;

TRUNCATE TABLE #CONCEPTS;
DROP TABLE #CONCEPTS;

TRUNCATE TABLE #TOTALS;
DROP TABLE #TOTALS;

TRUNCATE TABLE #DATA_SPEC;
DROP TABLE #DATA_SPEC;