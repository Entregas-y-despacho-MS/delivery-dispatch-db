# dispatch_statuses

Catálogo del estado de avance de un despacho, aplicable a cualquiera de sus tipos (entrega, recojo o traslado).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_status_id | SERIAL | NO | auto | Identificador del estado |
| name | VARCHAR(30) | NO | — | Uno de los estados listados en *Statuses*. Único (`UNIQUE`) |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Statuses

| Name | Significado |
|------|-------------|
| `pending` | Pedido listo, sin lote asignado; está en la bandeja del coordinador |
| `address_review` | Sin coordenadas válidas o fuera de cobertura; el coordinador debe fijar el punto en el mapa |
| `in_planning` | En un lote **propuesto por el generador** o en edición por un coordinador. El cliente no ve ninguna promesa. La reserva suave de edición (`dispatch_reservations`) no cambia este estado |
| `scheduled` | **Promesa aprobada y comunicada** (1.ª aprobación): fecha y franja definidas y el cliente ya fue avisado |
| `assigned` | Lote definitivo aprobado (2.ª aprobación) con repartidor y vehículo; el lote queda congelado |
| `out_for_delivery` | El repartidor inició la ruta con los bultos; todos los pedidos del lote pasan a este estado |
| `in_transit` | Se conserva: «en camino a una parada concreta»; solo un pedido está `in_transit` a la vez (lo usan el módulo de sincronización y la app móvil) |
| `delivered` | Entrega confirmada por el servidor con la evidencia exigida. Final |
| `not_delivered` | La visita no se concretó. **No es final**: el coordinador decide reprogramar (`rescheduled`) o devolver (`returned`) |
| `returned` | El pedido regresa al almacén (por ejemplo, al alcanzar el máximo de entregas no concretadas). Final |
| `incident` | El repartidor reportó un problema. **No es final**: mismas salidas que `not_delivered` (reprogramar o devolver) |
| `rescheduled` | Nueva fecha pactada por el coordinador; vuelve al plan con fecha fija, sin recalcular D2–D3. La reprogramación por autoservicio del cliente **no** pasa por este estado: el pedido sigue en `scheduled` |
| `pickup_scheduled` / `picked_up_in_transit` / `returned_to_warehouse` | Ciclo de recojos y logística inversa |
| `cancelled` | Anulado antes de salir del almacén. **Terminal**: un despacho se anula, nunca se borra |

## Business rules

- El repartidor/transportista actualiza el estado del despacho durante su ejecución (RF-U04). El coordinador y el supervisor lo visualizan en tiempo real (RF-A06, RF-A13).
- Es un catálogo estructural, no administrable por interfaz — por eso no tiene `deleted_at`.
- `in_planning` y `scheduled` cambiaron de significado con el plan de planificación semiautomática: antes eran "reservado por un coordinador" e "incluido en una ruta preliminar". Hoy `in_planning` es la propuesta del generador (sin promesa al cliente) y `scheduled` es la promesa ya aprobada y comunicada. Los despachos que ya tenían esos estados no se transforman: el backend (ST-49.4) los trata con la nueva semántica.

## Technical notes

- `cancelled` lo agregó la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3). Su `down.sql` lo elimina solo si ningún despacho lo usa.
- El estado de avance del lote (`provisional`, `pending_final_review`, `confirmed`, `in_execution`, `closed`, `cancelled`) es independiente y vive en `route_batches.status`.
- `name` es `UNIQUE`: el backend resuelve el estado por nombre, así que un estado no se renombra sin coordinarlo.
