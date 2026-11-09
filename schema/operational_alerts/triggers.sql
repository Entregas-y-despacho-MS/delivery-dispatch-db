CREATE OR REPLACE FUNCTION fn_operational_alerts_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_operational_alerts_set_updated_at ON operational_alerts;
CREATE TRIGGER trg_operational_alerts_set_updated_at
    BEFORE UPDATE ON operational_alerts
    FOR EACH ROW EXECUTE FUNCTION fn_operational_alerts_set_updated_at();
