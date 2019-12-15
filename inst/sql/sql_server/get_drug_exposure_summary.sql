SELECT 
  c.concept_id,
  c.concept_name,
  c.domain_id,
  c.vocabulary_id,
  c.concept_class_id,
  c.standard_concept,
  c.concept_code,
  c.valid_start_date,
  c.valid_end_date,
  c.invalid_reason,
	o.total_records, 
	o.total_person_cnt,
	o.field_name,
	o.tot_spec, 
	o.pct_spec  
FROM @resultsSchema.dus_overview o 
INNER JOIN @cdmDatabaseSchema.concept c ON o.concept_id = c.concept_id
ORDER BY o.total_records desc, concept_id
;