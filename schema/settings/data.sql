INSERT INTO settings (setting_key, setting_value, description) VALUES
    ('delivery_window_start',    '08:00', 'Start time of the general delivery window'),
    ('delivery_window_end',      '20:00', 'End time of the general delivery window'),
    ('max_wait_time_min',        '15',    'Maximum wait time at the delivery point, in minutes'),
    ('sla_alert_threshold_pct',  '90',    'Minimum SLA compliance percentage before triggering an alert'),
    ('password_min_length',      '8',     'Minimum password length'),
    ('password_expiration_days', '90',    'Days before forcing a password change'),
    ('otp_code_length',          '6',     'Number of digits in the delivery confirmation OTP code'),
    ('otp_expiry_minutes',       '60',    'Minutes an OTP code stays valid before expiring'),
    ('max_failed_login_attempts',    '5',  'Failed login attempts before an account is locked'),
    ('account_lockout_minutes',      '15', 'Minutes an account stays locked after too many failed login attempts'),
    ('password_reset_expiry_minutes','30', 'Minutes a password reset token stays valid before expiring'),
    ('session_inactivity_minutes',   '30', 'Minutes of inactivity before auto-closing a session (does not apply to the driver mobile app in route)'),
    ('order_reservation_ttl_minutes','15', 'Minutes a soft order reservation lasts without coordinator activity');
