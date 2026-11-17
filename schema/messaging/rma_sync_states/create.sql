-- Durable high-water mark for each RMA pickup order, keyed by the external rmaId.
CREATE TABLE rma_sync_states (
    rma_id               VARCHAR(100) NOT NULL,                     -- external RMA identifier (inventory.return.requested)
    last_record_version  BIGINT       NOT NULL DEFAULT 0,           -- highest recordVersion received; 0 means none yet
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (rma_id),
    CONSTRAINT chk_rma_sync_states_version CHECK (last_record_version >= 0)
);
