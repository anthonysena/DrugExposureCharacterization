IF OBJECT_ID('@resultsSchema.dus_overview', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_overview;

CREATE TABLE @resultsSchema.dus_overview (
  concept_id			    BIGINT			  NOT NULL,
  concept_name			  VARCHAR(255)	NOT NULL,
  domain_id				    VARCHAR(20)		NOT NULL,
  vocabulary_id			  VARCHAR(20)		NOT NULL,
  concept_class_id		VARCHAR(20)		NOT NULL,
  standard_concept		VARCHAR(1)		NULL,
	total_records			  BIGINT			  NOT NULL, 
	total_person_cnt		BIGINT			  NOT NULL,
	field_name          VARCHAR(50)	  NOT NULL,
	tot_spec            BIGINT			  NOT NULL, 
	pct_spec            FLOAT         NOT NULL
);

CREATE TABLE #Concepts (
  concept_id			    BIGINT			  NOT NULL,
  concept_name			  VARCHAR(255)	NOT NULL,
  domain_id				    VARCHAR(20)		NOT NULL,
  vocabulary_id			  VARCHAR(20)		NOT NULL,
  concept_class_id		VARCHAR(20)		NOT NULL,
  standard_concept		VARCHAR(1)		NULL,
  concept_code			  VARCHAR(50)		NOT NULL,
  valid_start_date		DATE			    NOT NULL,
  valid_end_date		  DATE			    NOT NULL,
  invalid_reason		  VARCHAR(1)		NULL
)
;

INSERT INTO #CONCEPTS ( concept_id,
  concept_name,
  domain_id,
  vocabulary_id,
  concept_class_id,
  standard_concept,
  concept_code,
  valid_start_date,
  valid_end_date,
  invalid_reason
)
select concept_id,
  concept_name,
  domain_id,
  vocabulary_id,
  concept_class_id,
  standard_concept,
  concept_code,
  valid_start_date,
  valid_end_date,
  invalid_reason 
from @cdmDatabaseSchema.concept c 
where concept_id IN (@conceptIds) 
;

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
FROM @cdmDatabaseSchema.drug_exposure de
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
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_exposure_start_datetime' field_name,
	SUM(CASE WHEN de.drug_exposure_start_datetime IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_exposure_end_date' field_name,
	SUM(CASE WHEN de.drug_exposure_end_date IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_exposure_end_datetime' field_name,
	SUM(CASE WHEN de.drug_exposure_end_datetime IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'drug_type_concept_id' field_name,
	SUM(CASE WHEN de.drug_exposure_end_datetime IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'quantity' field_name,
	SUM(CASE WHEN de.quantity IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'days_supply' field_name,
	SUM(CASE WHEN de.days_supply IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
UNION ALL
SELECT 
	c.concept_id, 
	'sig' field_name,
	SUM(CASE WHEN de.sig IS NOT NULL THEN 1 ELSE 0 END) tot_spec
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_id
;

INSERT INTO @resultsSchema.dus_overview (
  concept_id,
  concept_name,
  domain_id,
  vocabulary_id,
  concept_class_id,
  standard_concept,
	total_records, 
	total_person_cnt,
	field_name,
	tot_spec, 
	pct_spec
)
SELECT 
	c.concept_id, 
	c.concept_name, 
	c.domain_id,
	c.vocabulary_id, 
	c.concept_class_id,
	c.standard_concept,
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

DROP TABLE #Concepts;
DROP TABLE #TOTALS;
DROP TABLE #DATA_SPEC;