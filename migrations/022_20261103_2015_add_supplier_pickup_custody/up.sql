-- ST-239.1 (ES-239, ERP-06): custody of a supplier pickup, shared with the RMA pickup (ST-80.2).

ALTER TABLE dispatches
    ADD COLUMN IF NOT EXISTS received_boxes INT,
    ADD COLUMN IF NOT EXISTS custody_received_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS arrived_at_warehouse_at TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_dispatches_received_boxes'
        AND conrelid = 'dispatches'::regclass) THEN
        ALTER TABLE dispatches ADD CONSTRAINT chk_dispatches_received_boxes CHECK (received_boxes IS NULL OR received_boxes >= 0);
    END IF;
END $$;
