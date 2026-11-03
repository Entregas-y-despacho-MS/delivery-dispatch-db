-- ST-238.1 (ES-238, ERP-07): model the RMA pickup order so the inbound consumer (ST-238.2) can
-- create it from `inventory.return.requested` and track inbound idempotency per rmaId.

ALTER TABLE dispatches ADD COLUMN IF NOT EXISTS preferred_pickup_date TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS rma_sync_states (
    rma_id               VARCHAR(100) NOT NULL,
    last_record_version  BIGINT       NOT NULL DEFAULT 0,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (rma_id),
    CONSTRAINT chk_rma_sync_states_version CHECK (last_record_version >= 0)
);

CREATE OR REPLACE FUNCTION fn_rma_sync_states_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_rma_sync_states_set_updated_at ON rma_sync_states;
CREATE TRIGGER trg_rma_sync_states_set_updated_at
    BEFORE UPDATE ON rma_sync_states
    FOR EACH ROW EXECUTE FUNCTION fn_rma_sync_states_set_updated_at();

-- Same pattern as uq_dispatches_delivery_source_order_ref (migration 014): resolve the type by
-- name, never assume a seed id, and refuse if duplicates already exist.
DO $$
DECLARE
    return_pickup_type_id INT;
    duplicate_ref VARCHAR(100);
BEGIN
    SELECT dispatch_type_id INTO return_pickup_type_id FROM dispatch_types WHERE name = 'warehouse_return_pickup';
    IF return_pickup_type_id IS NULL THEN
        RAISE EXCEPTION 'dispatch type warehouse_return_pickup is missing';
    END IF;
    SELECT source_order_ref INTO duplicate_ref
    FROM dispatches WHERE dispatch_type_id = return_pickup_type_id
    GROUP BY source_order_ref HAVING COUNT(*) > 1 LIMIT 1;
    IF duplicate_ref IS NOT NULL THEN
        RAISE EXCEPTION 'duplicate warehouse_return_pickup source_order_ref: %', duplicate_ref;
    END IF;
    EXECUTE format(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_dispatches_warehouse_return_pickup_source_order_ref '
        || 'ON dispatches(source_order_ref) WHERE dispatch_type_id = %s', return_pickup_type_id
    );
END $$;
