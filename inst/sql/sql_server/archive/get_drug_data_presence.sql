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
  o.field_1_name,
  o.field_1_pres,
  o.field_2_name,
  o.field_2_pres,
  o.field_3_name,
  o.field_3_pres,
  o.field_4_name,
  o.field_4_pres,
  o.field_5_name,
  o.field_5_pres,
	o.rec_cnt,
	o.rec_cnt_total,
	o.rec_cnt_pct,
	o.person_cnt,
	o.person_cnt_total,
	o.person_cnt_pct
FROM @resultsSchema.dus_data_presence o 
INNER JOIN @cdmDatabaseSchema.concept c ON o.concept_id = c.concept_id
ORDER BY c.concept_id
;
