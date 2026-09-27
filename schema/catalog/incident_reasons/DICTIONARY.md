# incident_reasons

Catálogo de motivos de incidencia durante una entrega (ej. cliente ausente, dirección incorrecta).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| incident_reason_id | SERIAL | NO | auto | Identificador del motivo |
| code | VARCHAR(30) | NO | — | Código único de referencia (ej. `INC-CLI-AUS`), en mayúsculas |
| name | VARCHAR(150) | NO | — | Descripción del motivo de incidencia |
| requires_evidence | BOOLEAN | NO | FALSE | Si registrar una incidencia con este motivo exige foto de evidencia |
| active | BOOLEAN | NO | TRUE | Asignable a incidencias nuevas. Desactivarlo no afecta a las incidencias ya registradas con este motivo |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador de logística y el supervisor de operaciones administran este catálogo (RF-A32). El repartidor lo usa (vía la app móvil, descargado para uso offline) para registrar una incidencia durante la entrega (RF-U06).
- No hay borrado: la salida para retirar un motivo de uso es desactivarlo (`active = false`), que solo impide asignarlo a incidencias nuevas — las ya registradas con ese motivo no se ven afectadas. No se borra en duro por el historial de incidencias que lo referencian.

## Technical notes

- Único solo entre motivos no borrados, tanto por `name` como por `code` (`WHERE deleted_at IS NULL`).
- `code`, `requires_evidence` y `active` se agregaron con la migración `004_..._add_code_and_requires_evidence_to_incident_reasons` (RF-A32); los 3 motivos sembrados originalmente recibieron un código y una evidencia inventados en esa migración.
