-- ST-240.1 (ES-240, ERP-08): model the warehouse receipt confirmation (`inventory.receipt.confirmed`)
-- so the inbound consumer (ST-240.2) can close an RMA pickup or a supplier pickup, record
-- differences per item, and track idempotency per receiptId.

CREATE TABLE IF NOT EXISTS warehouse_receipts (
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

CREATE INDEX IF NOT EXISTS idx_warehouse_receipts_reference  ON warehouse_receipts(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_receipts_dispatch_id ON warehouse_receipts(dispatch_id);

CREATE OR REPLACE FUNCTION fn_warehouse_receipts_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_warehouse_receipts_set_updated_at ON warehouse_receipts;
CREATE TRIGGER trg_warehouse_receipts_set_updated_at
    BEFORE UPDATE ON warehouse_receipts
    FOR EACH ROW EXECUTE FUNCTION fn_warehouse_receipts_set_updated_at();

CREATE TABLE IF NOT EXISTS warehouse_receipt_items (
    warehouse_receipt_item_id SERIAL,
    receipt_id                 VARCHAR(100)    NOT NULL,                       -- recepción a la que pertenece
    package_id                 INT             ,                               -- bulto ya registrado, cuando aplica
    item_code                  VARCHAR(100)    ,                               -- código del producto en el sistema origen, cuando aplica
    accepted_quantity          NUMERIC(10,2)   NOT NULL DEFAULT 0,             -- cantidad aceptada en buen estado
    missing_quantity           NUMERIC(10,2)   NOT NULL DEFAULT 0,             -- cantidad declarada faltante
    damaged_quantity           NUMERIC(10,2)   NOT NULL DEFAULT 0,             -- cantidad recibida pero dañada
    detail                      TEXT           ,                               -- detalle libre de la diferencia (ej. motivo del daño)
    created_at                  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (warehouse_receipt_item_id),
    FOREIGN KEY (receipt_id) REFERENCES warehouse_receipts(receipt_id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES dispatch_packages(dispatch_package_id) ON DELETE SET NULL,
    CONSTRAINT chk_warehouse_receipt_items_item_ref CHECK (
        (package_id IS NOT NULL)::int + (item_code IS NOT NULL)::int = 1
    ),
    CONSTRAINT chk_warehouse_receipt_items_quantities CHECK (
        accepted_quantity >= 0 AND missing_quantity >= 0 AND damaged_quantity >= 0
    )
);

CREATE INDEX IF NOT EXISTS idx_warehouse_receipt_items_receipt_id ON warehouse_receipt_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_receipt_items_package_id ON warehouse_receipt_items(package_id);

CREATE OR REPLACE FUNCTION fn_warehouse_receipt_items_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_warehouse_receipt_items_set_updated_at ON warehouse_receipt_items;
CREATE TRIGGER trg_warehouse_receipt_items_set_updated_at
    BEFORE UPDATE ON warehouse_receipt_items
    FOR EACH ROW EXECUTE FUNCTION fn_warehouse_receipt_items_set_updated_at();
