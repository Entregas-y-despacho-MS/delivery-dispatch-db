-- Tabla de log append-only: a diferencia del resto de las tablas del proyecto, no lleva
-- updated_at porque un evento ya registrado nunca se modifica. La inmutabilidad la imponen dos
-- triggers (UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on', para limpieza
-- de pruebas). TRUNCATE no se bloquea: es convención.
CREATE TABLE route_batch_events (
    route_batch_event_id  SERIAL,
    route_batch_id        INT             NOT NULL,                        -- lote al que corresponde el evento
    dispatch_id           INT,                                             -- despacho involucrado, si el evento es sobre un pedido concreto
    event_type            VARCHAR(50)     NOT NULL,                        -- created | split | merged | order_removed | approved | frozen | reviewer_reassigned | ...
    actor_user_id         INT,                                             -- usuario que originó el evento; NULL si lo generó el sistema o el cliente
    actor_type            VARCHAR(20)     NOT NULL,                        -- user | system | customer
    reason                TEXT,                                            -- motivo declarado del evento
    metadata              JSONB,                                           -- valor anterior y nuevo, versión, resultado
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_batch_event_id),
    FOREIGN KEY (route_batch_id) REFERENCES route_batches(route_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_id)    REFERENCES dispatches(dispatch_id)       ON DELETE RESTRICT,
    FOREIGN KEY (actor_user_id)  REFERENCES users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT chk_route_batch_events_actor_type CHECK (actor_type IN ('user', 'system', 'customer'))
);

CREATE INDEX idx_route_batch_events_route_batch_id ON route_batch_events(route_batch_id);
CREATE INDEX idx_route_batch_events_dispatch_id    ON route_batch_events(dispatch_id);
CREATE INDEX idx_route_batch_events_actor_user_id  ON route_batch_events(actor_user_id);

CREATE FUNCTION fn_route_batch_events_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_batch_events is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_route_batch_events_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_batch_events is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_route_batch_events_prevent_update
    BEFORE UPDATE ON route_batch_events
    FOR EACH ROW EXECUTE FUNCTION fn_route_batch_events_prevent_update();

CREATE TRIGGER trg_route_batch_events_prevent_delete
    BEFORE DELETE ON route_batch_events
    FOR EACH ROW EXECUTE FUNCTION fn_route_batch_events_prevent_delete();
