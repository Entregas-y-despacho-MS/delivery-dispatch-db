ALTER TABLE delivery_evidences
    ADD COLUMN IF NOT EXISTS captured_at       TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS latitude          NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS longitude         NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS receiver_name     VARCHAR(150),
    ADD COLUMN IF NOT EXISTS receiver_document VARCHAR(30);

INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt)
VALUES ('INC-CUST-REJECTED', 'Rechazo del paquete por el cliente', TRUE, TRUE)
ON CONFLICT (code) WHERE deleted_at IS NULL DO NOTHING;

UPDATE incident_reasons
SET requires_evidence = TRUE
WHERE code IN ('INC-CUST-ABSENT', 'INC-ADDR-INVALID', 'INC-PROD-DAMAGED', 'INC-CUST-REJECTED')
  AND deleted_at IS NULL;

INSERT INTO settings (setting_key, setting_value, description)
VALUES (
    'incomplete_order_alert_minutes',
    '60',
    'Minutes before alerting that an order is incomplete; preserve the ST-31.5 behavior.'
)
ON CONFLICT (setting_key) DO NOTHING;
