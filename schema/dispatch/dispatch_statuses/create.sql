CREATE TABLE dispatch_statuses (
    dispatch_status_id  SERIAL,
    name                 VARCHAR(30)     NOT NULL UNIQUE,                 -- ver DICTIONARY.md para la lista completa
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_status_id)
);
