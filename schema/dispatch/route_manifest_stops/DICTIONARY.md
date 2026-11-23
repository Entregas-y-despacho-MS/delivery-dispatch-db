# route_manifest_stops

Las paradas de un manifiesto de ruta (`route_manifests`): qué despachos formaban la ruta en ese momento, en qué orden y si salían o quedaron excluidos (por ejemplo por un cotejo de bultos fallido). Con el manifiesto `started` se mide la finalización por parada sin esperar el cierre del lote (ES-302, Dashboard 2).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| route_manifest_stop_id | SERIAL | NO | auto | Identificador de la fila |
| route_manifest_id | INT | NO | — | Manifiesto al que pertenece |
| dispatch_id | INT | NO | — | Despacho de la parada |
| dispatch_type_id | INT | NO | — | Tipo del despacho (entrega, recojo...); separa entregas de recojos |
| sequence_order | INT | YES | — | Orden de visita en ese momento (`>= 1`); NULL si no tenía |
| stop_state | VARCHAR(20) | NO | — | `planned` (manifiesto `confirmed`), `departing` (sale) o `excluded` (no sale) |
| exclusion_code | VARCHAR(40) | YES | — | Motivo de la exclusión (`^[a-z][a-z0-9_]{1,39}$`, p. ej. `cotejo_failed`); NULL salvo `excluded` |
| created_at | TIMESTAMPTZ | NO | NOW() | Cuándo se guardó la fila |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| route_manifest_id | route_manifests.route_manifest_id | Manifiesto (`ON DELETE RESTRICT`) |
| dispatch_id | dispatches.dispatch_id | Despacho de la parada (`ON DELETE RESTRICT`) |
| dispatch_type_id | dispatch_types.dispatch_type_id | Tipo del despacho (`ON DELETE RESTRICT`) |

## Business rules

- Origen funcional: ES-302 / ST-302.2 y la regla 6 de la HU 5.17: separar entrega, recojo, cancelación previa y resultado no exitoso.
- **Una parada por despacho y manifiesto**: `(route_manifest_id, dispatch_id)` es único.
- `chk_route_manifest_stops_exclusion_code`: una parada `excluded` siempre lleva código; las demás nunca.
- **Cancelación previa** = parada presente en el manifiesto `confirmed` y ausente (o excluida) en el `started`. El resultado actual de la parada (entregada, recojo completado, no exitosa, pendiente) no se guarda acá: se lee del despacho, así el denominador del manifiesto no cambia aunque la ruta avance.
- La coherencia entre `stop_state` y el `kind` del manifiesto la valida el backend (cruza dos tablas).
- **Sin backfill**: los lotes anteriores a la migración `033` no tienen paradas de manifiesto.

## Technical notes

- **Tabla de historia append-only**: no tiene `updated_at`. Triggers `trg_route_manifest_stops_prevent_update` / `fn_route_manifest_stops_prevent_update()` (bloquea todo `UPDATE`) y `trg_route_manifest_stops_prevent_delete` / `fn_route_manifest_stops_prevent_delete()` (bloquea `DELETE` salvo `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas).
- Todas las FK usan `ON DELETE RESTRICT`: un despacho con paradas de manifiesto no se borra físicamente; la limpieza de datos (seeds, e2e) debe borrar antes estas filas, con `app.allow_event_purge = 'on'`.
- `uq_route_manifest_stops_manifest_dispatch` también cubre las consultas por manifiesto.
- **Restricciones e índices**: `chk_route_manifest_stops_stop_state` (`planned`, `departing` o `excluded`), `chk_route_manifest_stops_exclusion_code` (código solo en `excluded`, con formato válido) y `chk_route_manifest_stops_sequence_order` (`>= 1`). `idx_route_manifest_stops_dispatch_id` y `_dispatch_type_id` cubren las FK que no encabezan un compuesto.
- **`exclusion_code`**: el ejemplo `cotejo_failed` es un nombre propuesto; el catálogo real de códigos lo define el backend al escribir el manifiesto de inicio (ST-302.2, etapa del backend) y debe ajustarse a este formato.
- **Referencia funcional**: la HU 5.17 (Jira ES-302) no está en `docs/` ni tiene aún un RF; el origen es esa historia.
- Creada por la migración `033_20261122_1100_create_planning_cutoffs_and_route_manifests` (ST-302.2). El backend debe agregar la entidad correspondiente.
