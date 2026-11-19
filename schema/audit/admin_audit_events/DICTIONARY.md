# admin_audit_events

Registro de las acciones administrativas sensibles (RF-A35): quién ejecutó o intentó la acción, con qué rol, sobre qué entidad, con qué resultado y en qué solicitud.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| admin_audit_event_id | UUID | NO | — | Identificador del evento (`eventId`), generado por la aplicación |
| actor_user_id | INT | YES | — | Usuario autenticado que ejecutó o intentó la acción (`users.user_id`); NULL si no hubo actor autenticado |
| actor_role | VARCHAR(30) | YES | — | Rol del actor en el momento de la acción; NULL sin actor |
| action | VARCHAR(100) | NO | — | Acción del catálogo de acciones sensibles (ej. `user.role_changed`) |
| entity_type | VARCHAR(50) | YES | — | Tipo de entidad afectada (ej. `user`, `setting`) |
| entity_id | VARCHAR(64) | YES | — | Referencia de la entidad afectada; NULL si no aplica o no se conoce |
| result | VARCHAR(20) | NO | — | `success` (se ejecutó), `denied` (respuesta 401/403: sin autenticación, sin rol, contraseña pendiente de cambio o una regla de autorización de la propia acción) o `failed` (se intentó y terminó en otro error) |
| status_code | SMALLINT | YES | — | Código HTTP con el que terminó la solicitud |
| correlation_id | VARCHAR(64) | NO | — | Identificador de la solicitud (cabecera `X-Request-Id`); une el evento con los logs de esa solicitud |
| ip_address | INET | YES | — | IP del cliente; detrás de un proxy solo se toma de `X-Forwarded-For` cuando ese proxy está declarado en `TRUST_PROXY` |
| metadata | JSONB | NO | `'{}'` | Metadatos permitidos de la acción; nunca contraseñas, tokens, firmas ni datos personales innecesarios |
| occurred_at | TIMESTAMPTZ | NO | — | Momento en que terminó la acción |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que se guardó el evento |

## Business rules

- Se registran las acciones del catálogo de acciones administrativas sensibles, tanto las permitidas como las denegadas (RF-A35, ES-68).
- `denied` cubre toda respuesta 401/403: la solicitud sin autenticación (`actor_user_id` NULL), la de un actor sin el rol requerido o con cambio de contraseña pendiente, y la que la propia acción rechaza por una regla de autorización (p. ej. cambiar el rol propio).
- Nunca se guardan contraseñas, tokens, códigos, firmas ni datos personales innecesarios; `metadata` solo lleva campos permitidos por la acción.
- Es la base de la consulta (RF-A37) y la exportación (RF-A38) de auditoría.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at`; un evento ya escrito no se modifica ni se borra.
- `actor_user_id` no tiene FK a propósito: borrar un usuario no reescribe ni borra sus eventos.
- Distinta de `audit_logs`, que guarda alertas y trazas técnicas del sistema (scheduler, outbox, planificación).
