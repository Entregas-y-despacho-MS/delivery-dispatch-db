-- Aviso por correo al cliente, con su estado de envío (ST-39.2, RF-U16). Una fila = un envío lógico:
-- la clave idempotente (tipo de notificación + evento origen) es única, así que dos entregas del mismo
-- evento dejan una sola fila. A diferencia de dispatch_events (append-only), esta tabla se actualiza
-- en cada intento: estado, intentos, próximo intento y último error.
CREATE TABLE customer_notifications (
    customer_notification_id  SERIAL,
    dispatch_id               INT             NOT NULL,                        -- despacho cuyo cambio de estado originó el aviso
    notification_type         VARCHAR(50)     NOT NULL,                        -- status_change (cambio de estado del despacho)
    idempotency_key           VARCHAR(200)    NOT NULL,                        -- <notification_type>:<source_event_key>; única: un solo envío lógico por evento y tipo
    source_event_key          VARCHAR(120)    NOT NULL,                        -- evento origen: <dispatch_id>:<estado>:<instante ISO>; el evento no trae id propio
    dispatch_status           VARCHAR(30)     NOT NULL,                        -- estado del despacho que se avisa (para reconstruir el correo en un reintento)
    occurred_at               TIMESTAMPTZ     NOT NULL,                        -- instante de la transición que originó el aviso
    recipient                 VARCHAR(254)    NOT NULL,                        -- correo del destinatario normalizado (sin espacios, en minúsculas)
    template                  VARCHAR(50)     NOT NULL,                        -- plantilla Handlebars usada (ej. status-change)
    template_version          SMALLINT        NOT NULL,                        -- versión de la plantilla al momento del envío
    status                    VARCHAR(20)     NOT NULL DEFAULT 'sending',      -- sending | sent | retrying | bounced | exhausted
    attempts                  SMALLINT        NOT NULL DEFAULT 0,              -- intentos de envío realizados contra el proveedor
    next_attempt_at           TIMESTAMPTZ,                                     -- cuándo toca el próximo intento; NULL en los estados finales
    locked_until              TIMESTAMPTZ,                                     -- concesión del intento en curso; vencida, otro proceso puede retomarlo
    last_error                VARCHAR(200),                                    -- último error del proveedor, saneado: una línea de a lo sumo 200 caracteres, sin direcciones, enlaces ni tokens largos
    sent_at                   TIMESTAMPTZ,                                     -- momento en que el proveedor aceptó el correo; NULL mientras no se envíe
    created_at                TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (customer_notification_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    CONSTRAINT chk_customer_notifications_type CHECK (notification_type IN ('status_change')),
    CONSTRAINT chk_customer_notifications_status CHECK (status IN ('sending', 'sent', 'retrying', 'bounced', 'exhausted')),
    CONSTRAINT chk_customer_notifications_attempts CHECK (attempts >= 0),
    CONSTRAINT chk_customer_notifications_sent_at CHECK ((status = 'sent') = (sent_at IS NOT NULL))
);

CREATE UNIQUE INDEX uq_customer_notifications_idempotency_key ON customer_notifications(idempotency_key);
CREATE INDEX idx_customer_notifications_dispatch_id ON customer_notifications(dispatch_id);
-- Barrido de recuperación: solo las filas que todavía pueden reintentarse.
CREATE INDEX idx_customer_notifications_pending ON customer_notifications(next_attempt_at) WHERE status IN ('sending', 'retrying');

CREATE FUNCTION fn_customer_notifications_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customer_notifications_set_updated_at
    BEFORE UPDATE ON customer_notifications
    FOR EACH ROW EXECUTE FUNCTION fn_customer_notifications_set_updated_at();
