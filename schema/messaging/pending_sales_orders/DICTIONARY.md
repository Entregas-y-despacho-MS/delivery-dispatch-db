# pending_sales_orders

Información canónica de entrega recibida para un pedido de venta. Se conserva después de crear el despacho para aplicar cambios posteriores.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| sales_order_id | VARCHAR(100) | NO | — | Identificador del pedido de venta en el sistema de origen |
| record_version | BIGINT | NO | — | Versión del registro enviada por el origen |
| payload | JSONB | NO | — | Datos de entrega y pedido validados recibidos del origen |
| consolidated_at | TIMESTAMPTZ | YES | — | Primera vez que se unió el pedido con sus bultos para crear un despacho |
| dispatch_id | INT | YES | — | Despacho de entrega creado a partir del pedido |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que el pedido quedó en espera por primera vez |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización con una versión más reciente |

## Relationships

| Column | Reference | Description |
|--------|-----------|-------------|
| dispatch_id | dispatches.dispatch_id | Despacho creado al consolidar ambos orígenes |

## Business rules

- Se conserva una sola versión pendiente por pedido de venta.
- Una actualización con versión menor o igual a la almacenada no reemplaza el registro. Si llega un mensaje base `confirmed` después de un `updated`, sus campos completan únicamente los bloques que el `updated` no incluyó, aunque su versión sea menor.
- El registro se conserva al consolidar; `consolidated_at` y `dispatch_id` se asignan juntos.
- El payload fusionado conserva el estado actual de Marketplace, incluidos campos que aún no tienen columna en `dispatches`.

## Technical notes

- `sales_order_id` es la clave primaria y cuenta con el índice único necesario para buscar el registro y evitar duplicados.
- `record_version` no puede ser negativo.
- `chk_pending_sales_orders_consolidation` exige que fecha y despacho estén ambos presentes o ambos ausentes.
- `idx_pending_sales_orders_unconsolidated` facilita la recuperación de pedidos sin despacho.
- El trigger `trg_pending_sales_orders_set_updated_at` actualiza `updated_at` en cada cambio.
