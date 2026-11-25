# seed_password_complexity_settings

ST-310.1 (ES-310, RF-A25) — siembra las cuatro opciones booleanas de complejidad de contraseña que
el administrador de seguridad configura y que el backend aplica al crear, cambiar o restablecer
contraseñas.

- Inserta `password_require_uppercase`, `password_require_lowercase`, `password_require_number` y
  `password_require_symbol`, todas con `'true'` (el comportamiento que ya tenía la política fija).
- Los valores se guardan como texto `'true'`/`'false'`; el backend rechaza cualquier otro valor.
- `ON CONFLICT (setting_key) DO NOTHING` conserva el valor si la clave ya estaba configurada, así que
  correrla sobre una base creada con `schema/` actualizado no falla ni cambia nada.
- No cambia la forma de ninguna tabla. `password_min_length` (mínimo 8) no se toca.
- Una base actualizada con esta migración y una instalación limpia (`schema/settings/data.sql`)
  quedan con los mismos cuatro defaults.

`down.sql` elimina únicamente estas cuatro claves. Es un `DELETE` y no distingue si la fila la sembró
esta migración o ya existía (por ejemplo, en una base creada con `schema/` actualizado), ni si alguien
cambió su valor: el rollback pierde el valor configurado. Tras el rollback el backend de ST-310.1 ya no
encuentra las claves; usar el rollback solo junto con la versión anterior del backend.
