CREATE OR REPLACE FUNCTION fn_pending_shipments_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pending_shipments_set_updated_at
    BEFORE UPDATE ON pending_shipments
    FOR EACH ROW EXECUTE FUNCTION fn_pending_shipments_set_updated_at();
