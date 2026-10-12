# extend_dispatch_model_for_semiautomatic_planning

ST-49.3 (ES-49 / ES-213) — modelo de datos de la planificación semiautomática (plan v3, §6.1 de
`decisiones-planificacion-semiautomatica.md`). El plan la llama «migración 011»; es la **013**
porque la 011 (`seed_operational_settings`) y la 012 (`create_async_message_storage`) ya existían.
No se edita la 009.

## Qué cambia

| Tabla | Cambio |
|---|---|
| `dispatch_statuses` | Agrega `cancelled` (terminal). |
| `route_batches` | `status` (CHECK de 6 valores), `version`, `delivery_zone_id`, `origin_warehouse_id`, `proposed_driver_id`, `reviewer_user_id`, `accepted_at`, `closed_at`; índices únicos parciales `uq_route_batches_vehicle_shift_date` y `uq_route_batches_driver_shift_date` (excluyen `cancelled` y nulos). |
| `dispatches` | `version`, `customer_confirmation` (CHECK), `promise_notified_at`, `promise_firmed_at`, `order_confirmed_at`, `origin_warehouse_id`. |
| `route_batch_events` | Tabla nueva append-only (UPDATE bloqueado; DELETE solo con `app.allow_event_purge = 'on'`). |

## Efecto sobre las filas existentes

- **`route_batches.status`**: filas con `shift_date` anterior a hoy → `closed`; el resto → `confirmed`.
  Nunca `provisional`. `closed_at` queda `NULL` en las cerradas por backfill (el momento real no se
  conoce). Después del backfill la columna pasa a `NOT NULL` **sin default**: quien inserte un lote
  debe indicar `status`.
- **`dispatches`**: filas existentes quedan con `version = 0` y `customer_confirmation = 'pending'`;
  el resto de columnas, `NULL`.

## Decisión propia: duplicados del Sprint 1 (A-4 del plan)

El plan exige detectar los duplicados antes de crear los índices únicos y documentar el
tratamiento, pero no lo define. Tratamiento adoptado:

1. Un grupo es el conjunto de lotes no cancelados con el mismo `vehicle_id` (o `driver_id`) y la
   misma `shift_date`.
2. Se conserva la asignación del lote de **mayor `route_batch_id`**; en los demás la columna
   (`vehicle_id` o `driver_id`) pasa a `NULL`. Un lote puede existir sin asignar, y el estado
   (`status`) y los despachos del lote no cambian.
3. Cada limpieza deja un evento `migration_013_assignment_cleared` en `route_batch_events`
   (`actor_type = 'system'`, `metadata` con `field`, el valor anterior, `shift_date` y
   `kept_route_batch_id`) y un `RAISE NOTICE`.
4. Si no hay duplicados, no hace nada.

`down.sql` restaura esos valores desde los eventos (si el vehículo o usuario sigue existiendo y la
columna sigue en `NULL`) antes de eliminar la tabla.

## Qué hace `down.sql`

Revierte en orden inverso. Elimina `cancelled` solo si ningún despacho lo usa. Eliminar
`route_batch_events` descarta los eventos que se hayan registrado después de aplicar la migración:
es una reversión de desarrollo, no de producción.
