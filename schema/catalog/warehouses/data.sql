-- Ejemplo mínimo — ajustar a los almacenes reales de la operación antes de usar en un entorno
-- compartido. El primero es el centro de distribución: origen de las rutas para OSRM.
INSERT INTO warehouses (code, name, address, latitude, longitude, contact_name, contact_phone, reception_start_time, reception_end_time, active) VALUES
    ('WH-LPZ-01', 'Centro de Distribución La Paz', 'Av. Autopista Viacha, Zona Industrial, La Paz', -16.520000, -68.169000, 'Operaciones CD La Paz', '+591 2 2345678', '07:00', '19:00', TRUE),
    ('WH-LPZ-02', 'Almacén Sopocachi',             'Av. 20 de Octubre 2000, Sopocachi, La Paz',       -16.504000, -68.126000, 'Operaciones Sopocachi', '+591 2 2456789', '08:00', '17:00', TRUE);
