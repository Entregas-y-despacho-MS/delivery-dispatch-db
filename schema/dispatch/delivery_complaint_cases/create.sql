-- Inbox y referencia única del reclamo de CRM (ST-298.2, ES-298). Una fila = un caso de CRM: la clave
-- funcional (source, crm_case_id) es única, así que reentregar un mensaje o un caso nunca abre una
-- segunda investigación. ST-45.1 (ES-45) extiende esta tabla con la investigación; no se duplica.
CREATE TABLE delivery_complaint_cases (
    delivery_complaint_case_id  SERIAL,
    message_id                  UUID            NOT NULL,                        -- messageId del broker del último mensaje aplicado al caso
    source                      VARCHAR(100)    NOT NULL,                        -- sistema productor (crm)
    crm_case_id                 VARCHAR(64)     NOT NULL,                        -- id del caso en CRM; con source forma la clave funcional
    case_version                INT             NOT NULL,                        -- versión del caso en CRM; el backend ignora una menor o igual
    dispatch_id                 INT             NOT NULL,                        -- el despacho (parada) concreto al que resuelve el reclamo
    tracking_code               VARCHAR(20),                                     -- DSP-AAAA-NNNNN tal como llegó; el backend valida que coincida con dispatch_id
    reason_code                 VARCHAR(40)     NOT NULL,                        -- código de motivo del catálogo de CRM (patrón, no enum)
    affected_items              JSONB           NOT NULL,                        -- identificación mínima del producto/bulto afectado, sin datos personales
    opened_at                   TIMESTAMPTZ     NOT NULL,                        -- apertura del caso en CRM
    intake_status               VARCHAR(20)     NOT NULL DEFAULT 'received',     -- received | acknowledged
    consumed_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),          -- cuándo Despachos consumió el mensaje
    acknowledged_at             TIMESTAMPTZ,                                     -- cuándo se publicó el acuse received; NULL mientras no se publique
    created_at                  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_complaint_case_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    CONSTRAINT chk_delivery_complaint_cases_case_version CHECK (case_version >= 1),
    CONSTRAINT chk_delivery_complaint_cases_reason_code CHECK (reason_code ~ '^[A-Z][A-Z0-9_]{1,39}$'),
    CONSTRAINT chk_delivery_complaint_cases_affected_items CHECK (
        jsonb_typeof(affected_items) = 'array' AND jsonb_array_length(affected_items) BETWEEN 1 AND 100
    ),
    CONSTRAINT chk_delivery_complaint_cases_intake_status CHECK (intake_status IN ('received', 'acknowledged')),
    CONSTRAINT chk_delivery_complaint_cases_acknowledged_at CHECK ((intake_status = 'acknowledged') = (acknowledged_at IS NOT NULL))
);

CREATE UNIQUE INDEX uq_delivery_complaint_cases_message_id ON delivery_complaint_cases(message_id);
CREATE UNIQUE INDEX uq_delivery_complaint_cases_source_crm_case_id ON delivery_complaint_cases(source, crm_case_id);
CREATE INDEX idx_delivery_complaint_cases_dispatch_id ON delivery_complaint_cases(dispatch_id);
-- Recuperación de acuses: solo los casos cuyo acuse received aún no se publicó.
CREATE INDEX idx_delivery_complaint_cases_pending_ack ON delivery_complaint_cases(consumed_at) WHERE intake_status = 'received';

CREATE FUNCTION fn_delivery_complaint_cases_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_delivery_complaint_cases_set_updated_at
    BEFORE UPDATE ON delivery_complaint_cases
    FOR EACH ROW EXECUTE FUNCTION fn_delivery_complaint_cases_set_updated_at();
