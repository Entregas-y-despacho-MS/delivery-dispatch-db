# inbound_messages

Registro de cada mensaje recibido de los sistemas de venta y almacén, incluido su resultado de procesamiento.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| message_id | UUID | NO | — | Identificador único del mensaje recibido; evita procesarlo más de una vez |
| status | VARCHAR(20) | NO | — | Resultado final: `processed` o `rejected` |
| type | VARCHAR(100) | NO | — | Tipo de evento enviado por el sistema de origen |
| source | VARCHAR(100) | NO | — | Sistema que originó el mensaje |
| received_at | TIMESTAMPTZ | NO | NOW() | Momento en que el consumidor recibió el mensaje |
| error_detail | TEXT | YES | — | Detalle de validación o procesamiento cuando el mensaje fue rechazado |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que se creó el registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización del registro |

## Business rules

- Un `message_id` solo puede registrarse una vez para mantener la idempotencia ante reintentos.
- Un mensaje rechazado debe incluir `error_detail`; uno procesado no debe tenerlo.
- Los mensajes son un registro de recepción; no se eliminan como parte del procesamiento normal.
- El estado debe existir en el catálogo `inbound_message_statuses`.

## Technical notes

- `message_id` es la clave primaria y la genera el productor del mensaje.
- La clave foránea de `status` limita los resultados a `processed` y `rejected`.
- El índice `idx_inbound_messages_status` permite consultar mensajes por resultado.
- El trigger `trg_inbound_messages_set_updated_at` mantiene `updated_at` en cada cambio.
