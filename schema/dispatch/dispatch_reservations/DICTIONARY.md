# dispatch_reservations

Reserva suave de pedidos: mientras un coordinador arma una ruta con un lote, esos pedidos quedan a su nombre y los demás coordinadores los ven bloqueados («En planificación por [Nombre]»).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_id | INT | NO | — | Despacho reservado (PK: una sola reserva por despacho) |
| reserved_by | INT | NO | — | Coordinador que lo reservó |
| reserved_at | TIMESTAMPTZ | NO | NOW() | Momento en que se reservó |
| last_activity_at | TIMESTAMPTZ | NO | NOW() | Última actividad del coordinador; la renueva |
| expires_at | TIMESTAMPTZ | NO | — | Vencimiento: última actividad + `order_reservation_ttl_minutes` |

## Relationships

| Column | Reference | Description |
|--------|-----------|-------------|
| dispatch_id | dispatches.dispatch_id | Despacho reservado (`ON DELETE CASCADE`) |
| reserved_by | users.user_id | Coordinador dueño de la reserva (`ON DELETE CASCADE`) |

## Business rules

- Una reserva está vigente mientras `expires_at` sea futuro; el estado del despacho no cambia, la bandeja lo muestra como `in_planning` mientras la reserva exista.
- Se renueva con la actividad del coordinador y se libera al confirmar o cancelar la planificación, o sola al vencer (`order_reservation_ttl_minutes`, 15 por defecto, en `settings`).

## Technical notes

- No hay tarea programada de limpieza: las filas vencidas se ignoran al leer y la siguiente reserva del mismo despacho las reemplaza.
