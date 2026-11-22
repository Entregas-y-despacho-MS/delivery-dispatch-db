-- ST-45.1 (ES-45, RF-U22): persist the investigation and the RMA correlation of the complaint case.
-- Extends delivery_complaint_cases (ST-298.2, migration 030); the inbox is not duplicated and the
-- unique keys (source, crm_case_id) and message_id are untouched. Existing cases stay 'received'.

ALTER TABLE delivery_complaint_cases
    ADD COLUMN IF NOT EXISTS investigation_status      VARCHAR(20)  NOT NULL DEFAULT 'received',  -- received | assigned | in_investigation | decided
    ADD COLUMN IF NOT EXISTS assigned_user_id          INT,                                       -- user in charge of the investigation
    ADD COLUMN IF NOT EXISTS assigned_at               TIMESTAMPTZ,                               -- when the case was taken or assigned
    ADD COLUMN IF NOT EXISTS investigation_started_at  TIMESTAMPTZ,                               -- when the investigation started
    ADD COLUMN IF NOT EXISTS verdict                   VARCHAR(30),                               -- no_return_required | not_confirmed | request_RMA
    ADD COLUMN IF NOT EXISTS decision_reason           VARCHAR(500),                              -- sanitized reason for the verdict
    ADD COLUMN IF NOT EXISTS findings                  TEXT,                                      -- sanitized findings (no CRM file, secrets or binary evidence)
    ADD COLUMN IF NOT EXISTS decided_by_user_id        INT,                                       -- user who issued the verdict
    ADD COLUMN IF NOT EXISTS decided_at                TIMESTAMPTZ,                               -- when the verdict was issued
    ADD COLUMN IF NOT EXISTS authorization_request_id  VARCHAR(100),                              -- RMA authorization request sent to Inventory; NULL without RMA
    ADD COLUMN IF NOT EXISTS rma_id                    VARCHAR(100);                              -- external RMA id once Inventory approves; NULL without RMA

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_delivery_complaint_cases_assigned_user_id') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT fk_delivery_complaint_cases_assigned_user_id
            FOREIGN KEY (assigned_user_id) REFERENCES users(user_id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_delivery_complaint_cases_decided_by_user_id') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT fk_delivery_complaint_cases_decided_by_user_id
            FOREIGN KEY (decided_by_user_id) REFERENCES users(user_id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_investigation_status') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_investigation_status
            CHECK (investigation_status IN ('received', 'assigned', 'in_investigation', 'decided'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_verdict') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_verdict
            CHECK (verdict IS NULL OR verdict IN ('no_return_required', 'not_confirmed', 'request_RMA'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_findings_length') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_findings_length
            CHECK (findings IS NULL OR char_length(findings) <= 4000);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_assignment') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_assignment
            CHECK (investigation_status = 'received' OR (assigned_user_id IS NOT NULL AND assigned_at IS NOT NULL));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_started_at') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_started_at
            CHECK (investigation_status NOT IN ('in_investigation', 'decided') OR investigation_started_at IS NOT NULL);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_decision') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_decision
            CHECK (
                (investigation_status = 'decided'
                    AND verdict IS NOT NULL AND decided_at IS NOT NULL AND decided_by_user_id IS NOT NULL
                    AND decision_reason IS NOT NULL AND char_length(btrim(decision_reason)) > 0)
                OR (investigation_status <> 'decided'
                    AND verdict IS NULL AND decided_at IS NULL AND decided_by_user_id IS NULL AND decision_reason IS NULL)
            );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_delivery_complaint_cases_rma_references') THEN
        ALTER TABLE delivery_complaint_cases
            ADD CONSTRAINT chk_delivery_complaint_cases_rma_references
            CHECK (
                (authorization_request_id IS NULL OR char_length(btrim(authorization_request_id)) > 0)
                AND (rma_id IS NULL OR char_length(btrim(rma_id)) > 0)
                AND (verdict = 'request_RMA' OR (authorization_request_id IS NULL AND rma_id IS NULL))
            );
    END IF;
END $$;

-- Inbox queries: by status and date, and by dispatch and status.
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_status_consumed_at
    ON delivery_complaint_cases(investigation_status, consumed_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_dispatch_status
    ON delivery_complaint_cases(dispatch_id, investigation_status);
-- FK columns.
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_assigned_user_id
    ON delivery_complaint_cases(assigned_user_id) WHERE assigned_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_delivery_complaint_cases_decided_by_user_id
    ON delivery_complaint_cases(decided_by_user_id) WHERE decided_by_user_id IS NOT NULL;
-- One case per external RMA reference.
CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_complaint_cases_authorization_request_id
    ON delivery_complaint_cases(authorization_request_id) WHERE authorization_request_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_complaint_cases_rma_id
    ON delivery_complaint_cases(rma_id) WHERE rma_id IS NOT NULL;
