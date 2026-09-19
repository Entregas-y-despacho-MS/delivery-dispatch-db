CREATE TABLE vehicle_incident_types (
    vehicle_incident_type_id  SERIAL,
    name                      VARCHAR(100)  NOT NULL,                      -- descripción del tipo de incidente de vehículo
    deleted_at                TIMESTAMPTZ,                                 -- soft delete
    created_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vehicle_incident_type_id)
);

CREATE UNIQUE INDEX uq_vehicle_incident_types_name ON vehicle_incident_types(name) WHERE deleted_at IS NULL;
