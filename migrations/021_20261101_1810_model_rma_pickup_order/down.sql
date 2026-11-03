DROP INDEX IF EXISTS uq_dispatches_warehouse_return_pickup_source_order_ref;
DROP TRIGGER IF EXISTS trg_rma_sync_states_set_updated_at ON rma_sync_states;
DROP FUNCTION IF EXISTS fn_rma_sync_states_set_updated_at();
DROP TABLE IF EXISTS rma_sync_states;
ALTER TABLE dispatches DROP COLUMN IF EXISTS preferred_pickup_date;
