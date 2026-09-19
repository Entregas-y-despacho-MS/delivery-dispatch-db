-- Tabla de log append-only: a diferencia del resto de las tablas del proyecto, no lleva
-- updated_at porque una reprogramación ya registrada nunca se modifica.
-- Cubre tanto reprogramación (cambio de ventana horaria, RF-A05) como reasignación
-- (cambio de ruta ante contingencias, RF-A16) — reschedule_reasons (RF-A33) agrupa los
-- motivos de ambas. Una fila puede cambiar la ventana, la ruta, o las dos cosas.
CREATE TABLE dispatch_reschedules (
    dispatch_reschedule_id   SERIAL,
    dispatch_id              INT NOT NULL,                   -- despacho reprogramado/reasignado
    reschedule_reason_id     INT NOT NULL,                   -- motivo de la reprogramación o reasignación
    rescheduled_by           INT,                            -- usuario que la ejecutó; NULL si fue automática
    previous_route_batch_id  INT,                            -- ruta anterior (NULL si no cambió de ruta, o no tenía ruta asignada)
    new_route_batch_id       INT,                            -- ruta nueva (NULL si no cambió de ruta)
    previous_window_start    TIMESTAMPTZ,                    -- ventana horaria anterior (inicio)
    previous_window_end      TIMESTAMPTZ,                    -- ventana horaria anterior (fin)
    new_window_start         TIMESTAMPTZ,                    -- nueva ventana horaria (inicio); NULL si el cambio fue solo de ruta
    new_window_end           TIMESTAMPTZ,                    -- nueva ventana horaria (fin); NULL si el cambio fue solo de ruta
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_reschedule_id),
    FOREIGN KEY (dispatch_id)             REFERENCES dispatches(dispatch_id)                 ON DELETE CASCADE,
    FOREIGN KEY (reschedule_reason_id)    REFERENCES reschedule_reasons(reschedule_reason_id),
    FOREIGN KEY (rescheduled_by)          REFERENCES users(user_id)                          ON DELETE SET NULL,
    FOREIGN KEY (previous_route_batch_id) REFERENCES route_batches(route_batch_id)           ON DELETE SET NULL,
    FOREIGN KEY (new_route_batch_id)      REFERENCES route_batches(route_batch_id)           ON DELETE SET NULL,
    CONSTRAINT chk_dispatch_reschedules_has_change CHECK (
        new_window_start IS NOT NULL OR new_route_batch_id IS NOT NULL
    )
);

CREATE INDEX idx_dispatch_reschedules_dispatch_id ON dispatch_reschedules(dispatch_id);
CREATE INDEX idx_dispatch_reschedules_reschedule_reason_id ON dispatch_reschedules(reschedule_reason_id);
CREATE INDEX idx_dispatch_reschedules_rescheduled_by ON dispatch_reschedules(rescheduled_by);
CREATE INDEX idx_dispatch_reschedules_previous_route_batch_id ON dispatch_reschedules(previous_route_batch_id);
CREATE INDEX idx_dispatch_reschedules_new_route_batch_id ON dispatch_reschedules(new_route_batch_id);
