DELETE FROM settings WHERE setting_key = 'order_reservation_ttl_minutes';
DROP TABLE IF EXISTS dispatch_reservations;
