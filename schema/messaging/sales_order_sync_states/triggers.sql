CREATE OR REPLACE FUNCTION fn_sales_order_sync_states_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sales_order_sync_states_set_updated_at
    BEFORE UPDATE ON sales_order_sync_states
    FOR EACH ROW EXECUTE FUNCTION fn_sales_order_sync_states_set_updated_at();
