# rma_sync_states

Estado de recepción de cada recojo de devolución (RMA) que publica Inventarios y Almacén. Permite
conservar la versión más alta recibida por `rmaId`, incluso después de crear el despacho.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| rma_id | VARCHAR(100) | NO | — | Identificador externo del RMA (`inventory.return.requested`) |
| last_record_version | BIGINT | NO | 0 | Versión más alta recibida para este RMA; 0 indica que aún no llegó ninguna |
| created_at | TIMESTAMPTZ | NO | NOW() | Primera vez que se registró el estado |
| updated_at | TIMESTAMPTZ | NO | NOW() | Último cambio del estado |

## Business rules

- Un mensaje con `recordVersion` menor o igual al guardado se ignora (idempotencia de negocio,
  además de la idempotencia por `messageId` de `inbound_messages`).
- La fila se crea con la primera versión recibida; no existe "versión 0" real salvo que el
  recuperador necesite crearla preventivamente.

## Technical notes

- El trigger `trg_rma_sync_states_set_updated_at` actualiza `updated_at`.
- No comparte tabla con `sales_order_sync_states`: esa tabla es específica del flujo de pedidos de
  venta (Marketplace/Inventarios, ST-72.x) — su clave `(sales_order_id, source)` y columnas
  (`base_received`, `cancelled_at`, `sync_attempts`) no tienen equivalente de negocio para un RMA.
