# order_dispatch_events

Historial inmutable de los eventos de negocio de cada pedido y despacho (creación, asignación, cambios de estado): quién los originó, con qué rol, qué estado cambió, con qué resultado y en qué solicitud (RF-A36, ES-69).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| order_dispatch_event_id | UUID | NO | — | Identificador del evento (`eventId`), generado por la aplicación; permite reintentar la inserción sin duplicar |
| source_order_ref | VARCHAR(100) | NO | — | Pedido en el sistema origen (`dispatches.source_order_ref`). Sin FK: un pedido puede tener varios despachos |
| dispatch_id | INT | YES | — | Despacho al que corresponde el evento (`dispatches.dispatch_id`); NULL en eventos previos a que exista el despacho |
| route_batch_id | INT | YES | — | Lote de ruta involucrado (`route_batches.route_batch_id`), si hay uno |
| actor_user_id | INT | YES | — | Usuario que originó el evento (`users.user_id`); NULL si lo originó el sistema |
| actor_role | VARCHAR(30) | YES | — | Rol del actor en el momento del evento; `system` si no hay usuario |
| action | VARCHAR(100) | NO | — | Nombre del evento (ej. `dispatch.created`, `dispatch.status_changed`) |
| previous_status | VARCHAR(50) | YES | — | Código del estado anterior; NULL si no aplica |
| new_status | VARCHAR(50) | YES | — | Código del estado nuevo; NULL si no aplica |
| result | VARCHAR(20) | NO | — | `success`, `denied` o `failed` |
| correlation_id | VARCHAR(64) | NO | — | Identificador de la solicitud (cabecera `X-Request-Id`); une el evento con los logs de esa solicitud |
| detail | JSONB | NO | `'{}'` | Detalle saneado del evento; siempre un objeto JSON |
| occurred_at | TIMESTAMPTZ | NO | — | Momento en que ocurrió el evento |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que se guardó el evento |

## Relationships

- `dispatch_id` → `dispatches.dispatch_id` (`ON DELETE RESTRICT`).
- `route_batch_id` → `route_batches.route_batch_id` (`ON DELETE RESTRICT`).
- `actor_user_id` → `users.user_id` (`ON DELETE RESTRICT`).

## Business rules

- Es un registro append-only: la aplicación solo inserta y consulta; un evento ya escrito no se modifica ni se borra (RF-A36).
- `detail` nunca guarda contraseñas, tokens, firmas ni el payload completo; solo los campos necesarios para entender el evento.
- `previous_status` y `new_status` son los códigos de estado como texto (instantánea del momento), no FK: el historial no cambia si un catálogo se edita.
- `result` es `denied` cuando la acción fue rechazada por autorización y `failed` cuando se intentó y terminó en error.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at`.
- **Inmutabilidad en dos capas**: los triggers `trg_order_dispatch_events_prevent_update` y `trg_order_dispatch_events_prevent_delete` bloquean `UPDATE` siempre y `DELETE` salvo con `app.allow_event_purge = 'on'` (solo limpieza de pruebas, igual que `dispatch_events`); el rol `dispatch_app` (`NOLOGIN`) solo tiene `SELECT` e `INSERT`. `TRUNCATE` no se bloquea: es convención.
- El usuario de conexión del backend debe pertenecer a `dispatch_app` o tener los mismos privilegios.
- Índices de consulta: `(dispatch_id, occurred_at)`, `(source_order_ref, occurred_at)` y `correlation_id`; además los de las FK.
- Distinta de `dispatch_events` (solo despachos, sin correlación ni resultado) y de `admin_audit_events` (acciones administrativas sensibles).
- Creada por la migración `031_20261121_1200_create_order_dispatch_events` (ST-69.1).
