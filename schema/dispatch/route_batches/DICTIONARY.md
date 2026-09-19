# route_batches

Agrupa uno o varios despachos bajo un mismo repartidor, vehículo y turno — la unidad real de trabajo que el coordinador arma y asigna, en vez de asignar despacho por despacho.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| route_batch_id | SERIAL | NO | auto | Identificador de la ruta |
| driver_id | INT | YES | — | Repartidor asignado a la ruta; NULL hasta que el coordinador lo asigna |
| vehicle_id | INT | YES | — | Vehículo asignado a la ruta; NULL hasta que el coordinador lo asigna |
| shift_date | DATE | NO | — | Fecha/turno en que se ejecuta la ruta |
| route_geometry | TEXT | YES | — | Polyline codificado del recorrido completo, calculado una vez por el motor de ruteo (OSRM) y cacheado — no se recalcula en cada vista del mapa |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| driver_id | users.user_id | Repartidor/transportista asignado a la ruta |
| vehicle_id | vehicles.vehicle_id | Vehículo asignado a la ruta |

## Business rules

- El coordinador agrupa despachos por zona y valida la capacidad del vehículo (RF-A03) antes de asignar repartidor y vehículo a la ruta (RF-A04) — la asignación queda en `route_batches`, no en cada despacho individual.
- El orden en que el repartidor visita las paradas de su ruta queda en `dispatches.sequence_order`, calculado a partir de esta ruta — no es un requerimiento base del documento de requerimientos, es una funcionalidad extra del grupo (motor de ruteo OSRM, self-hosted).
- Una ruta puede existir sin repartidor/vehículo asignado todavía (recién creada, agrupando despachos por zona antes de decidir quién la ejecuta).

## Technical notes

- `driver_id`/`vehicle_id` usan `ON DELETE SET NULL`: si el usuario o el vehículo se elimina, la ruta no se pierde, solo queda sin asignar.
- `route_geometry` se guarda como polyline codificado (no GeoJSON crudo) por ser mucho más compacto — se decodifica en el cliente (web/app móvil) al momento de dibujar el mapa.
