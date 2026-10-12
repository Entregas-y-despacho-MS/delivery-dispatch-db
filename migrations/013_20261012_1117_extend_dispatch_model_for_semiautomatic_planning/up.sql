-- ST-49.3 — modelo de datos de la planificación semiautomática (plan v3, §6.1; "migración 011"
-- en el plan, materializada como 013 porque la 011 y la 012 ya existían).
-- No se edita la 009: todo lo nuevo va acá.

-- 1. Estado `cancelled` del despacho (terminal: un despacho se anula, nunca se borra).
INSERT INTO dispatch_statuses (name)
SELECT 'cancelled'
WHERE NOT EXISTS (SELECT 1 FROM dispatch_statuses WHERE name = 'cancelled');

-- 2. Bitácora append-only del lote. Se crea antes de tocar `route_batches` porque el tratamiento
--    de duplicados (punto 4) guarda ahí los valores originales que limpia.
CREATE TABLE IF NOT EXISTS route_batch_events (
    route_batch_event_id  SERIAL,
    route_batch_id        INT             NOT NULL,
    dispatch_id           INT,
    event_type            VARCHAR(50)     NOT NULL,
    actor_user_id         INT,
    actor_type            VARCHAR(20)     NOT NULL,
    reason                TEXT,
    metadata              JSONB,
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_batch_event_id),
    FOREIGN KEY (route_batch_id) REFERENCES route_batches(route_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_id)    REFERENCES dispatches(dispatch_id)       ON DELETE RESTRICT,
    FOREIGN KEY (actor_user_id)  REFERENCES users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT chk_route_batch_events_actor_type CHECK (actor_type IN ('user', 'system', 'customer'))
);

CREATE INDEX IF NOT EXISTS idx_route_batch_events_route_batch_id ON route_batch_events(route_batch_id);
CREATE INDEX IF NOT EXISTS idx_route_batch_events_dispatch_id    ON route_batch_events(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_route_batch_events_actor_user_id  ON route_batch_events(actor_user_id);

-- Inmutabilidad: UPDATE siempre bloqueado; DELETE solo con `app.allow_event_purge = 'on'`
-- (limpieza de pruebas; en producción nunca se activa). TRUNCATE no se bloquea: es convención.
CREATE OR REPLACE FUNCTION fn_route_batch_events_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_batch_events is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_route_batch_events_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_batch_events is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_route_batch_events_prevent_update ON route_batch_events;
CREATE TRIGGER trg_route_batch_events_prevent_update
    BEFORE UPDATE ON route_batch_events
    FOR EACH ROW EXECUTE FUNCTION fn_route_batch_events_prevent_update();

DROP TRIGGER IF EXISTS trg_route_batch_events_prevent_delete ON route_batch_events;
CREATE TRIGGER trg_route_batch_events_prevent_delete
    BEFORE DELETE ON route_batch_events
    FOR EACH ROW EXECUTE FUNCTION fn_route_batch_events_prevent_delete();

-- 3. route_batches: ciclo de vida y planificación del lote.
ALTER TABLE route_batches
    ADD COLUMN IF NOT EXISTS status               VARCHAR(30),
    ADD COLUMN IF NOT EXISTS version              INT          NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS delivery_zone_id     INT,
    ADD COLUMN IF NOT EXISTS origin_warehouse_id  INT,
    ADD COLUMN IF NOT EXISTS proposed_driver_id   INT,
    ADD COLUMN IF NOT EXISTS reviewer_user_id     INT,
    ADD COLUMN IF NOT EXISTS accepted_at          TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS closed_at            TIMESTAMPTZ;

-- Las filas del Sprint 1 ya fueron armadas a mano: no son `provisional`. Una ruta de un día
-- anterior a hoy ya se ejecutó (`closed`); una de hoy o futura es un lote ya confirmado.
-- `closed_at` queda NULL en las cerradas por backfill: el momento real de cierre no se conoce.
UPDATE route_batches
SET status = CASE WHEN shift_date < CURRENT_DATE THEN 'closed' ELSE 'confirmed' END
WHERE status IS NULL;

ALTER TABLE route_batches ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_route_batches_status') THEN
        ALTER TABLE route_batches ADD CONSTRAINT chk_route_batches_status
            CHECK (status IN ('provisional', 'pending_final_review', 'confirmed', 'in_execution', 'closed', 'cancelled'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_batches_delivery_zone_id_fkey') THEN
        ALTER TABLE route_batches ADD CONSTRAINT route_batches_delivery_zone_id_fkey
            FOREIGN KEY (delivery_zone_id) REFERENCES delivery_zones(delivery_zone_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_batches_origin_warehouse_id_fkey') THEN
        ALTER TABLE route_batches ADD CONSTRAINT route_batches_origin_warehouse_id_fkey
            FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_batches_proposed_driver_id_fkey') THEN
        ALTER TABLE route_batches ADD CONSTRAINT route_batches_proposed_driver_id_fkey
            FOREIGN KEY (proposed_driver_id) REFERENCES users(user_id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_batches_reviewer_user_id_fkey') THEN
        ALTER TABLE route_batches ADD CONSTRAINT route_batches_reviewer_user_id_fkey
            FOREIGN KEY (reviewer_user_id) REFERENCES users(user_id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_route_batches_status              ON route_batches(status);
CREATE INDEX IF NOT EXISTS idx_route_batches_delivery_zone_id    ON route_batches(delivery_zone_id);
CREATE INDEX IF NOT EXISTS idx_route_batches_origin_warehouse_id ON route_batches(origin_warehouse_id);
CREATE INDEX IF NOT EXISTS idx_route_batches_proposed_driver_id  ON route_batches(proposed_driver_id);
CREATE INDEX IF NOT EXISTS idx_route_batches_reviewer_user_id    ON route_batches(reviewer_user_id);

-- 4. Duplicados del Sprint 1 antes de crear los índices únicos. En cada grupo de lotes no
--    cancelados con el mismo vehículo (o conductor) y la misma fecha se conserva la asignación
--    del lote de mayor `route_batch_id`; en los demás la columna pasa a NULL (un lote puede
--    existir sin asignar). El valor original queda en `route_batch_events` y `down.sql` lo
--    restaura. Si no hay duplicados no hace nada.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT route_batch_id, vehicle_id AS value, shift_date, kept_id
        FROM (
            SELECT route_batch_id, vehicle_id, shift_date,
                   ROW_NUMBER()  OVER w AS rn,
                   FIRST_VALUE(route_batch_id) OVER w AS kept_id
            FROM route_batches
            WHERE vehicle_id IS NOT NULL AND status <> 'cancelled'
            WINDOW w AS (PARTITION BY vehicle_id, shift_date ORDER BY route_batch_id DESC)
        ) d
        WHERE rn > 1
    LOOP
        INSERT INTO route_batch_events (route_batch_id, event_type, actor_type, reason, metadata)
        VALUES (r.route_batch_id, 'migration_013_assignment_cleared', 'system',
                'Duplicate vehicle on the same shift_date cleared before creating the unique index',
                jsonb_build_object('field', 'vehicle_id', 'previous_vehicle_id', r.value,
                                   'shift_date', r.shift_date, 'kept_route_batch_id', r.kept_id));
        UPDATE route_batches SET vehicle_id = NULL WHERE route_batch_id = r.route_batch_id;
        RAISE NOTICE 'route_batches % (shift_date %): vehicle_id % cleared, kept by route_batches %',
            r.route_batch_id, r.shift_date, r.value, r.kept_id;
    END LOOP;

    FOR r IN
        SELECT route_batch_id, driver_id AS value, shift_date, kept_id
        FROM (
            SELECT route_batch_id, driver_id, shift_date,
                   ROW_NUMBER()  OVER w AS rn,
                   FIRST_VALUE(route_batch_id) OVER w AS kept_id
            FROM route_batches
            WHERE driver_id IS NOT NULL AND status <> 'cancelled'
            WINDOW w AS (PARTITION BY driver_id, shift_date ORDER BY route_batch_id DESC)
        ) d
        WHERE rn > 1
    LOOP
        INSERT INTO route_batch_events (route_batch_id, event_type, actor_type, reason, metadata)
        VALUES (r.route_batch_id, 'migration_013_assignment_cleared', 'system',
                'Duplicate driver on the same shift_date cleared before creating the unique index',
                jsonb_build_object('field', 'driver_id', 'previous_driver_id', r.value,
                                   'shift_date', r.shift_date, 'kept_route_batch_id', r.kept_id));
        UPDATE route_batches SET driver_id = NULL WHERE route_batch_id = r.route_batch_id;
        RAISE NOTICE 'route_batches % (shift_date %): driver_id % cleared, kept by route_batches %',
            r.route_batch_id, r.shift_date, r.value, r.kept_id;
    END LOOP;
END $$;

-- Un vehículo o un conductor no puede estar en dos lotes vigentes el mismo día.
CREATE UNIQUE INDEX IF NOT EXISTS uq_route_batches_vehicle_shift_date
    ON route_batches(vehicle_id, shift_date)
    WHERE vehicle_id IS NOT NULL AND status <> 'cancelled';
CREATE UNIQUE INDEX IF NOT EXISTS uq_route_batches_driver_shift_date
    ON route_batches(driver_id, shift_date)
    WHERE driver_id IS NOT NULL AND status <> 'cancelled';

-- 5. dispatches: versión de planificación y confirmación de la promesa al cliente.
ALTER TABLE dispatches
    ADD COLUMN IF NOT EXISTS version                INT          NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS customer_confirmation  VARCHAR(20)  NOT NULL DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS promise_notified_at    TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS promise_firmed_at      TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS order_confirmed_at     TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS origin_warehouse_id    INT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_dispatches_customer_confirmation') THEN
        ALTER TABLE dispatches ADD CONSTRAINT chk_dispatches_customer_confirmation
            CHECK (customer_confirmation IN ('pending', 'confirmed', 'rescheduled', 'change_requested'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dispatches_origin_warehouse_id_fkey') THEN
        ALTER TABLE dispatches ADD CONSTRAINT dispatches_origin_warehouse_id_fkey
            FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_dispatches_origin_warehouse_id ON dispatches(origin_warehouse_id);
