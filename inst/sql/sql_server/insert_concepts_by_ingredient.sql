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
from @cdmDatabaseSchema.concept_ancestor ca
inner join @cdmDatabaseSchema.concept c ON ca.descendant_concept_id = c.concept_id
where ca.ancestor_concept_id IN (@conceptIds)
;
