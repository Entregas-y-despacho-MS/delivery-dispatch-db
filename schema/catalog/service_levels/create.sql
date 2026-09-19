CREATE TABLE service_levels (
    service_level_id    SERIAL,
    name                 VARCHAR(50)     NOT NULL,                        -- estándar | express
    target_time_min      INT             NOT NULL,                        -- tiempo objetivo de entrega, en minutos
    deleted_at            TIMESTAMPTZ,                                     -- soft delete
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (service_level_id)
);

CREATE UNIQUE INDEX uq_service_levels_name ON service_levels(name) WHERE deleted_at IS NULL;
