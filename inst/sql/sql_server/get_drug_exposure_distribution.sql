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
  d.field_name,
  d.field_val,
	d.total_records, 
	CASE WHEN (o.tot_spec <> 0) THEN (d.total_records*1.0)/o.tot_spec ELSE NULL END pct_of_spec,
	CASE WHEN (o.total_records <> 0) THEN (d.total_records*1.0)/o.total_records ELSE NULL END pct_of_total,
	d.total_person_cnt,
	o.total_records tbl_total_records, 
	o.total_person_cnt tbl_total_person_cnt,
	o.tot_spec tbl_total_specified, 
	o.pct_spec tbl_total_pct_specified
FROM @resultsSchema.dus_dist d 
INNER JOIN @cdmDatabaseSchema.concept c ON d.concept_id = c.concept_id
INNER JOIN @resultsSchema.dus_overview o ON o.concept_id = d.concept_id AND o.field_name = d.field_name
ORDER BY c.concept_id, d.field_name, d.total_records desc
;