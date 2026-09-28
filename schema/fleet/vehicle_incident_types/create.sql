CREATE TABLE vehicle_incident_types (
    vehicle_incident_type_id  SERIAL,
    code                      VARCHAR(30)   NOT NULL,                      -- unique reference code (ej. MEC-FRE-01)
    name                      VARCHAR(100)  NOT NULL,                      -- descripción del tipo de incidente de vehículo
    severity                  VARCHAR(20)   NOT NULL,                      -- minor | moderate | critical
    disables_vehicle          BOOLEAN       NOT NULL DEFAULT FALSE,        -- registrar un incidente de este tipo pasa el vehículo a maintenance de inmediato
    deleted_at                TIMESTAMPTZ,                                 -- soft delete
    created_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vehicle_incident_type_id),
    CONSTRAINT chk_vehicle_incident_types_severity CHECK (severity IN ('minor', 'moderate', 'critical'))
);

CREATE UNIQUE INDEX uq_vehicle_incident_types_name ON vehicle_incident_types(name) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_vehicle_incident_types_code ON vehicle_incident_types(code) WHERE deleted_at IS NULL;
