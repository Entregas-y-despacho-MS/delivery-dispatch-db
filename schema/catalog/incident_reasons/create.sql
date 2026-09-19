CREATE TABLE incident_reasons (
    incident_reason_id   SERIAL,
    name                 VARCHAR(150)    NOT NULL,                        -- motivo de incidencia de entrega
    deleted_at           TIMESTAMPTZ,                                     -- soft delete
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (incident_reason_id)
);

CREATE UNIQUE INDEX uq_incident_reasons_name ON incident_reasons(name) WHERE deleted_at IS NULL;
