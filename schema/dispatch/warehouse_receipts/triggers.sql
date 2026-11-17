CREATE OR REPLACE FUNCTION fn_warehouse_receipts_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_warehouse_receipts_set_updated_at ON warehouse_receipts;
CREATE TRIGGER trg_warehouse_receipts_set_updated_at
    BEFORE UPDATE ON warehouse_receipts
    FOR EACH ROW EXECUTE FUNCTION fn_warehouse_receipts_set_updated_at();
