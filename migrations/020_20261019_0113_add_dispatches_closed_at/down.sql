DROP INDEX IF EXISTS idx_dispatches_closed_at;
DROP TRIGGER IF EXISTS trg_dispatches_set_closed_at ON dispatches;
DROP FUNCTION IF EXISTS fn_dispatches_set_closed_at();
ALTER TABLE dispatches DROP COLUMN IF EXISTS closed_at;
