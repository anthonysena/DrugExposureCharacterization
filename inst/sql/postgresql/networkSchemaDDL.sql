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
   FROM ((((((@networkSchema.drug_concept_xref x
     JOIN @networkSchema.concept c1 ON ((c1.concept_id = x.ingredient_concept_id)))
     JOIN @networkSchema.concept c2 ON ((c2.concept_id = x.drug_concept_id)))
     JOIN @networkSchema.concept c3 ON ((c3.concept_id = x.dose_form_concept_id)))
     JOIN @networkSchema.concept c4 ON ((c4.concept_id = x.amount_unit_concept_id)))
     JOIN @networkSchema.concept c5 ON ((c5.concept_id = x.numerator_unit_concept_id)))
     JOIN @networkSchema.concept c6 ON ((c6.concept_id = x.denominator_unit_concept_id)))
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
        CASE
            WHEN ((COALESCE(de.days_supply, 0) > 0) AND (de.days_supply <> 0)) THEN ((x.strength * de.quantity) / (de.days_supply)::numeric)
            ELSE (1)::numeric
        END AS daily_dose,
    x.dose_form_concept_id,
    x.dose_form,
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
