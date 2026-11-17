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
- Verificado en ST-49.3: la tabla ya contiene todas las claves de la sección 6.3 del plan de planificación semiautomática, de modo que la migración 013 **no siembra ninguna clave nueva**. `max_delivery_attempts` se compara con los intentos que suman los motivos con `incident_reasons.counts_as_attempt = TRUE`. Las claves vacías (`stop_service_minutes`, `planning_margin_pct`, `warehouse_prep_lead_minutes`, `reschedule_code_expiry_minutes`) siguen sin valor a propósito: no se inventa uno.

## Parámetros base

Claves sembradas por `data.sql` antes de los parámetros operativos de ST-57.2.

| Key | Initial value | Description |
|-----|---------------|-------------|
| `delivery_window_start` | `08:00` | Inicio de la ventana general de entregas (límite exterior) |
| `delivery_window_end` | `20:00` | Fin de la ventana general de entregas (límite exterior) |
| `max_wait_time_min` | `15` | Tiempo máximo de espera en el punto de entrega, en minutos |
| `sla_alert_threshold_pct` | `90` | Porcentaje mínimo de cumplimiento de SLA antes de disparar una alerta. Clave heredada: el evaluador de alertas usa `sla_alert_min_on_time_pct` (ST-67.1). |
| `password_min_length` | `8` | Longitud mínima de la contraseña |
| `password_expiration_days` | `90` | Días antes de exigir el cambio de contraseña |
| `otp_code_length` | `6` | Cantidad de dígitos del código OTP de confirmación de entrega |
| `otp_expiry_minutes` | `60` | Minutos que un código OTP sigue siendo válido |
| `max_failed_login_attempts` | `5` | Intentos de inicio de sesión fallidos antes de bloquear la cuenta |
| `account_lockout_minutes` | `15` | Minutos que una cuenta permanece bloqueada |
| `password_reset_expiry_minutes` | `30` | Minutos de validez del token de restablecimiento de contraseña |
| `session_inactivity_minutes` | `30` | Minutos de inactividad antes de cerrar la sesión (no aplica a la app móvil del repartidor en ruta) |
| `order_reservation_ttl_minutes` | `15` | Minutos que dura la reserva suave de un pedido sin actividad (migración 010) |

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
| `plan_min_orders_per_route` | `3` | Proposed minimum orders per route; the planner only warns below it (D-13); confirm with Operations. |
| `max_reschedule_attempts` | `2` | Maximum rescheduling attempts for an order. |
| `max_delivery_attempts` | `3` | Maximum delivery attempts for an order. |
| `reschedule_window_days` | `2` | Days available to reschedule a delivery. |
| `tracking_token_retention_days` | `30` | Proposed retention only; not a legal retention policy. |
| `incomplete_order_alert_minutes` | `60` | Alert delay for incomplete orders; preserve ST-31.5 behavior. |
| `final_review_escalation_time` | `07:00` | Proposed final review escalation time; confirm with Operations. |
| `warehouse_prep_end_time` | `08:15` | Example warehouse preparation end time; confirm against the shift. |
| `warehouse_prep_lead_minutes` | Empty | Unconfigured until the preparation lead time is defined. |
| `reschedule_code_expiry_minutes` | Empty | Unconfigured until the rescheduling code policy is defined. |
| `sla_alert_min_on_time_pct` | `90` | Minimum on-time delivery percentage (0–100) before an SLA alert is raised (ST-67.1, RF-A20). Edited with `PUT /settings/alert-thresholds`. |
| `gps_stale_alert_minutes` | `5` | Minutes without a GPS position before a stale-GPS alert is raised (ST-67.1, RF-A20). |
| `driver_incident_alert_per_day` | `3` | Incidents by one driver in a day that raise a driver-incidents alert (ST-67.1, RF-A20). |

`settings_version` is an internal counter initialized to `0`. The backend increments it after each successful operational setting update and does not expose it through `GET /settings`.

## Technical notes

- La PK es `setting_key` (no un `SERIAL`) porque esta tabla es de configuración, no una entidad con identidad propia — no aplica el formato estándar del proyecto.
- El bootstrap de `data.sql` conserva valores existentes al repetirse mediante `ON CONFLICT (setting_key) DO NOTHING`.
