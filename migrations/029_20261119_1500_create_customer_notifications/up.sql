-- RF-U16: customer email with its delivery state — idempotent per source event and notification type,
-- recoverable after a provider failure.

CREATE TABLE IF NOT EXISTS customer_notifications (
    customer_notification_id  SERIAL,
    dispatch_id               INT             NOT NULL,                        -- dispatch whose status change originated the email
    notification_type         VARCHAR(50)     NOT NULL,                        -- status_change (the dispatch changed status)
    idempotency_key           VARCHAR(200)    NOT NULL,                        -- <notification_type>:<source_event_key>; unique: one logical send per event and type
    source_event_key          VARCHAR(120)    NOT NULL,                        -- source event: <dispatch_id>:<status>:<ISO instant>; the event has no id of its own
    dispatch_status           VARCHAR(30)     NOT NULL,                        -- status of the dispatch being notified (to rebuild the email on a retry)
    occurred_at               TIMESTAMPTZ     NOT NULL,                        -- instant of the transition that originated the email
    recipient                 VARCHAR(254)    NOT NULL,                        -- normalized recipient address (trimmed, lower case)
    template                  VARCHAR(50)     NOT NULL,                        -- Handlebars template used (e.g. status-change)
    template_version          SMALLINT        NOT NULL,                        -- template version at send time
    status                    VARCHAR(20)     NOT NULL DEFAULT 'sending',      -- sending | sent | retrying | bounced | exhausted
    attempts                  SMALLINT        NOT NULL DEFAULT 0,              -- attempts made against the provider
    next_attempt_at           TIMESTAMPTZ,                                     -- when the next attempt is due; NULL in the final states
    locked_until              TIMESTAMPTZ,                                     -- lease of the attempt in progress; once it expires another process may take the row over
    last_error                VARCHAR(200),                                    -- last provider error, sanitized (one line, at most 200 characters, addresses, links and long tokens masked); kept after a later successful send
    sent_at                   TIMESTAMPTZ,                                     -- when the provider accepted the email; NULL until it is sent
    created_at                TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (customer_notification_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    CONSTRAINT chk_customer_notifications_type CHECK (notification_type IN ('status_change')),
    CONSTRAINT chk_customer_notifications_status CHECK (status IN ('sending', 'sent', 'retrying', 'bounced', 'exhausted')),
    CONSTRAINT chk_customer_notifications_attempts CHECK (attempts >= 0),
    CONSTRAINT chk_customer_notifications_sent_at CHECK ((status = 'sent') = (sent_at IS NOT NULL))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_notifications_idempotency_key ON customer_notifications(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_dispatch_id ON customer_notifications(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_pending ON customer_notifications(next_attempt_at) WHERE status IN ('sending', 'retrying');

CREATE OR REPLACE FUNCTION fn_customer_notifications_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_customer_notifications_set_updated_at ON customer_notifications;
CREATE TRIGGER trg_customer_notifications_set_updated_at
    BEFORE UPDATE ON customer_notifications
    FOR EACH ROW EXECUTE FUNCTION fn_customer_notifications_set_updated_at();
