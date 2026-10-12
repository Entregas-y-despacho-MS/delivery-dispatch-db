# pending_sales_orders

Última información de entrega recibida para un pedido de venta que todavía no tiene su información complementaria de bultos.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| sales_order_id | VARCHAR(100) | NO | — | Identificador del pedido de venta en el sistema de origen |
| record_version | BIGINT | NO | — | Versión del registro enviada por el origen |
| payload | JSONB | NO | — | Datos de entrega y pedido validados recibidos del origen |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que el pedido quedó en espera por primera vez |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización con una versión más reciente |

## Business rules

- Se conserva una sola versión pendiente por pedido de venta.
- Una actualización con versión menor o igual a la almacenada no debe reemplazar el registro.
- El registro permanece en espera hasta que llegue la información complementaria de bultos.

## Technical notes

- `sales_order_id` es la clave primaria y cuenta con el índice único necesario para buscar el registro y evitar duplicados.
- `record_version` no puede ser negativo.
- El trigger `trg_pending_sales_orders_set_updated_at` actualiza `updated_at` en cada cambio.
