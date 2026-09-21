# users

Personal interno del microservicio: coordinadores, supervisores y repartidores/transportistas. No incluye al Cliente Final, que no tiene cuenta.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| user_id | SERIAL | NO | auto | Identificador del usuario |
| role_id | INT | NO | — | Rol interno del usuario |
| full_name | VARCHAR(150) | NO | — | Nombre completo |
| username | VARCHAR(50) | NO | — | Usuario de acceso |
| email | VARCHAR(150) | YES | — | Correo de contacto |
| password_hash | VARCHAR(255) | NO | — | Contraseña almacenada con hash seguro; soporta el cambio y la recuperación segura de contraseña (RF-A23) |
| password_changed_at | TIMESTAMPTZ | NO | NOW() | Última vez que se cambió la contraseña, para forzar el cambio si venció el período de vigencia (RF-A25) |
| failed_attempts | SMALLINT | NO | 0 | Intentos fallidos de inicio de sesión consecutivos, para el bloqueo temporal (RF-A21) |
| locked_until | TIMESTAMPTZ | YES | — | Fecha hasta la que la cuenta queda bloqueada por intentos fallidos (RF-A21) |
| refresh_token_hash | VARCHAR(255) | YES | — | Hash del refresh token vigente, para que la app móvil del repartidor mantenga la sesión de forma segura mientras está en ruta (RF-A24) |
| requires_pwd_change | BOOLEAN | NO | TRUE | Fuerza el cambio de contraseña en el siguiente inicio de sesión |
| password_reset_token | VARCHAR(255) | YES | — | Token de recuperación cuando el usuario olvidó su contraseña y no puede loguearse (RF-A23); NULL si no hay ninguno pendiente |
| password_reset_expires_at | TIMESTAMPTZ | YES | — | Vencimiento del token de recuperación |
| two_factor_secret | VARCHAR(255) | YES | — | Secreto TOTP para la app autenticadora (Google Authenticator, Authy, etc.); NULL hasta que el usuario activa 2FA |
| two_factor_enabled | BOOLEAN | NO | FALSE | Si el usuario tiene 2FA activo — aplica a los 3 roles internos (coordinador, supervisor, repartidor), no solo a uno |
| active | BOOLEAN | NO | TRUE | Si el usuario está activo o inactivo (RF-A22, RF-A28) — estado de negocio, no borrado |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete técnico (equivalente a `@DeleteDateColumn` de TypeORM) |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| role_id | roles.role_id | Rol interno que determina qué puede hacer el usuario en el sistema |

## Business rules

- Un usuario nunca se elimina en duro: se desactiva (`active = false`) para quitarle acceso operativo sin perder su historial (RF-A26), o se marca `deleted_at` si realmente se da de baja del sistema — son dos estados independientes.
- El registro, edición y desactivación de usuarios internos lo hace el coordinador (RF-A26); el rol y los permisos se asignan y modifican también por el coordinador (RF-A27).
- **2FA vía TOTP, no por correo** (decisión del 2026-09-19, no viene de ningún RF, agregada por seguridad): se eligió TOTP (app autenticadora) en vez de un código enviado por correo/SMS porque el repartidor necesita poder loguearse sin depender de conectividad en el momento exacto del login — TOTP genera el código localmente en el celular, sin red, una vez configurado. Aplica a los 3 roles.
- **`requires_pwd_change` vs. `password_reset_token`, no confundir:** el primero fuerza un cambio *después* de loguearse con éxito (ej. cuenta recién creada por el coordinador). El segundo es para cuando el usuario **no puede loguearse** porque olvidó su contraseña (RF-A23) — se manda por correo (reusa el plugin `mailer`), es de un solo uso, y se limpia (`NULL`) apenas se usa para fijar la contraseña nueva.
- **`password_changed_at` — caducidad periódica (RF-A25):** en el login, si pasó más de `settings.password_expiration_days` desde `password_changed_at`, el backend igual deja entrar (no lo bloquea como `locked_until`), pero indica que debe cambiar la contraseña antes de seguir usando el resto del sistema — misma señal que `requires_pwd_change`, causa distinta (vencimiento por antigüedad vs. flag manual de un admin). Se actualiza cada vez que se fija una contraseña nueva (alta, cambio propio, o reset).

## Technical notes

- `username` y `email` son únicos solo entre usuarios no borrados (`WHERE deleted_at IS NULL`), para poder reusar un nombre de usuario después de un soft delete.
