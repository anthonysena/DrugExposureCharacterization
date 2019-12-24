{DEFAULT @includeDescendants = 0}

CREATE TABLE #CONCEPTS (
  concept_id			    BIGINT			  NOT NULL
)
;

INSERT INTO #CONCEPTS ( 
  concept_id
)
SELECT DISTINCT 
  c.concept_id
{@includeDescendants == 1} ? {
from @cdmDatabaseSchema.concept_ancestor ca
inner join @cdmDatabaseSchema.concept c ON ca.descendant_concept_id = c.concept_id
where ca.ancestor_concept_id IN (@conceptIds)
}
{@includeDescendants != 1} ? {
from @cdmDatabaseSchema.concept c 
where concept_id IN (@conceptIds) 
}
;
