# dispatch_statuses

Catálogo del estado de avance de un despacho, aplicable a cualquiera de sus tipos (entrega, recojo o traslado).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_status_id | SERIAL | NO | auto | Identificador del estado |
| name | VARCHAR(30) | NO | — | `pending`, `in_transit`, `delivered`, `not_delivered` o `returned` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El repartidor/transportista actualiza el estado del despacho durante su ejecución (RF-U04). El coordinador y el supervisor lo visualizan en tiempo real (RF-A06, RF-A13).
- Es un catálogo estructural, no administrable por interfaz — por eso no tiene `deleted_at`.
