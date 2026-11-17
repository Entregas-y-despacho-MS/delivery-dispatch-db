-- Reserva suave: una fila por despacho mientras un coordinador arma una ruta con él.
-- Vence sola cuando expires_at queda en el pasado; las filas vencidas se ignoran al leer.
CREATE TABLE dispatch_reservations (
    dispatch_id        INT             NOT NULL,                       -- despacho reservado
    reserved_by        INT             NOT NULL,                       -- coordinador que lo reservó
    reserved_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),         -- momento en que se reservó
    last_activity_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),         -- última actividad del coordinador (renueva la reserva)
    expires_at         TIMESTAMPTZ     NOT NULL,                       -- vencimiento = última actividad + order_reservation_ttl_minutes
    PRIMARY KEY (dispatch_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    FOREIGN KEY (reserved_by) REFERENCES users(user_id)          ON DELETE CASCADE
);

CREATE INDEX idx_dispatch_reservations_reserved_by ON dispatch_reservations(reserved_by);
CREATE INDEX idx_dispatch_reservations_expires_at  ON dispatch_reservations(expires_at);
