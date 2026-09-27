CREATE TABLE reschedule_reasons (
    reschedule_reason_id  SERIAL,
    name                  VARCHAR(150)   NOT NULL,                        -- motivo de reprogramación o reasignación de despachos
    description           VARCHAR(255),                                   -- detalle opcional del motivo
    category              VARCHAR(20)    NOT NULL,                        -- origen/responsabilidad: client | operations | force_majeure
    active                BOOLEAN        NOT NULL DEFAULT TRUE,           -- asignable a reprogramaciones nuevas / desactivado
    deleted_at            TIMESTAMPTZ,                                    -- soft delete
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (reschedule_reason_id),
    CONSTRAINT chk_reschedule_reasons_category CHECK (category IN ('client', 'operations', 'force_majeure'))
);

CREATE UNIQUE INDEX uq_reschedule_reasons_name ON reschedule_reasons(name) WHERE deleted_at IS NULL;
