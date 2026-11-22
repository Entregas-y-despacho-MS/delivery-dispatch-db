DROP TRIGGER IF EXISTS trg_order_dispatch_events_prevent_delete ON order_dispatch_events;
DROP TRIGGER IF EXISTS trg_order_dispatch_events_prevent_update ON order_dispatch_events;
DROP FUNCTION IF EXISTS fn_order_dispatch_events_prevent_delete();
DROP FUNCTION IF EXISTS fn_order_dispatch_events_prevent_update();

-- Dropping the table also removes its grants.
DROP TABLE IF EXISTS order_dispatch_events;

-- The role is cluster-wide: drop it only if this migration created it (marker comment)
-- and nothing else depends on it.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_roles r
        WHERE r.rolname = 'dispatch_app'
          AND shobj_description(r.oid, 'pg_authid') = 'created by migration 031_create_order_dispatch_events'
          AND NOT EXISTS (SELECT 1 FROM pg_auth_members m WHERE m.roleid = r.oid)
    ) THEN
        BEGIN
            DROP ROLE dispatch_app;
        EXCEPTION WHEN dependent_objects_still_exist THEN
            RAISE NOTICE 'dispatch_app still has dependencies; the role was kept';
        END;
    END IF;
END $$;
