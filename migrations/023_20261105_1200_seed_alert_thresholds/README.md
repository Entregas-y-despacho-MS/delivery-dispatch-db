# seed_alert_thresholds

ST-67.1 (ES-67, RF-A20) — siembra los tres umbrales que disparan las alertas de desempeño del
Supervisor (`ES-66` los lee en cada evaluación).

- Inserta `sla_alert_min_on_time_pct` (`90`), `gps_stale_alert_minutes` (`5`) y
  `driver_incident_alert_per_day` (`3`).
- `ON CONFLICT (setting_key) DO NOTHING` conserva el valor si la clave ya estaba configurada.
- No cambia la forma de ninguna tabla ni toca filas existentes.
- `sla_alert_threshold_pct` (ST-57.2) se conserva sin cambios; `sla_alert_min_on_time_pct` es la clave
  que usa el evaluador de alertas.

`down.sql` elimina únicamente estas tres claves. Es un `DELETE` y no distingue si la fila la sembró esta
migración o ya existía (por ejemplo, en una base creada con `schema/` actualizado) ni si alguien cambió
su valor: el rollback pierde el valor configurado. Para un cambio puntual de valores se usa
`PUT /settings/alert-thresholds`, no el rollback.
