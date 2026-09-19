-- ==========================================================
-- FULL RESET — drops everything and reloads from schema/
-- Use only on empty or development environments.
-- ==========================================================

DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

\i schema/init.sql
