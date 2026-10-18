# push_tokens

Token de notificaciones push de cada dispositivo de un repartidor, para avisarle en su teléfono cuando se aprueba el lote que lo incluye (RF-U10).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| push_token_id | SERIAL | NO | auto | Identificador del registro |
| user_id | INT | NO | — | Usuario dueño de este registro de dispositivo |
| device_id | VARCHAR(100) | NO | — | Identificador estable del dispositivo, generado por la app móvil |
| token | VARCHAR(255) | NO | — | Token del proveedor de notificaciones push (Expo o FCM) |
| platform | VARCHAR(10) | NO | — | Sistema operativo del dispositivo: `ios` o `android` |
| last_used_at | TIMESTAMPTZ | NO | NOW() | Última vez que la app registró este token |
| revoked_at | TIMESTAMPTZ | YES | — | `NULL` = activo; se llena al cerrar sesión o si el proveedor rechaza el token |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que se creó el registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Momento de la última actualización del registro |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| user_id | users.user_id | Usuario al que pertenece el dispositivo |

## Business rules

- Hay una sola fila por usuario y dispositivo (`uq_push_tokens_user_device`): volver a registrar el mismo dispositivo actualiza la fila, no la duplica. Si estaba revocada, la reactiva (`revoked_at` vuelve a `NULL`).
- Un token activo (`revoked_at IS NULL`) pertenece a un solo usuario (`uq_push_tokens_active_token`). Si otro repartidor inicia sesión en el mismo teléfono, el backend revoca primero el registro anterior, para que los avisos del primero no lleguen al segundo.
- Un token revocado no recibe notificaciones. Se revoca al cerrar sesión o cuando el proveedor responde que el token ya no es válido (app desinstalada o token caducado).
- Los tokens revocados se conservan como historial; no se borran como parte del flujo normal.
- `platform` solo admite `ios` y `android`.

## Technical notes

- `ON DELETE CASCADE` — si se borra un usuario, sus dispositivos no tienen sentido por separado.
- `uq_push_tokens_user_device` también cumple el papel de índice de la FK `user_id`, por eso no hay un `idx_push_tokens_user_id` aparte.
- `uq_push_tokens_active_token` es un índice único parcial sobre los tokens activos; los revocados pueden repetirse.
- Sin soft delete: `revoked_at` cumple ese papel, así que la unicidad por usuario y dispositivo es una restricción normal.
- Sin trigger de `updated_at`: solo el backend escribe en la tabla y lo actualiza en cada cambio.
- Creada por la migración `019_20261018_1517_create_push_tokens` (ST-36.3).
