-- Durable per-origin high-water mark and recovery state for each sales order.
CREATE TABLE sales_order_sync_states (
    sales_order_id           VARCHAR(100)  NOT NULL,                    -- external sales-order identifier
    source                   VARCHAR(20)   NOT NULL,                    -- marketplace, inventory or procurement
    last_record_version      BIGINT        NOT NULL DEFAULT 0,         -- 0 means no version received
    base_received            BOOLEAN       NOT NULL DEFAULT FALSE,     -- confirmed or ready base was received
    cancelled_at             TIMESTAMPTZ,                              -- terminal cancellation from this source
    cancelled_record_version BIGINT,                                   -- version of the terminal cancellation
    sync_attempts            SMALLINT      NOT NULL DEFAULT 0,         -- recovery requests for this source
    last_sync_requested_at   TIMESTAMPTZ,                              -- most recent recovery request
    incomplete_alerted_at    TIMESTAMPTZ,                              -- prevents repeated incomplete-order alerts
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id, source),
    CONSTRAINT chk_sales_order_sync_states_source CHECK (source IN ('marketplace', 'inventory', 'procurement')),
    CONSTRAINT chk_sales_order_sync_states_version CHECK (last_record_version >= 0),
    CONSTRAINT chk_sales_order_sync_states_cancel_version CHECK (
        (cancelled_at IS NULL AND cancelled_record_version IS NULL)
        OR (cancelled_at IS NOT NULL AND cancelled_record_version IS NOT NULL
            AND cancelled_record_version >= 1)
    ),
    CONSTRAINT chk_sales_order_sync_states_attempts CHECK (sync_attempts BETWEEN 0 AND 3)
);
