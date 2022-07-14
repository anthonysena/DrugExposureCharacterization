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
where ca.ancestor_concept_id IN (@conceptIds)
;
