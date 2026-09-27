-- RF-A32 — service parametrization for the incident reasons catalog: a unique reference code (e.g.
-- INC-CLI-AUS), whether logging that reason requires photographic evidence, and whether it can
-- still be assigned to new reports (deactivating one must not touch the incidents that already
-- reference it — same "active" pattern as service_levels, migration 003).
ALTER TABLE incident_reasons
    ADD COLUMN IF NOT EXISTS code             VARCHAR(30),
    ADD COLUMN IF NOT EXISTS requires_evidence BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS active            BOOLEAN NOT NULL DEFAULT TRUE;

-- Backfill for the 3 reasons already seeded (data.sql) — placeholders picked for an old, unmanaged
-- database that pre-dates this migration; edit them to match the real operational codes before
-- running this in a shared environment. All 3 stay active.
DO $$
BEGIN
    UPDATE incident_reasons SET code = 'INC-CUST-ABSENT', requires_evidence = FALSE WHERE name = 'Customer absent'  AND code IS NULL;
    UPDATE incident_reasons SET code = 'INC-ADDR-INVALID', requires_evidence = FALSE WHERE name = 'Incorrect address' AND code IS NULL;
    UPDATE incident_reasons SET code = 'INC-PROD-DAMAGED', requires_evidence = TRUE  WHERE name = 'Damaged product'   AND code IS NULL;
END $$;

-- A fresh database only runs data.sql (which already includes code) — this only bites on an
-- old database being migrated. Anything else still NULL needs a manual code before NOT NULL applies.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM incident_reasons WHERE code IS NULL) THEN
        RAISE EXCEPTION 'incident_reasons has rows with no code after backfill — set one manually, then re-run this migration';
    END IF;
END $$;

ALTER TABLE incident_reasons ALTER COLUMN code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_incident_reasons_code ON incident_reasons(code) WHERE deleted_at IS NULL;
