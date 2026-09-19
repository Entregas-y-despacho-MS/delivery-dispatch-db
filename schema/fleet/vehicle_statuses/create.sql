CREATE TABLE vehicle_statuses (
    vehicle_status_id   SERIAL,
    name                VARCHAR(30)     NOT NULL UNIQUE,                   -- active | maintenance | out_of_service
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vehicle_status_id)
);
