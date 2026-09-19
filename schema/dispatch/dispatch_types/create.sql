CREATE TABLE dispatch_types (
    dispatch_type_id    SERIAL,
    name                 VARCHAR(50)     NOT NULL UNIQUE,                 -- delivery | warehouse_return_pickup | supplier_pickup | supplier_return
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_type_id)
);
