ALTER TABLE dispatches DROP CONSTRAINT IF EXISTS chk_dispatches_received_boxes;
ALTER TABLE dispatches
    DROP COLUMN IF EXISTS arrived_at_warehouse_at,
    DROP COLUMN IF EXISTS custody_received_at,
    DROP COLUMN IF EXISTS received_boxes;
