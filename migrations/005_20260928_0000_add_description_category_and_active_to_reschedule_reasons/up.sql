-- RF-A33 — service parametrization for the reschedule/reassignment reasons catalog: an optional
-- description, the origin/responsibility category (Escenario 2 — a `client` reason marks the
-- delay as not counting against the team's internal punctuality metric, once a reschedule actually
-- using this reason is recorded), and whether the reason is still assignable to new reschedules.
ALTER TABLE reschedule_reasons
    ADD COLUMN IF NOT EXISTS description VARCHAR(255),
    ADD COLUMN IF NOT EXISTS category    VARCHAR(20),
    ADD COLUMN IF NOT EXISTS active      BOOLEAN NOT NULL DEFAULT TRUE;

-- No seeded rows exist yet (reschedule_reasons.data.sql has none — "administrado por el
-- coordinador"), so there is nothing to backfill; category only needs to become NOT NULL.
ALTER TABLE reschedule_reasons ALTER COLUMN category SET NOT NULL;

ALTER TABLE reschedule_reasons
    ADD CONSTRAINT chk_reschedule_reasons_category CHECK (category IN ('client', 'operations', 'force_majeure'));
