DROP INDEX IF EXISTS idx_dispatches_delivery_point;
DROP INDEX IF EXISTS idx_delivery_zones_boundary;
ALTER TABLE delivery_zones DROP COLUMN IF EXISTS boundary;

DROP TRIGGER IF EXISTS trg_dispatches_tracking_code_immutable ON dispatches;
DROP FUNCTION IF EXISTS prevent_tracking_code_change();
DROP FUNCTION IF EXISTS next_tracking_code();
DROP TABLE IF EXISTS tracking_code_counters;

ALTER TABLE dispatches DROP CONSTRAINT IF EXISTS chk_dispatches_evidence_policy;
ALTER TABLE dispatches DROP CONSTRAINT IF EXISTS uq_dispatches_tracking_code;
ALTER TABLE dispatches
    DROP COLUMN IF EXISTS evidence_policy,
    DROP COLUMN IF EXISTS tracking_code;

DROP TABLE IF EXISTS dispatch_packages;

-- Solo se pueden quitar los estados que ningún despacho usa.
DELETE FROM dispatch_statuses
WHERE name IN ('address_review', 'in_planning', 'scheduled', 'assigned', 'out_for_delivery',
               'incident', 'rescheduled', 'pickup_scheduled', 'picked_up_in_transit', 'returned_to_warehouse')
  AND NOT EXISTS (SELECT 1 FROM dispatches d WHERE d.dispatch_status_id = dispatch_statuses.dispatch_status_id);
