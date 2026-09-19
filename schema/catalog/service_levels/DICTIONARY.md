# service_levels

Catálogo de niveles de servicio de entrega ofrecidos (ej. estándar, express), con su tiempo objetivo.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| service_level_id | SERIAL | NO | auto | Identificador del nivel de servicio |
| name | VARCHAR(50) | NO | — | Nombre del nivel de servicio |
| target_time_min | INT | NO | — | Tiempo objetivo de entrega para ese nivel, en minutos |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A31). No se borra en duro por el historial de despachos que lo referencian.

## Technical notes

- Único solo entre niveles no borrados (`WHERE deleted_at IS NULL`).
