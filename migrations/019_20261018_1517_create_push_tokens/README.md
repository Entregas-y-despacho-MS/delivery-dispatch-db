# create_push_tokens

ST-36.3 (ES-36, RF-U10) — crea `push_tokens`, donde el backend guarda el token de notificaciones push de cada dispositivo de un repartidor para poder avisarle cuando se aprueba su lote.

- Una fila por (`user_id`, `device_id`): registrar de nuevo el mismo dispositivo actualiza la fila, no la duplica.
- Un token activo (`revoked_at IS NULL`) pertenece a un solo usuario (`uq_push_tokens_active_token`): si el mismo teléfono lo usa otro repartidor, el backend revoca primero el registro anterior.
- `platform` solo admite `ios` y `android`.

**Filas existentes:** ninguna, la tabla es nueva. `down.sql` la elimina junto con sus índices.
