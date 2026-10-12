-- Tabla de log append-only: a diferencia del resto de las tablas del proyecto, no lleva
-- updated_at porque un evento ya registrado nunca se modifica. La inmutabilidad la imponen dos
-- triggers (UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on', para limpieza
-- de pruebas). TRUNCATE no se bloquea: es convención.
CREATE TABLE dispatch_events (
    dispatch_event_id  SERIAL,
    dispatch_id          INT             NOT NULL,                        -- despacho al que corresponde el evento
    event_type            VARCHAR(50)     NOT NULL,                        -- created | assigned | status_changed | ...
    detail                  TEXT,                                            -- detalle libre del evento (ej. estado anterior -> nuevo)
    client_event_id       UUID,                                            -- id generado por la app móvil offline (RF-U13); NULL en eventos generados por el propio backend
    actor_user_id         INT,                                             -- usuario que originó el evento; NULL si lo generó el sistema o el cliente
    actor_type            VARCHAR(20),                                     -- user | system | customer; NULL en eventos anteriores a la migración 013
    reason                TEXT,                                            -- motivo declarado del evento
    metadata              JSONB,                                           -- valor anterior y nuevo, versión, resultado
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_event_id),
    FOREIGN KEY (dispatch_id)   REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    FOREIGN KEY (actor_user_id) REFERENCES users(user_id)          ON DELETE RESTRICT,
    CONSTRAINT chk_dispatch_events_actor_type CHECK (actor_type IN ('user', 'system', 'customer'))
);

CREATE INDEX idx_dispatch_events_dispatch_id   ON dispatch_events(dispatch_id);
CREATE INDEX idx_dispatch_events_actor_user_id ON dispatch_events(actor_user_id);

-- Único solo cuando está presente: permite reintentar el mismo evento offline sin duplicarlo
-- (RF-U13, Escenario 3), sin exigirle un valor a los eventos que genera el propio backend.
CREATE UNIQUE INDEX uq_dispatch_events_client_event_id ON dispatch_events(client_event_id) WHERE client_event_id IS NOT NULL;

CREATE FUNCTION fn_dispatch_events_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'dispatch_events is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_dispatch_events_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'dispatch_events is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dispatch_events_prevent_update
    BEFORE UPDATE ON dispatch_events
    FOR EACH ROW EXECUTE FUNCTION fn_dispatch_events_prevent_update();

CREATE TRIGGER trg_dispatch_events_prevent_delete
    BEFORE DELETE ON dispatch_events
    FOR EACH ROW EXECUTE FUNCTION fn_dispatch_events_prevent_delete();
