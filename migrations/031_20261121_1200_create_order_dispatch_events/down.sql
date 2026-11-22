REVOKE ALL ON order_dispatch_events FROM dispatch_app;

DROP TRIGGER IF EXISTS trg_order_dispatch_events_prevent_delete ON order_dispatch_events;
DROP TRIGGER IF EXISTS trg_order_dispatch_events_prevent_update ON order_dispatch_events;
DROP FUNCTION IF EXISTS fn_order_dispatch_events_prevent_delete();
DROP FUNCTION IF EXISTS fn_order_dispatch_events_prevent_update();

DROP TABLE IF EXISTS order_dispatch_events;

-- The role is cluster-wide: drop it only when nothing else depends on it.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dispatch_app') THEN
        BEGIN
            DROP ROLE dispatch_app;
        EXCEPTION WHEN dependent_objects_still_exist THEN
            RAISE NOTICE 'dispatch_app still has dependencies; the role was kept';
        END;
    END IF;
END $$;
