# outbound_message_statuses

Catálogo de estados del ciclo de publicación de un mensaje saliente.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| status | VARCHAR(20) | NO | — | Clave natural del estado del envío |
| description | TEXT | NO | — | Significado del estado |

## Business rules

- `pending` indica que el mensaje espera publicación o reintento.
- `sent` indica que se publicó correctamente.
- `failed` indica que agotó la política de reintentos y no se volverá a publicar.

## Technical notes

- `status` es la clave primaria natural y es referenciada por `outbound_messages.status`.
