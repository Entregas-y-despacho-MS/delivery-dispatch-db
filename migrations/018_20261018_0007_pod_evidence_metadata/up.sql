ALTER TABLE delivery_evidences
    ADD COLUMN IF NOT EXISTS captured_at       TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS latitude          NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS longitude         NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS receiver_name     VARCHAR(150),
    ADD COLUMN IF NOT EXISTS receiver_document VARCHAR(30);

-- OTP values are never retained in plaintext, including values written before this migration.
UPDATE delivery_evidences SET otp_code = NULL WHERE otp_code IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_delivery_evidences_otp_code_null'
          AND conrelid = 'public.delivery_evidences'::regclass
    ) THEN
        ALTER TABLE delivery_evidences
            ADD CONSTRAINT chk_delivery_evidences_otp_code_null CHECK (otp_code IS NULL);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_delivery_evidences_latitude_range'
          AND conrelid = 'public.delivery_evidences'::regclass
    ) THEN
        ALTER TABLE delivery_evidences
            ADD CONSTRAINT chk_delivery_evidences_latitude_range
            CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_delivery_evidences_longitude_range'
          AND conrelid = 'public.delivery_evidences'::regclass
    ) THEN
        ALTER TABLE delivery_evidences
            ADD CONSTRAINT chk_delivery_evidences_longitude_range
            CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180);
    END IF;
END $$;

-- Capture the catalog values changed by this migration so down.sql can restore pre-existing rows.
CREATE TABLE IF NOT EXISTS migration_018_incident_reason_state (
    incident_reason_id       INT PRIMARY KEY,
    created_by_migration     BOOLEAN NOT NULL,
    previous_requires_evidence BOOLEAN,
    previous_counts_as_attempt BOOLEAN
);

INSERT INTO migration_018_incident_reason_state (
    incident_reason_id, created_by_migration, previous_requires_evidence, previous_counts_as_attempt
)
SELECT incident_reason_id, FALSE, requires_evidence, counts_as_attempt
FROM incident_reasons
WHERE code IN ('INC-CUST-ABSENT', 'INC-ADDR-INVALID', 'INC-PROD-DAMAGED', 'INC-CUST-REJECTED')
  AND deleted_at IS NULL
ON CONFLICT (incident_reason_id) DO NOTHING;

DO $$
DECLARE
    reason_id_for_code INT;
    reason_id_for_name INT;
BEGIN
    SELECT incident_reason_id INTO reason_id_for_code
    FROM incident_reasons
    WHERE code = 'INC-CUST-REJECTED' AND deleted_at IS NULL;

    SELECT incident_reason_id INTO reason_id_for_name
    FROM incident_reasons
    WHERE name = 'Rechazo del paquete por el cliente' AND deleted_at IS NULL;

    IF reason_id_for_code IS NOT NULL AND reason_id_for_name IS DISTINCT FROM reason_id_for_code THEN
        RAISE EXCEPTION 'incident_reasons code INC-CUST-REJECTED is already assigned to a different name';
    END IF;
    IF reason_id_for_name IS NOT NULL AND reason_id_for_code IS DISTINCT FROM reason_id_for_name THEN
        RAISE EXCEPTION 'incident_reasons name "Rechazo del paquete por el cliente" is already assigned to a different code';
    END IF;

    IF reason_id_for_code IS NULL THEN
        INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt)
        VALUES ('INC-CUST-REJECTED', 'Rechazo del paquete por el cliente', TRUE, TRUE)
        RETURNING incident_reason_id INTO reason_id_for_code;

        INSERT INTO migration_018_incident_reason_state (
            incident_reason_id, created_by_migration, previous_requires_evidence, previous_counts_as_attempt
        ) VALUES (reason_id_for_code, TRUE, NULL, NULL)
        ON CONFLICT (incident_reason_id) DO NOTHING;
    END IF;
END $$;

UPDATE incident_reasons
SET requires_evidence = TRUE,
    counts_as_attempt = CASE WHEN code = 'INC-CUST-REJECTED' THEN TRUE ELSE counts_as_attempt END
WHERE code IN ('INC-CUST-ABSENT', 'INC-ADDR-INVALID', 'INC-PROD-DAMAGED', 'INC-CUST-REJECTED')
  AND deleted_at IS NULL;

INSERT INTO settings (setting_key, setting_value, description)
VALUES (
    'incomplete_order_alert_minutes',
    '60',
    'Minutes before alerting that an order is incomplete; preserve the ST-31.5 behavior.'
)
ON CONFLICT (setting_key) DO NOTHING;
