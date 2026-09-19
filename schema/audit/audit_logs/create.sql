-- Tabla de log append-only: no lleva updated_at (un registro de auditoría ya escrito no se modifica).
CREATE TABLE audit_logs (
    audit_log_id  SERIAL,
    user_id         INT,                                                    -- usuario que ejecutó la acción (NULL si el usuario fue eliminado)
    action            VARCHAR(100)    NOT NULL,                              -- login | password_change | user_created | ...
    detail              TEXT,                                                  -- detalle libre de la acción
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (audit_log_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
