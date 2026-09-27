DROP INDEX IF EXISTS uq_incident_reasons_code;
ALTER TABLE incident_reasons
    DROP COLUMN IF EXISTS code,
    DROP COLUMN IF EXISTS requires_evidence,
    DROP COLUMN IF EXISTS active;
