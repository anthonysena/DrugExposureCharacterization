select distinct
	s.drug_source_concept_id,
	s.drug_source_value,
	c.concept_name drug_source_concept_name,
	s.total_records,
	s.total_person_cnt,
	s.min_de_start_date,
	s.max_de_start_date,
	c2.concept_id standard_concept_id,
	c2.concept_name standard_concept_name,
	c2.vocabulary_id,
	c2.concept_class_id,
	c2.standard_concept,
	c2.concept_code,
	c2.valid_start_date,
	c2.valid_end_date,
	c2.invalid_reason,
	CASE WHEN ISNULL(ds.drug_concept_id, 0) = 0 THEN 0 ELSE 1 END has_drug_strengh_rec
from @results_database_schema.dus_orphan_source_codes s
INNER JOIN @cdm_database_schema.concept c ON c.concept_id = s.drug_source_concept_id
LEFT JOIN @cdm_database_schema.concept_relationship cr ON s.drug_source_concept_id = cr.concept_id_1 and cr.relationship_id = 'Maps to'
LEFT JOIN @cdm_database_schema.concept c2 ON c2.concept_id = cr.concept_id_2 
LEFT JOIN @cdm_database_schema.drug_strength ds ON ds.drug_concept_id = c2.concept_id
ORDER BY c.concept_name
;