-- Orden inverso a up.sql.

-- 10. service_levels: Express vuelve a su valor de semilla (activo), que es el que tenía antes de up.sql.
UPDATE service_levels SET active = TRUE
WHERE name = 'Express' AND deleted_at IS NULL AND active = FALSE;

-- 9. vehicles
ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS chk_vehicles_max_package_height_cm;
ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS chk_vehicles_max_package_width_cm;
ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS chk_vehicles_max_package_length_cm;
ALTER TABLE vehicles
    DROP COLUMN IF EXISTS max_package_height_cm,
    DROP COLUMN IF EXISTS max_package_width_cm,
    DROP COLUMN IF EXISTS max_package_length_cm;

-- 8. incident_reasons (el motivo sembrado se quita solo si ninguna incidencia lo usa)
DELETE FROM incident_reasons
WHERE code = 'INC-COMP-FAILURE'
  AND NOT EXISTS (SELECT 1 FROM dispatch_incidents i WHERE i.incident_reason_id = incident_reasons.incident_reason_id);
ALTER TABLE incident_reasons DROP COLUMN IF EXISTS counts_as_attempt;

-- 7. dispatch_reschedules (el motivo sembrado se quita solo si ninguna reprogramación lo usa)
ALTER TABLE dispatch_reschedules DROP CONSTRAINT IF EXISTS chk_dispatch_reschedules_rescheduled_by_type;
ALTER TABLE dispatch_reschedules DROP COLUMN IF EXISTS rescheduled_by_type;
DELETE FROM reschedule_reasons
WHERE code = 'RES-CLI-SELF'
  AND NOT EXISTS (SELECT 1 FROM dispatch_reschedules r WHERE r.reschedule_reason_id = reschedule_reasons.reschedule_reason_id);

-- 6. dispatch_events
DROP TRIGGER IF EXISTS trg_dispatch_events_prevent_delete ON dispatch_events;
DROP TRIGGER IF EXISTS trg_dispatch_events_prevent_update ON dispatch_events;
DROP FUNCTION IF EXISTS fn_dispatch_events_prevent_delete();
DROP FUNCTION IF EXISTS fn_dispatch_events_prevent_update();
DROP INDEX IF EXISTS idx_dispatch_events_actor_user_id;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint
               WHERE conname = 'dispatch_events_dispatch_id_fkey' AND conrelid = 'dispatch_events'::regclass AND confdeltype = 'r') THEN
        ALTER TABLE dispatch_events DROP CONSTRAINT dispatch_events_dispatch_id_fkey;
        ALTER TABLE dispatch_events ADD CONSTRAINT dispatch_events_dispatch_id_fkey
            FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE;
    ELSIF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dispatch_events_dispatch_id_fkey' AND conrelid = 'dispatch_events'::regclass) THEN
        ALTER TABLE dispatch_events ADD CONSTRAINT dispatch_events_dispatch_id_fkey
            FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE;
    END IF;
END $$;

ALTER TABLE dispatch_events DROP CONSTRAINT IF EXISTS dispatch_events_actor_user_id_fkey;
ALTER TABLE dispatch_events DROP CONSTRAINT IF EXISTS chk_dispatch_events_actor_type;
ALTER TABLE dispatch_events
    DROP COLUMN IF EXISTS metadata,
    DROP COLUMN IF EXISTS reason,
    DROP COLUMN IF EXISTS actor_type,
    DROP COLUMN IF EXISTS actor_user_id;


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
          AND rb.status <> 'cancelled'
          AND EXISTS (SELECT 1 FROM vehicles v WHERE v.vehicle_id = (e.metadata ->> 'previous_vehicle_id')::INT);

        UPDATE route_batches rb
        SET driver_id = (e.metadata ->> 'previous_driver_id')::INT
        FROM route_batch_events e
        WHERE e.event_type = 'migration_013_assignment_cleared'
          AND e.metadata ->> 'field' = 'driver_id'
          AND e.route_batch_id = rb.route_batch_id
          AND rb.driver_id IS NULL
          AND rb.status <> 'cancelled'
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
