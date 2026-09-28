DROP INDEX IF EXISTS uq_reschedule_reasons_code;
ALTER TABLE reschedule_reasons DROP COLUMN IF EXISTS code;
