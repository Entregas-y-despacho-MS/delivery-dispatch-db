# vehicles

La flota de vehículos disponible para despachos y traslados.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| vehicle_id | SERIAL | NO | auto | Identificador del vehículo |
| vehicle_status_id | INT | NO | — | Estado operativo actual |
| type | VARCHAR(50) | NO | — | Tipo de vehículo (moto, camioneta, camión, etc.) |
| plate | VARCHAR(15) | NO | — | Placa |
| capacity_kg | NUMERIC(10,2) | NO | — | Capacidad de carga en kg — misma unidad que `dispatches.estimated_weight_kg`, para poder validar antes de asignar pedidos (RF-A03) sin ambigüedad de unidades |
| deleted_at | TIMESTAMPTZ | YES | — | Baja permanente de la flota (soft delete) |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| vehicle_status_id | vehicle_statuses.vehicle_status_id | Estado operativo (activo, en mantenimiento, fuera de servicio) |

## Business rules

- El coordinador administra el catálogo de vehículos (RF-A30). Un vehículo dado de baja (`deleted_at`) no se borra en duro porque hay despachos y mantenimientos históricos que lo referencian — solo deja de aparecer como opción para asignar.
- Se usa para camiones de gran volumen en traslados de/hacia proveedor, no solo para reparto de última milla.

## Technical notes

- `plate` es única solo entre vehículos no borrados (`WHERE deleted_at IS NULL`).
