-- Append-only receipt log. The source message UUID is the idempotency key supplied by the broker.
CREATE TABLE inbound_messages (
    message_id    UUID            NOT NULL,                              -- broker message identifier
    status        VARCHAR(20)     NOT NULL,                              -- processed | rejected
    type          VARCHAR(100)    NOT NULL,                              -- event type supplied by the producer
    source        VARCHAR(100)    NOT NULL,                              -- source system, such as marketplace or warehouse
    received_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),                -- time the message reached the consumer
    error_detail  TEXT,                                                  -- validation or processing error for rejected messages
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id),
    FOREIGN KEY (status) REFERENCES inbound_message_statuses(status),
    CONSTRAINT chk_inbound_messages_error_detail CHECK (
        (status = 'rejected' AND error_detail IS NOT NULL)
        OR (status = 'processed' AND error_detail IS NULL)
    )
);

CREATE INDEX idx_inbound_messages_status ON inbound_messages(status);
