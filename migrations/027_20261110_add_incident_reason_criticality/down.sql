ALTER TABLE incident_reasons
    DROP CONSTRAINT IF EXISTS chk_incident_reasons_criticality,
    DROP COLUMN IF EXISTS criticality;
