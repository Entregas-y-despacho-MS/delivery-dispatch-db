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
