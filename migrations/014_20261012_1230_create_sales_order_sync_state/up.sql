-- ST-72.1: per-origin state, retained pending data, and one delivery per sales order.

ALTER TABLE dispatches
    ADD COLUMN IF NOT EXISTS delivery_reference TEXT,
    ADD COLUMN IF NOT EXISTS shipment_ready BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS sales_order_sync_states (
    sales_order_id          VARCHAR(100) NOT NULL,
    source                  VARCHAR(20)  NOT NULL,
    last_record_version     BIGINT       NOT NULL DEFAULT 0,
    base_received           BOOLEAN      NOT NULL DEFAULT FALSE,
    cancelled_at            TIMESTAMPTZ,
    cancelled_record_version BIGINT,
    sync_attempts           SMALLINT     NOT NULL DEFAULT 0,
    last_sync_requested_at  TIMESTAMPTZ,
    incomplete_alerted_at   TIMESTAMPTZ,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id, source),
    CONSTRAINT chk_sales_order_sync_states_source CHECK (source IN ('marketplace', 'inventory')),
    CONSTRAINT chk_sales_order_sync_states_version CHECK (last_record_version >= 0),
    CONSTRAINT chk_sales_order_sync_states_cancel_version CHECK (
        (cancelled_at IS NULL AND cancelled_record_version IS NULL)
        OR (cancelled_at IS NOT NULL AND cancelled_record_version IS NOT NULL
            AND cancelled_record_version >= 1)
    ),
    CONSTRAINT chk_sales_order_sync_states_attempts CHECK (sync_attempts BETWEEN 0 AND 3)
);

CREATE OR REPLACE FUNCTION fn_sales_order_sync_states_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sales_order_sync_states_set_updated_at ON sales_order_sync_states;
CREATE TRIGGER trg_sales_order_sync_states_set_updated_at
    BEFORE UPDATE ON sales_order_sync_states
    FOR EACH ROW EXECUTE FUNCTION fn_sales_order_sync_states_set_updated_at();

ALTER TABLE pending_sales_orders
    ADD COLUMN IF NOT EXISTS consolidated_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS dispatch_id INT;
ALTER TABLE pending_shipments
    ADD COLUMN IF NOT EXISTS consolidated_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS dispatch_id INT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_pending_sales_orders_consolidation'
        AND conrelid = 'pending_sales_orders'::regclass) THEN
        ALTER TABLE pending_sales_orders ADD CONSTRAINT chk_pending_sales_orders_consolidation
            CHECK ((consolidated_at IS NULL) = (dispatch_id IS NULL));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_pending_shipments_consolidation'
        AND conrelid = 'pending_shipments'::regclass) THEN
        ALTER TABLE pending_shipments ADD CONSTRAINT chk_pending_shipments_consolidation
            CHECK ((consolidated_at IS NULL) = (dispatch_id IS NULL));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pending_sales_orders_dispatch_id_fkey'
        AND conrelid = 'pending_sales_orders'::regclass) THEN
        ALTER TABLE pending_sales_orders ADD CONSTRAINT pending_sales_orders_dispatch_id_fkey
            FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pending_shipments_dispatch_id_fkey'
        AND conrelid = 'pending_shipments'::regclass) THEN
        ALTER TABLE pending_shipments ADD CONSTRAINT pending_shipments_dispatch_id_fkey
            FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE RESTRICT;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pending_sales_orders_dispatch_id ON pending_sales_orders(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_pending_shipments_dispatch_id ON pending_shipments(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_pending_sales_orders_unconsolidated
    ON pending_sales_orders(updated_at) WHERE consolidated_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_pending_shipments_unconsolidated
    ON pending_shipments(updated_at) WHERE consolidated_at IS NULL;

-- Defensive backfill: consumers have not written these tables yet, but preserve any existing data.
INSERT INTO sales_order_sync_states (sales_order_id, source, last_record_version, base_received)
SELECT sales_order_id, 'marketplace', record_version, payload ? 'confirmedAt'
FROM pending_sales_orders
ON CONFLICT (sales_order_id, source) DO NOTHING;

INSERT INTO sales_order_sync_states (sales_order_id, source, last_record_version, base_received)
SELECT sales_order_id, 'inventory', record_version, FALSE
FROM pending_shipments
ON CONFLICT (sales_order_id, source) DO NOTHING;

-- Resolve the delivery type by name; never assume a seed ID. Refuse existing duplicate deliveries.
DO $$
DECLARE
    delivery_type_id INT;
    duplicate_ref VARCHAR(100);
BEGIN
    SELECT dispatch_type_id INTO delivery_type_id FROM dispatch_types WHERE name = 'delivery';
    IF delivery_type_id IS NULL THEN
        RAISE EXCEPTION 'dispatch type delivery is missing';
    END IF;
    SELECT source_order_ref INTO duplicate_ref
    FROM dispatches WHERE dispatch_type_id = delivery_type_id
    GROUP BY source_order_ref HAVING COUNT(*) > 1 LIMIT 1;
    IF duplicate_ref IS NOT NULL THEN
        RAISE EXCEPTION 'duplicate delivery source_order_ref: %', duplicate_ref;
    END IF;
    EXECUTE format(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_dispatches_delivery_source_order_ref '
        || 'ON dispatches(source_order_ref) WHERE dispatch_type_id = %s', delivery_type_id
    );
END $$;
