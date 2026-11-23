# route_manifests

Manifiesto de una ruta: una foto congelada de sus paradas en un momento clave (al confirmarla, al iniciarla o tras un cambio posterior). El manifiesto `started` es la base para medir la finalización de paradas; los cambios posteriores agregan una versión nueva y no reescriben el histórico inicial (ES-302, Dashboard 2).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| route_manifest_id | SERIAL | NO | auto | Identificador del manifiesto |
| route_batch_id | INT | NO | — | Lote al que pertenece |
| manifest_version | INT | NO | — | 1, 2, ... por lote (`>= 1`); un cambio posterior agrega una versión |
| kind | VARCHAR(20) | NO | — | `confirmed` (2.ª aprobación), `started` (inicio de ruta) o `revised` (cambio posterior al inicio) |
| route_version | INT | NO | — | `route_batches.version` del lote cuando se congeló (`>= 0`) |
| vehicle_id | INT | YES | — | Vehículo del lote en ese momento |
| driver_id | INT | YES | — | Repartidor del lote en ese momento |
| actor_user_id | INT | YES | — | Usuario que originó el manifiesto; NULL si fue el sistema |
| reason | TEXT | YES | — | Motivo declarado; obligatorio en `revised` |
| created_at | TIMESTAMPTZ | NO | NOW() | Cuándo se congeló |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| route_batch_id | route_batches.route_batch_id | Lote (`ON DELETE RESTRICT`) |
| vehicle_id | vehicles.vehicle_id | Vehículo en ese momento (`ON DELETE RESTRICT`) |
| driver_id | users.user_id | Repartidor en ese momento (`ON DELETE RESTRICT`) |
| actor_user_id | users.user_id | Autor del manifiesto (`ON DELETE RESTRICT`) |

Es referenciada por `route_manifest_stops.route_manifest_id`.

## Business rules

- Origen funcional: ES-302 / ST-302.2 y las reglas 6 y 7 de la HU 5.17 (finalización de paradas confirmadas al inicio de ruta con manifiesto congelado; capacidad por versión de ruta).
- **Un manifiesto nunca se edita**: un cambio posterior agrega otro con `manifest_version + 1`. `uq_route_manifests_batch_version` impide repetir la versión de un lote.
- **`confirmed`** se escribe en la 2.ª aprobación (lote a `confirmed`); **`started`** al iniciar la ruta (lote a `in_execution`); **`revised`** cuando cambia el conjunto de paradas de un lote ya iniciado.
- **A lo sumo un `started` por lote** (`uq_route_manifests_started`): es la base de la finalización; no se sustituye. `confirmed` **no** es único por lote a propósito: la cobertura solo pregunta si el despacho estuvo en algún manifiesto `confirmed`, y repetir uno (con otra `manifest_version`) no altera ese resultado.
- `chk_route_manifests_revised_reason`: un `revised` siempre lleva motivo.
- La coherencia entre el tipo de manifiesto y el estado de sus paradas (`confirmed` → `planned`; `started` y `revised` → `departing` o `excluded`) cruza dos tablas y la valida el backend.
- **Sin backfill**: los lotes anteriores a la migración `033` no tienen manifiesto y su finalización se lee como desconocida (N/D).

## Technical notes

- **Tabla de historia append-only**: no tiene `updated_at`. Triggers `trg_route_manifests_prevent_update` / `fn_route_manifests_prevent_update()` (bloquea todo `UPDATE`) y `trg_route_manifests_prevent_delete` / `fn_route_manifests_prevent_delete()` (bloquea `DELETE` salvo `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas).
- Todas las FK usan `ON DELETE RESTRICT`. `uq_route_manifests_batch_version` también cubre las consultas por lote.
- **Restricciones e índices**: `chk_route_manifests_kind` (`confirmed`, `started` o `revised`), `chk_route_manifests_manifest_version` (`>= 1`), `chk_route_manifests_route_version` (`>= 0`) y `chk_route_manifests_revised_reason` (un `revised` exige motivo). `uq_route_manifests_started` es un índice único **parcial** (`WHERE kind = 'started'`). `idx_route_manifests_vehicle_id`, `_driver_id` y `_actor_user_id` cubren las FK que no encabezan un compuesto.
- **Referencia funcional**: la HU 5.17 (Jira ES-302) no está en `docs/` ni tiene aún un RF; el origen es esa historia.
- Creada por la migración `033_20261122_1100_create_planning_cutoffs_and_route_manifests` (ST-302.2). El backend debe agregar la entidad correspondiente.
