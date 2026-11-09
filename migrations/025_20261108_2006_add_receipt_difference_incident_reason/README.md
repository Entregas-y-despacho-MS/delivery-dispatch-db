# add_receipt_difference_incident_reason

ST-240.2 (ES-251, ERP-08) — el consumidor de `inventory.receipt.confirmed` abre una incidencia
(`dispatch_incidents`) cuando Almacén confirma una recepción con `result: with_differences` o
`rejected`. No existía ningún `incident_reasons` para eso: los 5 motivos actuales son todos para
incidencias que reporta el repartidor en ruta (`requires_evidence`/`counts_as_attempt` pensados
para ese flujo), no para un resultado que el propio backend recibe de otro microservicio.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `incident_reasons` | Fila nueva `INC-RECEIPT-DIFF`, `requires_evidence = FALSE` y `counts_as_attempt = FALSE` (lo crea el sistema, no el repartidor, ninguna de las dos reglas aplica). |

## `down.sql`

Elimina la fila por `code`. No hay backfill: ningún consumidor la usó todavía.
