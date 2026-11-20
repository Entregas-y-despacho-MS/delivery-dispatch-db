# customer_notifications

Aviso por correo al cliente y su estado de envío (RF-U16, ST-39.2). Una fila es un envío lógico: dos entregas del mismo evento origen y tipo de notificación dejan una sola fila. A diferencia de `dispatch_events` (append-only), esta tabla se actualiza en cada intento.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| customer_notification_id | SERIAL | NO | auto | Identificador del aviso |
| dispatch_id | INT | NO | — | Despacho cuyo cambio de estado originó el aviso |
| notification_type | VARCHAR(50) | NO | — | Tipo de notificación. Hoy solo `status_change` |
| idempotency_key | VARCHAR(200) | NO | — | `<notification_type>:<source_event_key>`. Única |
| source_event_key | VARCHAR(120) | NO | — | Evento origen: `<dispatch_id>:<estado>:<instante ISO>` (el evento `dispatch.status_changed` no trae id propio) |
| dispatch_status | VARCHAR(30) | NO | — | Estado del despacho que se avisa; permite reconstruir el correo en un reintento |
| occurred_at | TIMESTAMPTZ | NO | — | Instante de la transición que originó el aviso |
| recipient | VARCHAR(254) | NO | — | Correo del destinatario normalizado (sin espacios, en minúsculas) |
| template | VARCHAR(50) | NO | — | Plantilla Handlebars usada (ej. `status-change`) |
| template_version | SMALLINT | NO | — | Versión de la plantilla al momento del envío |
| status | VARCHAR(20) | NO | `sending` | `sending`, `sent`, `retrying`, `bounced` o `exhausted` |
| attempts | SMALLINT | NO | `0` | Intentos de envío realizados contra el proveedor |
| next_attempt_at | TIMESTAMPTZ | YES | — | Cuándo toca el próximo intento; NULL en los estados finales |
| locked_until | TIMESTAMPTZ | YES | — | Concesión del intento en curso; vencida, otro proceso puede retomarlo |
| last_error | VARCHAR(200) | YES | — | Último error del proveedor, saneado: una línea de a lo sumo 200 caracteres, sin direcciones, enlaces ni tokens largos |
| sent_at | TIMESTAMPTZ | YES | — | Momento en que el proveedor aceptó el correo |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho avisado (`ON DELETE RESTRICT`: el historial de avisos no se pierde) |

## Business rules

- **Un envío lógico por evento y tipo**: `idempotency_key` es única. El backend inserta con `ON CONFLICT DO NOTHING`; quien no logra insertar no envía.
- **Estados**: `sending` (intento en curso o por retomar), `sent` (el proveedor aceptó el correo), `retrying` (falló de forma transitoria; toca otro intento en `next_attempt_at`), `bounced` (el proveedor rechazó al destinatario: permanente, no se reintenta) y `exhausted` (se agotaron los intentos). `sent`, `bounced` y `exhausted` son finales.
- `sent_at` está presente si y solo si `status = 'sent'`.
- Un proveedor caído no revierte la transición del despacho: el aviso se registra aparte y se recupera.
- `last_error` guarda el texto del error del proveedor, pero sin la dirección del cliente, sin enlaces (el de seguimiento lleva el token) y sin cadenas largas tipo token o clave: el backend las reemplaza por `[email]`, `[url]` y `[redacted]` antes de escribir. Lo que no encaja en esos patrones se guarda tal cual.
- Una fila `sending` cuya concesión (`locked_until`) venció la retoma la tarea de recuperación, y ese intento se cuenta en `attempts` (el proceso que murió lo intentó): así una fila que mata su proceso cada vez termina en `exhausted`.

## Technical notes

- `uq_customer_notifications_idempotency_key` es la guarda real de unicidad (el backend la usa con `ON CONFLICT`).
- `idx_customer_notifications_pending` es parcial (`status IN ('sending','retrying')`): lo usa el barrido de recuperación, que también retoma filas `sending` con `locked_until` vencida.
- `updated_at` se mantiene con el trigger `trg_customer_notifications_set_updated_at`.
- Creada por la migración `029_20261119_1500_create_customer_notifications`. Los eventos `customer_status_notice_*` que ST-39.1 dejó en `dispatch_events` quedan como historial.
- Entidad TypeORM en `delivery-dispatch-svc`: se mapea en la etapa del backend de ST-39.2.
