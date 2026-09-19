# dispatch_reschedules

Historial de reprogramaciones y reasignaciones de un despacho: cada vez que cambia su ventana horaria, su ruta asignada, o ambas cosas, queda un registro de cómo estaba antes, cómo quedó, quién lo hizo y por qué.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_reschedule_id | SERIAL | NO | auto | Identificador del registro |
| dispatch_id | INT | NO | — | Despacho reprogramado o reasignado |
| reschedule_reason_id | INT | NO | — | Motivo de la reprogramación o reasignación |
| rescheduled_by | INT | YES | — | Usuario que ejecutó el cambio; NULL si fue automático/del sistema |
| previous_route_batch_id | INT | YES | — | Ruta que tenía el despacho antes de este cambio; NULL si no cambió de ruta o no tenía ninguna asignada |
| new_route_batch_id | INT | YES | — | Ruta nueva; NULL si el cambio no movió al despacho de ruta |
| previous_window_start | TIMESTAMPTZ | YES | — | Inicio de la ventana horaria anterior |
| previous_window_end | TIMESTAMPTZ | YES | — | Fin de la ventana horaria anterior |
| new_window_start | TIMESTAMPTZ | YES | — | Nuevo inicio de ventana horaria; NULL si el cambio fue solo de ruta |
| new_window_end | TIMESTAMPTZ | YES | — | Nuevo fin de ventana horaria; NULL si el cambio fue solo de ruta |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha del cambio |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho al que corresponde este registro |
| reschedule_reason_id | reschedule_reasons.reschedule_reason_id | Motivo (catálogo compartido entre reprogramación y reasignación) |
| rescheduled_by | users.user_id | Usuario (coordinador/supervisor) que ejecutó el cambio |
| previous_route_batch_id | route_batches.route_batch_id | Ruta de la que salió el despacho, si cambió de ruta |
| new_route_batch_id | route_batches.route_batch_id | Ruta a la que entró el despacho, si cambió de ruta |

## Business rules

- Cubre dos casos de uso distintos que comparten el mismo catálogo de motivos (RF-A33, "motivos de reprogramación/reasignación"):
  - **Reprogramación** (RF-A05, coordinador): cambia la ventana horaria de una entrega fallida/rechazada — llena `new_window_start/end`, puede dejar la ruta sin cambios.
  - **Reasignación** (RF-A16, supervisor de flota): mueve el despacho a otra ruta ante una contingencia (vehículo averiado, repartidor no disponible) — llena `new_route_batch_id`, puede dejar la ventana sin cambios.
  - Un mismo evento puede cambiar las dos cosas a la vez.
- Cada cambio también actualiza el valor vigente correspondiente en `dispatches` (`scheduled_window_start/end` y/o `route_batch_id`) — esta tabla es el historial, `dispatches` siempre refleja lo actual.
- `previous_window_start/end` y `previous_route_batch_id` pueden venir NULL si el despacho todavía no tenía ventana u ruta asignada antes de este cambio.

## Technical notes

- `dispatch_id` usa `ON DELETE CASCADE`: el historial no tiene sentido si se elimina el despacho.
- `previous_route_batch_id`/`new_route_batch_id` usan `ON DELETE SET NULL`: si esa ruta se elimina más adelante, el registro histórico se conserva, solo pierde la referencia.
- `chk_dispatch_reschedules_has_change` impide una fila que no cambie ni ventana ni ruta (evita registros vacíos sin sentido).
- Tabla append-only: un registro ya escrito no se modifica, por eso no tiene `updated_at`.
