# delivery_zones

Catálogo de zonas geográficas de reparto, con su tiempo estimado de entrega.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| delivery_zone_id | SERIAL | NO | auto | Identificador de la zona |
| code | VARCHAR(20) | NO | — | Código único que identifica la zona (ej. `ZON-SUR`) |
| name | VARCHAR(100) | NO | — | Nombre de la zona de reparto |
| estimated_time_min | INT | NO | — | Tiempo estimado de entrega para esa zona, en minutos |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A29) y agrupa pedidos por zona antes de asignarlos a un repartidor (RF-A03). No se borra en duro por el historial de despachos que la referencian.
- `code` es el identificador operativo que usan coordinador/repartidor para referirse a la zona (ej. en asignación rápida); es distinto de `name`, que es el nombre descriptivo. Ambos son únicos.

## Technical notes

- `code` y `name` son únicos solo entre zonas no borradas (`WHERE deleted_at IS NULL`) — permite reusarlos tras un soft delete.
