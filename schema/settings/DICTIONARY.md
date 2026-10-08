# settings

Parámetros generales del servicio, en formato clave-valor.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| setting_key | VARCHAR(100) | NO | — | Nombre del parámetro (clave natural, es la PK) |
| setting_value | TEXT | NO | — | Valor actual, se interpreta según el parámetro |
| description | TEXT | YES | — | Para qué sirve este parámetro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador configura la ventana horaria general de entregas y el tiempo máximo de espera (RF-A10), el supervisor configura el umbral de alerta de SLA (RF-A20), y el administrador de seguridad configura la política de contraseñas (RF-A25).
- `max_failed_login_attempts`/`account_lockout_minutes`/`password_reset_expiry_minutes` también los administra el administrador de seguridad, misma lógica que la política de contraseñas (RF-A25) aunque no sean estrictamente sobre la contraseña en sí, sino sobre el login.
- `session_inactivity_minutes` (RF-A24, cierre automático por inactividad) — no aplica a la app móvil del repartidor en ruta, que persiste la sesión vía refresh tokens a propósito.
- `order_reservation_ttl_minutes` (RF-A40, ST-48.2) — minutos que dura la reserva suave de un pedido sin actividad del coordinador (15 por defecto); lo administra el coordinador.

## Technical notes

- La PK es `setting_key` (no un `SERIAL`) porque esta tabla es de configuración, no una entidad con identidad propia — no aplica el formato estándar del proyecto.
