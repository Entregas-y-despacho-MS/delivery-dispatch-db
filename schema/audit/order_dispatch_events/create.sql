-- Tabla de log append-only: no lleva updated_at (un evento ya registrado nunca se modifica). La
-- inmutabilidad la imponen dos triggers (UPDATE siempre bloqueado; DELETE solo con
-- app.allow_event_purge = 'on', para limpieza de pruebas) y el rol dispatch_app, que solo tiene
-- SELECT e INSERT. TRUNCATE no se bloquea: es convención.
CREATE TABLE order_dispatch_events (
    order_dispatch_event_id  UUID            NOT NULL,                        -- eventId generado por la aplicación (inserción idempotente)
    source_order_ref         VARCHAR(100)    NOT NULL,                        -- pedido en el sistema origen (dispatches.source_order_ref). Sin FK: un pedido puede tener varios despachos
    dispatch_id              INT,                                             -- despacho al que corresponde el evento; NULL en eventos previos a que exista el despacho
    route_batch_id           INT,                                             -- lote de ruta involucrado, si hay uno
    actor_user_id            INT,                                             -- usuario que originó el evento; NULL si lo originó el sistema
    actor_role               VARCHAR(30),                                     -- rol del actor en el momento del evento; 'system' si no hay usuario
    action                   VARCHAR(100)    NOT NULL,                        -- nombre del evento (ej. dispatch.created, dispatch.status_changed)
    previous_status          VARCHAR(50),                                     -- código del estado anterior; NULL si no aplica
    new_status               VARCHAR(50),                                     -- código del estado nuevo; NULL si no aplica
    result                   VARCHAR(20)     NOT NULL,                        -- success | denied | failed
    correlation_id           VARCHAR(64)     NOT NULL,                        -- identificador de la solicitud (cabecera X-Request-Id)
    detail                   JSONB           NOT NULL DEFAULT '{}',           -- detalle saneado; nunca secretos, tokens ni el payload completo
    occurred_at              TIMESTAMPTZ     NOT NULL,                        -- momento en que ocurrió el evento
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_dispatch_event_id),
    FOREIGN KEY (dispatch_id)    REFERENCES dispatches(dispatch_id)       ON DELETE RESTRICT,
    FOREIGN KEY (route_batch_id) REFERENCES route_batches(route_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (actor_user_id)  REFERENCES users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT chk_order_dispatch_events_result CHECK (result IN ('success', 'denied', 'failed')),
    CONSTRAINT chk_order_dispatch_events_detail CHECK (jsonb_typeof(detail) = 'object')
);

CREATE INDEX idx_order_dispatch_events_dispatch_occurred ON order_dispatch_events(dispatch_id, occurred_at);
CREATE INDEX idx_order_dispatch_events_order_occurred    ON order_dispatch_events(source_order_ref, occurred_at);
CREATE INDEX idx_order_dispatch_events_correlation_id    ON order_dispatch_events(correlation_id);
CREATE INDEX idx_order_dispatch_events_route_batch_id    ON order_dispatch_events(route_batch_id);
CREATE INDEX idx_order_dispatch_events_actor_user_id     ON order_dispatch_events(actor_user_id);

CREATE FUNCTION fn_order_dispatch_events_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'order_dispatch_events is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_order_dispatch_events_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'order_dispatch_events is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_dispatch_events_prevent_update
    BEFORE UPDATE ON order_dispatch_events
    FOR EACH ROW EXECUTE FUNCTION fn_order_dispatch_events_prevent_update();

CREATE TRIGGER trg_order_dispatch_events_prevent_delete
    BEFORE DELETE ON order_dispatch_events
    FOR EACH ROW EXECUTE FUNCTION fn_order_dispatch_events_prevent_delete();

-- Rol de la aplicación: solo lee y agrega. El usuario de conexión del backend debe pertenecer a
-- él (o tener los mismos privilegios). Los roles son del clúster, por eso la guarda.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dispatch_app') THEN
        CREATE ROLE dispatch_app NOLOGIN;
    END IF;
END $$;

REVOKE ALL ON order_dispatch_events FROM dispatch_app;
GRANT SELECT, INSERT ON order_dispatch_events TO dispatch_app;
