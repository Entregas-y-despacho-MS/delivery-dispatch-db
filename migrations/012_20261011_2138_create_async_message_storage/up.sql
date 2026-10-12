-- ST-72.3 — durable storage for inbound messages, out-of-order integration data, and the outbox.

CREATE TABLE IF NOT EXISTS inbound_message_statuses (
    status       VARCHAR(20)    NOT NULL,
    description  TEXT           NOT NULL,
    PRIMARY KEY (status)
);

INSERT INTO inbound_message_statuses (status, description) VALUES
    ('processed', 'Message passed validation and was processed successfully.'),
    ('rejected', 'Message was invalid or could not be processed and must be sent to the dead-letter topic.')
ON CONFLICT (status) DO NOTHING;

CREATE TABLE IF NOT EXISTS outbound_message_statuses (
    status       VARCHAR(20)    NOT NULL,
    description  TEXT           NOT NULL,
    PRIMARY KEY (status)
);

INSERT INTO outbound_message_statuses (status, description) VALUES
    ('pending', 'Message is waiting to be published or retried.'),
    ('sent', 'Message was published successfully.'),
    ('failed', 'Message exhausted its retry policy and will not be published again.')
ON CONFLICT (status) DO NOTHING;

CREATE TABLE IF NOT EXISTS inbound_messages (
    message_id    UUID            NOT NULL,
    status        VARCHAR(20)     NOT NULL,
    type          VARCHAR(100)    NOT NULL,
    source        VARCHAR(100)    NOT NULL,
    received_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    error_detail  TEXT,
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id),
    FOREIGN KEY (status) REFERENCES inbound_message_statuses(status),
    CONSTRAINT chk_inbound_messages_error_detail CHECK (
        (status = 'rejected' AND error_detail IS NOT NULL)
        OR (status = 'processed' AND error_detail IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_inbound_messages_status ON inbound_messages(status);

CREATE OR REPLACE FUNCTION fn_inbound_messages_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inbound_messages_set_updated_at ON inbound_messages;
CREATE TRIGGER trg_inbound_messages_set_updated_at
    BEFORE UPDATE ON inbound_messages
    FOR EACH ROW EXECUTE FUNCTION fn_inbound_messages_set_updated_at();

CREATE TABLE IF NOT EXISTS pending_sales_orders (
    sales_order_id  VARCHAR(100)    NOT NULL,
    record_version  BIGINT          NOT NULL,
    payload         JSONB           NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id),
    CONSTRAINT chk_pending_sales_orders_record_version CHECK (record_version >= 0)
);

CREATE OR REPLACE FUNCTION fn_pending_sales_orders_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pending_sales_orders_set_updated_at ON pending_sales_orders;
CREATE TRIGGER trg_pending_sales_orders_set_updated_at
    BEFORE UPDATE ON pending_sales_orders
    FOR EACH ROW EXECUTE FUNCTION fn_pending_sales_orders_set_updated_at();

CREATE TABLE IF NOT EXISTS pending_shipments (
    sales_order_id  VARCHAR(100)    NOT NULL,
    record_version  BIGINT          NOT NULL,
    payload         JSONB           NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id),
    CONSTRAINT chk_pending_shipments_record_version CHECK (record_version >= 0)
);

CREATE OR REPLACE FUNCTION fn_pending_shipments_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pending_shipments_set_updated_at ON pending_shipments;
CREATE TRIGGER trg_pending_shipments_set_updated_at
    BEFORE UPDATE ON pending_shipments
    FOR EACH ROW EXECUTE FUNCTION fn_pending_shipments_set_updated_at();

CREATE TABLE IF NOT EXISTS outbound_messages (
    message_id        UUID            NOT NULL,
    status            VARCHAR(20)     NOT NULL DEFAULT 'pending',
    type              VARCHAR(100)    NOT NULL,
    payload           JSONB           NOT NULL,
    attempts          INT             NOT NULL DEFAULT 0,
    next_attempt_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id),
    FOREIGN KEY (status) REFERENCES outbound_message_statuses(status),
    CONSTRAINT chk_outbound_messages_attempts CHECK (attempts >= 0)
);

CREATE INDEX IF NOT EXISTS idx_outbound_messages_status_next_attempt_at
    ON outbound_messages(status, next_attempt_at);

CREATE OR REPLACE FUNCTION fn_outbound_messages_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_outbound_messages_set_updated_at ON outbound_messages;
CREATE TRIGGER trg_outbound_messages_set_updated_at
    BEFORE UPDATE ON outbound_messages
    FOR EACH ROW EXECUTE FUNCTION fn_outbound_messages_set_updated_at();
