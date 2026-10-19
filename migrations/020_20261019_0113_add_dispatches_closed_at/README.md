# add_dispatches_closed_at

ST-55.2 (ES-55, RF-A08) — agrega `dispatches.closed_at`, la fecha de cierre del despacho: el momento
en que llegó a un estado terminal (`delivered`, `not_delivered`, `returned`, `returned_to_warehouse`,
`cancelled`). El historial de despachos filtra y ordena por ella, y ST-33.2 (historial del
repartidor) la reutiliza.

## Por qué hacía falta

Ninguna columna existente sirve: `confirmed_at` no la escribe ningún código y solo aplicaría a las
entregas; `updated_at` cambia con cualquier otra actualización; `route_batches.closed_at` es del
lote, no del despacho. Tampoco se puede filtrar por rango de fechas sobre `dispatch_events` sin un
índice propio.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `dispatches.closed_at` | Columna nueva `TIMESTAMPTZ`, nullable. |
| `fn_dispatches_set_closed_at()` + `trg_dispatches_set_closed_at` | `BEFORE UPDATE OF dispatch_status_id`. Si el estado cambia a uno terminal y quien escribe no informó `closed_at`, lo llena con `NOW()`; si el estado sale de los terminales, lo pone en `NULL`. Si el estado no cambia, no hace nada. |
| `idx_dispatches_closed_at` | Índice parcial sobre `closed_at DESC` donde `closed_at IS NOT NULL`. |

`closed_at` es la **hora del evento**, no la de recepción: la app móvil sincroniza con retraso, así
que el backend escribe el `occurredAt` del dispositivo al cambiar el estado. El trigger es solo un
respaldo para escritores que no lo informan.

## Efecto sobre las filas existentes

- Despachos en estado terminal: `closed_at` = hora del último evento `status_changed` cuyo
  `metadata.status` es el estado actual; si no existe (eventos anteriores a la migración 013 no tienen
  `metadata`), `updated_at`.
- Despachos no terminales: `NULL`.

## `down.sql`

Elimina el índice, el trigger, la función y la columna. Al borrar la columna se pierde su valor, pero
es recalculable con el mismo relleno de esta migración (salvo la hora exacta de eventos sin
`metadata`).
