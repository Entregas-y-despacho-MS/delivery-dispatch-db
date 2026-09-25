-- RF-A28: the user list shows each user's last access date. Nothing recorded it until now.
--
-- Nullable on purpose: NULL means "has never logged in", and existing users start as NULL (their
-- past logins were never tracked), so no backfill is needed.
-- Idempotent (IF NOT EXISTS): if the database was created from scratch with the already-updated
-- schema, this migration does nothing instead of failing on a duplicate column.

ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
