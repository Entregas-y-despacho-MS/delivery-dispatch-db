CREATE OR REPLACE FUNCTION fn_warehouse_receipt_items_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_warehouse_receipt_items_set_updated_at ON warehouse_receipt_items;
CREATE TRIGGER trg_warehouse_receipt_items_set_updated_at
    BEFORE UPDATE ON warehouse_receipt_items
    FOR EACH ROW EXECUTE FUNCTION fn_warehouse_receipt_items_set_updated_at();
