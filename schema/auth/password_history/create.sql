CREATE TABLE password_history (
    password_history_id    SERIAL,
    user_id                 INT NOT NULL,                       -- usuario dueño de esta contraseña histórica
    password_hash           VARCHAR(255) NOT NULL,               -- hash de una contraseña que el usuario tuvo antes
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (password_history_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_password_history_user_id ON password_history(user_id);
