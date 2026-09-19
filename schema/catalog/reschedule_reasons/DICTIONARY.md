# reschedule_reasons

Catálogo de motivos por los que se reprograma o reasigna un despacho.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| reschedule_reason_id | SERIAL | NO | auto | Identificador del motivo |
| name | VARCHAR(150) | NO | — | Descripción del motivo de reprogramación o reasignación |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A33), distinto del catálogo de motivos de incidencia: este es sobre decisiones de reprogramación/reasignación (RF-A05, RF-A16), no sobre problemas ocurridos durante la entrega.

## Technical notes

- Único solo entre motivos no borrados (`WHERE deleted_at IS NULL`).
