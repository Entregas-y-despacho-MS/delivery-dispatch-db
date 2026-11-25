INSERT INTO settings (setting_key, setting_value, description) VALUES
    ('password_require_uppercase', 'true', 'Whether a password must include at least one uppercase letter.'),
    ('password_require_lowercase', 'true', 'Whether a password must include at least one lowercase letter.'),
    ('password_require_number',    'true', 'Whether a password must include at least one number.'),
    ('password_require_symbol',    'true', 'Whether a password must include at least one symbol.')
ON CONFLICT (setting_key) DO NOTHING;
