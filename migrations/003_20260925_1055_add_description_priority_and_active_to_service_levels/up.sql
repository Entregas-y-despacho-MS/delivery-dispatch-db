-- RF-A31: service levels need a description, a priority hierarchy and an enabled/disabled state.
--
-- description: optional free text.
-- active: TRUE = can be assigned to new orders. Same DEFAULT as schema/, so existing levels
--         simply start enabled.
-- priority_level: 1 = highest priority. It is NOT NULL, so levels that already exist need a value:
--         they are ranked by target time (the shortest target time gets the highest priority),
--         which is the order the hierarchy would naturally have. The backfill runs only when the
--         column is actually being added: on a database created from scratch with the already-updated
--         schema the column exists, so this migration leaves the existing priorities untouched.
-- Idempotent: safe to run on a database that already has these columns.

ALTER TABLE service_levels ADD COLUMN IF NOT EXISTS description VARCHAR(255);

ALTER TABLE service_levels ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = current_schema() AND table_name = 'service_levels' AND column_name = 'priority_level'
    ) THEN
        ALTER TABLE service_levels
            ADD COLUMN priority_level SMALLINT NOT NULL DEFAULT 1
            CONSTRAINT chk_service_levels_priority_level CHECK (priority_level >= 1);

        UPDATE service_levels sl
        SET priority_level = ranked.position
        FROM (
            SELECT service_level_id,
                   ROW_NUMBER() OVER (ORDER BY target_time_min, service_level_id)::SMALLINT AS position
            FROM service_levels
        ) ranked
        WHERE sl.service_level_id = ranked.service_level_id;

        ALTER TABLE service_levels ALTER COLUMN priority_level DROP DEFAULT;
    END IF;
END
$$;
