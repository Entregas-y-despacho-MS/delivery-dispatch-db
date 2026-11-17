INSERT INTO settings (setting_key, setting_value, description) VALUES
    ('sla_alert_min_on_time_pct', '90', 'Minimum percentage of on-time deliveries before a sla_below_threshold alert is raised.'),
    ('gps_stale_alert_minutes', '5', 'Minutes without a GPS position from a driver on route before a gps_stale alert is raised.'),
    ('driver_incident_alert_per_day', '3', 'Number of incidents reported by one driver in a day that raises a driver_incidents alert.')
ON CONFLICT (setting_key) DO NOTHING;
