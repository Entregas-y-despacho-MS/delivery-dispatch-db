CREATE TABLE roles (
    role_id             SERIAL,
    name                VARCHAR(30)     NOT NULL UNIQUE,                   -- root | admin | coordinator | supervisor | driver
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id)
);
