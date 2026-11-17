CREATE OR REPLACE FUNCTION fn_inbound_messages_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inbound_messages_set_updated_at
    BEFORE UPDATE ON inbound_messages
    FOR EACH ROW EXECUTE FUNCTION fn_inbound_messages_set_updated_at();
