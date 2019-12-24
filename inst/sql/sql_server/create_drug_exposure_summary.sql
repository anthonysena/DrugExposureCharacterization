@insertConceptsByIngredient

IF OBJECT_ID('@resultsSchema.dus_de_overview', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_de_overview;

CREATE TABLE @resultsSchema.dus_de_overview (
  drug_concept_id INT NOT NULL,
	tot_rec_cnt BIGINT NOT NULL, 
	tot_person_cnt BIGINT NOT NULL,
	min_start_date DATETIME NOT NULL,
	max_start_date DATETIME NOT NULL
);

-- This is a duplicate of Achilles analysis 700, 701, 702
-- but puts all of the same info into a single table.
-- TODO: refactor to prefer Achilles data since it is already calculated?
INSERT INTO @resultsSchema.dus_de_overview (
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
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
GROUP BY de.drug_concept_id
;

IF OBJECT_ID('@resultsSchema.dus_de_detail', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_de_detail;

CREATE TABLE @resultsSchema.dus_de_detail (
  drug_concept_id INT NOT NULL,
  drug_type_concept_id INT NOT NULL,
  visit_type_concept_id INT NOT NULL,
  drug_source_concept_id INT NOT NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date DATETIME NOT NULL,
  max_start_date DATETIME NOT NULL
);

INSERT INTO @resultsSchema.dus_de_detail (
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
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
LEFT JOIN @cdmDatabaseSchema.visit_occurrence vo 
  ON vo.visit_occurrence_id = de.visit_occurrence_id
GROUP BY
  de.drug_concept_id,
  ISNULL(de.drug_type_concept_id, 0),
  ISNULL(vo.visit_type_concept_id, 0),
  de.drug_source_concept_id
;

IF OBJECT_ID('@resultsSchema.dus_drug_concept_xref', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_drug_concept_xref;

CREATE TABLE @resultsSchema.dus_drug_concept_xref (
  drug_concept_id INT NOT NULL,
  ingredient_concept_id INT NOT NULL,
  dose_form_concept_id INT NOT NULL,
  amount_value FLOAT NOT NULL,
  amount_unit_concept_id INT NOT NULL,
  numerator_value FLOAT NOT NULL,
  numerator_unit_concept_id INT NOT NULL,
  denominator_value FLOAT NOT NULL,
  denominator_unit_concept_id INT NOT NULL,
  box_size INT NULL,
  valid_start_date DATETIME NOT NULL,
  valid_end_date DATETIME NOT NULL,
  invalid_reason VARCHAR(1) NULL
);

INSERT INTO @resultsSchema.dus_drug_concept_xref (
  drug_concept_id,
  ingredient_concept_id,
  dose_form_concept_id,
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
	ds.drug_concept_id,
	ds.ingredient_concept_id,
	ISNULL(cr.concept_id_2, 0) dose_form_concept_id,
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
INNER JOIN @resultsSchema.dus_de_overview o ON o.drug_concept_id = ci.concept_id
LEFT JOIN @cdmDatabaseSchema.drug_strength ds 
  ON ci.concept_id = ds.drug_concept_id 
  AND ci.ingredient_concept_id = ds.ingredient_concept_id
LEFT JOIN @cdmDatabaseSchema.concept_relationship cr
    ON cr.concept_id_1 = o.drug_concept_id
	AND cr.relationship_id = 'RxNorm has dose form'
;

IF OBJECT_ID('@resultsSchema.dus_de_data_presence', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_de_data_presence;

CREATE TABLE @resultsSchema.dus_de_data_presence (
  drug_concept_id BIGINT NOT NULL,
  days_supply INT NULL,
  quantity FLOAT NULL,
  sig VARCHAR(MAX) NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date DATETIME NOT NULL,
  max_start_date DATETIME NOT NULL
);

INSERT INTO  @resultsSchema.dus_de_data_presence (
  drug_concept_id,
  days_supply,
  quantity,
  sig,
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
  COUNT(*) tot_rec_cnt,
  COUNT(DISTINCT de.person_id) tot_person_cnt,
  MIN(de.drug_exposure_start_date) min_start_date,
  MAX(de.drug_exposure_start_date) max_start_date
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN (SELECT DISTINCT concept_id FROM #CONCEPTS_INGRED) c ON de.drug_concept_id = c.concept_id
GROUP BY
  de.drug_concept_id,
  de.days_supply,
  de.quantity,
  de.sig
;
