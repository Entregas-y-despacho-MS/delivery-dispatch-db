CREATE TABLE dispatch_packages (
    dispatch_package_id   SERIAL,
    dispatch_id           INT             NOT NULL,                       -- despacho al que pertenece el bulto
    external_package_id   VARCHAR(100)    NOT NULL,                       -- packageId asignado por Almacén
    length_cm             NUMERIC(8,2)    NOT NULL,
    width_cm              NUMERIC(8,2)    NOT NULL,
    height_cm             NUMERIC(8,2)    NOT NULL,
    gross_weight_kg       NUMERIC(10,3)   NOT NULL,                       -- peso bruto real
    handling_conditions   TEXT[]          NOT NULL DEFAULT '{}',          -- ej. fragile, keep_upright
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_package_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT uq_dispatch_packages_external UNIQUE (dispatch_id, external_package_id),
    CONSTRAINT chk_dispatch_packages_dimensions CHECK (length_cm > 0 AND width_cm > 0 AND height_cm > 0),
    CONSTRAINT chk_dispatch_packages_weight CHECK (gross_weight_kg > 0)
);

CREATE INDEX idx_dispatch_packages_dispatch_id ON dispatch_packages(dispatch_id);
