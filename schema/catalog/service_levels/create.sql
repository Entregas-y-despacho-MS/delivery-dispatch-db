CREATE TABLE service_levels (
    service_level_id    SERIAL,
    name                 VARCHAR(50)     NOT NULL,                        -- estándar | express
    description          VARCHAR(255),                                    -- descripción del nivel de servicio (opcional)
    target_time_min      INT             NOT NULL,                        -- tiempo objetivo de entrega, en minutos
    priority_level       SMALLINT        NOT NULL,                        -- jerarquía de prioridad: 1 = la más alta
    active               BOOLEAN         NOT NULL DEFAULT TRUE,           -- habilitado para asignarse a órdenes nuevas / desactivado
    deleted_at            TIMESTAMPTZ,                                     -- soft delete
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (service_level_id),
    CONSTRAINT chk_service_levels_priority_level CHECK (priority_level >= 1)
);

CREATE UNIQUE INDEX uq_service_levels_name ON service_levels(name) WHERE deleted_at IS NULL;
