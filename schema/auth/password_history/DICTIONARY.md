# password_history

Contraseñas anteriores de cada usuario interno, para impedir que reutilice una de sus últimas contraseñas al cambiarla (RF-A25).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| password_history_id | SERIAL | NO | auto | Identificador del registro histórico |
| user_id | INT | NO | — | Usuario dueño de esta contraseña histórica |
| password_hash | VARCHAR(255) | NO | — | Hash de una contraseña que el usuario tuvo antes |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que esa contraseña dejó de ser la actual |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| user_id | users.user_id | Usuario al que perteneció esta contraseña |

## Business rules

- Al cambiar su contraseña (cambio propio o recuperación), el sistema rechaza la nueva si coincide con la contraseña actual o con alguna de las últimas 3 registradas acá (RF-A25).
- Es de solo inserción — nunca se actualiza un registro existente, solo se agregan nuevos al cambiar la contraseña.
- No tiene límite de borrado automático de filas antiguas (más allá de las últimas 3, las filas más viejas no se consultan, pero se conservan como historial).

## Technical notes

- `ON DELETE CASCADE` — si se borra un usuario, su historial de contraseñas no tiene sentido por separado.
