CREATE INDEX idx_concept_concept_id ON @networkSchema.concept (concept_id);

CREATE INDEX idx_de_data_presence_source_id ON @networkSchema.de_data_presence (source_id);
CREATE INDEX idx_de_data_presence_drug_concept_id ON @networkSchema.de_data_presence (drug_concept_id);
CREATE INDEX idx_de_data_presence_days_supply ON @networkSchema.de_data_presence (days_supply);
CREATE INDEX idx_de_data_presence_quantity ON @networkSchema.de_data_presence (quantity);
CREATE INDEX idx_de_data_presence_sig ON @networkSchema.de_data_presence (sig);
CREATE INDEX idx_de_data_presence_end_date ON @networkSchema.de_data_presence (drug_exposure_end_date_spec);
CREATE INDEX idx_de_data_presence_duration_days ON @networkSchema.de_data_presence (duration_days);

CREATE INDEX idx_de_detail_source_id ON @networkSchema.de_detail (source_id);
CREATE INDEX idx_de_detail_drug_concept_id ON @networkSchema.de_detail (drug_concept_id);

CREATE INDEX idx_de_overview_source_id ON @networkSchema.de_overview (source_id);
CREATE INDEX idx_de_overview_drug_concept_id ON @networkSchema.de_overview (drug_concept_id);

CREATE INDEX idx_drug_concept_xref_source_id ON @networkSchema.drug_concept_xref (source_id);
CREATE INDEX idx_drug_concept_xref_drug_concept_id ON @networkSchema.drug_concept_xref (drug_concept_id);
CREATE INDEX idx_drug_concept_xref_ingredient_concept_id ON @networkSchema.drug_concept_xref (ingredient_concept_id);
CREATE INDEX idx_drug_concept_xref_dose_form_concept_id ON @networkSchema.drug_concept_xref (dose_form_concept_id);
CREATE INDEX idx_drug_concept_xref_dose_form_group_concept_id ON @networkSchema.drug_concept_xref (dose_form_group_concept_id);

CREATE INDEX idx_source_source_id ON @networkSchema.source (source_id);
