# pending_shipments

Última información de bultos recibida para un pedido de venta que todavía no tiene sus datos de entrega.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| sales_order_id | VARCHAR(100) | NO | — | Identificador del pedido de venta asociado a los bultos |
| record_version | BIGINT | NO | — | Versión del registro enviada por el origen |
| payload | JSONB | NO | — | Datos de bultos validados recibidos del almacén |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que los bultos quedaron en espera por primera vez |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización con una versión más reciente |

## Business rules

- Se conserva una sola versión pendiente de bultos por pedido de venta.
- Una actualización con versión menor o igual a la almacenada no debe reemplazar el registro.
- El registro permanece en espera hasta que llegue la información complementaria del pedido.

## Technical notes

- `sales_order_id` es la clave primaria y cuenta con el índice único necesario para buscar el registro y evitar duplicados.
- `record_version` no puede ser negativo.
- El trigger `trg_pending_shipments_set_updated_at` actualiza `updated_at` en cada cambio.
