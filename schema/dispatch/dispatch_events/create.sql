-- Tabla de log append-only: a diferencia del resto de las tablas del proyecto, no lleva
-- updated_at porque un evento ya registrado nunca se modifica.
CREATE TABLE dispatch_events (
    dispatch_event_id  SERIAL,
    dispatch_id          INT             NOT NULL,                        -- despacho al que corresponde el evento
    event_type            VARCHAR(50)     NOT NULL,                        -- created | assigned | status_changed | ...
    detail                  TEXT,                                            -- detalle libre del evento (ej. estado anterior -> nuevo)
    client_event_id       UUID,                                            -- id generado por la app móvil offline (RF-U13); NULL en eventos generados por el propio backend
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_event_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE
);

CREATE INDEX idx_dispatch_events_dispatch_id ON dispatch_events(dispatch_id);

-- Único solo cuando está presente: permite reintentar el mismo evento offline sin duplicarlo
-- (RF-U13, Escenario 3), sin exigirle un valor a los eventos que genera el propio backend.
CREATE UNIQUE INDEX uq_dispatch_events_client_event_id ON dispatch_events(client_event_id) WHERE client_event_id IS NOT NULL;
