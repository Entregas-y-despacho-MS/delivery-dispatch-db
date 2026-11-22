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
    -- Investigación y correlación del caso (ST-45.1, migración 032). Van al final para coincidir con el orden de la migración.
    investigation_status        VARCHAR(20)     NOT NULL DEFAULT 'received',     -- received | assigned | in_investigation | decided (independiente de intake_status)
    assigned_user_id            INT,                                             -- responsable de la investigación
    assigned_at                 TIMESTAMPTZ,                                     -- cuándo se tomó o asignó el caso
    investigation_started_at    TIMESTAMPTZ,                                     -- cuándo se inició la investigación
    verdict                     VARCHAR(30),                                     -- no_return_required | not_confirmed | request_RMA
    decision_reason             VARCHAR(500),                                    -- causal saneada del dictamen
    findings                    TEXT,                                            -- hallazgos saneados (sin expediente CRM, secretos ni evidencia binaria)
    decided_by_user_id          INT,                                             -- quien emitió el dictamen
    decided_at                  TIMESTAMPTZ,                                     -- cuándo se emitió el dictamen
    authorization_request_id    VARCHAR(100),                                    -- solicitud de autorización RMA a Inventarios; NULL sin RMA
    rma_id                      VARCHAR(100),                                    -- id externo del RMA tras la aprobación; NULL sin RMA
    PRIMARY KEY (delivery_complaint_case_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    CONSTRAINT fk_delivery_complaint_cases_assigned_user_id FOREIGN KEY (assigned_user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_delivery_complaint_cases_decided_by_user_id FOREIGN KEY (decided_by_user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_delivery_complaint_cases_case_version CHECK (case_version >= 1),
    CONSTRAINT chk_delivery_complaint_cases_reason_code CHECK (reason_code ~ '^[A-Z][A-Z0-9_]{1,39}$'),
    CONSTRAINT chk_delivery_complaint_cases_affected_items CHECK (
        jsonb_typeof(affected_items) = 'array' AND jsonb_array_length(affected_items) BETWEEN 1 AND 100
    ),
    CONSTRAINT chk_delivery_complaint_cases_intake_status CHECK (intake_status IN ('received', 'acknowledged')),
    CONSTRAINT chk_delivery_complaint_cases_acknowledged_at CHECK ((intake_status = 'acknowledged') = (acknowledged_at IS NOT NULL)),
    CONSTRAINT chk_delivery_complaint_cases_investigation_status CHECK (investigation_status IN ('received', 'assigned', 'in_investigation', 'decided')),
    CONSTRAINT chk_delivery_complaint_cases_verdict CHECK (verdict IS NULL OR verdict IN ('no_return_required', 'not_confirmed', 'request_RMA')),
    CONSTRAINT chk_delivery_complaint_cases_findings_length CHECK (findings IS NULL OR char_length(findings) <= 4000),
    CONSTRAINT chk_delivery_complaint_cases_assignment CHECK (investigation_status = 'received' OR (assigned_user_id IS NOT NULL AND assigned_at IS NOT NULL)),
    CONSTRAINT chk_delivery_complaint_cases_started_at CHECK (investigation_status NOT IN ('in_investigation', 'decided') OR investigation_started_at IS NOT NULL),
    CONSTRAINT chk_delivery_complaint_cases_decision CHECK (
        (investigation_status = 'decided'
            AND verdict IS NOT NULL AND decided_at IS NOT NULL AND decided_by_user_id IS NOT NULL
            AND decision_reason IS NOT NULL AND char_length(btrim(decision_reason)) > 0)
        OR (investigation_status <> 'decided'
            AND verdict IS NULL AND decided_at IS NULL AND decided_by_user_id IS NULL AND decision_reason IS NULL)
    ),
    CONSTRAINT chk_delivery_complaint_cases_rma_references CHECK (
        (authorization_request_id IS NULL OR char_length(btrim(authorization_request_id)) > 0)
        AND (rma_id IS NULL OR char_length(btrim(rma_id)) > 0)
        AND (COALESCE(verdict = 'request_RMA', FALSE) OR (authorization_request_id IS NULL AND rma_id IS NULL))
    )
);

CREATE UNIQUE INDEX uq_delivery_complaint_cases_message_id ON delivery_complaint_cases(message_id);
CREATE UNIQUE INDEX uq_delivery_complaint_cases_source_crm_case_id ON delivery_complaint_cases(source, crm_case_id);
CREATE INDEX idx_delivery_complaint_cases_dispatch_id ON delivery_complaint_cases(dispatch_id);
-- Recuperación de acuses: solo los casos cuyo acuse received aún no se publicó.
CREATE INDEX idx_delivery_complaint_cases_pending_ack ON delivery_complaint_cases(consumed_at) WHERE intake_status = 'received';
-- Bandeja de la investigación (ST-45.1): por estado y fecha, y por despacho y estado.
CREATE INDEX idx_delivery_complaint_cases_status_consumed_at ON delivery_complaint_cases(investigation_status, consumed_at DESC);
CREATE INDEX idx_delivery_complaint_cases_dispatch_status ON delivery_complaint_cases(dispatch_id, investigation_status);
CREATE INDEX idx_delivery_complaint_cases_assigned_user_id ON delivery_complaint_cases(assigned_user_id) WHERE assigned_user_id IS NOT NULL;
CREATE INDEX idx_delivery_complaint_cases_decided_by_user_id ON delivery_complaint_cases(decided_by_user_id) WHERE decided_by_user_id IS NOT NULL;
-- Una referencia RMA externa pertenece a un solo caso.
CREATE UNIQUE INDEX uq_delivery_complaint_cases_authorization_request_id ON delivery_complaint_cases(authorization_request_id) WHERE authorization_request_id IS NOT NULL;
CREATE UNIQUE INDEX uq_delivery_complaint_cases_rma_id ON delivery_complaint_cases(rma_id) WHERE rma_id IS NOT NULL;

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
