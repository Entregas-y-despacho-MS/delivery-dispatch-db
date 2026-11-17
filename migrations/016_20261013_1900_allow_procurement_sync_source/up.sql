ALTER TABLE sales_order_sync_states
    DROP CONSTRAINT IF EXISTS chk_sales_order_sync_states_source;

ALTER TABLE sales_order_sync_states
    ADD CONSTRAINT chk_sales_order_sync_states_source
    CHECK (source IN ('marketplace', 'inventory', 'procurement'));
