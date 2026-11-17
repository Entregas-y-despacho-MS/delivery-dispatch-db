-- Detalle por ítem de una recepción: cuánto se aceptó, cuánto faltó y cuánto llegó dañado.
-- Un ítem se identifica de dos formas excluyentes entre sí: package_id cuando corresponde a un
-- bulto ya registrado en dispatch_packages (entregas), o item_code cuando es un producto conocido
-- solo por el sistema origen (RMA/recogida a proveedor, igual que dispatch_pickup_items.item_code).
CREATE TABLE warehouse_receipt_items (
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

CREATE INDEX idx_warehouse_receipt_items_receipt_id ON warehouse_receipt_items(receipt_id);
CREATE INDEX idx_warehouse_receipt_items_package_id ON warehouse_receipt_items(package_id);
