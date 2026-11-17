# inbound_message_statuses

Catálogo de resultados posibles para los mensajes recibidos de sistemas externos.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| status | VARCHAR(20) | NO | — | Clave natural del resultado del mensaje |
| description | TEXT | NO | — | Significado del resultado |

## Business rules

- `processed` indica que el mensaje pasó la validación y se procesó correctamente.
- `rejected` indica que el mensaje no es válido o no pudo procesarse y debe enviarse al tópico dead-letter.

## Technical notes

- `status` es la clave primaria natural y es referenciada por `inbound_messages.status`.
