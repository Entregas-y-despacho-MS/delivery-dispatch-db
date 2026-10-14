ALTER TABLE dispatches
    ADD COLUMN IF NOT EXISTS estimated_boxes INT,
    ADD COLUMN IF NOT EXISTS estimated_volume_m3 NUMERIC(10,3),
    ADD COLUMN IF NOT EXISTS transport_conditions TEXT,
    ADD COLUMN IF NOT EXISTS destination_warehouse_id INT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_dispatches_destination_warehouse'
          AND conrelid = 'dispatches'::regclass
    ) THEN
        ALTER TABLE dispatches
            ADD CONSTRAINT fk_dispatches_destination_warehouse
            FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(warehouse_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_dispatches_destination_warehouse_id
    ON dispatches(destination_warehouse_id);

CREATE TABLE IF NOT EXISTS dispatch_pickup_items (
    dispatch_pickup_item_id SERIAL,
    dispatch_id             INT             NOT NULL,                       -- despacho de recogida al que pertenece el producto
    item_code               VARCHAR(100)    NOT NULL,                       -- código del producto en Compras
    description             TEXT            NOT NULL,                       -- descripción recibida de Compras
    expected_quantity       NUMERIC(10,2)   NOT NULL,                       -- cantidad esperada (> 0)
    received_quantity       NUMERIC(10,2),                                  -- cantidad recibida, pendiente hasta la recepción
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_pickup_item_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT uq_dispatch_pickup_items_dispatch_item UNIQUE (dispatch_id, item_code),
    CONSTRAINT chk_dispatch_pickup_items_expected_quantity CHECK (expected_quantity > 0),
    CONSTRAINT chk_dispatch_pickup_items_received_quantity CHECK (received_quantity IS NULL OR received_quantity >= 0)
);

CREATE INDEX IF NOT EXISTS idx_dispatch_pickup_items_dispatch_id
    ON dispatch_pickup_items(dispatch_id);
