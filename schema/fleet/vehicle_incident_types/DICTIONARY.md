# vehicle_incident_types

Catálogo de los tipos de problema mecánico o de mantenimiento que puede tener un vehículo de la flota.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| vehicle_incident_type_id | SERIAL | NO | auto | Identificador del tipo de incidente |
| code | VARCHAR(30) | NO | — | Código de referencia único (ej. `MEC-FRE-01`) |
| name | VARCHAR(100) | NO | — | Descripción del tipo de incidente (ej. "Falla mecánica") |
| severity | VARCHAR(20) | NO | — | Clasificación de gravedad: `minor`, `moderate` o `critical` |
| disables_vehicle | BOOLEAN | NO | FALSE | Si registrar un incidente de este tipo sobre un vehículo lo pasa de inmediato a `maintenance` |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El supervisor de flota administra este catálogo (RF-A34). No se borra en duro porque hay mantenimientos históricos que lo referencian.
- `disables_vehicle` es el flag que decide si registrar el incidente en `vehicle_maintenances` dispara el cambio de estado del vehículo a `maintenance` — es independiente de `severity` (una clasificación informativa/de reporte), aunque en la práctica los incidentes `critical` normalmente también tengan `disables_vehicle = true`.

## Technical notes

- Único solo entre filas no borradas (`WHERE deleted_at IS NULL`), tanto por `name` como por `code` (índices separados).
- `severity` restringido por `chk_vehicle_incident_types_severity` a exactamente `minor`, `moderate` o `critical`.
- `code`, `severity` y `disables_vehicle` se agregaron con la migración `007_..._add_code_severity_disables_vehicle_to_vehicle_incident_types` (RF-A34). Backfill de las 4 filas sembradas (`data.sql`) incluido en la migración.
