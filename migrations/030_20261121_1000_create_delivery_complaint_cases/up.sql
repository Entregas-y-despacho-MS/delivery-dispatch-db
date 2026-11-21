-- ST-298.2 (ES-298): inbox and single reference of the CRM delivery complaint. One row per CRM case:
-- (source, crm_case_id) is unique, so redelivering a message or a case never opens a second investigation.
-- ST-45.1 extends this table with the investigation; it is not duplicated.

CREATE TABLE IF NOT EXISTS delivery_complaint_cases (
    delivery_complaint_case_id  SERIAL,
    message_id                  UUID            NOT NULL,                        -- broker messageId of the last message applied to the case
    source                      VARCHAR(100)    NOT NULL,                        -- producer system (crm)
    crm_case_id                 VARCHAR(64)     NOT NULL,                        -- case id in the CRM; with source it is the functional key
    case_version                INT             NOT NULL,                        -- CRM case version; an older or equal one is ignored by the backend
    dispatch_id                 INT             NOT NULL,                        -- the specific dispatch (stop) the complaint resolves to
    tracking_code               VARCHAR(20),                                     -- DSP-YYYY-NNNNN as received; the backend checks it matches dispatch_id
    reason_code                 VARCHAR(40)     NOT NULL,                        -- reason code from the CRM catalog (pattern, not an enum)
    affected_items              JSONB           NOT NULL,                        -- minimal affected product/package identification, no personal data
    opened_at                   TIMESTAMPTZ     NOT NULL,                        -- when the case was opened in the CRM
    intake_status               VARCHAR(20)     NOT NULL DEFAULT 'received',     -- received | acknowledged
    consumed_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),          -- when Dispatch consumed the message
    acknowledged_at             TIMESTAMPTZ,                                     -- when the received acknowledgement was published; NULL until then
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

CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_complaint_cases_message_id ON delivery_complaint_cases(message_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_complaint_cases_source_crm_case_id ON delivery_complaint_cases(source, crm_case_id);
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_dispatch_id ON delivery_complaint_cases(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_pending_ack ON delivery_complaint_cases(consumed_at) WHERE intake_status = 'received';

CREATE OR REPLACE FUNCTION fn_delivery_complaint_cases_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_delivery_complaint_cases_set_updated_at ON delivery_complaint_cases;
CREATE TRIGGER trg_delivery_complaint_cases_set_updated_at
    BEFORE UPDATE ON delivery_complaint_cases
    FOR EACH ROW EXECUTE FUNCTION fn_delivery_complaint_cases_set_updated_at();
