-- ST-48.2 — reserva suave de pedidos mientras un coordinador arma una ruta.
-- Una fila por despacho reservado; la reserva vence sola cuando expires_at queda en el pasado
-- (las filas vencidas se ignoran al leer y se reemplazan al reservar de nuevo).
CREATE TABLE IF NOT EXISTS dispatch_reservations (
    dispatch_id        INT             NOT NULL,
    reserved_by        INT             NOT NULL,
    reserved_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    last_activity_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ     NOT NULL,
    PRIMARY KEY (dispatch_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    FOREIGN KEY (reserved_by) REFERENCES users(user_id)          ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dispatch_reservations_reserved_by ON dispatch_reservations(reserved_by);
CREATE INDEX IF NOT EXISTS idx_dispatch_reservations_expires_at  ON dispatch_reservations(expires_at);

INSERT INTO settings (setting_key, setting_value, description)
VALUES ('order_reservation_ttl_minutes', '15', 'Minutes a soft order reservation lasts without coordinator activity')
ON CONFLICT (setting_key) DO NOTHING;
