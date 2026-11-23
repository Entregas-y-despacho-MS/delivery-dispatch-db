-- ES-302 (ST-302.2): planning universe per cutoff and frozen route manifests.
-- Four append-only history tables (UPDATE is always blocked; DELETE only with
-- app.allow_event_purge = 'on', for test cleanup, the same as route_batch_events).
-- No backfill: earlier history has no rows and reads as unknown (N/A).

-- 1. Planning cutoff (D-1): one row per run that left a snapshot.
CREATE TABLE IF NOT EXISTS planning_cutoffs (
    planning_cutoff_id   SERIAL,
    shift_date           DATE            NOT NULL,                        -- operating day of the routes the cutoff plans
    cutoff_at            TIMESTAMPTZ     NOT NULL,                        -- UTC instant of the cutoff (start of the run)
    operating_timezone   VARCHAR(40)     NOT NULL,                        -- operating timezone in which shift_date is read (America/La_Paz)
    trigger_type         VARCHAR(20)     NOT NULL,                        -- scheduled | manual
    occurrence           VARCHAR(60),                                     -- scheduled occurrence (route-cutoff@YYYY-MM-DDTHH:mm); NULL when manual
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (planning_cutoff_id),
    CONSTRAINT chk_planning_cutoffs_trigger_type CHECK (trigger_type IN ('scheduled', 'manual')),
    CONSTRAINT chk_planning_cutoffs_occurrence   CHECK ((trigger_type = 'scheduled') = (occurrence IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS idx_planning_cutoffs_shift_date ON planning_cutoffs(shift_date);
CREATE UNIQUE INDEX IF NOT EXISTS uq_planning_cutoffs_occurrence ON planning_cutoffs(occurrence) WHERE occurrence IS NOT NULL;

-- 2. Universe of the cutoff: every dispatch read, eligible or excluded with a reason.
CREATE TABLE IF NOT EXISTS planning_cutoff_dispatches (
    planning_cutoff_dispatch_id  SERIAL,
    planning_cutoff_id           INT             NOT NULL,                -- cutoff the row belongs to
    dispatch_id                  INT             NOT NULL,                -- dispatch evaluated
    universe_status              VARCHAR(20)     NOT NULL,                -- eligible | excluded
    exclusion_code               VARCHAR(40),                             -- code of the exclusion reason; NULL when eligible
    exclusion_detail             TEXT,                                    -- readable explanation of the reason, as given at the cutoff; NULL when eligible
    route_batch_id               INT             NOT NULL,                -- provisional batch the dispatch was in when the cutoff read it
    route_version                INT             NOT NULL,                -- route_batches.version of that batch when the cutoff read it
    dispatch_type_id             INT             NOT NULL,                -- type of the dispatch (delivery, pickup...)
    delivery_zone_id             INT,                                     -- zone of the batch when the cutoff read it
    origin_warehouse_id          INT,                                     -- origin warehouse of the batch when the cutoff read it; NULL if the batch had none
    scheduled_window_start       TIMESTAMPTZ,                             -- start of the promised window when the cutoff read it (shift); NULL if it had none
    created_at                   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (planning_cutoff_dispatch_id),
    FOREIGN KEY (planning_cutoff_id)  REFERENCES planning_cutoffs(planning_cutoff_id) ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_id)         REFERENCES dispatches(dispatch_id)              ON DELETE RESTRICT,
    FOREIGN KEY (route_batch_id)      REFERENCES route_batches(route_batch_id)        ON DELETE RESTRICT,
    FOREIGN KEY (dispatch_type_id)    REFERENCES dispatch_types(dispatch_type_id)     ON DELETE RESTRICT,
    FOREIGN KEY (delivery_zone_id)    REFERENCES delivery_zones(delivery_zone_id)     ON DELETE RESTRICT,
    FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id)             ON DELETE RESTRICT,
    CONSTRAINT chk_planning_cutoff_dispatches_universe_status CHECK (universe_status IN ('eligible', 'excluded')),
    CONSTRAINT chk_planning_cutoff_dispatches_route_version   CHECK (route_version >= 0),
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

-- 3. Manifest of a route: a picture of its stops at a moment (confirmation, start or revision).
CREATE TABLE IF NOT EXISTS route_manifests (
    route_manifest_id    SERIAL,
    route_batch_id       INT             NOT NULL,                        -- batch the manifest belongs to
    manifest_version     INT             NOT NULL,                        -- 1, 2, ... per batch; a later change adds a version, never rewrites
    kind                 VARCHAR(20)     NOT NULL,                        -- confirmed (2nd approval) | started (route start) | revised (change after the start)
    route_version        INT             NOT NULL,                        -- route_batches.version of the batch when it was frozen
    vehicle_id           INT,                                             -- vehicle of the batch at that moment
    driver_id            INT,                                             -- driver of the batch at that moment
    actor_user_id        INT,                                             -- user who caused the manifest; NULL when the system did
    reason               TEXT,                                            -- declared reason (mandatory for revised)
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

-- 4. Stops of a manifest.
CREATE TABLE IF NOT EXISTS route_manifest_stops (
    route_manifest_stop_id  SERIAL,
    route_manifest_id       INT             NOT NULL,                     -- manifest the stop belongs to
    dispatch_id             INT             NOT NULL,                     -- dispatch of the stop
    dispatch_type_id        INT             NOT NULL,                     -- type of the dispatch (delivery, pickup...)
    sequence_order          INT,                                          -- visiting order at that moment; NULL if it had none
    stop_state              VARCHAR(20)     NOT NULL,                     -- planned (confirmed) | departing | excluded (started and revised)
    exclusion_code          VARCHAR(40),                                  -- reason the stop does not leave (e.g. failed package check); NULL unless excluded
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

-- Immutability: UPDATE is always blocked; DELETE only with app.allow_event_purge = 'on'.
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
