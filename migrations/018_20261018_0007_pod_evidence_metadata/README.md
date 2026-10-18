# pod_evidence_metadata

ST-31.5 (Jira subtask ES-200 under ES-31) completes the POD evidence metadata and configures the
operational incident reasons used by ES-32. It also adds the customer package rejection reason,
which requires evidence and counts as a delivery attempt. Its Spanish display name follows the
task wording.

## What changes

- Adds optional capture and receiver metadata to `delivery_evidences`.
- Clears any existing plaintext value from `otp_code` and adds a constraint that keeps the column
  `NULL`. The deleted OTP values cannot be recovered by `down.sql`; rollback removes the constraint
  but does not restore secret values.
- Constrains latitude to −90…90 and longitude to −180…180.
- Sets `requires_evidence = TRUE` for operational customer incident reasons. It sets
  `counts_as_attempt = TRUE` for `INC-CUST-REJECTED` even when that reason already exists.
- Rejects an active code/name collision with a clear error instead of silently selecting a different
  catalog row.
- Keeps `incomplete_order_alert_minutes = 60` as an idempotent compatibility guard. Migration 011
  already owns and seeds this key; this migration does not replace a configured value.

## Rollback

`up.sql` records the prior flags for pre-existing incident reasons in a migration state table.
`down.sql` restores those values, including the original `requires_evidence` values for
`INC-CUST-ABSENT` and `INC-ADDR-INVALID`; this intentionally overwrites changes made to those flags
after migration 018. A reason inserted by this migration is retired with `active = FALSE` and
`deleted_at` instead of being hard-deleted, so incident history remains valid. The migration state
table is removed. The setting remains because migration 011 owns it.
