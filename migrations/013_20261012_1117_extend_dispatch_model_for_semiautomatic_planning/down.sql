-- Orden inverso a up.sql.

-- 5. dispatches
DROP INDEX IF EXISTS idx_dispatches_origin_warehouse_id;
ALTER TABLE dispatches DROP CONSTRAINT IF EXISTS dispatches_origin_warehouse_id_fkey;
ALTER TABLE dispatches DROP CONSTRAINT IF EXISTS chk_dispatches_customer_confirmation;
ALTER TABLE dispatches
    DROP COLUMN IF EXISTS origin_warehouse_id,
    DROP COLUMN IF EXISTS order_confirmed_at,
    DROP COLUMN IF EXISTS promise_firmed_at,
    DROP COLUMN IF EXISTS promise_notified_at,
    DROP COLUMN IF EXISTS customer_confirmation,
    DROP COLUMN IF EXISTS version;

-- 4. Índices únicos y restauración de las asignaciones que up.sql limpió por duplicado.
DROP INDEX IF EXISTS uq_route_batches_driver_shift_date;
DROP INDEX IF EXISTS uq_route_batches_vehicle_shift_date;

DO $$
BEGIN
    IF to_regclass('route_batch_events') IS NOT NULL THEN
        UPDATE route_batches rb
        SET vehicle_id = (e.metadata ->> 'previous_vehicle_id')::INT
        FROM route_batch_events e
        WHERE e.event_type = 'migration_013_assignment_cleared'
          AND e.metadata ->> 'field' = 'vehicle_id'
          AND e.route_batch_id = rb.route_batch_id
          AND rb.vehicle_id IS NULL
          AND EXISTS (SELECT 1 FROM vehicles v WHERE v.vehicle_id = (e.metadata ->> 'previous_vehicle_id')::INT);

        UPDATE route_batches rb
        SET driver_id = (e.metadata ->> 'previous_driver_id')::INT
        FROM route_batch_events e
        WHERE e.event_type = 'migration_013_assignment_cleared'
          AND e.metadata ->> 'field' = 'driver_id'
          AND e.route_batch_id = rb.route_batch_id
          AND rb.driver_id IS NULL
          AND EXISTS (SELECT 1 FROM users u WHERE u.user_id = (e.metadata ->> 'previous_driver_id')::INT);
    END IF;
END $$;

-- 3. route_batches
DROP INDEX IF EXISTS idx_route_batches_reviewer_user_id;
DROP INDEX IF EXISTS idx_route_batches_proposed_driver_id;
DROP INDEX IF EXISTS idx_route_batches_origin_warehouse_id;
DROP INDEX IF EXISTS idx_route_batches_delivery_zone_id;
DROP INDEX IF EXISTS idx_route_batches_status;

ALTER TABLE route_batches DROP CONSTRAINT IF EXISTS route_batches_reviewer_user_id_fkey;
ALTER TABLE route_batches DROP CONSTRAINT IF EXISTS route_batches_proposed_driver_id_fkey;
ALTER TABLE route_batches DROP CONSTRAINT IF EXISTS route_batches_origin_warehouse_id_fkey;
ALTER TABLE route_batches DROP CONSTRAINT IF EXISTS route_batches_delivery_zone_id_fkey;
ALTER TABLE route_batches DROP CONSTRAINT IF EXISTS chk_route_batches_status;
ALTER TABLE route_batches
    DROP COLUMN IF EXISTS closed_at,
    DROP COLUMN IF EXISTS accepted_at,
    DROP COLUMN IF EXISTS reviewer_user_id,
    DROP COLUMN IF EXISTS proposed_driver_id,
    DROP COLUMN IF EXISTS origin_warehouse_id,
    DROP COLUMN IF EXISTS delivery_zone_id,
    DROP COLUMN IF EXISTS version,
    DROP COLUMN IF EXISTS status;

-- 2. route_batch_events (la tabla completa, con sus triggers; DROP TABLE no dispara el de DELETE)
DROP TRIGGER IF EXISTS trg_route_batch_events_prevent_delete ON route_batch_events;
DROP TRIGGER IF EXISTS trg_route_batch_events_prevent_update ON route_batch_events;
DROP FUNCTION IF EXISTS fn_route_batch_events_prevent_delete();
DROP FUNCTION IF EXISTS fn_route_batch_events_prevent_update();
DROP TABLE IF EXISTS route_batch_events;

-- 1. Solo se quita `cancelled` si ningún despacho lo usa (mismo criterio que la 009).
DELETE FROM dispatch_statuses
WHERE name = 'cancelled'
  AND NOT EXISTS (SELECT 1 FROM dispatches d WHERE d.dispatch_status_id = dispatch_statuses.dispatch_status_id);
