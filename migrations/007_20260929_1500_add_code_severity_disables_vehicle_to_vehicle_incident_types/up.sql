-- RF-A34 — service parametrization for the vehicle incident types catalog: a unique reference code,
-- a severity classification (minor | moderate | critical — Escenario 3 makes it mandatory), and
-- whether registering an incident of this type immediately takes the vehicle out of service
-- (Escenario 2 — the actual status-flip trigger lives in the app, this only adds the flag it reads).
ALTER TABLE vehicle_incident_types
    ADD COLUMN IF NOT EXISTS code             VARCHAR(30),
    ADD COLUMN IF NOT EXISTS severity          VARCHAR(20),
    ADD COLUMN IF NOT EXISTS disables_vehicle  BOOLEAN NOT NULL DEFAULT FALSE;

-- Backfill for the 4 types already seeded (data.sql) — placeholders for an old, unmanaged database
-- that pre-dates this migration; edit them to match the real operational codes/severities before
-- running this in a shared environment.
DO $$
BEGIN
    UPDATE vehicle_incident_types SET code = 'MEC-GEN-01', severity = 'critical', disables_vehicle = TRUE  WHERE name = 'Mechanical failure'              AND code IS NULL;
    UPDATE vehicle_incident_types SET code = 'TIR-DAM-01', severity = 'moderate', disables_vehicle = FALSE WHERE name = 'Damaged tire'                    AND code IS NULL;
    UPDATE vehicle_incident_types SET code = 'ACC-TRF-01', severity = 'critical', disables_vehicle = TRUE  WHERE name = 'Traffic accident'                AND code IS NULL;
    UPDATE vehicle_incident_types SET code = 'MNT-OVD-01', severity = 'minor',    disables_vehicle = FALSE WHERE name = 'Overdue preventive maintenance'  AND code IS NULL;
END $$;

-- A fresh database only runs data.sql (which already includes code/severity) — this only bites on
-- an old database being migrated. Anything else still NULL needs manual values before NOT NULL applies.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM vehicle_incident_types WHERE code IS NULL OR severity IS NULL) THEN
        RAISE EXCEPTION 'vehicle_incident_types has rows with no code/severity after backfill — set them manually, then re-run this migration';
    END IF;
END $$;

ALTER TABLE vehicle_incident_types
    ALTER COLUMN code     SET NOT NULL,
    ALTER COLUMN severity SET NOT NULL;

-- Postgres has no `ADD CONSTRAINT IF NOT EXISTS` — guard it manually, or a second run of this
-- migration (e.g. a retry after a partial failure elsewhere in the same batch) fails here.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_vehicle_incident_types_severity') THEN
        ALTER TABLE vehicle_incident_types
            ADD CONSTRAINT chk_vehicle_incident_types_severity CHECK (severity IN ('minor', 'moderate', 'critical'));
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_vehicle_incident_types_code ON vehicle_incident_types(code) WHERE deleted_at IS NULL;
