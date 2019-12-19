IF OBJECT_ID('@resultsSchema.dus_de_sourcecode_map', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_de_sourcecode_map;

CREATE TABLE @resultsSchema.dus_de_sourcecode_map (
  concept_id			     BIGINT			  NOT NULL,
  drug_type_concept_id BIGINT       NULL,
  source_concept_id    BIGINT       NOT NULL,
  dose_form_concept_id BIGINT       NULL,
	total_records			   BIGINT			  NOT NULL, 
	total_person_cnt		 BIGINT			  NOT NULL,
	min_de_start_date    DATETIME     NULL, 
	max_de_start_date    DATETIME     NULL
);

@insertConcepts

@insertConceptsByIngredient

-- Roll up all drug_exposures with dose form
INSERT INTO @resultsSchema.dus_de_sourcecode_map (
  concept_id,
  drug_type_concept_id,
  source_concept_id,
  dose_form_concept_id,
	total_records,
	total_person_cnt,
	min_de_start_date,
	max_de_start_date
)
SELECT 
	de.drug_concept_id concept_id,
	ISNULL(de.drug_type_concept_id, 0) drug_type_concept_id,
	de.drug_source_concept_id source_concept_id,
	c2.concept_id dose_form_concept_id,
	COUNT(*) total_records,
	COUNT(DISTINCT de.person_id) total_person_cnt,
	MIN(de.drug_exposure_start_date) min_de_start_date,
	MAX(de.drug_exposure_start_date) max_de_start_date
FROM @cdmDatabaseSchema.drug_exposure de
INNER JOIN #CONCEPTS c ON de.drug_concept_id = c.concept_id
LEFT JOIN @cdmDatabaseSchema.concept_relationship cr
    ON cr.concept_id_1 = de.drug_concept_id
	AND cr.relationship_id = 'RxNorm has dose form'
LEFT JOIN @cdmDatabaseSchema.concept c2 ON 
	cr.concept_id_2 = c2.concept_id
GROUP BY 
	de.drug_concept_id,
	ISNULL(de.drug_type_concept_id, 0),
	de.drug_source_concept_id,
	c2.concept_id
;

IF OBJECT_ID('@resultsSchema.dus_ingredient_combos', 'U') IS NOT NULL DROP TABLE @resultsSchema.dus_ingredient_combos;

CREATE TABLE @resultsSchema.dus_ingredient_combos (
  ingredient_concept_id			     BIGINT			  NOT NULL,
  combo_ingredient_concept_id    BIGINT       NOT NULL
);

-- Find other ingredients used in combination with those ingredients specified
INSERT INTO @resultsSchema.dus_ingredient_combos (
  ingredient_concept_id,
  combo_ingredient_concept_id
)
SELECT DISTINCT
	c.ingredient_concept_id,
	c2.concept_id combo_ingredient_concept_id
from #CONCEPTS_INGRED c
INNER JOIN @cdmDatabaseSchema.drug_strength ds 
	ON c.concept_id = ds.drug_concept_id 
	AND ds.ingredient_concept_id <> c.ingredient_concept_id
INNER JOIN @cdmDatabaseSchema.concept c2
	ON c2.concept_id = ds.ingredient_concept_id
;
