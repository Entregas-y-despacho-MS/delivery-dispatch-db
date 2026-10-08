# dispatch_statuses

Catálogo del estado de avance de un despacho, aplicable a cualquiera de sus tipos (entrega, recojo o traslado).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_status_id | SERIAL | NO | auto | Identificador del estado |
| name | VARCHAR(30) | NO | — | Uno de los estados listados en *Statuses* |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Statuses

| Name | Significado |
|------|-------------|
| `pending` | Orden creada, en la bandeja del coordinador |
| `address_review` | Sin coordenadas válidas o fuera de cobertura; el coordinador debe fijar el punto en el mapa |
| `in_planning` | Reservado por un coordinador que arma una ruta (reserva temporal) |
| `scheduled` | Incluido en una ruta preliminar |
| `assigned` | Ruta asignada a repartidor y vehículo |
| `out_for_delivery` | La ruta salió del almacén |
| `in_transit` | Se conserva: «en camino a una parada concreta» (lo usan el módulo de sincronización y la app móvil) |
| `delivered` / `not_delivered` / `returned` | Resultados finales de la entrega |
| `incident` | Incidencia operativa reportada |
| `rescheduled` | Nueva fecha pactada; vuelve a la bandeja ese día |
| `pickup_scheduled` / `picked_up_in_transit` / `returned_to_warehouse` | Ciclo de recojos y logística inversa |

## Business rules

- El repartidor/transportista actualiza el estado del despacho durante su ejecución (RF-U04). El coordinador y el supervisor lo visualizan en tiempo real (RF-A06, RF-A13).
- Es un catálogo estructural, no administrable por interfaz — por eso no tiene `deleted_at`.
