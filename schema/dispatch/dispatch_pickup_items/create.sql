CREATE TABLE dispatch_pickup_items (
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

CREATE INDEX idx_dispatch_pickup_items_dispatch_id ON dispatch_pickup_items(dispatch_id);
