-- Grupo dispatch (núcleo del microservicio):
-- 1. sus propios catálogos (types, statuses)
-- 2. route_batches (depende de auth/users y fleet/vehicles; dispatches depende de ella)
-- 3. dispatches (depende de catalog/, fleet/, auth/, route_batches y de sus propios catálogos)
-- 4. tablas hijas de dispatches (route_batch_events va al final: depende de route_batches y dispatches)
\i schema/dispatch/dispatch_types/init.sql
\i schema/dispatch/dispatch_statuses/init.sql
\i schema/dispatch/route_batches/init.sql
\i schema/dispatch/dispatches/init.sql
\i schema/dispatch/dispatch_pickup_items/init.sql
\i schema/dispatch/dispatch_packages/init.sql
\i schema/dispatch/warehouse_receipts/init.sql
\i schema/dispatch/warehouse_receipt_items/init.sql
\i schema/dispatch/dispatch_reservations/init.sql
\i schema/dispatch/delivery_evidences/init.sql
\i schema/dispatch/dispatch_incidents/init.sql
\i schema/dispatch/dispatch_ratings/init.sql
\i schema/dispatch/dispatch_complaints/init.sql
\i schema/dispatch/dispatch_events/init.sql
\i schema/dispatch/customer_notifications/init.sql
\i schema/dispatch/dispatch_reschedules/init.sql
\i schema/dispatch/route_batch_events/init.sql
