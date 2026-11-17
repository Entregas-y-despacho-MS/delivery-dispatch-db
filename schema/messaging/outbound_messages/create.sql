-- Durable outbox for messages that must be published to another system.
CREATE TABLE outbound_messages (
    message_id        UUID            NOT NULL,                          -- unique outgoing message identifier
    status            VARCHAR(20)     NOT NULL DEFAULT 'pending',        -- pending | sent | failed
    type              VARCHAR(100)    NOT NULL,                          -- event type to publish
    payload           JSONB           NOT NULL,                          -- message body to publish
    attempts          INT             NOT NULL DEFAULT 0,                -- number of publish attempts already made
    next_attempt_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),            -- earliest time the publisher may retry
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),            -- time the outbox message was created
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),            -- time the delivery state last changed
    PRIMARY KEY (message_id),
    FOREIGN KEY (status) REFERENCES outbound_message_statuses(status),
    CONSTRAINT chk_outbound_messages_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_outbound_messages_status_next_attempt_at
    ON outbound_messages(status, next_attempt_at);
