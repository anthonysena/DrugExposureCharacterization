SELECT 
  concept_id, 
  concept_name,
  concept_class_id,
  standard_concept
FROM @cdmDatabaseSchema.concept
WHERE concept_id IN (@conceptIds)
;