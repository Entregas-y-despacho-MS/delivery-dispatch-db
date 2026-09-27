CREATE TABLE incident_reasons (
    incident_reason_id   SERIAL,
    code                 VARCHAR(30)     NOT NULL,                        -- unique reference code (ej. INC-CLI-AUS)
    name                 VARCHAR(150)    NOT NULL,                        -- motivo de incidencia de entrega
    requires_evidence    BOOLEAN         NOT NULL DEFAULT FALSE,          -- exige foto al registrar la incidencia
    active               BOOLEAN         NOT NULL DEFAULT TRUE,           -- asignable a incidencias nuevas / desactivado
    deleted_at           TIMESTAMPTZ,                                     -- soft delete
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (incident_reason_id)
);

CREATE UNIQUE INDEX uq_incident_reasons_name ON incident_reasons(name) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_incident_reasons_code ON incident_reasons(code) WHERE deleted_at IS NULL;
