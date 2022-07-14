SELECT 
  concept_id, 
  concept_name,
  concept_class_id,
  standard_concept
FROM @cdm_database_schema.concept
WHERE concept_id IN (@concept_ids)
;