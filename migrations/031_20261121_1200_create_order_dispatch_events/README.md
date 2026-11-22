# create_order_dispatch_events

ST-69.1 (ES-69, RF-A36). The business history of each order and dispatch (creation, assignment, status changes) needs an immutable store. `dispatch_events` only covers dispatches and has no correlation or result, and `admin_audit_events` is for sensitive administrative actions, so this adds its own append-only table `order_dispatch_events` with the order reference, optional dispatch and route batch, actor and role, action, previous and new status, result, `correlation_id` and a sanitized `detail`.

**Immutability, in two layers:**
- Triggers block `UPDATE` always and `DELETE` unless `app.allow_event_purge = 'on'` (same escape hatch as `dispatch_events`, only for test cleanup). `TRUNCATE` is not blocked: it is a convention.
- Role `dispatch_app` (`NOLOGIN`) gets only `SELECT` and `INSERT`. The backend connection user must belong to it.

**Existing rows:** none; the table is new and nothing is copied from `dispatch_events` or `admin_audit_events` (no backfill). Actor and status columns are nullable so older events can be mapped later.

**`up.sql`** is idempotent. Creating the role needs a migration user with `CREATEROLE`.

**`down.sql`** drops the triggers, functions and table, and drops the role `dispatch_app` only if nothing else depends on it (otherwise it keeps it and raises a notice). History stored in the table is lost.
