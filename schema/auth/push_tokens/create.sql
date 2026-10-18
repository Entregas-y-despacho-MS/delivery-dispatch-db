CREATE TABLE push_tokens (
    push_token_id  SERIAL,
    user_id        INT             NOT NULL,                       -- usuario dueño de este registro de dispositivo
    device_id      VARCHAR(100)    NOT NULL,                       -- identificador estable del dispositivo, generado por la app móvil
    token          VARCHAR(255)    NOT NULL,                       -- token del proveedor de notificaciones push (Expo o FCM)
    platform       VARCHAR(10)     NOT NULL,                       -- sistema operativo del dispositivo: ios o android
    last_used_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),         -- última vez que la app registró este token
    revoked_at     TIMESTAMPTZ,                                    -- NULL = activo; se llena al cerrar sesión o si el proveedor rechaza el token
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (push_token_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_push_tokens_user_device UNIQUE (user_id, device_id),
    CONSTRAINT chk_push_tokens_platform CHECK (platform IN ('ios', 'android'))
);

-- El token pertenece a un teléfono, no a una persona: mientras está activo solo puede tener un dueño.
CREATE UNIQUE INDEX uq_push_tokens_active_token ON push_tokens(token) WHERE revoked_at IS NULL;
