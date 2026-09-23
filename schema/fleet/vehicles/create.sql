CREATE TABLE vehicles (
    vehicle_id           SERIAL,
    vehicle_status_id    INT             NOT NULL,                        -- estado actual del vehículo
    type                 VARCHAR(50)     NOT NULL,                        -- tipo de vehículo (moto, camioneta, etc.)
    model                VARCHAR(100)    NOT NULL,                        -- modelo del vehículo
    plate                VARCHAR(15)     NOT NULL,                        -- placa
    capacity_kg          NUMERIC(10,2)   NOT NULL,                        -- capacidad de carga en kg, misma unidad que dispatches.estimated_weight_kg
    capacity_m3          NUMERIC(10,2)   NOT NULL,                        -- capacidad volumétrica en metros cúbicos
    deleted_at           TIMESTAMPTZ,                                     -- baja permanente de la flota (soft delete); vehicle_status_id sigue siendo el estado operativo (activo/mantenimiento/fuera_de_servicio)
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vehicle_id),
    FOREIGN KEY (vehicle_status_id) REFERENCES vehicle_statuses(vehicle_status_id)
);

CREATE INDEX idx_vehicles_status_id ON vehicles(vehicle_status_id);
CREATE UNIQUE INDEX uq_vehicles_plate ON vehicles(plate) WHERE deleted_at IS NULL;
