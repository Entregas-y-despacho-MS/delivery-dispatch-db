-- PK en UUID (no SERIAL): igual que delivery_evidences, la crea directamente la app móvil del
-- repartidor, que puede estar sin conexión. Sin DEFAULT: el ID lo genera el
-- dispositivo antes de sincronizar.
-- Generar como UUID v7, no v4 (ver detalle en delivery_evidences/create.sql). Ojo en el backend:
-- `ParseUUIDPipe`/`@IsUUID()` de NestJS no aceptan v7 por default (solo v3/v4/v5) — hay que pasar
-- version: '7' explícitamente en cualquier endpoint que reciba este ID.
CREATE TABLE dispatch_incidents (
    dispatch_incident_id  UUID,
    dispatch_id           INT             NOT NULL,                       -- despacho donde ocurrió la incidencia
    incident_reason_id    INT             NOT NULL,                       -- motivo de incidencia (catálogo)
    description             TEXT,                                          -- detalle adicional de la incidencia
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_incident_id),
    FOREIGN KEY (dispatch_id)        REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    FOREIGN KEY (incident_reason_id) REFERENCES incident_reasons(incident_reason_id)
);

CREATE INDEX idx_dispatch_incidents_dispatch_id ON dispatch_incidents(dispatch_id);
CREATE INDEX idx_dispatch_incidents_incident_reason_id ON dispatch_incidents(incident_reason_id);
