-- Express queda desactivado: no se ofrece en este alcance (migración 013).
INSERT INTO service_levels (name, description, target_time_min, priority_level, active) VALUES
    ('Standard', 'Regular delivery', 240, 2, true),
    ('Express',  'Priority delivery for urgent orders', 90, 1, false);
