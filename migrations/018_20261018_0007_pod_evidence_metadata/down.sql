ALTER TABLE delivery_evidences
    DROP COLUMN IF EXISTS receiver_document,
    DROP COLUMN IF EXISTS receiver_name,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude,
    DROP COLUMN IF EXISTS captured_at;

UPDATE incident_reasons
SET requires_evidence = FALSE
WHERE code IN ('INC-CUST-ABSENT', 'INC-ADDR-INVALID')
  AND deleted_at IS NULL;

DELETE FROM incident_reasons
WHERE code = 'INC-CUST-REJECTED'
  AND deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM dispatch_incidents
      WHERE dispatch_incidents.incident_reason_id = incident_reasons.incident_reason_id
  );

-- incomplete_order_alert_minutes is also seeded by migration 011, so this migration
-- intentionally leaves that setting in place when rolled back.
