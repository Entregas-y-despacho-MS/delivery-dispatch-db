-- ST-49.2 — base de datos del flujo de órdenes de despacho: estados ampliados, bultos reales,
-- código de traslado DSP-AAAA-NNNNN, política de evidencia e índices espaciales.

-- 1. Estados del despacho. `in_transit` se conserva ("en camino a una parada concreta").
INSERT INTO dispatch_statuses (name)
SELECT s.name
FROM (VALUES
    ('address_review'), ('in_planning'), ('scheduled'), ('assigned'), ('out_for_delivery'),
    ('incident'), ('rescheduled'), ('pickup_scheduled'), ('picked_up_in_transit'),
    ('returned_to_warehouse')
) AS s(name)
WHERE NOT EXISTS (SELECT 1 FROM dispatch_statuses d WHERE d.name = s.name);

-- 2. Bultos reales informados por Almacén.
CREATE TABLE IF NOT EXISTS dispatch_packages (
    dispatch_package_id   SERIAL,
    dispatch_id           INT             NOT NULL,
    external_package_id   VARCHAR(100)    NOT NULL,
    length_cm             NUMERIC(8,2)    NOT NULL,
    width_cm              NUMERIC(8,2)    NOT NULL,
    height_cm             NUMERIC(8,2)    NOT NULL,
    gross_weight_kg       NUMERIC(10,3)   NOT NULL,
    handling_conditions   TEXT[]          NOT NULL DEFAULT '{}',
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_package_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT uq_dispatch_packages_external UNIQUE (dispatch_id, external_package_id),
    CONSTRAINT chk_dispatch_packages_dimensions CHECK (length_cm > 0 AND width_cm > 0 AND height_cm > 0),
    CONSTRAINT chk_dispatch_packages_weight CHECK (gross_weight_kg > 0)
);

CREATE INDEX IF NOT EXISTS idx_dispatch_packages_dispatch_id ON dispatch_packages(dispatch_id);

-- 3. Código de traslado y política de evidencia en dispatches.
ALTER TABLE dispatches
    ADD COLUMN IF NOT EXISTS tracking_code    VARCHAR(20),
    ADD COLUMN IF NOT EXISTS evidence_policy  VARCHAR(30) NOT NULL DEFAULT 'hand_delivery_standard';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_dispatches_tracking_code') THEN
        ALTER TABLE dispatches ADD CONSTRAINT uq_dispatches_tracking_code UNIQUE (tracking_code);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_dispatches_evidence_policy') THEN
        ALTER TABLE dispatches ADD CONSTRAINT chk_dispatches_evidence_policy
            CHECK (evidence_policy IN ('hand_delivery_standard', 'contactless_delivery', 'high_value_control'));
    END IF;
END $$;

-- Contador anual: una fila por año; el UPSERT toma el bloqueo de la fila, así que dos
-- transacciones simultáneas nunca obtienen el mismo número y la secuencia reinicia cada año.
CREATE TABLE IF NOT EXISTS tracking_code_counters (
    code_year   SMALLINT   NOT NULL,
    last_value  INT        NOT NULL DEFAULT 0,
    PRIMARY KEY (code_year)
);

CREATE OR REPLACE FUNCTION next_tracking_code() RETURNS VARCHAR AS $$
DECLARE
    y  SMALLINT := EXTRACT(YEAR FROM NOW())::SMALLINT;
    n  INT;
BEGIN
    INSERT INTO tracking_code_counters (code_year, last_value) VALUES (y, 1)
    ON CONFLICT (code_year) DO UPDATE SET last_value = tracking_code_counters.last_value + 1
    RETURNING last_value INTO n;
    RETURN 'DSP-' || y || '-' || LPAD(n::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- El código es inmutable una vez asignado.
CREATE OR REPLACE FUNCTION prevent_tracking_code_change() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.tracking_code IS NOT NULL AND NEW.tracking_code IS DISTINCT FROM OLD.tracking_code THEN
        RAISE EXCEPTION 'dispatches.tracking_code is immutable once assigned';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dispatches_tracking_code_immutable ON dispatches;
CREATE TRIGGER trg_dispatches_tracking_code_immutable
    BEFORE UPDATE OF tracking_code ON dispatches
    FOR EACH ROW EXECUTE FUNCTION prevent_tracking_code_change();

-- 4. Índices espaciales GiST (tipos geométricos nativos; la imagen postgres no incluye PostGIS).
ALTER TABLE delivery_zones ADD COLUMN IF NOT EXISTS boundary POLYGON;

CREATE INDEX IF NOT EXISTS idx_delivery_zones_boundary ON delivery_zones USING GIST (boundary)
    WHERE boundary IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_dispatches_delivery_point ON dispatches
    USING GIST (point(delivery_longitude::float8, delivery_latitude::float8))
    WHERE delivery_latitude IS NOT NULL AND delivery_longitude IS NOT NULL;
