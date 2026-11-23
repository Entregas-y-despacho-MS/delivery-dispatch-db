-- Tabla de historia append-only: no lleva updated_at porque las paradas de un manifiesto nunca se modifican.
-- Inmutabilidad por triggers (UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on').
CREATE TABLE route_manifest_stops (
    route_manifest_stop_id  SERIAL,
    route_manifest_id       INT             NOT NULL,                     -- manifiesto al que pertenece la parada
    dispatch_id             INT             NOT NULL,                     -- despacho de la parada
    dispatch_type_id        INT             NOT NULL,                     -- tipo del despacho (entrega, recojo...)
    sequence_order          INT,                                          -- orden de visita en ese momento; NULL si no tenía
    stop_state              VARCHAR(20)     NOT NULL,                     -- planned (confirmed) | departing | excluded (started y revised)
    exclusion_code          VARCHAR(40),                                  -- motivo de la exclusión (p. ej. cotejo fallido); NULL salvo excluded
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_manifest_stop_id),
    FOREIGN KEY (route_manifest_id) REFERENCES route_manifests(route_manifest_id) ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_id)       REFERENCES dispatches(dispatch_id)            ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_type_id)  REFERENCES dispatch_types(dispatch_type_id)   ON DELETE RESTRICT,
    CONSTRAINT chk_route_manifest_stops_stop_state     CHECK (stop_state IN ('planned', 'departing', 'excluded')),
    CONSTRAINT chk_route_manifest_stops_exclusion_code CHECK (
        (stop_state = 'excluded' AND exclusion_code IS NOT NULL AND exclusion_code ~ '^[a-z][a-z0-9_]{1,39}$')
        OR (stop_state <> 'excluded' AND exclusion_code IS NULL)
    ),
    CONSTRAINT chk_route_manifest_stops_sequence_order CHECK (sequence_order IS NULL OR sequence_order >= 1)
);

CREATE UNIQUE INDEX uq_route_manifest_stops_manifest_dispatch ON route_manifest_stops(route_manifest_id, dispatch_id);
CREATE INDEX idx_route_manifest_stops_dispatch_id      ON route_manifest_stops(dispatch_id);
CREATE INDEX idx_route_manifest_stops_dispatch_type_id ON route_manifest_stops(dispatch_type_id);

CREATE FUNCTION fn_route_manifest_stops_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_manifest_stops is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_route_manifest_stops_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_manifest_stops is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_route_manifest_stops_prevent_update
    BEFORE UPDATE ON route_manifest_stops
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifest_stops_prevent_update();

CREATE TRIGGER trg_route_manifest_stops_prevent_delete
    BEFORE DELETE ON route_manifest_stops
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifest_stops_prevent_delete();
