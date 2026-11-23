-- Tabla de historia append-only: no lleva updated_at porque un corte ya registrado nunca se modifica.
-- La inmutabilidad la imponen dos triggers (UPDATE siempre bloqueado; DELETE solo con
-- app.allow_event_purge = 'on', para limpieza de pruebas). TRUNCATE no se bloquea: es convención.
CREATE TABLE planning_cutoffs (
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

CREATE INDEX idx_planning_cutoffs_shift_date ON planning_cutoffs(shift_date);
CREATE UNIQUE INDEX uq_planning_cutoffs_occurrence ON planning_cutoffs(occurrence) WHERE occurrence IS NOT NULL;

CREATE FUNCTION fn_planning_cutoffs_prevent_update() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'planning_cutoffs is append-only: UPDATE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION fn_planning_cutoffs_prevent_delete() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(current_setting('app.allow_event_purge', true), '') = 'on' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'planning_cutoffs is append-only: DELETE is not allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_planning_cutoffs_prevent_update
    BEFORE UPDATE ON planning_cutoffs
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoffs_prevent_update();

CREATE TRIGGER trg_planning_cutoffs_prevent_delete
    BEFORE DELETE ON planning_cutoffs
    FOR EACH ROW EXECUTE FUNCTION fn_planning_cutoffs_prevent_delete();
