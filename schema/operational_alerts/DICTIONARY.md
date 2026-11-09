# operational_alerts

Alerta operativa que el sistema levanta para el supervisor de flota (RF-A19): una incidencia crítica de un despacho, un repartidor sin reportar GPS, muchas incidencias de un mismo repartidor en el día, o el SLA de una zona por debajo del umbral configurado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| operational_alert_id | SERIAL | NO | auto | Identificador de la alerta |
| zone_id | INT | YES | — | Zona a la que se refiere, cuando el tipo de alerta es por zona (`sla_below_threshold`) |
| dispatch_id | INT | YES | — | Despacho al que se refiere, cuando el tipo de alerta es por despacho (`critical_incident`) |
| driver_id | INT | YES | — | Repartidor al que se refiere, cuando el tipo de alerta es por repartidor (`gps_stale`, `driver_incidents`) |
| vehicle_id | INT | YES | — | Vehículo al que se refiere, cuando aplica |
| acknowledged_by | INT | YES | — | Supervisor o coordinador que reconoció la alerta |
| kind | VARCHAR(30) | NO | — | Tipo de alerta: `critical_incident`, `gps_stale`, `driver_incidents` o `sla_below_threshold` |
| severity | VARCHAR(20) | NO | — | `critical` o `warning` |
| detail | JSONB | NO | `{}` | Contexto propio de cada tipo (ej. motivo de la incidencia, minutos sin GPS, porcentaje de SLA) |
| status | VARCHAR(20) | NO | `open` | `open` mientras nadie la atendió, `acknowledged` una vez reconocida |
| acknowledged_at | TIMESTAMPTZ | YES | — | Momento en que se reconoció; NULL mientras `status = open` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| zone_id | delivery_zones.delivery_zone_id | Zona del despacho/SLA que la alerta describe |
| dispatch_id | dispatches.dispatch_id | Despacho cuya incidencia crítica generó la alerta |
| driver_id | users.user_id | Repartidor al que se refiere la alerta |
| vehicle_id | vehicles.vehicle_id | Vehículo al que se refiere la alerta |
| acknowledged_by | users.user_id | Quién reconoció la alerta (`ON DELETE RESTRICT`: no se puede borrar a quien reconoció una alerta) |

## Business rules

- El sujeto de la alerta depende de `kind`: cada tipo completa solo la columna que le corresponde (zona, despacho o repartidor), el resto queda en NULL. `vehicle_id` es siempre dato auxiliar, nunca el sujeto por sí solo — no participa en la regla de unicidad.
- No puede haber dos alertas `open` del mismo `kind` para el mismo sujeto (`zone_id`/`dispatch_id`/`driver_id`) — el supervisor ya tiene una pendiente de ese tipo y sujeto.
- `acknowledged_by`/`acknowledged_at` van juntos: ambos NULL mientras `status = open`, ambos obligatorios cuando `status = acknowledged`.

## Technical notes

- `uq_operational_alerts_open_subject` es el índice único parcial (`WHERE status = 'open'`) sobre (`kind`, `zone_id`, `dispatch_id`, `driver_id`) que impone la regla de no duplicar alertas abiertas, con `COALESCE(..., -1)`: un índice único normal no bloquea dos filas con NULL en la misma columna. `vehicle_id` queda fuera del índice a propósito (ver Business rules).
- `chk_operational_alerts_acknowledged` impone la correlación `status`/`acknowledged_by`/`acknowledged_at` a nivel de base.
- `updated_at` se mantiene con el trigger `trg_operational_alerts_set_updated_at`.
