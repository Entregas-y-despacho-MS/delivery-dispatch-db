CREATE TABLE dispatch_complaints (
    dispatch_complaint_id  SERIAL,
    dispatch_id             INT             NOT NULL,                     -- despacho sobre el que se reclama
    description               TEXT            NOT NULL,                    -- detalle del reclamo
    status                     VARCHAR(20)     NOT NULL DEFAULT 'open',    -- open | closed
    created_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_complaint_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT chk_dispatch_complaints_status CHECK (status IN ('open', 'closed'))
);

CREATE INDEX idx_dispatch_complaints_dispatch_id ON dispatch_complaints(dispatch_id);
