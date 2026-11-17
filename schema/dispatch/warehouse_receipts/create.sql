-- Confirmación de recepción física que publica Almacén (`inventory.receipt.confirmed`) para una
-- devolución (RMA) o una recogida en proveedor. `receipt_id` es el identificador externo del
-- mensaje (no un SERIAL propio): lo usa el consumidor (ST-240.2) como clave de idempotencia junto
-- con record_version.
CREATE TABLE warehouse_receipts (
    receipt_id          VARCHAR(100)    NOT NULL,                       -- receiptId asignado por Almacén
    dispatch_id         INT             ,                               -- traslado resuelto; NULL si la referencia llegó huérfana
    reference_type      VARCHAR(20)     NOT NULL,                       -- rma | purchase_order
    reference_id        VARCHAR(100)    NOT NULL,                       -- rmaId o id de la orden de compra que originó el traslado
    result              VARCHAR(20)     NOT NULL,                       -- complete | with_differences | rejected
    received_at         TIMESTAMPTZ     NOT NULL,                       -- momento en que Almacén recibió físicamente la mercadería
    record_version      BIGINT          NOT NULL DEFAULT 0,             -- versión del mensaje, para ignorar reintentos/desorden (idempotencia)
    notes                TEXT           ,                               -- observaciones libres de Almacén sobre la recepción
    status               VARCHAR(20)    NOT NULL,                       -- applied | orphan
    created_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (receipt_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE SET NULL,
    CONSTRAINT chk_warehouse_receipts_reference_type CHECK (reference_type IN ('rma', 'purchase_order')),
    CONSTRAINT chk_warehouse_receipts_result CHECK (result IN ('complete', 'with_differences', 'rejected')),
    CONSTRAINT chk_warehouse_receipts_status CHECK (status IN ('applied', 'orphan')),
    CONSTRAINT chk_warehouse_receipts_record_version CHECK (record_version >= 0),
    CONSTRAINT chk_warehouse_receipts_status_dispatch CHECK (
        (status = 'orphan' AND dispatch_id IS NULL) OR (status = 'applied' AND dispatch_id IS NOT NULL)
    )
);

CREATE INDEX idx_warehouse_receipts_reference  ON warehouse_receipts(reference_type, reference_id);
CREATE INDEX idx_warehouse_receipts_dispatch_id ON warehouse_receipts(dispatch_id);
