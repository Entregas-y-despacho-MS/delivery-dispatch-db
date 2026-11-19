-- Tabla de log append-only: no lleva updated_at (un evento de auditoría ya escrito no se modifica ni se borra).
CREATE TABLE admin_audit_events (
    admin_audit_event_id  UUID            NOT NULL,                        -- eventId generado por la aplicación
    actor_user_id         INT,                                             -- usuario autenticado que ejecutó o intentó la acción; NULL sin actor. Sin FK: el evento no cambia si el usuario se borra
    actor_role            VARCHAR(30),                                     -- rol del actor en el momento de la acción; NULL sin actor
    action                VARCHAR(100)    NOT NULL,                        -- acción del catálogo de acciones sensibles (ej. user.role_changed)
    entity_type           VARCHAR(50),                                     -- tipo de entidad afectada (ej. user, setting)
    entity_id             VARCHAR(64),                                     -- referencia de la entidad afectada; NULL si no aplica o no se conoce
    result                VARCHAR(20)     NOT NULL,                        -- success | denied | failed
    status_code           SMALLINT,                                        -- código HTTP con el que terminó la solicitud
    correlation_id        VARCHAR(64)     NOT NULL,                        -- identificador de la solicitud (cabecera X-Request-Id)
    ip_address            INET,                                            -- IP del cliente solo cuando llega por un proxy confiable (TRUST_PROXY) o directa
    metadata              JSONB           NOT NULL DEFAULT '{}',           -- metadatos permitidos de la acción; nunca secretos, tokens ni datos personales
    occurred_at           TIMESTAMPTZ     NOT NULL,                        -- momento en que terminó la acción
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (admin_audit_event_id),
    CONSTRAINT chk_admin_audit_events_result CHECK (result IN ('success', 'denied', 'failed'))
);

CREATE INDEX idx_admin_audit_events_occurred_at   ON admin_audit_events(occurred_at);
CREATE INDEX idx_admin_audit_events_actor_user_id ON admin_audit_events(actor_user_id);
CREATE INDEX idx_admin_audit_events_action        ON admin_audit_events(action);
CREATE INDEX idx_admin_audit_events_entity        ON admin_audit_events(entity_type, entity_id);
CREATE INDEX idx_admin_audit_events_correlation_id ON admin_audit_events(correlation_id);
