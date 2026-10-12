-- Canonical Inventory data, retained after a delivery is created.
CREATE TABLE pending_shipments (
    sales_order_id  VARCHAR(100)    NOT NULL,                            -- external sales-order identifier
    record_version  BIGINT          NOT NULL,                            -- producer version used to ignore stale updates
    payload         JSONB           NOT NULL,                            -- validated package/shipment data from the producer
    consolidated_at TIMESTAMPTZ,                                         -- when both origins first created a delivery
    dispatch_id     INT,                                                 -- retained delivery created from this order
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),              -- first time the pending record was stored
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),              -- last time a newer version replaced the payload
    PRIMARY KEY (sales_order_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT,
    CONSTRAINT chk_pending_shipments_record_version CHECK (record_version >= 0),
    CONSTRAINT chk_pending_shipments_consolidation CHECK ((consolidated_at IS NULL) = (dispatch_id IS NULL))
);
CREATE INDEX idx_pending_shipments_dispatch_id ON pending_shipments(dispatch_id);
CREATE INDEX idx_pending_shipments_unconsolidated ON pending_shipments(updated_at)
    WHERE consolidated_at IS NULL;
