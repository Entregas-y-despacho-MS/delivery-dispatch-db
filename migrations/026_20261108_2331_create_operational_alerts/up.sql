-- ST-66.1 (ES-278, RF-A19): operational alerts for the fleet supervisor — critical incidents, stale
-- GPS, repeated driver incidents in a day, and zone SLA below threshold.

CREATE TABLE IF NOT EXISTS operational_alerts (
    operational_alert_id  SERIAL,
    zone_id               INT             ,                               -- zona del despacho/incidente, cuando aplica (sla_below_threshold)
    dispatch_id           INT             ,                               -- despacho de la incidencia crítica, cuando aplica
    driver_id             INT             ,                               -- repartidor del que se alerta (gps_stale, driver_incidents)
    vehicle_id            INT             ,                               -- vehículo del que se alerta, cuando aplica
    acknowledged_by       INT             ,                               -- supervisor/coordinador que reconoció la alerta
    kind                  VARCHAR(30)     NOT NULL,                       -- critical_incident | gps_stale | driver_incidents | sla_below_threshold
    severity              VARCHAR(20)     NOT NULL,                       -- critical | warning
    detail                JSONB           NOT NULL DEFAULT '{}',          -- contexto propio de cada kind (ej. motivo, minutos sin GPS, % de SLA)
    status                VARCHAR(20)     NOT NULL DEFAULT 'open',        -- open | acknowledged
    acknowledged_at       TIMESTAMPTZ     ,                               -- momento en que se reconoció; NULL mientras status = open
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (operational_alert_id),
    FOREIGN KEY (zone_id)         REFERENCES delivery_zones(delivery_zone_id) ON DELETE SET NULL,
    FOREIGN KEY (dispatch_id)     REFERENCES dispatches(dispatch_id)         ON DELETE SET NULL,
    FOREIGN KEY (driver_id)       REFERENCES users(user_id)                  ON DELETE SET NULL,
    FOREIGN KEY (vehicle_id)      REFERENCES vehicles(vehicle_id)            ON DELETE SET NULL,
    FOREIGN KEY (acknowledged_by) REFERENCES users(user_id)                  ON DELETE RESTRICT,
    CONSTRAINT chk_operational_alerts_kind CHECK (kind IN ('critical_incident', 'gps_stale', 'driver_incidents', 'sla_below_threshold')),
    CONSTRAINT chk_operational_alerts_severity CHECK (severity IN ('critical', 'warning')),
    CONSTRAINT chk_operational_alerts_status CHECK (status IN ('open', 'acknowledged')),
    CONSTRAINT chk_operational_alerts_acknowledged CHECK (
        (status = 'open' AND acknowledged_by IS NULL AND acknowledged_at IS NULL)
        OR (status = 'acknowledged' AND acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_operational_alerts_open_subject
    ON operational_alerts(kind, COALESCE(zone_id, -1), COALESCE(dispatch_id, -1), COALESCE(driver_id, -1))
    WHERE status = 'open';

CREATE INDEX IF NOT EXISTS idx_operational_alerts_status ON operational_alerts(status);
CREATE INDEX IF NOT EXISTS idx_operational_alerts_zone_id ON operational_alerts(zone_id);
CREATE INDEX IF NOT EXISTS idx_operational_alerts_driver_id ON operational_alerts(driver_id);
CREATE INDEX IF NOT EXISTS idx_operational_alerts_dispatch_id ON operational_alerts(dispatch_id);

CREATE OR REPLACE FUNCTION fn_operational_alerts_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_operational_alerts_set_updated_at ON operational_alerts;
CREATE TRIGGER trg_operational_alerts_set_updated_at
    BEFORE UPDATE ON operational_alerts
    FOR EACH ROW EXECUTE FUNCTION fn_operational_alerts_set_updated_at();
