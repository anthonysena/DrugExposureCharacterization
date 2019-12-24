DROP TABLE IF EXISTS @networkSchema.de_overview CASCADE;

CREATE TABLE @networkSchema.de_overview (
	source_id INT NOT NULL,
    drug_concept_id INT NOT NULL,
	tot_rec_cnt BIGINT NOT NULL, 
	tot_person_cnt BIGINT NOT NULL,
	min_start_date TIMESTAMP NOT NULL,
	max_start_date TIMESTAMP NOT NULL
);

DROP TABLE IF EXISTS @networkSchema.de_detail CASCADE;

CREATE TABLE @networkSchema.de_detail (
  source_id INT NOT NULL,
  drug_concept_id INT NOT NULL,
  drug_type_concept_id INT NOT NULL,
  visit_type_concept_id INT NOT NULL,
  drug_source_concept_id INT NOT NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date TIMESTAMP NOT NULL,
  max_start_date TIMESTAMP NOT NULL
);

DROP TABLE IF EXISTS @networkSchema.drug_concept_xref CASCADE;

CREATE TABLE @networkSchema.drug_concept_xref (
  source_id INT NOT NULL,
  drug_concept_id INT NOT NULL,
  ingredient_concept_id INT NOT NULL,
  dose_form_concept_id INT NOT NULL,
  amount_value NUMERIC NOT NULL,
  amount_unit_concept_id INT NOT NULL,
  numerator_value NUMERIC NOT NULL,
  numerator_unit_concept_id INT NOT NULL,
  denominator_value NUMERIC NOT NULL,
  denominator_unit_concept_id INT NOT NULL,
  box_size INT NULL,
  valid_start_date TIMESTAMP NOT NULL,
  valid_end_date TIMESTAMP NOT NULL,
  invalid_reason VARCHAR(1) NULL
);

DROP TABLE IF EXISTS @networkSchema.de_data_presence CASCADE;

CREATE TABLE @networkSchema.de_data_presence (
  source_id INT NOT NULL,
  drug_concept_id BIGINT NOT NULL,
  days_supply INT NULL,
  quantity NUMERIC NULL,
  sig TEXT NULL,
  tot_rec_cnt BIGINT NOT NULL, 
  tot_person_cnt BIGINT NOT NULL,
  min_start_date TIMESTAMP NOT NULL,
  max_start_date TIMESTAMP NOT NULL
);

DROP TABLE IF EXISTS @networkSchema.concept CASCADE;

CREATE TABLE @networkSchema.concept
(
    concept_id integer NOT NULL,
    concept_name character varying(255)NOT NULL,
    domain_id character varying(20) NOT NULL,
    vocabulary_id character varying(20) NOT NULL,
    concept_class_id character varying(20) NOT NULL,
    standard_concept character varying(1),
    concept_code character varying(50),
    valid_start_date date NOT NULL,
    valid_end_date date NOT NULL,
    invalid_reason character varying(1),
    CONSTRAINT xpk_concept PRIMARY KEY (concept_id)
)
;

DROP TABLE IF EXISTS @networkSchema.source CASCADE;

CREATE TABLE @networkSchema.source
(
    source_id integer NOT NULL,
    source_name character varying(255) NOT NULL,
    vocabulary_version character varying(255) NOT NULL,
    CONSTRAINT pk_source_id PRIMARY KEY (source_id),
    CONSTRAINT uq_source_name UNIQUE (source_name)
)
;

ALTER TABLE ONLY @networkSchema.de_overview
    ADD CONSTRAINT pk_de_overview PRIMARY KEY (source_id, drug_concept_id)
;

-- View: public.v_drug_dosage

DROP VIEW IF EXISTS public.v_drug_dosage;

CREATE OR REPLACE VIEW public.v_drug_dosage AS 
select 
  x.source_id,
	x.ingredient_concept_id,
	c1.concept_name ingredient_name,
	x.drug_concept_id,
	c2.concept_name drug_name,
	x.dose_form_concept_id,
  CASE
      WHEN x.dose_form_concept_id = 0 THEN 'UNSPECIFIED'
      ELSE c3.concept_name
  END AS dose_form,
  CASE
      WHEN x.amount_value > 0 AND x.amount_unit_concept_id > 0 THEN x.amount_value
      WHEN x.amount_value = 0 AND x.amount_unit_concept_id = 0 AND x.numerator_value > 0 AND x.numerator_unit_concept_id > 0 AND x.denominator_value <> 0 AND x.denominator_unit_concept_id > 0 THEN x.numerator_value/x.denominator_value
      WHEN x.amount_value = 0 AND x.amount_unit_concept_id = 0 AND x.numerator_value > 0 AND x.numerator_unit_concept_id > 0 AND x.denominator_value = 0 AND x.denominator_unit_concept_id > 0 THEN x.numerator_value
      ELSE 0
  END AS dosage,
  CASE
      WHEN x.amount_value > 0 AND x.amount_unit_concept_id > 0 THEN concat(x.amount_value, ' ', c4.concept_name)
      WHEN x.amount_value = 0 AND x.amount_unit_concept_id = 0 AND x.numerator_value > 0 AND x.numerator_unit_concept_id > 0 AND x.denominator_value <> 1 AND x.denominator_unit_concept_id > 0 THEN concat(x.numerator_value, '/', x.denominator_value, ' ', c5.concept_name, '/', c6.concept_name)
      WHEN x.amount_value = 0 AND x.amount_unit_concept_id = 0 AND x.numerator_value > 0 AND x.numerator_unit_concept_id > 0 AND x.denominator_value = 1 AND x.denominator_unit_concept_id > 0 THEN concat(x.numerator_value, ' ', c5.concept_name, '/', c6.concept_name)
      ELSE 'UNSPECIFIED'
  END AS dosage_formatted,
	x.amount_value,
	x.amount_unit_concept_id,
	c4.concept_name amount_unit,
	x.numerator_value,
	x.numerator_unit_concept_id,
	c5.concept_name numerator_unit,
	x.denominator_value,
	x.denominator_unit_concept_id,
	c6.concept_name denominator_unit,
	x.box_size,
	x.valid_start_date,
	x.valid_end_date 
from public.drug_concept_xref x 
inner join public.concept c1 ON c1.concept_id = x.ingredient_concept_id
inner join public.concept c2 ON c2.concept_id = x.drug_concept_id
inner join public.concept c3 on c3.concept_id = x.dose_form_concept_id
inner join public.concept c4 ON c4.concept_id = x.amount_unit_concept_id
inner join public.concept c5 ON c5.concept_id = x.numerator_unit_concept_id
inner join public.concept c6 ON c6.concept_id = x.denominator_unit_concept_id
order by c3.concept_name
;
;