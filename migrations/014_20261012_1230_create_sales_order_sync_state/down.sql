DROP INDEX IF EXISTS uq_dispatches_delivery_source_order_ref;
DROP INDEX IF EXISTS idx_pending_shipments_unconsolidated;
DROP INDEX IF EXISTS idx_pending_sales_orders_unconsolidated;
DROP INDEX IF EXISTS idx_pending_shipments_dispatch_id;
DROP INDEX IF EXISTS idx_pending_sales_orders_dispatch_id;

ALTER TABLE pending_shipments DROP CONSTRAINT IF EXISTS pending_shipments_dispatch_id_fkey;
ALTER TABLE pending_sales_orders DROP CONSTRAINT IF EXISTS pending_sales_orders_dispatch_id_fkey;
ALTER TABLE pending_shipments DROP CONSTRAINT IF EXISTS chk_pending_shipments_consolidation;
ALTER TABLE pending_sales_orders DROP CONSTRAINT IF EXISTS chk_pending_sales_orders_consolidation;
ALTER TABLE pending_shipments
    DROP COLUMN IF EXISTS dispatch_id,
    DROP COLUMN IF EXISTS consolidated_at;
ALTER TABLE pending_sales_orders
    DROP COLUMN IF EXISTS dispatch_id,
    DROP COLUMN IF EXISTS consolidated_at;

DROP TRIGGER IF EXISTS trg_sales_order_sync_states_set_updated_at ON sales_order_sync_states;
DROP FUNCTION IF EXISTS fn_sales_order_sync_states_set_updated_at();
DROP TABLE IF EXISTS sales_order_sync_states;

ALTER TABLE dispatches
    DROP COLUMN IF EXISTS shipment_ready,
    DROP COLUMN IF EXISTS delivery_reference;
