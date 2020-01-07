DROP VIEW IF EXISTS @networkSchema.v_drug_strength CASCADE;

CREATE VIEW @networkSchema.v_drug_strength AS
 SELECT x.source_id,
    x.ingredient_concept_id,
    c1.concept_name AS ingredient_name,
    x.drug_concept_id,
    c2.concept_name AS drug_name,
    x.dose_form_concept_id,
        CASE
            WHEN (x.dose_form_concept_id = 0) THEN 'UNSPECIFIED'::character varying
            ELSE c3.concept_name
        END AS dose_form,
    x.dose_form_group_concept_id,
    c7.concept_name dose_form_group,
    CASE
        WHEN ((x.amount_value > (0)::numeric) AND (x.amount_unit_concept_id > 0)) THEN x.amount_value
        WHEN ((x.amount_value = (0)::numeric) AND (x.amount_unit_concept_id = 0) AND (x.numerator_value > (0)::numeric) AND (x.numerator_unit_concept_id > 0) AND (x.denominator_value <> (0)::numeric) AND (x.denominator_unit_concept_id > 0)) THEN (x.numerator_value / x.denominator_value)
        WHEN ((x.amount_value = (0)::numeric) AND (x.amount_unit_concept_id = 0) AND (x.numerator_value > (0)::numeric) AND (x.numerator_unit_concept_id > 0) AND (x.denominator_value = (0)::numeric) AND (x.denominator_unit_concept_id > 0)) THEN x.numerator_value
        ELSE (0)::numeric
    END AS strength,
    CASE
        WHEN ((x.amount_value > (0)::numeric) AND (x.amount_unit_concept_id > 0)) THEN concat(x.amount_value, ' ', c4.concept_name)
        WHEN ((x.amount_value = (0)::numeric) AND (x.amount_unit_concept_id = 0) AND (x.numerator_value > (0)::numeric) AND (x.numerator_unit_concept_id > 0) AND (x.denominator_value <> (1)::numeric) AND (x.denominator_unit_concept_id > 0)) THEN concat(x.numerator_value, '/', x.denominator_value, ' ', c5.concept_name, '/', c6.concept_name)
        WHEN ((x.amount_value = (0)::numeric) AND (x.amount_unit_concept_id = 0) AND (x.numerator_value > (0)::numeric) AND (x.numerator_unit_concept_id > 0) AND (x.denominator_value = (1)::numeric) AND (x.denominator_unit_concept_id > 0)) THEN concat(x.numerator_value, ' ', c5.concept_name, '/', c6.concept_name)
        ELSE 'UNSPECIFIED'::text
    END AS strength_formatted,
    x.amount_value,
    x.amount_unit_concept_id,
    c4.concept_name AS amount_unit,
    x.numerator_value,
    x.numerator_unit_concept_id,
    c5.concept_name AS numerator_unit,
    x.denominator_value,
    x.denominator_unit_concept_id,
    c6.concept_name AS denominator_unit,
    x.box_size,
    x.valid_start_date,
    x.valid_end_date
   FROM @networkSchema.drug_concept_xref x
     JOIN @networkSchema.concept c1 ON c1.concept_id = x.ingredient_concept_id
     JOIN @networkSchema.concept c2 ON c2.concept_id = x.drug_concept_id
     JOIN @networkSchema.concept c3 ON c3.concept_id = x.dose_form_concept_id
     JOIN @networkSchema.concept c4 ON c4.concept_id = x.amount_unit_concept_id
     JOIN @networkSchema.concept c5 ON c5.concept_id = x.numerator_unit_concept_id
     JOIN @networkSchema.concept c6 ON c6.concept_id = x.denominator_unit_concept_id
     JOIN @networkSchema.concept c7 ON c7.concept_id = x.dose_form_group_concept_id
  ORDER BY c3.concept_name
;

DROP VIEW IF EXISTS @networkSchema.v_drug_exposure_data_presence CASCADE;

CREATE VIEW @networkSchema.v_drug_exposure_data_presence AS
 SELECT de.source_id,
    s.source_name,
    x.ingredient_concept_id,
    x.ingredient_name,
    de.drug_concept_id,
    x.drug_name,
    de.days_supply,
    de.quantity,
    de.sig,
    de.drug_exposure_end_date_spec,
        CASE
            WHEN ((COALESCE(de.days_supply, 0) > 0) AND (de.days_supply <> 0)) THEN ((x.strength * de.quantity) / (de.days_supply)::numeric)
            ELSE (1)::numeric
        END AS daily_dose,
    de.duration_days,
    x.dose_form_concept_id,
    x.dose_form,
    x.dose_form_group_concept_id,
    x.dose_form_group,
    x.strength,
    x.strength_formatted,
    de.tot_rec_cnt,
    de.tot_person_cnt,
    de.min_start_date,
    de.max_start_date
   FROM ((@networkSchema.de_data_presence de
     JOIN @networkSchema.v_drug_strength x ON (((de.source_id = x.source_id) AND (de.drug_concept_id = x.drug_concept_id))))
     JOIN @networkSchema.source s ON ((s.source_id = x.source_id)))
;

DROP VIEW IF EXISTS @networkSchema.v_drug_exposure_detail CASCADE;

CREATE VIEW @networkSchema.v_drug_exposure_detail AS
 SELECT de.source_id,
    s.source_name,
    x.ingredient_concept_id,
    x.ingredient_name,
    de.drug_concept_id,
    x.drug_name,
    de.drug_type_concept_id,
    c1.concept_name AS drug_type,
    de.visit_type_concept_id,
    c2.concept_name AS visit_type,
    de.drug_source_concept_id,
    c3.vocabulary_id AS drug_source_vocab,
    c3.concept_name AS drug_source_name,
    c3.concept_code AS drug_source_code,
    x.dose_form_concept_id,
    x.dose_form,
    x.dose_form_group_concept_id,
    x.dose_form_group,
    x.strength,
    x.strength_formatted,
    de.tot_rec_cnt,
    de.tot_person_cnt,
    de.min_start_date,
    de.max_start_date
   FROM (((((@networkSchema.de_detail de
     JOIN @networkSchema.v_drug_strength x ON (((de.source_id = x.source_id) AND (de.drug_concept_id = x.drug_concept_id))))
     JOIN @networkSchema.concept c1 ON ((c1.concept_id = de.drug_type_concept_id)))
     JOIN @networkSchema.concept c2 ON ((c2.concept_id = de.visit_type_concept_id)))
     JOIN @networkSchema.concept c3 ON ((c3.concept_id = de.drug_source_concept_id)))
     JOIN @networkSchema.source s ON ((s.source_id = x.source_id)))
;

DROP VIEW IF EXISTS @networkSchema.v_drug_exposure_overview CASCADE;

CREATE VIEW @networkSchema.v_drug_exposure_overview AS
 SELECT de.source_id,
    s.source_name,
    x.ingredient_concept_id,
    x.ingredient_name,
    de.drug_concept_id,
    x.drug_name,
    x.dose_form_concept_id,
    x.dose_form,
    x.dose_form_group_concept_id,
    x.dose_form_group,
    x.strength,
    x.strength_formatted,
    de.tot_rec_cnt,
    de.tot_person_cnt,
    de.min_start_date,
    de.max_start_date
   FROM ((@networkSchema.de_overview de
     JOIN @networkSchema.v_drug_strength x ON (((de.source_id = x.source_id) AND (de.drug_concept_id = x.drug_concept_id))))
     JOIN @networkSchema.source s ON ((s.source_id = x.source_id)))
;

DROP VIEW IF EXISTS @networkSchema.v_drug_exposure_data_presence_summary CASCADE;

CREATE VIEW @networkSchema.v_drug_exposure_data_presence_summary AS
SELECT 
	source_id,
	source_name,
	ingredient_concept_id,
	ingredient_name,
	drug_concept_id,
	drug_name,
	CASE WHEN COALESCE(days_supply, 0) = 0 THEN 0 ELSE 1 END days_supply_spec,
	CASE WHEN COALESCE(quantity, 0) = 0 THEN 0 ELSE 1 END quantity_spec,
	CASE WHEN COALESCE(sig, '') = '' THEN 0 ELSE 1 END sig_spec,
	CASE WHEN drug_exposure_end_date_spec <= 0 THEN 0 ELSE 1 END drug_exposure_end_date_spec,
	CASE WHEN strength <= 0 THEN 0 ELSE 1 END strength_spec,
	CASE WHEN COALESCE(duration_days, 0) = 0 THEN 0 ELSE 1 END duration_days_spec,
	SUM(tot_rec_cnt) tot_rec_cnt,
	SUM(tot_person_cnt) tot_person_cnt
FROM @networkSchema.v_drug_exposure_data_presence 
GROUP BY
	source_id,
	source_name,
	ingredient_concept_id,
	ingredient_name,
	drug_concept_id,
	drug_name,
	CASE WHEN COALESCE(days_supply, 0) = 0 THEN 0 ELSE 1 END,
	CASE WHEN COALESCE(quantity, 0) = 0 THEN 0 ELSE 1 END,
	CASE WHEN COALESCE(sig, '') = '' THEN 0 ELSE 1 END,
	CASE WHEN drug_exposure_end_date_spec <= 0 THEN 0 ELSE 1 END,
	CASE WHEN strength <= 0 THEN 0 ELSE 1 END,
	CASE WHEN COALESCE(duration_days, 0) = 0 THEN 0 ELSE 1 END
order by ingredient_name, source_name, SUM(tot_rec_cnt) desc
;
