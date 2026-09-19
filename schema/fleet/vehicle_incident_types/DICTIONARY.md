# vehicle_incident_types

Catálogo de los tipos de problema mecánico o de mantenimiento que puede tener un vehículo de la flota.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| vehicle_incident_type_id | SERIAL | NO | auto | Identificador del tipo de incidente |
| name | VARCHAR(100) | NO | — | Descripción del tipo de incidente (ej. "Falla mecánica") |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A34). No se borra en duro porque hay mantenimientos históricos que lo referencian.

## Technical notes

- Único solo entre filas no borradas (`WHERE deleted_at IS NULL`).
