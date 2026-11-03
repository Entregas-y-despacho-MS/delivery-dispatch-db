# model_rma_pickup_order

ST-238.1 (ES-238, ERP-07) — modela lo que necesita el consumidor de `inventory.return.requested`
(ST-238.2) para crear la orden de recojo RMA: la fecha preferida de recojo informada por Almacén y
el estado de sincronización por `rmaId` para la idempotencia por `recordVersion`.

## Por qué hacía falta

`dispatches` ya tiene `return_reason`, `estimated_boxes`, `destination_warehouse_id` y
`confirmed_at` (de migraciones anteriores) y se reutilizan sin cambios — pero no tenía la fecha
preferida de recojo del cliente, que es distinta de `scheduled_window_start/end` (esas las define
el planificador, no el RMA entrante).

`sales_order_sync_states` no encaja para los RMA: su clave es `(sales_order_id, source)` y sus
columnas (`base_received`, `cancelled_at`, `sync_attempts`) son específicas del flujo de pedidos de
venta de Marketplace/Inventarios (ST-72.x) — mezclar un `rmaId` ahí como si fuera un
`sales_order_id` sería confuso y no necesita ninguna de esas columnas. Se crea `rma_sync_states`
aparte, con solo lo que el consumidor necesita: la versión más alta recibida por RMA.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `dispatches.preferred_pickup_date` | Columna nueva `TIMESTAMPTZ`, nullable. |
| `rma_sync_states` | Tabla nueva, `rma_id` como PK natural, `last_record_version`. |
| `uq_dispatches_warehouse_return_pickup_source_order_ref` | Índice único parcial — un `rmaId` (guardado en `source_order_ref`) no puede tener dos recojos de devolución, mismo patrón que `uq_dispatches_delivery_source_order_ref` de la migración 014. |

## `down.sql`

Elimina el índice, el trigger, la función, la tabla `rma_sync_states` y la columna
`preferred_pickup_date`. No hay backfill: ningún consumidor escribió estas columnas todavía.
