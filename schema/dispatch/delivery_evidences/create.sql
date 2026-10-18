-- PK en UUID (no SERIAL): esta tabla la crea directamente la app móvil del repartidor, que puede
-- estar sin conexión. El cliente genera el UUID en el dispositivo antes de sincronizar,
-- por eso no lleva DEFAULT — un SERIAL no serviría porque el ID solo existiría después del INSERT
-- en el servidor, imposible mientras el dispositivo está offline.
-- Generar como UUID v7 (RFC 9562) en el cliente, no v4: v7 embebe el timestamp de creación,
-- lo que mantiene los INSERTs ordenados y evita fragmentar el índice de la PK (a diferencia de
-- v4, puramente aleatorio). Postgres no valida la versión, pero el backend NestJS sí: por default
-- `ParseUUIDPipe` y `@IsUUID()` solo aceptan v3/v4/v5 — hay que pasar version: '7' explícitamente
-- (`new ParseUUIDPipe({ version: '7' })`, `@IsUUID('7')`) en cualquier endpoint que reciba este ID.
CREATE TABLE delivery_evidences (
    delivery_evidence_id  UUID,
    dispatch_id           INT             NOT NULL,                       -- despacho al que corresponde la evidencia
    type                  VARCHAR(20)     NOT NULL,                       -- photo | signature | otp
    file_url              TEXT,                                           -- URL al archivo (foto/firma), ya comprimido por la app antes de enviarse
    otp_code               VARCHAR(10),                                    -- reservado; nunca guardar aquí el OTP en claro
    captured_at           TIMESTAMPTZ,                                    -- instante de captura de la evidencia
    latitude              NUMERIC(9,6),                                   -- latitud de captura, si está disponible
    longitude             NUMERIC(9,6),                                   -- longitud de captura, si está disponible
    receiver_name         VARCHAR(150),                                   -- nombre de quien recibió, para firma
    receiver_document     VARCHAR(30),                                    -- documento de quien recibió, para firma
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_evidence_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT chk_delivery_evidences_type CHECK (type IN ('photo', 'signature', 'otp')),
    CONSTRAINT chk_delivery_evidences_otp_code_null CHECK (otp_code IS NULL),
    CONSTRAINT chk_delivery_evidences_latitude_range CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_delivery_evidences_longitude_range CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_delivery_evidences_dispatch_id ON delivery_evidences(dispatch_id);
