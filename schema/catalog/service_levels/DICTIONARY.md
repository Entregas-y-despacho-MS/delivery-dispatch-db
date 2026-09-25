# service_levels

Catálogo de niveles de servicio de entrega ofrecidos (ej. estándar, express), con su tiempo objetivo.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| service_level_id | SERIAL | NO | auto | Identificador del nivel de servicio |
| name | VARCHAR(50) | NO | — | Nombre del nivel de servicio |
| description | VARCHAR(255) | YES | — | Descripción del nivel de servicio (opcional) |
| target_time_min | INT | NO | — | Tiempo objetivo de entrega (SLA) para ese nivel, en minutos. La API exige al menos 15 (RF-A31) |
| priority_level | SMALLINT | NO | — | Jerarquía de prioridad entre niveles: 1 es la más alta. Permite priorizar automáticamente los despachos urgentes. Dos niveles pueden compartir prioridad (desempata el tiempo objetivo) |
| active | BOOLEAN | NO | TRUE | Habilitado para asignarse a órdenes nuevas. Desactivarlo no afecta a los despachos que ya lo tienen asignado |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A31). No se borra en duro por el historial de despachos que lo referencian.
- **No se puede borrar un nivel con despachos activos** (`pending` o `in_transit`): la API lo rechaza y la salida es desactivarlo (`active = false`), lo que solo impide asignarlo a órdenes futuras. Un nivel sin despachos activos sí puede darse de baja (soft delete).
- La lista se muestra ordenada por `priority_level` (1 primero) y, a igualdad, por tiempo objetivo.

## Technical notes

- Único solo entre niveles no borrados (`WHERE deleted_at IS NULL`).
- `priority_level >= 1` (constraint `chk_service_levels_priority_level`).
- `description`, `priority_level` y `active` se agregaron con la migración `003_..._add_description_priority_and_active_to_service_levels` (RF-A31); los niveles previos quedaron habilitados y con prioridad según su tiempo objetivo (el más corto = 1).
