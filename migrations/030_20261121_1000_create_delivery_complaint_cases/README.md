# create_delivery_complaint_cases

ST-298.2 (ES-298) — persists the CRM delivery complaint received through Pub/Sub as a single case, so the
backend (ST-298.3) consumes it once and acknowledges it asynchronously.

## Why it was needed

The simulated CRM publishes `crm.delivery_complaint.opened`. Dispatch must keep the message and the case
idempotently, tie the case to one specific dispatch and remember whether the `received` acknowledgement was
published. `inbound_messages` only logs receipt; it holds neither the case nor its dispatch. ST-45.1 (ES-45)
extends this table with the investigation (verdict, findings, assignee, RMA references); it does not create
a second inbox. `dispatch_complaints` (the plain portal complaint) is left untouched.

## What changes

| Object | Change |
|---|---|
| `delivery_complaint_cases` | New table. |
| `uq_delivery_complaint_cases_message_id` | One row per `message_id`. |
| `uq_delivery_complaint_cases_source_crm_case_id` | Functional key: one case per `(source, crm_case_id)`. |
| `idx_delivery_complaint_cases_dispatch_id` | FK index, lookups by dispatch. |
| `idx_delivery_complaint_cases_pending_ack` | Partial index (`intake_status = 'received'`) for recovering unpublished acknowledgements. |
| `chk_delivery_complaint_cases_*` | `case_version >= 1`; `reason_code` pattern of the contract; `affected_items` is an array of 1 to 100; `intake_status` in (`received`, `acknowledged`); `acknowledged_at` present if and only if `acknowledged`. |
| `trg_delivery_complaint_cases_set_updated_at` | Keeps `updated_at`. |

## Existing rows

None: the table is new. Rejected, invalid or ambiguous messages never reach it (they stay in
`inbound_messages` as `rejected`).

## Notes

- `message_id` is the last message applied to the case: a higher `case_version` updates the row and its
  `message_id`. Redelivery of an older `messageId` is stopped by `inbound_messages` (its primary key), not here.
- That `dispatch_id` and `tracking_code` refer to the same dispatch is validated by the backend.
- `dispatch_id` is `ON DELETE RESTRICT`: a dispatch with complaint cases cannot be deleted physically.
  Data cleanups (test seeds, e2e) must delete the dispatch's cases first.

## `down.sql`

Drops the trigger, the function and the table. There is no backfill to revert, but **the rollback loses the
received cases** (and their acknowledgement state): the table has no copy elsewhere.
