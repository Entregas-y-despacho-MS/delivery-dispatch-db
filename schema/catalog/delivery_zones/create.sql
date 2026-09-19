CREATE TABLE delivery_zones (
    delivery_zone_id     SERIAL,
    name                 VARCHAR(100)    NOT NULL,                        -- nombre de la zona de reparto
    estimated_time_min   INT             NOT NULL,                        -- tiempo estimado de entrega, en minutos
    deleted_at           TIMESTAMPTZ,                                     -- soft delete
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_zone_id)
);

-- Único solo entre zonas activas: permite reusar el nombre después de un soft delete
CREATE UNIQUE INDEX uq_delivery_zones_name ON delivery_zones(name) WHERE deleted_at IS NULL;
