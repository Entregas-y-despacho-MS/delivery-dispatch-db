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
- Los parámetros operativos de planificación y entrega de ST-57.2 se inicializan en `data.sql`; el coordinador puede consultarlos y actualizarlos desde el backend. Las horas usan la zona local `America/La_Paz` cuando su descripción lo indica.

## Initial operational settings

| Key | Initial value | Description |
|-----|---------------|-------------|
| `plan_generation_times` | `08:30,13:30` | Local automatic plan generation times (`America/La_Paz`). |
| `plan_horizon_days` | `4` | Days included in an automatic delivery plan. |
| `plan_working_days` | `1,2,3,4,5` | Weekdays included in planning; 1 is Monday and 7 is Sunday. |
| `plan_non_working_dates` | Empty | ISO dates excluded from planning; empty means none configured. |
| `route_cutoff_time` | `15:00` | Proposed route planning cutoff; confirm with Operations. |
| `final_review_end_time` | `16:00` | Proposed final route review end; confirm with Operations. |
| `route_reminder_time` | `16:30` | Proposed route reminder time; confirm with Operations. |
| `promise_response_window_minutes` | `720` | Minutes allowed for a customer to respond to a delivery promise. |
| `service_min_operating_days` | `2` | Minimum operating days offered for a delivery service. |
| `service_max_operating_days` | `3` | Maximum operating days offered for a delivery service. |
| `slot_duration_minutes` | `120` | Delivery time slot duration in minutes. |
| `morning_window_start` | `09:00` | Morning delivery window start. |
| `morning_window_end` | `13:00` | Morning delivery window end. |
| `afternoon_window_start` | `14:00` | Afternoon delivery window start. |
| `afternoon_window_end` | `18:00` | Afternoon delivery window end. |
| `stop_service_minutes` | Empty | Unconfigured until Operations measures average service time. |
| `planning_margin_pct` | Empty | Unconfigured until Operations calibrates the planning margin. |
| `max_reschedule_attempts` | `2` | Maximum rescheduling attempts for an order. |
| `max_delivery_attempts` | `3` | Maximum delivery attempts for an order. |
| `reschedule_window_days` | `2` | Days available to reschedule a delivery. |
| `tracking_token_retention_days` | `30` | Proposed retention only; not a legal retention policy. |
| `incomplete_order_alert_minutes` | `60` | Alert delay for incomplete orders; preserve ST-31.5 behavior. |
| `final_review_escalation_time` | `07:00` | Proposed final review escalation time; confirm with Operations. |
| `warehouse_prep_end_time` | `08:15` | Example warehouse preparation end time; confirm against the shift. |
| `warehouse_prep_lead_minutes` | Empty | Unconfigured until the preparation lead time is defined. |
| `reschedule_code_expiry_minutes` | Empty | Unconfigured until the rescheduling code policy is defined. |

`settings_version` is an internal counter initialized to `0`. The backend increments it after each successful operational setting update and does not expose it through `GET /settings`.

## Technical notes

- La PK es `setting_key` (no un `SERIAL`) porque esta tabla es de configuración, no una entidad con identidad propia — no aplica el formato estándar del proyecto.
- El bootstrap de `data.sql` conserva valores existentes al repetirse mediante `ON CONFLICT (setting_key) DO NOTHING`.
