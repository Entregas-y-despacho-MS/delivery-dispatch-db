-- Tabla de historia append-only: no lleva updated_at porque un manifiesto ya congelado nunca se modifica;
-- un cambio posterior agrega otro manifiesto con manifest_version + 1.
-- Inmutabilidad por triggers (UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on').
CREATE TABLE route_manifests (
    route_manifest_id    SERIAL,
    route_batch_id       INT             NOT NULL,                        -- lote al que pertenece el manifiesto
    manifest_version     INT             NOT NULL,                        -- 1, 2, ... por lote; un cambio posterior agrega una versión, nunca reescribe
    kind                 VARCHAR(20)     NOT NULL,                        -- confirmed (2.ª aprobación) | started (inicio de ruta) | revised (cambio posterior al inicio)
    route_version        INT             NOT NULL,                        -- route_batches.version del lote cuando se congeló
    vehicle_id           INT,                                             -- vehículo del lote en ese momento
    driver_id            INT,                                             -- repartidor del lote en ese momento
    actor_user_id        INT,                                             -- usuario que originó el manifiesto; NULL si fue el sistema
    reason               TEXT,                                            -- motivo declarado (obligatorio en revised)
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_manifest_id),
    FOREIGN KEY (route_batch_id)  REFERENCES route_batches(route_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (vehicle_id)      REFERENCES vehicles(vehicle_id)          ON DELETE RESTRICT,
    FOREIGN KEY (driver_id)       REFERENCES users(user_id)                ON DELETE RESTRICT,
    FOREIGN KEY (actor_user_id)   REFERENCES users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT chk_route_manifests_kind             CHECK (kind IN ('confirmed', 'started', 'revised')),
    CONSTRAINT chk_route_manifests_manifest_version CHECK (manifest_version >= 1),
    CONSTRAINT chk_route_manifests_route_version    CHECK (route_version >= 0),
    CONSTRAINT chk_route_manifests_revised_reason   CHECK (kind <> 'revised' OR (reason IS NOT NULL AND btrim(reason) <> ''))
);

CREATE UNIQUE INDEX uq_route_manifests_batch_version ON route_manifests(route_batch_id, manifest_version);
CREATE UNIQUE INDEX uq_route_manifests_started       ON route_manifests(route_batch_id) WHERE kind = 'started';
CREATE INDEX idx_route_manifests_vehicle_id    ON route_manifests(vehicle_id);
CREATE INDEX idx_route_manifests_driver_id     ON route_manifests(driver_id);
CREATE INDEX idx_route_manifests_actor_user_id ON route_manifests(actor_user_id);

CREATE FUNCTION fn_route_manifests_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_manifests is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_route_manifests_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_manifests is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_route_manifests_prevent_update
    BEFORE UPDATE ON route_manifests
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifests_prevent_update();

CREATE TRIGGER trg_route_manifests_prevent_delete
    BEFORE DELETE ON route_manifests
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifests_prevent_delete();
