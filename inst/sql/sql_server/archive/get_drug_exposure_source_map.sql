SELECT 
  v.concept_id,
  c1.concept_name drug_exp_concept_name, 
  c1.vocabulary_id drug_exp_vocab_id,
  c1.concept_class_id drug_exp_concept_class,
  c1.standard_concept drug_exp_std,
  ISNULL(v.drug_type_concept_id, 0) drug_type_concept_id,
  c2.concept_name drug_type_concept_name,
  v.source_concept_id,
  c3.concept_name drug_src_concept_name, 
  c3.vocabulary_id drug_src_vocab_id,
  v.dose_form_concept_id,
  c4.concept_name dose_form_concept_name,
  v.total_records,
  v.total_person_cnt,
  v.min_de_start_date,
  v.max_de_start_date
FROM @results_database_schema.dus_de_sourcecode_map v
INNER JOIN @cdm_database_schema.concept c1 ON c1.concept_id = v.concept_id
INNER JOIN @cdm_database_schema.concept c2 ON c2.concept_id = ISNULL(v.drug_type_concept_id, 0)
INNER JOIN @cdm_database_schema.concept c3 ON c3.concept_id = v.source_concept_id
INNER JOIN @cdm_database_schema.concept c4 ON c4.concept_id = ISNULL(v.dose_form_concept_id, 0)
ORDER BY 
  v.total_records desc,
  v.total_person_cnt
;
