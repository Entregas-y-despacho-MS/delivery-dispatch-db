-- ==========================================================
-- SCHEMA LOAD ORDER
-- Paths are always from the project root. Dependencies first.
-- ==========================================================

-- Standalone: sin dependencias
\i schema/settings/init.sql

-- Grupos, en orden de dependencia:
-- auth      -> sin dependencias externas
-- fleet     -> depende de auth (ninguna, en realidad no depende de auth; independiente)
-- catalog   -> sin dependencias externas
-- dispatch  -> depende de auth (users), fleet (vehicles) y catalog (zones, service_levels)
-- audit     -> depende de auth (users)
\i schema/auth/init.sql
\i schema/fleet/init.sql
\i schema/catalog/init.sql
\i schema/dispatch/init.sql
-- messaging/pending_* references dispatches after consolidation
\i schema/messaging/init.sql
\i schema/audit/init.sql
-- operational_alerts: standalone, references auth (users), fleet (vehicles), catalog (zones) and dispatch (dispatches)
\i schema/operational_alerts/init.sql
