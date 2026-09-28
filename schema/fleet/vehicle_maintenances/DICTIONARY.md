# vehicle_maintenances

Historial de mantenimientos e incidentes mecánicos registrados sobre un vehículo de la flota.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| vehicle_maintenance_id | SERIAL | NO | auto | Identificador del registro |
| vehicle_id | INT | NO | — | Vehículo al que corresponde |
| vehicle_incident_type_id | INT | YES | — | Tipo de incidente asociado; NULL si es un mantenimiento rutinario sin incidente |
| description | TEXT | NO | — | Detalle del mantenimiento o incidente |
| status | VARCHAR(20) | NO | 'pending' | `pending`, `in_progress` o `completed` |
| scheduled_at | TIMESTAMPTZ | YES | — | Fecha programada |
| completed_at | TIMESTAMPTZ | YES | — | Fecha de finalización real |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| vehicle_id | vehicles.vehicle_id | Vehículo bajo mantenimiento |
| vehicle_incident_type_id | vehicle_incident_types.vehicle_incident_type_id | Tipo de incidente que originó el mantenimiento, si aplica |

## Business rules

- El supervisor de flota registra y da seguimiento a estos mantenimientos (RF-A17). Es un registro histórico, no se borra.
- Si `vehicle_incident_type_id` referencia un tipo con `disables_vehicle = true`, registrar la fila también actualiza de inmediato `vehicles.vehicle_status_id` a `maintenance` (RF-A34, Escenario 2) — ambas escrituras en una sola transacción.

## Estado del backend (2026-09-29)

Solo existe el alta (`POST /vehicle-maintenances`), construida como parte mínima de RF-A34 para poder
disparar el cambio de estado del Escenario 2 — no como el CRUD completo de RF-A17 (listar, editar,
programar, completar), que sigue sin construirse.
