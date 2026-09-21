CREATE TABLE users (
    user_id                    SERIAL,
    role_id                    INT NOT NULL,                       -- rol interno (coordinador, supervisor o repartidor)
    full_name                  VARCHAR(150) NOT NULL,              -- nombre completo
    username                   VARCHAR(50) NOT NULL,               -- usuario de acceso
    email                      VARCHAR(150),                       -- correo de contacto
    password_hash              VARCHAR(255) NOT NULL,              -- contraseña con hash seguro
    password_changed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- última vez que se cambió la contraseña, para la caducidad periódica (RF-A25)
    failed_attempts            SMALLINT NOT NULL DEFAULT 0,        -- intentos fallidos consecutivos
    locked_until               TIMESTAMPTZ,                        -- bloqueo temporal hasta esta fecha
    refresh_token_hash         VARCHAR(255),                       -- hash del refresh token vigente, persistencia segura de la app móvil
    requires_pwd_change        BOOLEAN NOT NULL DEFAULT TRUE,      -- fuerza cambio de contraseña en el próximo login
    password_reset_token       VARCHAR(255),                       -- token de recuperación de contraseña; NULL si no hay ninguno pendiente
    password_reset_expires_at  TIMESTAMPTZ,                        -- vencimiento del token de recuperación
    two_factor_secret          VARCHAR(255),                       -- secreto TOTP (2FA); NULL hasta que el usuario lo activa
    two_factor_enabled         BOOLEAN NOT NULL DEFAULT FALSE,     -- si el usuario tiene 2FA activo
    active                     BOOLEAN NOT NULL DEFAULT TRUE,      -- activo/inactivo — estado de negocio, no soft delete
    deleted_at                 TIMESTAMPTZ,                        -- soft delete técnico (@DeleteDateColumn de TypeORM); distinto de "active"
    created_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE UNIQUE INDEX uq_users_username ON users(username) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_users_email    ON users(email)    WHERE deleted_at IS NULL AND email IS NOT NULL;
CREATE UNIQUE INDEX uq_users_password_reset_token ON users(password_reset_token) WHERE password_reset_token IS NOT NULL;
