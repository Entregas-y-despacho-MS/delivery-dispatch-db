INSERT INTO settings (setting_key, setting_value, description) VALUES
    ('plan_min_orders_per_route', '3', 'Proposed minimum number of orders per route; the planner only warns below it and never postpones a promise; confirm with Operations.')
ON CONFLICT (setting_key) DO NOTHING;
