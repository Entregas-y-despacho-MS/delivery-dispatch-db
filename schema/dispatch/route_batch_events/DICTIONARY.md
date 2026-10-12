# route_batch_events

Bitácora de eventos de cada lote (`route_batches`): crear, dividir, fusionar, sacar un pedido, aprobar, congelar, reasignar revisor, etc. Da trazabilidad completa de quién cambió el lote y por qué.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| route_batch_event_id | SERIAL | NO | auto | Identificador del evento |
| route_batch_id | INT | NO | — | Lote al que corresponde el evento |
| dispatch_id | INT | YES | — | Despacho involucrado, si el evento es sobre un pedido concreto (p. ej. sacarlo del lote) |
| event_type | VARCHAR(50) | NO | — | Tipo de evento (ej. `created`, `split`, `merged`, `order_removed`, `approved`, `frozen`, `reviewer_reassigned`, `migration_013_assignment_cleared`) |
| actor_user_id | INT | YES | — | Usuario que originó el evento; NULL si lo generó el sistema o el cliente |
| actor_type | VARCHAR(20) | NO | — | `user`, `system` o `customer` |
| reason | TEXT | YES | — | Motivo declarado del evento |
| metadata | JSONB | YES | — | Valor anterior y nuevo, versión, resultado |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que ocurrió el evento |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| route_batch_id | route_batches.route_batch_id | Lote al que pertenece el evento |
| dispatch_id | dispatches.dispatch_id | Despacho involucrado, si aplica |
| actor_user_id | users.user_id | Usuario que originó el evento |

## Business rules

- Es append-only: un evento ya registrado nunca se modifica ni se borra.
- Cuando el actor es el sistema, `actor_user_id` es NULL y `actor_type = 'system'`; cuando es el cliente (autoservicio), `actor_type = 'customer'`.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at` (mismo criterio que `dispatch_events`). La inmutabilidad la imponen los triggers `trg_route_batch_events_prevent_update` / `fn_route_batch_events_prevent_update()` (bloquea todo `UPDATE`) y `trg_route_batch_events_prevent_delete` / `fn_route_batch_events_prevent_delete()` (bloquea `DELETE` salvo que la sesión tenga `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas). `TRUNCATE` no se bloquea: la inmutabilidad total es por convención.
- Las tres FK usan `ON DELETE RESTRICT`: un lote, un despacho o un usuario con eventos no se borra en silencio.
- `chk_route_batch_events_actor_type` restringe `actor_type`. A diferencia de `dispatch_events`, es `NOT NULL` porque la tabla es nueva y el autor siempre se conoce.
- Creada por la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3). El backend (ST-49.4) debe agregar la entidad correspondiente.
