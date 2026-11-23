-- Tabla de historia append-only: no lleva updated_at porque el universo de un corte nunca se modifica.
-- Inmutabilidad por triggers (UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on').
CREATE TABLE planning_cutoff_dispatches (
    planning_cutoff_dispatch_id  SERIAL,
    planning_cutoff_id           INT             NOT NULL,                -- corte al que pertenece la fila
    dispatch_id                  INT             NOT NULL,                -- despacho evaluado
    universe_status              VARCHAR(20)     NOT NULL,                -- eligible | excluded
    exclusion_code               VARCHAR(40),                             -- código del motivo de exclusión; NULL si es elegible
    exclusion_detail             TEXT,                                    -- explicación legible del motivo, tal como se dio en el corte; NULL si es elegible
    route_batch_id               INT             NOT NULL,                -- lote provisional en que estaba el despacho al leer el corte
    route_version                INT             NOT NULL,                -- route_batches.version de ese lote al leer el corte
    dispatch_type_id             INT             NOT NULL,                -- tipo del despacho (entrega, recojo...)
    delivery_zone_id             INT,                                     -- zona del lote al leer el corte
    origin_warehouse_id          INT,                                     -- almacén de origen del lote al leer el corte; NULL si el lote no lo tenía
    scheduled_window_start       TIMESTAMPTZ,                             -- inicio de la ventana prometida al leer el corte (turno); NULL si no tenía
    created_at                   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (planning_cutoff_dispatch_id),
    FOREIGN KEY (planning_cutoff_id)  REFERENCES planning_cutoffs(planning_cutoff_id) ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_id)         REFERENCES dispatches(dispatch_id)              ON DELETE RESTRICT,
    FOREIGN KEY (route_batch_id)      REFERENCES route_batches(route_batch_id)        ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_type_id)    REFERENCES dispatch_types(dispatch_type_id)     ON DELETE RESTRICT,
    FOREIGN KEY (delivery_zone_id)    REFERENCES delivery_zones(delivery_zone_id)     ON DELETE RESTRICT,
    FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id)             ON DELETE RESTRICT,
    CONSTRAINT chk_planning_cutoff_dispatches_universe_status CHECK (universe_status IN ('eligible', 'excluded')),
    CONSTRAINT chk_planning_cutoff_dispatches_exclusion CHECK (
        (universe_status = 'eligible' AND exclusion_code IS NULL AND exclusion_detail IS NULL)
        OR (universe_status = 'excluded'
            AND exclusion_code IS NOT NULL AND exclusion_code ~ '^[a-z][a-z0-9_]{1,39}$'
            AND exclusion_detail IS NOT NULL AND btrim(exclusion_detail) <> '')
    )
);

CREATE UNIQUE INDEX uq_planning_cutoff_dispatches_cutoff_dispatch ON planning_cutoff_dispatches(planning_cutoff_id, dispatch_id);
CREATE INDEX idx_planning_cutoff_dispatches_cutoff_status       ON planning_cutoff_dispatches(planning_cutoff_id, universe_status);
CREATE INDEX idx_planning_cutoff_dispatches_dispatch_id         ON planning_cutoff_dispatches(dispatch_id);
CREATE INDEX idx_planning_cutoff_dispatches_route_batch_id      ON planning_cutoff_dispatches(route_batch_id);
CREATE INDEX idx_planning_cutoff_dispatches_dispatch_type_id    ON planning_cutoff_dispatches(dispatch_type_id);
CREATE INDEX idx_planning_cutoff_dispatches_delivery_zone_id    ON planning_cutoff_dispatches(delivery_zone_id);
CREATE INDEX idx_planning_cutoff_dispatches_origin_warehouse_id ON planning_cutoff_dispatches(origin_warehouse_id);

CREATE FUNCTION fn_planning_cutoff_dispatches_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'planning_cutoff_dispatches is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_planning_cutoff_dispatches_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'planning_cutoff_dispatches is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_planning_cutoff_dispatches_prevent_update
    BEFORE UPDATE ON planning_cutoff_dispatches
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoff_dispatches_prevent_update();

CREATE TRIGGER trg_planning_cutoff_dispatches_prevent_delete
    BEFORE DELETE ON planning_cutoff_dispatches
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoff_dispatches_prevent_delete();
