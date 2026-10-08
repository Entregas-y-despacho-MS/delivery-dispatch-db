CREATE TABLE dispatches (
    dispatch_id                SERIAL         ,
    dispatch_type_id           INT            NOT NULL,                  -- delivery / warehouse pickup / supplier pickup / supplier return
    dispatch_status_id         INT            NOT NULL,                  -- estado actual del despacho
    delivery_zone_id           INT            ,                          -- zona de reparto (solo aplica a delivery/warehouse_return_pickup)
    service_level_id           INT            ,                          -- nivel de servicio contratado
    route_batch_id             INT            ,                          -- ruta a la que pertenece; NULL hasta que el coordinador lo asigna a una ruta
    sequence_order             SMALLINT       ,                          -- orden de visita dentro de su route_batch (calculado por OSRM)
    source_order_ref           VARCHAR(100)   NOT NULL,                  -- referencia del pedido/orden en el sistema origen (Almacén o Compras y Proveedores)
    priority                   VARCHAR(10)    NOT NULL DEFAULT 'normal', -- urgent | normal
    delivery_address           TEXT           NOT NULL,                  -- dirección de destino (cliente, domicilio de recojo, o planta del proveedor)
    delivery_latitude          NUMERIC(9,6)   ,                          -- latitud del destino, recibida del sistema origen (el usuario la marca en un mapa) junto con delivery_address
    delivery_longitude         NUMERIC(9,6)   ,                          -- longitud del destino, recibida del sistema origen (mismo motivo que arriba)
    contact_name               VARCHAR(150)   ,                          -- nombre de la persona de contacto en el destino (cliente o encargado en planta del proveedor)
    contact_phone              VARCHAR(30)    ,                          -- teléfono de contacto
    contact_email              VARCHAR(150)   ,                          -- correo de contacto
    payment_status_label       VARCHAR(50)    ,                          -- etiqueta informativa de pago recibida del origen, ej. "Prepaid" — de solo lectura, Despachos no gestiona pagos
    package_contents           TEXT           ,                          -- resumen del contenido del paquete, recibido del origen — de solo lectura, Despachos no gestiona inventario
    estimated_weight_kg        NUMERIC(10,2)  ,                          -- peso estimado del paquete/carga, informado en el preaviso de preparación (escenario 1)
    return_reason              TEXT           ,                          -- motivo de la devolución/garantía o del rechazo al proveedor (solo aplica a warehouse_return_pickup / supplier_return)
    scheduled_window_start     TIMESTAMPTZ    ,                          -- inicio de la ventana horaria prometida
    scheduled_window_end       TIMESTAMPTZ    ,                          -- fin de la ventana horaria prometida
    package_ready_at           TIMESTAMPTZ    ,                          -- momento en que el origen confirmó que el paquete/carga está físicamente listo para ser recogido (segundo aviso, escenario 1)
    tracking_token             VARCHAR(100)   UNIQUE,                    -- token del enlace de seguimiento del cliente
    tracking_token_expires_at  TIMESTAMPTZ    ,                          -- vencimiento del token
    last_latitude              NUMERIC(9,6)   ,                          -- última latitud conocida
    last_longitude             NUMERIC(9,6)   ,                          -- última longitud conocida
    last_location_at           TIMESTAMPTZ    ,                          -- momento de la última actualización de ubicación
    tracking_code              VARCHAR(20)    ,                          -- código de traslado DSP-AAAA-NNNNN (único e inmutable; lo genera next_tracking_code())
    evidence_policy            VARCHAR(30)    NOT NULL DEFAULT 'hand_delivery_standard', -- política de evidencia exigida por Almacén
    confirmed_at               TIMESTAMPTZ    ,                          -- momento en que se confirmó la entrega, el recojo o la recepción en destino
    created_at                 TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_id),
    FOREIGN KEY (dispatch_type_id)   REFERENCES dispatch_types(dispatch_type_id),
    FOREIGN KEY (dispatch_status_id) REFERENCES dispatch_statuses(dispatch_status_id),
    FOREIGN KEY (delivery_zone_id)   REFERENCES delivery_zones(delivery_zone_id),
    FOREIGN KEY (service_level_id)   REFERENCES service_levels(service_level_id),
    FOREIGN KEY (route_batch_id)     REFERENCES route_batches(route_batch_id)         ON DELETE SET NULL,
    CONSTRAINT chk_dispatches_priority CHECK (priority IN ('urgent', 'normal')),
    CONSTRAINT uq_dispatches_tracking_code UNIQUE (tracking_code),
    CONSTRAINT chk_dispatches_evidence_policy CHECK (evidence_policy IN ('hand_delivery_standard', 'contactless_delivery', 'high_value_control'))
);

CREATE INDEX idx_dispatches_status_id      ON dispatches(dispatch_status_id);
CREATE INDEX idx_dispatches_type_id        ON dispatches(dispatch_type_id);
CREATE INDEX idx_dispatches_zone_id        ON dispatches(delivery_zone_id);
CREATE INDEX idx_dispatches_service_level_id ON dispatches(service_level_id);
CREATE INDEX idx_dispatches_route_batch_id ON dispatches(route_batch_id);
CREATE INDEX idx_dispatches_source_order_ref ON dispatches(source_order_ref);

-- Evita que dos despachos de la misma ruta queden con el mismo orden de visita
CREATE UNIQUE INDEX uq_dispatches_route_batch_sequence ON dispatches(route_batch_id, sequence_order)
    WHERE route_batch_id IS NOT NULL AND sequence_order IS NOT NULL;

-- Punto de destino indexado con GiST (tipos geométricos nativos; la imagen postgres no incluye PostGIS)
CREATE INDEX idx_dispatches_delivery_point ON dispatches
    USING GIST (point(delivery_longitude::float8, delivery_latitude::float8))
    WHERE delivery_latitude IS NOT NULL AND delivery_longitude IS NOT NULL;

-- Contador anual del código de traslado: el UPSERT bloquea la fila, seguro ante concurrencia
CREATE TABLE tracking_code_counters (
    code_year   SMALLINT   NOT NULL,
    last_value  INT        NOT NULL DEFAULT 0,
    PRIMARY KEY (code_year)
);

CREATE FUNCTION next_tracking_code() RETURNS VARCHAR AS $$
DECLARE
    y  SMALLINT := EXTRACT(YEAR FROM NOW())::SMALLINT;
    n  INT;
BEGIN
    INSERT INTO tracking_code_counters (code_year, last_value) VALUES (y, 1)
    ON CONFLICT (code_year) DO UPDATE SET last_value = tracking_code_counters.last_value + 1
    RETURNING last_value INTO n;
    RETURN 'DSP-' || y || '-' || LPAD(n::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION prevent_tracking_code_change() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.tracking_code IS NOT NULL AND NEW.tracking_code IS DISTINCT FROM OLD.tracking_code THEN
        RAISE EXCEPTION 'dispatches.tracking_code is immutable once assigned';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dispatches_tracking_code_immutable
    BEFORE UPDATE OF tracking_code ON dispatches
    FOR EACH ROW EXECUTE FUNCTION prevent_tracking_code_change();
