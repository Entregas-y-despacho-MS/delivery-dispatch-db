# create_customer_notifications

ST-39.2 (ES-39, RF-U16) — records each customer email with its delivery state, so the backend sends it
once per event and can recover it when the provider fails.

## Why it was needed

ST-39.1 reserved the email in `dispatch_events`, which is append-only (a trigger blocks `UPDATE`): it
cannot hold an attempts counter or a state that changes, and uniqueness depended on an advisory lock and a
`NOT EXISTS`, not on an index. A table of its own allows a unique idempotency key and a recovery sweep by state.

## What changes

| Object | Change |
|---|---|
| `customer_notifications` | New table. |
| `uq_customer_notifications_idempotency_key` | Unique index on `idempotency_key` (notification type + source event): two deliveries of the same event leave one row. |
| `idx_customer_notifications_pending` | Partial index on `next_attempt_at` (`status IN ('sending','retrying')`) for the recovery sweep. |
| `chk_customer_notifications_sent_at` | `sent_at` is present if and only if `status = 'sent'`. |
| `trg_customer_notifications_set_updated_at` | Keeps `updated_at`. |

## Existing rows

None: the table is new. The `customer_status_notice_*` events that ST-39.1 left in `dispatch_events`
stay as history and are not migrated.

## Deleting dispatches

The foreign key to `dispatches` is `ON DELETE RESTRICT`: a dispatch with notifications cannot be deleted
physically. The application never deletes dispatches; any data cleanup (test seeds, e2e suites) must delete
the dispatch's `customer_notifications` rows first.

## `down.sql`

Drops the trigger, the function and the table. There is no backfill to revert, but **the rollback loses the
recorded notifications** (state, attempts and errors): the table has no copy elsewhere.
