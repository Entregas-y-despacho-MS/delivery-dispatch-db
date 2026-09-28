-- RF-A33, Escenario 3 — the story's own acceptance criteria checks duplicates by "nombre o código"
-- (name or code), which migration 005 missed: it only added description/category/active, no code.
-- Adds the same unique reference code the sibling incident_reasons catalog has (migration 004).
ALTER TABLE reschedule_reasons
    ADD COLUMN IF NOT EXISTS code VARCHAR(30);

-- Placeholder for any row created before this migration (there were none seeded, but the team has
-- had this catalog live in `test` since migration 005 — a teammate may have already created real
-- rows through the API). A real code should replace this manually before it matters in practice;
-- the point here is only that the column can safely become NOT NULL below.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT reschedule_reason_id FROM reschedule_reasons WHERE code IS NULL LOOP
        UPDATE reschedule_reasons SET code = 'RES-' || r.reschedule_reason_id WHERE reschedule_reason_id = r.reschedule_reason_id;
    END LOOP;
END $$;

ALTER TABLE reschedule_reasons ALTER COLUMN code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_reschedule_reasons_code ON reschedule_reasons(code) WHERE deleted_at IS NULL;
