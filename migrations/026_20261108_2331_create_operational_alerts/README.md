# create_operational_alerts

ST-66.1 (ES-278, RF-A19) — modela las alertas operativas que el evaluador del backend (ST-66.2)
va a levantar para el supervisor de flota: incidencia crítica de un despacho, repartidor sin
reportar GPS, muchas incidencias de un repartidor en el día, y SLA de zona bajo el umbral
(umbrales ya sembrados en la migración 023).

## Por qué hacía falta

No existía ninguna tabla para registrar estas alertas — son datos operativos nuevos, no una
extensión de una tabla existente. El sujeto de cada alerta depende de su tipo (`kind`), así que
`zone_id`/`dispatch_id`/`driver_id`/`vehicle_id` son todos nullable y cada fila completa solo el
que corresponda.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `operational_alerts` | Tabla nueva. |
| `uq_operational_alerts_open_subject` | Índice único parcial (`WHERE status = 'open'`) sobre (`kind`, `zone_id`, `dispatch_id`, `driver_id`, `vehicle_id`) — evita dos alertas abiertas del mismo tipo y sujeto. |
| `chk_operational_alerts_acknowledged` | CHECK que correlaciona `status` con `acknowledged_by`/`acknowledged_at`. |

## `down.sql`

Elimina la tabla, su trigger y su función. No hay backfill: ningún consumidor la usó todavía.
