CREATE TABLE route_batches (
    route_batch_id       SERIAL,
    status               VARCHAR(30)     NOT NULL,                -- ciclo de vida del lote: provisional | pending_final_review | confirmed | in_execution | closed | cancelled
    version              INT             NOT NULL DEFAULT 0,      -- versión de planificación: solo cambia al aprobar, mover, fusionar o congelar
    driver_id            INT,                                     -- repartidor asignado a la ruta; NULL hasta asignar
    vehicle_id           INT,                                     -- vehículo asignado a la ruta; NULL hasta asignar
    proposed_driver_id   INT,                                     -- repartidor propuesto por el generador antes de la 2.ª aprobación
    reviewer_user_id     INT,                                     -- coordinador que revisa y aprueba el lote
    delivery_zone_id     INT,                                     -- zona de reparto del lote; NULL en lotes manuales anteriores al plan
    origin_warehouse_id  INT,                                     -- almacén desde el que sale el lote
    shift_date           DATE NOT NULL,                           -- fecha/turno de la ruta
    route_geometry       TEXT,                                    -- polyline codificado del recorrido calculado por OSRM, cacheado
    accepted_at          TIMESTAMPTZ,                             -- momento en que el repartidor aceptó el lote y cotejó la carga
    closed_at            TIMESTAMPTZ,                             -- momento en que el lote pasó a closed
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_batch_id),
    FOREIGN KEY (driver_id)           REFERENCES users(user_id)                  ON DELETE SET NULL,
    FOREIGN KEY (vehicle_id)          REFERENCES vehicles(vehicle_id)            ON DELETE SET NULL,
    FOREIGN KEY (proposed_driver_id)  REFERENCES users(user_id)                  ON DELETE SET NULL,
    FOREIGN KEY (reviewer_user_id)    REFERENCES users(user_id)                  ON DELETE SET NULL,
    FOREIGN KEY (delivery_zone_id)    REFERENCES delivery_zones(delivery_zone_id),
    FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id),
    CONSTRAINT chk_route_batches_status CHECK (status IN ('provisional', 'pending_final_review', 'confirmed', 'in_execution', 'closed', 'cancelled'))
);

CREATE INDEX idx_route_batches_driver_id           ON route_batches(driver_id);
CREATE INDEX idx_route_batches_vehicle_id          ON route_batches(vehicle_id);
CREATE INDEX idx_route_batches_shift_date          ON route_batches(shift_date);
CREATE INDEX idx_route_batches_status              ON route_batches(status);
CREATE INDEX idx_route_batches_delivery_zone_id    ON route_batches(delivery_zone_id);
CREATE INDEX idx_route_batches_origin_warehouse_id ON route_batches(origin_warehouse_id);
CREATE INDEX idx_route_batches_proposed_driver_id  ON route_batches(proposed_driver_id);
CREATE INDEX idx_route_batches_reviewer_user_id    ON route_batches(reviewer_user_id);

-- Un vehículo o un conductor no puede estar en dos lotes vigentes (no cancelados) el mismo día.
CREATE UNIQUE INDEX uq_route_batches_vehicle_shift_date ON route_batches(vehicle_id, shift_date)
    WHERE vehicle_id IS NOT NULL AND status <> 'cancelled';
CREATE UNIQUE INDEX uq_route_batches_driver_shift_date ON route_batches(driver_id, shift_date)
    WHERE driver_id IS NOT NULL AND status <> 'cancelled';
