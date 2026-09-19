-- Tabla de configuración clave-valor (parámetros generales del servicio). Se aparta del formato
-- estándar (PK = SERIAL) porque su clave natural es el nombre del parámetro, no un ID artificial.
CREATE TABLE settings (
    setting_key    VARCHAR(100)    NOT NULL,                              -- nombre del parámetro
    setting_value  TEXT            NOT NULL,                              -- valor actual (se interpreta según el parámetro)
    description    TEXT,                                                  -- para qué sirve este parámetro
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (setting_key)
);
