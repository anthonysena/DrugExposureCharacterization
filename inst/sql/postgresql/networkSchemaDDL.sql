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
  dose_form_group_concept_id INT NOT NULL,
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
  drug_exposure_end_date_spec INT NULL,
  duration_days INT NULL,
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
