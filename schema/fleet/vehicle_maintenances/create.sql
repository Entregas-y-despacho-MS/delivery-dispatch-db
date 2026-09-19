CREATE TABLE vehicle_maintenances (
    vehicle_maintenance_id    SERIAL,
    vehicle_id                INT             NOT NULL,                   -- vehículo al que corresponde
    vehicle_incident_type_id  INT,                                        -- tipo de incidente asociado (NULL = mantenimiento rutinario)
    description                TEXT            NOT NULL,                   -- detalle del mantenimiento o incidente
    status                     VARCHAR(20)     NOT NULL DEFAULT 'pending',  -- pending | in_progress | completed
    scheduled_at               TIMESTAMPTZ,                                -- fecha programada
    completed_at               TIMESTAMPTZ,                                -- fecha de finalización real
    created_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vehicle_maintenance_id),
    FOREIGN KEY (vehicle_id)               REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (vehicle_incident_type_id) REFERENCES vehicle_incident_types(vehicle_incident_type_id),
    CONSTRAINT chk_vehicle_maintenances_status CHECK (status IN ('pending', 'in_progress', 'completed'))
);

CREATE INDEX idx_vehicle_maintenances_vehicle_id ON vehicle_maintenances(vehicle_id);
CREATE INDEX idx_vehicle_maintenances_incident_type_id ON vehicle_maintenances(vehicle_incident_type_id);
