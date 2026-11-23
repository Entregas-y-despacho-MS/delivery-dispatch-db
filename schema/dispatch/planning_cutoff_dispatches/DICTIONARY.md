# planning_cutoff_dispatches

El universo de un corte de planificación: cada despacho que el corte leyó, marcado como elegible o excluido con código y explicación. Con esta tabla la cobertura al corte se calcula sobre el mismo denominador (los `eligible` del corte) y cada exclusión es explicable (ES-302, Dashboard 2).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| planning_cutoff_dispatch_id | SERIAL | NO | auto | Identificador de la fila |
| planning_cutoff_id | INT | NO | — | Corte al que pertenece |
| dispatch_id | INT | NO | — | Despacho evaluado |
| universe_status | VARCHAR(20) | NO | — | `eligible` (entra al denominador) o `excluded` |
| exclusion_code | VARCHAR(40) | YES | — | Código del motivo (`^[a-z][a-z0-9_]{1,39}$`, p. ej. `cutoff_window_open`, `cutoff_no_promise`); NULL si es elegible |
| exclusion_detail | TEXT | YES | — | Explicación legible del motivo, tal como se dio en el corte; NULL si es elegible |
| route_batch_id | INT | NO | — | Lote provisional en que estaba el despacho al leer el corte |
| route_version | INT | NO | — | `route_batches.version` de ese lote al leer el corte |
| dispatch_type_id | INT | NO | — | Tipo del despacho (entrega, recojo...) |
| delivery_zone_id | INT | YES | — | Zona del lote al leer el corte |
| origin_warehouse_id | INT | YES | — | Almacén de origen del lote al leer el corte; NULL si el lote no lo tenía |
| scheduled_window_start | TIMESTAMPTZ | YES | — | Inicio de la ventana prometida al leer el corte (sirve para el turno); NULL si no tenía |
| created_at | TIMESTAMPTZ | NO | NOW() | Cuándo se guardó la fila |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| planning_cutoff_id | planning_cutoffs.planning_cutoff_id | Corte (`ON DELETE RESTRICT`) |
| dispatch_id | dispatches.dispatch_id | Despacho evaluado (`ON DELETE RESTRICT`) |
| route_batch_id | route_batches.route_batch_id | Lote en que estaba al leer el corte (`ON DELETE RESTRICT`) |
| dispatch_type_id | dispatch_types.dispatch_type_id | Tipo del despacho (`ON DELETE RESTRICT`) |
| delivery_zone_id | delivery_zones.delivery_zone_id | Zona (`ON DELETE RESTRICT`) |
| origin_warehouse_id | warehouses.warehouse_id | Almacén de origen (`ON DELETE RESTRICT`) |

## Business rules

- Origen funcional: ES-302 / ST-302.2 y la regla 5 de la HU 5.17: la cobertura usa como denominador los despachos elegibles **en ese mismo corte**, registra el snapshot y el motivo de exclusión.
- **Una fila por despacho y corte**: `(planning_cutoff_id, dispatch_id)` es único.
- **Cada exclusión tiene código y explicación**: `chk_planning_cutoff_dispatches_exclusion` exige ambos si `universe_status = 'excluded'` y prohíbe ambos si es `eligible`. El catálogo de códigos vive en el backend (no es un `CHECK`), porque crece con las reglas del corte.
- **Elegible** es el despacho cuya promesa es firme, que es un recojo, o cuya ventana de respuesta del cliente ya venció. **Excluido** es el que espera con la ventana abierta (`cutoff_window_open`) o el que nunca fue aprobado y vuelve a `pending` (`cutoff_no_promise`). Un despacho elegible cuyo lote no se pudo simular sigue siendo elegible (queda en el denominador y sin confirmar).
- El lote, la versión de ruta, la zona, el almacén y el inicio de ventana son los de **la lectura del corte**, no los actuales: permiten filtrar el snapshot sin reconstruirlo.
- **Sin backfill**: los cortes anteriores a la migración `033` no tienen filas.

## Technical notes

- **Tabla de historia append-only**: no tiene `updated_at`. Triggers `trg_planning_cutoff_dispatches_prevent_update` / `fn_planning_cutoff_dispatches_prevent_update()` (bloquea todo `UPDATE`) y `trg_planning_cutoff_dispatches_prevent_delete` / `fn_planning_cutoff_dispatches_prevent_delete()` (bloquea `DELETE` salvo `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas).
- Todas las FK usan `ON DELETE RESTRICT`: un corte, despacho o lote con historia no se borra en silencio. Cualquier limpieza de datos (seeds, e2e) debe borrar antes estas filas, con `app.allow_event_purge = 'on'`.
- `uq_planning_cutoff_dispatches_cutoff_dispatch` cubre las consultas por corte y despacho; `idx_planning_cutoff_dispatches_cutoff_status` sirve para contar elegibles y excluidos de un corte.
- **Restricciones e índices**: `chk_planning_cutoff_dispatches_universe_status` (`eligible` o `excluded`) y `chk_planning_cutoff_dispatches_exclusion` (código y explicación presentes solo si es `excluded`, con el formato del código). Un índice por cada FK que no encabeza un compuesto: `idx_planning_cutoff_dispatches_dispatch_id`, `_route_batch_id`, `_dispatch_type_id`, `_delivery_zone_id` y `_origin_warehouse_id`, para filtrar el snapshot por despacho, lote, tipo, zona y almacén.
- **Referencia funcional**: la HU 5.17 (Jira ES-302) no está en `docs/` ni tiene aún un RF; el origen es esa historia.
- Creada por la migración `033_20261122_1100_create_planning_cutoffs_and_route_manifests` (ST-302.2). El backend debe agregar la entidad correspondiente.
