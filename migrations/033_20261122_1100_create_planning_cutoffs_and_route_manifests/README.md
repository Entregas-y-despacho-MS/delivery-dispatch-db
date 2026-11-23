# create_planning_cutoffs_and_route_manifests

ST-302.2 (ES-302, Dashboard 2: planning and route execution). Coverage at the cutoff and stop completion must be reproducible: the same cutoff has to return the same denominator even after the route advances. Today the cutoff, the final approval and the route start overwrite the current state and keep nothing frozen, so this adds four append-only history tables in the `dispatch` group.

- `planning_cutoffs`: one row per cutoff run that left a snapshot (day, UTC instant, operating timezone, `scheduled`/`manual`, and the scheduled `occurrence`, unique so a repeated run never rewrites the first snapshot).
- `planning_cutoff_dispatches`: the universe of that cutoff. Each dispatch read is `eligible` or `excluded`; an exclusion always carries a code and a readable explanation (a CHECK enforces it). It also keeps the batch, route version, type, zone, warehouse and window start the dispatch had at the cutoff, so the dashboard filters stay reproducible.
- `route_manifests`: a frozen picture of a route at the second approval (`confirmed`), at route start (`started`, at most one per batch: the baseline to measure completion) or after a later change (`revised`, with a reason). A change adds a new `manifest_version`; nothing is rewritten.
- `route_manifest_stops`: the stops of each manifest, `planned`, `departing` or `excluded` (with the exclusion code, e.g. a failed package check).

**Immutability:** `UPDATE` is always blocked by trigger; `DELETE` only with `SET app.allow_event_purge = 'on'`, the same escape hatch as `route_batch_events` (test cleanup).

**Existing rows:** none. There is deliberately no backfill: batches and cutoffs before this migration have no snapshot and read as unknown (N/D), instead of being rebuilt from today's statuses.

**Rules the database cannot check** (they cross tables and are enforced by the backend): `confirmed` manifests use `planned` stops, `started` and `revised` use `departing`/`excluded`; "the official cutoff of a day is the first scheduled one" is a reading rule, not a constraint.

**`up.sql`** is idempotent (`IF NOT EXISTS`, `CREATE OR REPLACE`, `DROP TRIGGER IF EXISTS`). **`down.sql`** drops triggers, functions and tables in reverse order; the history stored in them is lost.
