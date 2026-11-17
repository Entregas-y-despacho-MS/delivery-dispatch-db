# extend_dispatch_model_for_semiautomatic_planning

ST-49.3 (ES-49 / ES-213) — modelo de datos de la planificación semiautomática (plan v3, §6.1 de
`decisiones-planificacion-semiautomatica.md`). El plan la llama «migración 011»; es la **013**
porque la 011 (`seed_operational_settings`) y la 012 (`create_async_message_storage`) ya existían.
No se edita la 009. No siembra nada en `settings`: la 011 ya contiene todas las claves de §6.3
(`stop_service_minutes` y `planning_margin_pct` siguen sin valor).

## Qué cambia

| Tabla | Cambio |
|---|---|
| `dispatch_statuses` | Agrega `cancelled` (terminal). |
| `route_batches` | `status` (CHECK de 6 valores), `version`, `delivery_zone_id`, `origin_warehouse_id`, `proposed_driver_id`, `reviewer_user_id`, `accepted_at`, `closed_at`; índices únicos parciales `uq_route_batches_vehicle_shift_date` y `uq_route_batches_driver_shift_date` (excluyen `cancelled` y nulos). |
| `dispatches` | `version`, `customer_confirmation` (CHECK), `promise_notified_at`, `promise_firmed_at`, `order_confirmed_at`, `origin_warehouse_id`. |
| `route_batch_events` | Tabla nueva append-only (UPDATE bloqueado; DELETE solo con `app.allow_event_purge = 'on'`). |
| `dispatch_events` | `actor_user_id` (FK `RESTRICT`), `actor_type` (CHECK), `reason`, `metadata JSONB`; FK `dispatch_id` pasa de `CASCADE` a `RESTRICT`; mismos triggers de inmutabilidad. |
| `dispatch_reschedules` | `rescheduled_by_type` (`customer`, `coordinator`, `system`), `NOT NULL`. |
| `reschedule_reasons` | Siembra `RES-CLI-SELF` (autoservicio del cliente). |
| `incident_reasons` | `counts_as_attempt` (default `FALSE`; `INC-CUST-ABSENT` e `INC-ADDR-INVALID` en `TRUE`); siembra `INC-COMP-FAILURE`. |
| `vehicles` | `max_package_length_cm`, `max_package_width_cm`, `max_package_height_cm` (nullable, CHECK `> 0`). |
| `service_levels` | Express queda con `active = FALSE`. |

## Efecto sobre las filas existentes

- **`route_batches.status`**: filas con `shift_date` anterior a hoy (fecha en `America/La_Paz`, no la del huso de la sesión) → `closed`; el resto → `confirmed`.
  Nunca `provisional`. `closed_at` queda `NULL` en las cerradas por backfill (el momento real no se
  conoce). Después del backfill la columna pasa a `NOT NULL` **sin default**: quien inserte un lote
  debe indicar `status`.
- **`dispatches`**: filas existentes quedan con `version = 0` y `customer_confirmation = 'pending'`;
  el resto de columnas, `NULL`.
- **`dispatch_events`**: las filas existentes quedan con `actor_type`, `actor_user_id`, `reason` y
  `metadata` en `NULL` (no se sabe quién las generó). `actor_type` es nullable a propósito.
- **`dispatch_reschedules.rescheduled_by_type`**: `system` si `rescheduled_by` es `NULL`;
  `coordinator` si tiene usuario (decisión propia: el plan solo fija el caso `NULL`). Sin default:
  quien inserte debe indicarlo.
- **`incident_reasons`**: solo los códigos `INC-CUST-ABSENT` e `INC-ADDR-INVALID` pasan a `TRUE`; el
  resto, incluidos los motivos creados por el equipo, queda en `FALSE`.

## Decisiones propias (no fijadas por el plan)

**Duplicados del Sprint 1 (A-4).** El plan exige detectar los duplicados antes de crear los índices
únicos y documentar el tratamiento, pero no lo define. Tratamiento adoptado:

1. Un grupo es el conjunto de lotes no cancelados con el mismo `vehicle_id` (o `driver_id`) y la
   misma `shift_date`. Incluye lotes históricos `closed`: el índice único los abarca (el plan solo
   excluye `cancelled`), así que sus duplicados también deben resolverse para poder crearlo.
2. Se conserva la asignación del lote **con más despachos** (a igualdad, el de mayor `route_batch_id`); en los demás la columna
   (`vehicle_id` o `driver_id`) pasa a `NULL`. Un lote puede existir sin asignar, y el estado
   (`status`) y los despachos del lote no cambian.
3. Cada limpieza deja un evento `migration_013_assignment_cleared` en `route_batch_events`
   (`actor_type = 'system'`, `metadata` con `field`, el valor anterior, `shift_date` y
   `kept_route_batch_id`) y un `RAISE NOTICE`.
4. Si no hay duplicados, no hace nada.

**Datos semilla.** Motivo de autoservicio: `RES-CLI-SELF` / «Customer self-service reschedule» /
categoría `client`. Falla de la empresa: `INC-COMP-FAILURE` / «Company or vehicle failure»
(`requires_evidence = FALSE`, `counts_as_attempt = FALSE`).

**Detalles de diseño.** `proposed_driver_id` y `reviewer_user_id` usan `ON DELETE SET NULL` (como
`driver_id`); el plan no fija el `ON DELETE`. `route_batch_events.actor_type` es `NOT NULL` por ser
una tabla nueva. El bloqueo de `DELETE` no cubre `TRUNCATE` (inmutabilidad por convención).

## Efecto en el backend (no se modifica en esta subtarea)

El backend actual **falla contra una base migrada** hasta que llegue ST-49.4. Avisar al equipo antes
de aplicar la 013 en una base compartida (`dev`/`test`):

- `INSERT INTO route_batches` sin `status` y `INSERT INTO dispatch_reschedules` sin
  `rescheduled_by_type` fallan con `23502` (ambas columnas son `NOT NULL` sin default, como pide el plan).
- `DELETE FROM dispatches` falla con `23503` para cualquier despacho con eventos
  (`dispatch_events.dispatch_id` ahora es `RESTRICT`), no solo en las pruebas: un despacho se anula
  (`cancelled`), no se borra.
- Los `DELETE` y `UPDATE` sobre `dispatch_events` y `route_batch_events` quedan bloqueados. La
  limpieza de las pruebas e2e debe hacerse con `SET LOCAL app.allow_event_purge = 'on'` y borrando
  primero `dispatch_events` y `route_batch_events` (A-3). Lo resuelve ST-49.4.

## Qué hace `down.sql`

Revierte en orden inverso, pensado para desarrollo, no para producción. Hay que tener presente:

- **Pierde datos nuevos**: elimina las columnas agregadas con su contenido (`status`, `closed_at`,
  `proposed_driver_id`… de `route_batches`; `actor_user_id`, `actor_type`, `reason`, `metadata` de
  `dispatch_events`; las de `dispatches`, `dispatch_reschedules`, `incident_reasons` y `vehicles`) y
  la tabla `route_batch_events` completa.
- **Restaura asignaciones** limpiadas por duplicado desde `route_batch_events`, solo si la columna
  sigue en `NULL`, el lote no está `cancelled` y el vehículo o usuario sigue existiendo. Puede
  reponer un valor que alguien dejó en `NULL` a propósito después de la migración.
- **Reactiva Express** (su valor de semilla). Si alguien lo había desactivado a propósito antes de la
  migración, el rollback lo deja activo.
- **Elimina `cancelled`, `RES-CLI-SELF` e `INC-COMP-FAILURE` solo si nada los usa**. Si el equipo ya
  tenía un motivo con ese mismo código antes de la migración, `up.sql` no insertó el suyo
  (`ON CONFLICT DO NOTHING`) y `down.sql` lo borrará si nadie lo usa.
