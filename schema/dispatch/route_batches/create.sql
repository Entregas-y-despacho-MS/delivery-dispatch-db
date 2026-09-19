CREATE TABLE route_batches (
    route_batch_id  SERIAL,
    driver_id       INT,                    -- repartidor asignado a la ruta; NULL hasta asignar
    vehicle_id      INT,                    -- vehículo asignado a la ruta; NULL hasta asignar
    shift_date      DATE NOT NULL,          -- fecha/turno de la ruta
    route_geometry  TEXT,                   -- polyline codificado del recorrido calculado por OSRM, cacheado
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_batch_id),
    FOREIGN KEY (driver_id)  REFERENCES users(user_id)       ON DELETE SET NULL,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE SET NULL
);

CREATE INDEX idx_route_batches_driver_id  ON route_batches(driver_id);
CREATE INDEX idx_route_batches_vehicle_id ON route_batches(vehicle_id);
CREATE INDEX idx_route_batches_shift_date ON route_batches(shift_date);
