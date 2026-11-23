-- ES-302 (ST-302.2): universo de planificación por corte y manifiestos de ruta congelados.
-- Cuatro tablas de historia append-only (UPDATE siempre bloqueado; DELETE solo con
-- app.allow_event_purge = 'on', para limpieza de pruebas, igual que route_batch_events).
-- Sin backfill: el histórico anterior queda sin filas y se lee como desconocido (N/D).

-- 1. Corte de planificación (D-1): una fila por corrida que dejó snapshot.
CREATE TABLE IF NOT EXISTS planning_cutoffs (
    planning_cutoff_id   SERIAL,
    shift_date           DATE            NOT NULL,                        -- día operativo de las rutas que el corte planifica
    cutoff_at            TIMESTAMPTZ     NOT NULL,                        -- instante UTC del corte (inicio de la corrida)
    operating_timezone   VARCHAR(40)     NOT NULL,                        -- zona operativa en que se interpreta shift_date (America/La_Paz)
    trigger_type         VARCHAR(20)     NOT NULL,                        -- scheduled | manual
    occurrence           VARCHAR(60),                                     -- ocurrencia programada (route-cutoff@AAAA-MM-DDTHH:mm); NULL si fue manual
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (planning_cutoff_id),
    CONSTRAINT chk_planning_cutoffs_trigger_type CHECK (trigger_type IN ('scheduled', 'manual')),
    CONSTRAINT chk_planning_cutoffs_occurrence   CHECK ((trigger_type = 'scheduled') = (occurrence IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS idx_planning_cutoffs_shift_date ON planning_cutoffs(shift_date);
CREATE UNIQUE INDEX IF NOT EXISTS uq_planning_cutoffs_occurrence ON planning_cutoffs(occurrence) WHERE occurrence IS NOT NULL;

-- 2. Universo del corte: cada despacho leído, elegible o excluido con motivo.
CREATE TABLE IF NOT EXISTS planning_cutoff_dispatches (
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

CREATE UNIQUE INDEX IF NOT EXISTS uq_planning_cutoff_dispatches_cutoff_dispatch ON planning_cutoff_dispatches(planning_cutoff_id, dispatch_id);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_cutoff_status       ON planning_cutoff_dispatches(planning_cutoff_id, universe_status);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_dispatch_id         ON planning_cutoff_dispatches(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_route_batch_id      ON planning_cutoff_dispatches(route_batch_id);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_dispatch_type_id    ON planning_cutoff_dispatches(dispatch_type_id);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_delivery_zone_id    ON planning_cutoff_dispatches(delivery_zone_id);
CREATE INDEX IF NOT EXISTS idx_planning_cutoff_dispatches_origin_warehouse_id ON planning_cutoff_dispatches(origin_warehouse_id);

-- 3. Manifiesto de una ruta: foto de sus paradas en un momento (confirmación, inicio o revisión).
CREATE TABLE IF NOT EXISTS route_manifests (
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

CREATE UNIQUE INDEX IF NOT EXISTS uq_route_manifests_batch_version ON route_manifests(route_batch_id, manifest_version);
CREATE UNIQUE INDEX IF NOT EXISTS uq_route_manifests_started       ON route_manifests(route_batch_id) WHERE kind = 'started';
CREATE INDEX IF NOT EXISTS idx_route_manifests_vehicle_id    ON route_manifests(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_route_manifests_driver_id     ON route_manifests(driver_id);
CREATE INDEX IF NOT EXISTS idx_route_manifests_actor_user_id ON route_manifests(actor_user_id);

-- 4. Paradas de un manifiesto.
CREATE TABLE IF NOT EXISTS route_manifest_stops (
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

CREATE UNIQUE INDEX IF NOT EXISTS uq_route_manifest_stops_manifest_dispatch ON route_manifest_stops(route_manifest_id, dispatch_id);
CREATE INDEX IF NOT EXISTS idx_route_manifest_stops_dispatch_id      ON route_manifest_stops(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_route_manifest_stops_dispatch_type_id ON route_manifest_stops(dispatch_type_id);

-- Inmutabilidad: UPDATE siempre bloqueado; DELETE solo con app.allow_event_purge = 'on'.
CREATE OR REPLACE FUNCTION fn_planning_cutoffs_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'planning_cutoffs is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_planning_cutoffs_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'planning_cutoffs is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_planning_cutoff_dispatches_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'planning_cutoff_dispatches is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_planning_cutoff_dispatches_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'planning_cutoff_dispatches is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_route_manifests_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_manifests is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_route_manifests_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_manifests is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_route_manifest_stops_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'route_manifest_stops is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_route_manifest_stops_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'route_manifest_stops is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_planning_cutoffs_prevent_update ON planning_cutoffs;
CREATE TRIGGER trg_planning_cutoffs_prevent_update
    BEFORE UPDATE ON planning_cutoffs
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoffs_prevent_update();

DROP TRIGGER IF EXISTS trg_planning_cutoffs_prevent_delete ON planning_cutoffs;
CREATE TRIGGER trg_planning_cutoffs_prevent_delete
    BEFORE DELETE ON planning_cutoffs
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoffs_prevent_delete();

DROP TRIGGER IF EXISTS trg_planning_cutoff_dispatches_prevent_update ON planning_cutoff_dispatches;
CREATE TRIGGER trg_planning_cutoff_dispatches_prevent_update
    BEFORE UPDATE ON planning_cutoff_dispatches
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoff_dispatches_prevent_update();

DROP TRIGGER IF EXISTS trg_planning_cutoff_dispatches_prevent_delete ON planning_cutoff_dispatches;
CREATE TRIGGER trg_planning_cutoff_dispatches_prevent_delete
    BEFORE DELETE ON planning_cutoff_dispatches
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoff_dispatches_prevent_delete();

DROP TRIGGER IF EXISTS trg_route_manifests_prevent_update ON route_manifests;
CREATE TRIGGER trg_route_manifests_prevent_update
    BEFORE UPDATE ON route_manifests
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifests_prevent_update();

DROP TRIGGER IF EXISTS trg_route_manifests_prevent_delete ON route_manifests;
CREATE TRIGGER trg_route_manifests_prevent_delete
    BEFORE DELETE ON route_manifests
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifests_prevent_delete();

DROP TRIGGER IF EXISTS trg_route_manifest_stops_prevent_update ON route_manifest_stops;
CREATE TRIGGER trg_route_manifest_stops_prevent_update
    BEFORE UPDATE ON route_manifest_stops
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifest_stops_prevent_update();

DROP TRIGGER IF EXISTS trg_route_manifest_stops_prevent_delete ON route_manifest_stops;
CREATE TRIGGER trg_route_manifest_stops_prevent_delete
    BEFORE DELETE ON route_manifest_stops
    FOR EACH ROW EXECUTE FUNCTION fn_route_manifest_stops_prevent_delete();
