-- Alerta operativa para el supervisor de flota (RF-A19): incidencia crítica, GPS sin reportar, muchas
-- incidencias de un repartidor en el día, o SLA de zona bajo el umbral. El sujeto de la alerta (a
-- quién o qué se refiere) depende de `kind` — por eso zone_id/dispatch_id/driver_id/vehicle_id son
-- todos nullable, solo el que corresponda a ese `kind` se completa.
CREATE TABLE operational_alerts (
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

-- Evita dos alertas abiertas del mismo tipo para el mismo sujeto (el supervisor ya tiene una pendiente).
-- vehicle_id queda fuera a propósito: nunca es el sujeto por sí solo, siempre es dato auxiliar de un
-- driver_id o dispatch_id (ej. "este repartidor, que además andaba en este vehículo") — incluirlo
-- rompería la unicidad si se completa de forma inconsistente entre dos alertas del mismo sujeto real.
-- COALESCE a -1: un índice único normal no bloquea dos filas con NULL en la misma columna (NULL no es
-- igual a NULL para unicidad), y la mayoría de estas columnas son NULL salvo la que importa por `kind`.
CREATE UNIQUE INDEX uq_operational_alerts_open_subject
    ON operational_alerts(kind, COALESCE(zone_id, -1), COALESCE(dispatch_id, -1), COALESCE(driver_id, -1))
    WHERE status = 'open';

CREATE INDEX idx_operational_alerts_status ON operational_alerts(status);
CREATE INDEX idx_operational_alerts_zone_id ON operational_alerts(zone_id);
CREATE INDEX idx_operational_alerts_driver_id ON operational_alerts(driver_id);
CREATE INDEX idx_operational_alerts_dispatch_id ON operational_alerts(dispatch_id);
