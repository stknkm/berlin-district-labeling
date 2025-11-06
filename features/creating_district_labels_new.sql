CREATE TABLE IF NOT EXISTS berlin_labels.district_labels_new (
    district_id VARCHAR(10),
    category VARCHAR(50),
    label VARCHAR(50),
    PRIMARY KEY (district_id, label),
    CONSTRAINT fk_district FOREIGN KEY (district_id) REFERENCES berlin_source_data.districts (district_id)
);