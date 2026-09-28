DROP INDEX IF EXISTS uq_vehicle_incident_types_code;
ALTER TABLE vehicle_incident_types DROP CONSTRAINT IF EXISTS chk_vehicle_incident_types_severity;
ALTER TABLE vehicle_incident_types
    DROP COLUMN IF EXISTS code,
    DROP COLUMN IF EXISTS severity,
    DROP COLUMN IF EXISTS disables_vehicle;
