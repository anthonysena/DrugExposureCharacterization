-- Find other ingredients used in combination with fentanyl using the drug strength table
SELECT 
	c.ingredient_concept_id,
	c1.concept_name source_ingred_concept_name,
	c.combo_ingredient_concept_id,  
	c2.concept_name combo_ingred_concept_name
FROM @resultsSchema.dus_ingredient_combos c
INNER JOIN @cdmDatabaseSchema.concept c1
	ON c1.concept_id = c.ingredient_concept_id
INNER JOIN @cdmDatabaseSchema.concept c2
	ON c2.concept_id = c.combo_ingredient_concept_id
ORDER BY c1.concept_name, c2.concept_name
;