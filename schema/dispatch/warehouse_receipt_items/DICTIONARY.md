# warehouse_receipt_items

Detalle por ítem de una recepción de Almacén: cuánto se aceptó, cuánto faltó y cuánto llegó dañado de cada bulto o producto.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| warehouse_receipt_item_id | SERIAL | NO | auto | Identificador del detalle |
| receipt_id | VARCHAR(100) | NO | — | Recepción a la que pertenece este detalle |
| package_id | INT | YES | — | Bulto ya registrado del despacho, cuando el ítem corresponde a una entrega |
| item_code | VARCHAR(100) | YES | — | Código del producto en el sistema origen, cuando el ítem viene de una devolución o recogida sin bulto propio |
| accepted_quantity | NUMERIC(10,2) | NO | 0 | Cantidad aceptada en buen estado |
| missing_quantity | NUMERIC(10,2) | NO | 0 | Cantidad declarada faltante respecto de lo esperado |
| damaged_quantity | NUMERIC(10,2) | NO | 0 | Cantidad recibida pero dañada |
| detail | TEXT | YES | — | Detalle libre de la diferencia, por ejemplo el motivo del daño |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| receipt_id | warehouse_receipts.receipt_id | Recepción dueña del detalle (`ON DELETE CASCADE`) |
| package_id | dispatch_packages.dispatch_package_id | Bulto de la entrega que este detalle cubre, cuando corresponde (`ON DELETE SET NULL`) |

## Business rules

- Cada fila identifica su ítem de exactamente una forma: `package_id` **o** `item_code`, nunca ambos ni ninguno.
- Las tres cantidades son independientes entre sí — la suma no está forzada a igualar ninguna cantidad esperada externa, ya que esa referencia vive en el sistema origen (Compras/Almacén), no en este detalle.

## Technical notes

- `chk_warehouse_receipt_items_item_ref` impone la exclusividad `package_id`/`item_code` a nivel de base.
- `updated_at` se mantiene con el trigger `trg_warehouse_receipt_items_set_updated_at`.
