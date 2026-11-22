# extend_delivery_complaint_cases_with_investigation

ST-45.1 (ES-45, RF-U22). The complaint case received from the CRM (ST-298.2, migration `030`) now also stores its investigation and RMA correlation, so ES-45 can show an inbox, assign the case, record findings and issue a verdict. The inbox is **not** duplicated: `delivery_complaint_cases` keeps the unique keys `(source, crm_case_id)` and `message_id`, and `reason_code`, `case_version`, `dispatch_id` and `consumed_at` (the received-at instant) are reused.

**New columns (all nullable except the status):** `investigation_status` (`received` | `assigned` | `in_investigation` | `decided`, independent of `intake_status`), `assigned_user_id` / `assigned_at`, `investigation_started_at`, `verdict` (`no_return_required` | `not_confirmed` | `request_RMA`), `decision_reason`, `findings` (sanitized text, up to 4000 characters), `decided_by_user_id` / `decided_at`, `authorization_request_id` and `rma_id`.

**Integrity:** `CHECK`s keep the lifecycle coherent (assignment before investigation, start instant, verdict + actor + instant + reason all present when `decided` and all absent otherwise, RMA references only with `request_RMA`). Both user columns are `RESTRICT` foreign keys to `users`. `authorization_request_id` and `rma_id` are unique when present; there is no FK to `rma_sync_states` because the case references the RMA before Inventory syncs it.

**Indexes:** `(investigation_status, consumed_at DESC)` and `(dispatch_id, investigation_status)` for the inbox queries, plus partial indexes on the two user FKs. The `dispatch_id` index from `030` is kept.

**Existing rows:** kept. They get `investigation_status = 'received'` and every other new column NULL, which satisfies all the checks. No backfill. The `DEFAULT 'received'` of `investigation_status` is permanent (it is the legitimate initial state, not a temporary backfill default). The assignment check only requires the assignee when the status is not `received`; it does not forbid keeping one on a `received` case. The verdict value `request_RMA` keeps the casing of the ES-45 story.

**`up.sql`** is idempotent (`ADD COLUMN IF NOT EXISTS`, guarded constraints, `CREATE ... IF NOT EXISTS`).

**`down.sql`** drops the indexes, constraints and columns in reverse order. The investigation, verdict and RMA references stored in those columns are lost; the inbox columns from `030` are untouched.
