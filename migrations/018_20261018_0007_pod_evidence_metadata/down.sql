ALTER TABLE delivery_evidences
    DROP CONSTRAINT IF EXISTS chk_delivery_evidences_longitude_range,
    DROP CONSTRAINT IF EXISTS chk_delivery_evidences_latitude_range,
    DROP CONSTRAINT IF EXISTS chk_delivery_evidences_otp_code_null;

ALTER TABLE delivery_evidences
    DROP COLUMN IF EXISTS receiver_document,
    DROP COLUMN IF EXISTS receiver_name,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude,
    DROP COLUMN IF EXISTS captured_at;

UPDATE incident_reasons AS reason
SET requires_evidence = state.previous_requires_evidence,
    counts_as_attempt = state.previous_counts_as_attempt
FROM migration_018_incident_reason_state AS state
WHERE reason.incident_reason_id = state.incident_reason_id
  AND NOT state.created_by_migration;

-- Keep a migration-created catalog row for incident history; retire it instead of hard-deleting it.
UPDATE incident_reasons AS reason
SET active = FALSE,
    deleted_at = COALESCE(reason.deleted_at, NOW())
FROM migration_018_incident_reason_state AS state
WHERE reason.incident_reason_id = state.incident_reason_id
  AND state.created_by_migration;

DROP TABLE migration_018_incident_reason_state;

-- incomplete_order_alert_minutes is also seeded by migration 011, so this migration
-- intentionally leaves that setting in place when rolled back.
