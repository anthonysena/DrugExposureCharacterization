SELECT DISTINCT c.*
FROM @cdm_database_schema.concept c
INNER JOIN  (
	SELECT DISTINCT drug_concept_id concept_id FROM @results_database_schema.dus_de_data_presence
	UNION ALL
	SELECT DISTINCT drug_concept_id FROM @results_database_schema.dus_de_detail
	UNION ALL
	SELECT DISTINCT drug_type_concept_id FROM @results_database_schema.dus_de_detail
	UNION ALL
	SELECT DISTINCT visit_type_concept_id FROM @results_database_schema.dus_de_detail
	UNION ALL
	SELECT DISTINCT drug_source_concept_id FROM @results_database_schema.dus_de_detail
	UNION ALL
	SELECT DISTINCT drug_concept_id FROM @results_database_schema.dus_de_overview
	UNION ALL
	SELECT DISTINCT drug_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT ingredient_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT dose_form_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT dose_form_group_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT amount_unit_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT numerator_unit_concept_id FROM @results_database_schema.dus_drug_concept_xref
	UNION ALL
	SELECT DISTINCT denominator_unit_concept_id FROM @results_database_schema.dus_drug_concept_xref
) cu ON cu.concept_id = c.concept_id
;