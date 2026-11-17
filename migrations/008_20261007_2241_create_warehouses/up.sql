-- Corrección de ES-26/ST-26.1: esta tabla figuraba como entregada en el Sprint 1 pero nunca se
-- creó. La necesitan ST-74.2 (FK de almacén de destino en recogidas), ST-50.2 (origen de rutas
-- para OSRM) y ST-75.1 (horario de recepción) del Sprint 2.
CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id           SERIAL,
    code                    VARCHAR(30)     NOT NULL,
    name                    VARCHAR(100)    NOT NULL,
    address                 TEXT            NOT NULL,
    latitude                NUMERIC(9,6)    NOT NULL,
    longitude               NUMERIC(9,6)    NOT NULL,
    contact_name            VARCHAR(150),
    contact_phone           VARCHAR(30),
    reception_start_time    TIME            NOT NULL,
    reception_end_time      TIME            NOT NULL,
    active                  BOOLEAN         NOT NULL DEFAULT TRUE,
    deleted_at              TIMESTAMPTZ,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (warehouse_id)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_warehouses_reception_window') THEN
        ALTER TABLE warehouses
            ADD CONSTRAINT chk_warehouses_reception_window CHECK (reception_end_time > reception_start_time);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_warehouses_code ON warehouses(code) WHERE deleted_at IS NULL;

-- Mínimo operativo: el centro de distribución (origen de rutas) + un segundo almacén de ejemplo.
-- Ajustar a los almacenes reales antes de correr esto en un entorno compartido.
INSERT INTO warehouses (code, name, address, latitude, longitude, contact_name, contact_phone, reception_start_time, reception_end_time, active)
SELECT 'WH-LPZ-01', 'Centro de Distribución La Paz', 'Av. Autopista Viacha, Zona Industrial, La Paz', -16.520000, -68.169000, 'Operaciones CD La Paz', '+591 2 2345678', '07:00', '19:00', TRUE
WHERE NOT EXISTS (SELECT 1 FROM warehouses WHERE code = 'WH-LPZ-01');

INSERT INTO warehouses (code, name, address, latitude, longitude, contact_name, contact_phone, reception_start_time, reception_end_time, active)
SELECT 'WH-LPZ-02', 'Almacén Sopocachi', 'Av. 20 de Octubre 2000, Sopocachi, La Paz', -16.504000, -68.126000, 'Operaciones Sopocachi', '+591 2 2456789', '08:00', '17:00', TRUE
WHERE NOT EXISTS (SELECT 1 FROM warehouses WHERE code = 'WH-LPZ-02');
