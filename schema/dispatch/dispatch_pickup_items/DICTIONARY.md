# dispatch_pickup_items

Productos esperados en una recogida a proveedor. Compras conserva la propiedad de la orden de compra; esta tabla guarda la información necesaria para coordinar y confirmar el traslado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_pickup_item_id | SERIAL | NO | auto | Identificador del producto de la recogida |
| dispatch_id | INT | NO | — | Despacho de tipo `supplier_pickup` al que pertenece |
| item_code | VARCHAR(100) | NO | — | Código del producto en Compras; único dentro del despacho |
| description | TEXT | NO | — | Descripción recibida de Compras |
| expected_quantity | NUMERIC(10,2) | NO | — | Cantidad esperada (> 0) |
| received_quantity | NUMERIC(10,2) | YES | — | Cantidad efectivamente recibida; NULL mientras no se registra la recepción |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|-------------|
| dispatch_id | dispatches.dispatch_id | Despacho dueño del producto (`ON DELETE CASCADE`) |

## Business rules

- La combinación de `dispatch_id` e `item_code` es única.
- `expected_quantity` debe ser mayor que cero.
- `received_quantity` es opcional hasta registrar la recepción y, cuando se informa, no puede ser negativa.
- Los productos se reciben mediante mensajes de solicitud de Compras; esta tabla no modifica la orden de compra de origen.
