CREATE TABLE reschedule_reasons (
    reschedule_reason_id  SERIAL,
    name                  VARCHAR(150)   NOT NULL,                        -- motivo de reprogramación o reasignación de despachos
    deleted_at            TIMESTAMPTZ,                                    -- soft delete
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (reschedule_reason_id)
);

CREATE UNIQUE INDEX uq_reschedule_reasons_name ON reschedule_reasons(name) WHERE deleted_at IS NULL;
