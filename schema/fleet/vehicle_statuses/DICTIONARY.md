# vehicle_statuses

Catálogo del estado operativo en que puede estar un vehículo de la flota.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| vehicle_status_id | SERIAL | NO | auto | Identificador del estado |
| name | VARCHAR(30) | NO | — | `active`, `maintenance` o `out_of_service` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El supervisor de flota gestiona la disponibilidad de un vehículo cambiándolo entre estos estados (RF-A15).
- Es distinto de `vehicles.deleted_at`: este estado es operativo y temporal (ej. un vehículo en mantenimiento vuelve a `active`), mientras que `deleted_at` es una baja permanente de la flota.

## Technical notes

- Catálogo estructural, no administrable por interfaz — no tiene `deleted_at`.
