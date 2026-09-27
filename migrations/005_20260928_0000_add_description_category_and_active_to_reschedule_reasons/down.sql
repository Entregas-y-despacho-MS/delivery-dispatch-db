ALTER TABLE reschedule_reasons DROP CONSTRAINT IF EXISTS chk_reschedule_reasons_category;
ALTER TABLE reschedule_reasons
    DROP COLUMN IF EXISTS description,
    DROP COLUMN IF EXISTS category,
    DROP COLUMN IF EXISTS active;
