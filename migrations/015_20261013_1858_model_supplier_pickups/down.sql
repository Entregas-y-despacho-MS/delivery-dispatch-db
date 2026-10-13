DROP TABLE IF EXISTS dispatch_pickup_items;

DROP INDEX IF EXISTS idx_dispatches_destination_warehouse_id;

ALTER TABLE dispatches
    DROP CONSTRAINT IF EXISTS fk_dispatches_destination_warehouse,
    DROP COLUMN IF EXISTS destination_warehouse_id,
    DROP COLUMN IF EXISTS transport_conditions,
    DROP COLUMN IF EXISTS estimated_volume_m3,
    DROP COLUMN IF EXISTS estimated_boxes;
