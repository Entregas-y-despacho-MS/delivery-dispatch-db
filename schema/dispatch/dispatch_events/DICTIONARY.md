# dispatch_events

Log de eventos de negocio de cada despacho: creación, asignación, cambios de estado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_event_id | SERIAL | NO | auto | Identificador del evento |
| dispatch_id | INT | NO | — | Despacho al que corresponde |
| event_type | VARCHAR(50) | NO | — | Tipo de evento (ej. `created`, `assigned`, `status_changed`) |
| detail | TEXT | YES | — | Detalle libre del evento (ej. estado anterior → nuevo) |
| client_event_id | UUID | YES | — | Id generado por la app móvil del repartidor cuando el evento se creó offline (RF-U13); NULL en eventos generados por el propio backend |
| actor_user_id | INT | YES | — | Usuario que originó el evento; NULL si lo generó el sistema o el cliente |
| actor_type | VARCHAR(20) | YES | — | `user`, `system` o `customer`. NULL en los eventos anteriores a la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3) (no se sabe quién los generó) |
| reason | TEXT | YES | — | Motivo declarado del evento |
| metadata | JSONB | YES | — | Valor anterior y nuevo, versión, resultado |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que ocurrió el evento |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho al que pertenece el evento |
| actor_user_id | users.user_id | Usuario que originó el evento |

## Business rules

- Se genera automáticamente por la aplicación ante cada pedido/despacho: creación, asignación, cambios de estado (RF-A36), para dar trazabilidad completa.
- Los cambios de estado que llegan desde la app móvil offline (RF-U13) traen su propio `client_event_id`: si el mismo evento se reintenta (por un corte de red durante la sincronización), no se duplica — se trata como ya aplicado.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at` porque un evento ya registrado nunca se modifica — es intencional, distinto del resto de las tablas del proyecto. Desde la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3) la inmutabilidad la imponen los triggers `trg_dispatch_events_prevent_update` / `fn_dispatch_events_prevent_update()` (bloquea todo `UPDATE`) y `trg_dispatch_events_prevent_delete` / `fn_dispatch_events_prevent_delete()` (bloquea `DELETE` salvo que la sesión tenga `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas; en producción nunca se activa). `TRUNCATE` no se bloquea: es convención.
- `dispatch_id` y `actor_user_id` usan `ON DELETE RESTRICT`: un despacho o un usuario con eventos no se borra en silencio (antes `dispatch_id` era `CASCADE`). No se usa `SET NULL` en `actor_user_id` porque ese `UPDATE` implícito chocaría con el trigger.
- `chk_dispatch_events_actor_type` restringe `actor_type`. Es nullable a propósito: las filas previas a la migración no registraron autor; el backend (ST-49.4) debe informarlo siempre desde entonces.
- `client_event_id` es único solo cuando no es NULL (índice `uq_dispatch_events_client_event_id`, `WHERE client_event_id IS NOT NULL`) — permite que eventos generados por el propio backend (sin este id) convivan sin restricción de unicidad entre ellos.
