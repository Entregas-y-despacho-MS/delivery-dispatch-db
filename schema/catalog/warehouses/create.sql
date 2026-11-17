CREATE TABLE warehouses (
    warehouse_id           SERIAL,
    code                    VARCHAR(30)     NOT NULL,                        -- ej. WH-LPZ-01
    name                    VARCHAR(100)    NOT NULL,
    address                 TEXT            NOT NULL,
    latitude                NUMERIC(9,6)    NOT NULL,
    longitude               NUMERIC(9,6)    NOT NULL,
    contact_name            VARCHAR(150),
    contact_phone           VARCHAR(30),
    reception_start_time    TIME            NOT NULL,                        -- inicio de la ventana de recepción
    reception_end_time      TIME            NOT NULL,                        -- fin de la ventana de recepción
    active                  BOOLEAN         NOT NULL DEFAULT TRUE,
    deleted_at              TIMESTAMPTZ,                                     -- soft delete
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (warehouse_id),
    CONSTRAINT chk_warehouses_reception_window CHECK (reception_end_time > reception_start_time)
);

CREATE UNIQUE INDEX uq_warehouses_code ON warehouses(code) WHERE deleted_at IS NULL;
