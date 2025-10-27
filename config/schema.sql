CREATE TABLE IF NOT EXISTS experiments (
    exp_id SERIAL PRIMARY KEY,
    name VARCHAR,
    creation_time BIGINT,
    run_counter INT,
    format_string VARCHAR
);

CREATE TABLE IF NOT EXISTS runs (
    run_id SERIAL PRIMARY KEY,
    exp_id INT REFERENCES experiments(exp_id),
    name VARCHAR,
    device VARCHAR,
    setup VARCHAR,
    result_table_name VARCHAR,
    result_counter INT,
    batch_counter INT,
    run_timestamp BIGINT,
    completed_timestamp BIGINT,
    is_completed BOOLEAN,
    parameters TEXT,
    guid VARCHAR,
    run_description TEXT,
    snapshot TEXT,
    captured_run_id INT,
    captured_counter INT,
    parent_datasets TEXT,
    measurement_exception TEXT,
    inspectr_tag VARCHAR,
    keyboard_interrupt BOOLEAN
);

