-- Latest delivery data received for a sales order while its shipment event is still missing.
CREATE TABLE pending_sales_orders (
    sales_order_id  VARCHAR(100)    NOT NULL,                            -- external sales-order identifier
    record_version  BIGINT          NOT NULL,                            -- producer version used to ignore stale updates
    payload         JSONB           NOT NULL,                            -- validated delivery/order data from the producer
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),              -- first time the pending record was stored
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),              -- last time a newer version replaced the payload
    PRIMARY KEY (sales_order_id),
    CONSTRAINT chk_pending_sales_orders_record_version CHECK (record_version >= 0)
);
