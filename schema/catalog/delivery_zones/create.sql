CREATE TABLE delivery_zones (
    delivery_zone_id     SERIAL,
    code                 VARCHAR(20)     NOT NULL,                        -- código único de la zona (ej. ZON-SUR)
    name                 VARCHAR(100)    NOT NULL,                        -- nombre de la zona de reparto
    estimated_time_min   INT             NOT NULL,                        -- tiempo estimado de entrega, en minutos
    deleted_at           TIMESTAMPTZ,                                     -- soft delete
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_zone_id)
);

-- Únicos solo entre zonas activas: permite reusar código y nombre después de un soft delete
CREATE UNIQUE INDEX uq_delivery_zones_code ON delivery_zones(code) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_delivery_zones_name ON delivery_zones(name) WHERE deleted_at IS NULL;
