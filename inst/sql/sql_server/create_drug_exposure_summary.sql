CREATE TABLE #CONCEPTS_INGRED (
  ingredient_concept_id  BIGINT     NOT NULL,
  concept_id			       BIGINT			NOT NULL
)
;

INSERT INTO #CONCEPTS_INGRED ( 
  ingredient_concept_id,
  concept_id
)
SELECT DISTINCT 
  ca.ancestor_concept_id ingredient_concept_id,
  c.concept_id
from @cdm_database_schema.concept_ancestor ca
inner join @cdm_database_schema.concept c ON ca.descendant_concept_id = c.concept_id
where ca.ancestor_concept_id IN (@drug_ingredient_concept_ids)
;


-- Concepts in this table will be given priority
-- when joining to the concept_ancestor table
-- to find concepts where concept_class_id = 'Dose Form Group'
CREATE TABLE #DOSE_FORM_GROUP (
  dose_form_group_concept_id  BIGINT     NOT NULL
)
;

-- AGS: Remove priority for dose form group
/*
INSERT INTO #DOSE_FORM_GROUP ( 
  dose_form_group_concept_id
)
SELECT 36217214	-- Oral Product
UNION ALL
SELECT 36217206	-- Topical Product
UNION ALL
SELECT 36217207	-- Inhalant Product
UNION ALL
SELECT 36217215	-- Dental Product
UNION ALL
SELECT 36217209	--Vaginal Product
;
*/

IF OBJECT_ID('@results_database_schema.dus_de_overview', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_de_overview;

CREATE TABLE @results_database_schema.dus_de_overview (
  drug_concept_id INT NOT NULL,
	tot_rec_cnt BIGINT NOT NULL, 
	tot_person_cnt BIGINT NOT NULL,
	min_start_date DATETIME NOT NULL,
	max_start_date DATETIME NOT NULL
);

-- This is a duplicate of Achilles analysis 700, 701, 702
-- but puts all of the same info into a single table.
-- TODO: refactor to prefer Achilles data since it is already calculated?
INSERT INTO @results_database_schema.dus_de_overview (
  drug_concept_id,
	tot_rec_cnt,
	tot_person_cnt,
	min_start_date,
	max_start_date
)
SELECT
  de.drug_concept_id,
  COUNT(*) tot_rec_cnt,
  COUNT(DISTINCT de.person_id) tot_person_cnt,
  MIN(de.drug_exposure_start_date) min_start_date,
  MAX(de.drug_exposure_start_date) max_start_date
FROM @cdm_database_schema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
GROUP BY de.drug_concept_id
;

IF OBJECT_ID('@results_database_schema.dus_de_detail', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_de_detail;

CREATE TABLE @results_database_schema.dus_de_detail (
  drug_concept_id INT NOT NULL,
  drug_type_concept_id INT NOT NULL,
  visit_type_concept_id INT NOT NULL,
  drug_source_concept_id INT NOT NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date DATETIME NOT NULL,
  max_start_date DATETIME NOT NULL
);

INSERT INTO @results_database_schema.dus_de_detail (
  drug_concept_id,
  drug_type_concept_id,
  visit_type_concept_id,
  drug_source_concept_id,
  tot_rec_cnt, 
  tot_person_cnt,
  min_start_date,
  max_start_date
)
SELECT
  de.drug_concept_id,
  ISNULL(de.drug_type_concept_id, 0) drug_type_concept_id,
  ISNULL(vo.visit_type_concept_id, 0) visit_type_concept_id,
  de.drug_source_concept_id,
  COUNT(*) tot_rec_cnt,
  COUNT(DISTINCT de.person_id) tot_person_cnt,
  MIN(de.drug_exposure_start_date) min_start_date,
  MAX(de.drug_exposure_start_date) max_start_date
FROM @cdm_database_schema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
LEFT JOIN @cdm_database_schema.visit_occurrence vo 
  ON vo.visit_occurrence_id = de.visit_occurrence_id
GROUP BY
  de.drug_concept_id,
  ISNULL(de.drug_type_concept_id, 0),
  ISNULL(vo.visit_type_concept_id, 0),
  de.drug_source_concept_id
;

-- Get the dose form and dose form group
WITH all_dose_form as (
  SELECT 
  	ci.concept_id drug_concept_id,
  	ISNULL(cr.concept_id_2, 0) dose_form_concept_id,
  	ISNULL(c.concept_id, 0) dose_form_group_concept_id
  	--CASE
  	--	WHEN dfg.dose_form_group_concept_id IS NOT NULL THEN 2
  	--	WHEN c.concept_id IS NOT NULL THEN 1
  	--	ELSE 0
  	--END dfg_priority
  FROM #CONCEPTS_INGRED ci 
  LEFT JOIN @cdm_database_schema.concept_relationship cr
      ON cr.concept_id_1 = ci.concept_id
  	AND cr.relationship_id = 'RxNorm has dose form'
  LEFT JOIN @cdm_database_schema.concept_relationship cr2
      ON cr.concept_id_2 = cr2.concept_id_1
  	AND cr2.relationship_id = 'RxNorm is a'
  LEFT JOIN @cdm_database_schema.concept c 
  	ON c.concept_id = cr2.concept_id_2
      AND c.concept_class_id = 'Dose Form Group'
  --LEFT JOIN #DOSE_FORM_GROUP dfg 
  --  ON c.concept_id = dfg.dose_form_group_concept_id
)
-- AGS: Remove prioritization since this may mask other general issues
--, dfPrioritized AS (
--  SELECT
--    drug_concept_id,
--    dose_form_concept_id,
--    dose_form_group_concept_id,
--    row_number() over (PARTITION BY drug_concept_id ORDER BY dfg_priority DESC) ordinal
--  FROM all_dose_form
--)
SELECT 
    drug_concept_id,
    dose_form_concept_id,
    dose_form_group_concept_id
INTO #DFG_PRIORITIZED
--FROM dfPrioritized
FROM all_dose_form
--WHERE ordinal = 1
;

IF OBJECT_ID('@results_database_schema.dus_drug_concept_xref', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_drug_concept_xref;

CREATE TABLE @results_database_schema.dus_drug_concept_xref (
  drug_concept_id INT NOT NULL,
  ingredient_concept_id INT NOT NULL,
  dose_form_concept_id INT NOT NULL,
  dose_form_group_concept_id INT NOT NULL,
  amount_value FLOAT NOT NULL,
  amount_unit_concept_id INT NOT NULL,
  numerator_value FLOAT NOT NULL,
  numerator_unit_concept_id INT NOT NULL,
  denominator_value FLOAT NOT NULL,
  denominator_unit_concept_id INT NOT NULL,
  box_size INT NULL,
  valid_start_date DATETIME NULL,
  valid_end_date DATETIME NULL,
  invalid_reason VARCHAR(1) NULL
);

INSERT INTO @results_database_schema.dus_drug_concept_xref (
  drug_concept_id,
  ingredient_concept_id,
  dose_form_concept_id,
  dose_form_group_concept_id,
  amount_value,
  amount_unit_concept_id,
  numerator_value,
  numerator_unit_concept_id,
  denominator_value,
  denominator_unit_concept_id,
  box_size,
  valid_start_date,
  valid_end_date,
  invalid_reason
)
SELECT 
	o.drug_concept_id,
	ci.ingredient_concept_id,
	dfg.dose_form_concept_id,
	dfg.dose_form_group_concept_id,
	ISNULL(ds.amount_value, 0) amount_value,
	ISNULL(ds.amount_unit_concept_id, 0) amount_unit_concept_id,
	ISNULL(ds.numerator_value, 0) numerator_value,
	ISNULL(ds.numerator_unit_concept_id, 0) numerator_unit_concept_id,
	ISNULL(ds.denominator_value, 1) denominator_value,
	ISNULL(ds.denominator_unit_concept_id, 0) denominator_unit_concept_id,
	ISNULL(ds.box_size, 0) box_size,
	ds.valid_start_date,
	ds.valid_end_date,
	ds.invalid_reason
FROM #CONCEPTS_INGRED ci 
INNER JOIN @results_database_schema.dus_de_overview o ON o.drug_concept_id = ci.concept_id
LEFT JOIN @cdm_database_schema.drug_strength ds 
  ON ci.concept_id = ds.drug_concept_id 
  AND ci.ingredient_concept_id = ds.ingredient_concept_id
LEFT JOIN #DFG_PRIORITIZED dfg
    ON dfg.drug_concept_id = o.drug_concept_id
;

IF OBJECT_ID('@results_database_schema.dus_de_data_presence', 'U') IS NOT NULL DROP TABLE @results_database_schema.dus_de_data_presence;

CREATE TABLE @results_database_schema.dus_de_data_presence (
  drug_concept_id BIGINT NOT NULL,
  days_supply INT NULL,
  quantity FLOAT NULL,
  sig VARCHAR(MAX) NULL,
  drug_exposure_end_date_spec INT NULL,
  duration_days INT NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date DATETIME NOT NULL,
  max_start_date DATETIME NOT NULL
);

INSERT INTO  @results_database_schema.dus_de_data_presence (
  drug_concept_id,
  days_supply,
  quantity,
  sig,
  drug_exposure_end_date_spec,
  duration_days,
  tot_rec_cnt,
  tot_person_cnt,
  min_start_date,
  max_start_date
)
SELECT
  de.drug_concept_id,
  de.days_supply,
  de.quantity,
  de.sig,
  CASE WHEN de.drug_exposure_end_date IS NULL THEN 0 ELSE 1 END drug_exposure_end_date_spec,
  CASE 
    WHEN de.drug_exposure_end_date IS NULL THEN NULL 
    ELSE DATEDIFF(dd, DATEADD(dd, 1, de.drug_exposure_start_date), de.drug_exposure_end_date)
  END duration_days,
  COUNT(*) tot_rec_cnt,
  COUNT(DISTINCT de.person_id) tot_person_cnt,
  MIN(de.drug_exposure_start_date) min_start_date,
  MAX(de.drug_exposure_start_date) max_start_date
FROM @cdm_database_schema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
GROUP BY
  de.drug_concept_id,
  de.days_supply,
  de.quantity,
  de.sig,
  CASE WHEN de.drug_exposure_end_date IS NULL THEN 0 ELSE 1 END,
  CASE 
    WHEN de.drug_exposure_end_date IS NULL THEN NULL 
    ELSE DATEDIFF(dd, DATEADD(dd, 1, de.drug_exposure_start_date), de.drug_exposure_end_date)
  END
;

TRUNCATE TABLE #CONCEPTS_INGRED;
DROP TABLE #CONCEPTS_INGRED;

TRUNCATE TABLE #DOSE_FORM_GROUP;
DROP TABLE #DOSE_FORM_GROUP;

--TRUNCATE TABLE #DFG_PRIORITIZED;
--DROP TABLE #DFG_PRIORITIZED;
