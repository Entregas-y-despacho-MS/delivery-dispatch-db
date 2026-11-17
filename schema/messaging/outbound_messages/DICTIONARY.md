# outbound_messages

Mensajes que el backend debe publicar a otros sistemas, con el estado y la próxima fecha de reintento.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| message_id | UUID | NO | — | Identificador único del mensaje saliente |
| status | VARCHAR(20) | NO | `pending` | Estado del envío: `pending`, `sent` o `failed` |
| type | VARCHAR(100) | NO | — | Tipo de evento que se publicará |
| payload | JSONB | NO | — | Contenido del mensaje que se publicará |
| attempts | INT | NO | 0 | Cantidad de intentos de publicación realizados |
| next_attempt_at | TIMESTAMPTZ | NO | NOW() | Momento a partir del cual puede reintentarse la publicación |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que el mensaje fue registrado en el outbox |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento del último cambio de estado o intento |

## Business rules

- El mensaje se guarda en el outbox dentro de la misma transacción que produce el evento que debe publicarse.
- Solo los mensajes `pending` cuya fecha `next_attempt_at` ya llegó están listos para publicación o reintento.
- Cada reintento incrementa `attempts` y programa una nueva fecha; los estados `sent` y `failed` son terminales.
- El estado debe existir en el catálogo `outbound_message_statuses`.

## Technical notes

- `message_id` es la clave primaria del registro.
- La clave foránea de `status` restringe los valores a `pending`, `sent` y `failed`.
- El índice `idx_outbound_messages_status_next_attempt_at` ayuda a encontrar los mensajes pendientes listos para reintento.
- El trigger `trg_outbound_messages_set_updated_at` actualiza `updated_at` en cada cambio.
