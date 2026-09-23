-- RF-A30: the fleet user story requires registering the vehicle model and its volumetric capacity
-- (m3) in addition to plate, type and kg.
--
-- Each new column is NOT NULL, so it is first added with a temporary DEFAULT (so rows that already
-- exist get a value) and the DEFAULT is dropped right after - same as in schema/, where the column
-- has no default and every insert must provide it.
-- Idempotent (IF NOT EXISTS): if the database was created from scratch with the already-updated
-- schema, this migration does nothing instead of failing on a duplicate column.

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS model VARCHAR(100) NOT NULL DEFAULT 'Unspecified';
ALTER TABLE vehicles ALTER COLUMN model DROP DEFAULT;

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS capacity_m3 NUMERIC(10,2) NOT NULL DEFAULT 0;
ALTER TABLE vehicles ALTER COLUMN capacity_m3 DROP DEFAULT;
