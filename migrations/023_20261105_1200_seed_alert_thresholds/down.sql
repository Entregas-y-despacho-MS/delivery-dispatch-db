DELETE FROM settings
WHERE setting_key IN (
    'sla_alert_min_on_time_pct',
    'gps_stale_alert_minutes',
    'driver_incident_alert_per_day'
);
