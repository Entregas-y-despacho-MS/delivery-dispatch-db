-- ST-55.2 — dispatches.closed_at: moment the dispatch reached a terminal status (RF-A08).

ALTER TABLE dispatches ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;

-- Existing terminal dispatches: time of the last status_changed event that set the current status;
-- events written before migration 013 have no metadata, so fall back to updated_at.
UPDATE dispatches d
   SET closed_at = COALESCE(
        (SELECT MAX(e.created_at)
           FROM dispatch_events e
          WHERE e.dispatch_id = d.dispatch_id
            AND e.event_type = 'status_changed'
            AND e.metadata->>'status' = s.name),
        d.updated_at)
  FROM dispatch_statuses s
 WHERE s.dispatch_status_id = d.dispatch_status_id
   AND s.name IN ('delivered', 'not_delivered', 'returned', 'returned_to_warehouse', 'cancelled')
   AND d.closed_at IS NULL;

-- Safety net: the writers pass the real event time (the device's occurredAt); when one does not, a
-- dispatch entering a terminal status still gets a closing time, and one leaving them loses it.
CREATE OR REPLACE FUNCTION fn_dispatches_set_closed_at() RETURNS TRIGGER AS $$
DECLARE
    is_terminal BOOLEAN;
BEGIN
    IF NEW.dispatch_status_id IS NOT DISTINCT FROM OLD.dispatch_status_id THEN
        RETURN NEW;
    END IF;

    SELECT s.name IN ('delivered', 'not_delivered', 'returned', 'returned_to_warehouse', 'cancelled')
      INTO is_terminal
      FROM dispatch_statuses s
     WHERE s.dispatch_status_id = NEW.dispatch_status_id;

    IF COALESCE(is_terminal, FALSE) THEN
        IF NEW.closed_at IS NULL OR NEW.closed_at IS NOT DISTINCT FROM OLD.closed_at THEN
            NEW.closed_at := NOW();
        END IF;
    ELSE
        NEW.closed_at := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dispatches_set_closed_at ON dispatches;
CREATE TRIGGER trg_dispatches_set_closed_at
    BEFORE UPDATE OF dispatch_status_id ON dispatches
    FOR EACH ROW EXECUTE FUNCTION fn_dispatches_set_closed_at();

CREATE INDEX IF NOT EXISTS idx_dispatches_closed_at ON dispatches(closed_at DESC) WHERE closed_at IS NOT NULL;
