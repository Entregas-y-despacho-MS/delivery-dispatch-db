DELETE FROM settings
WHERE setting_key IN (
    'password_require_uppercase',
    'password_require_lowercase',
    'password_require_number',
    'password_require_symbol'
);
