# incident_reasons

Catálogo de motivos de incidencia durante una entrega (ej. cliente ausente, dirección incorrecta).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| incident_reason_id | SERIAL | NO | auto | Identificador del motivo |
| name | VARCHAR(150) | NO | — | Descripción del motivo de incidencia |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A32). El repartidor lo usa para registrar una incidencia durante la entrega (RF-U06). No se borra en duro por el historial de incidencias que lo referencian.

## Technical notes

- Único solo entre motivos no borrados (`WHERE deleted_at IS NULL`).
