# pending_shipments

Información canónica de bultos recibida para un pedido de venta. Se conserva después de crear el despacho para aplicar cambios posteriores.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| sales_order_id | VARCHAR(100) | NO | — | Identificador del pedido de venta asociado a los bultos |
| record_version | BIGINT | NO | — | Versión del registro enviada por el origen |
| payload | JSONB | NO | — | Datos de bultos validados recibidos del almacén |
| consolidated_at | TIMESTAMPTZ | YES | — | Primera vez que se unieron los bultos con los datos de entrega |
| dispatch_id | INT | YES | — | Despacho de entrega creado con estos bultos |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que los bultos quedaron en espera por primera vez |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización con una versión más reciente |

## Relationships

| Column | Reference | Description |
|--------|-----------|-------------|
| dispatch_id | dispatches.dispatch_id | Despacho creado al consolidar ambos orígenes |

## Business rules

- Se conserva una sola versión pendiente de bultos por pedido de venta.
- Una actualización con versión menor o igual a la almacenada no reemplaza el registro. Si llega un mensaje base `ready` después de un `updated`, sus campos completan únicamente los bloques que el `updated` no incluyó, aunque su versión sea menor.
- El registro se conserva al consolidar; `consolidated_at` y `dispatch_id` se asignan juntos.
- El payload fusionado conserva el estado actual de Almacén, incluso después de crear el despacho.

## Technical notes

- `sales_order_id` es la clave primaria y cuenta con el índice único necesario para buscar el registro y evitar duplicados.
- `record_version` no puede ser negativo.
- `chk_pending_shipments_consolidation` exige que fecha y despacho estén ambos presentes o ambos ausentes.
- `idx_pending_shipments_unconsolidated` facilita la recuperación de pedidos sin despacho.
- El trigger `trg_pending_shipments_set_updated_at` actualiza `updated_at` en cada cambio.
