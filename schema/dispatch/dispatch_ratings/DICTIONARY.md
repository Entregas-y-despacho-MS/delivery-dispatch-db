# dispatch_ratings

Calificación que el Cliente Final da al servicio de entrega recibido.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_rating_id | SERIAL | NO | auto | Identificador de la calificación |
| dispatch_id | INT | NO | — | Despacho calificado; un despacho tiene a lo sumo una calificación |
| score | SMALLINT | NO | — | Puntaje de 1 a 5 |
| comment | TEXT | YES | — | Observaciones del cliente |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho calificado |

## Business rules

- El Cliente Final califica el servicio de entrega (RF-U19) y puede dejar comentarios (RF-U20), desde el portal web, sin necesitar una cuenta.
- El promedio de `score` de un repartidor (join `dispatches` → `route_batches.driver_id` vía `dispatches.route_batch_id`) es parte de su propio resumen de desempeño (RF-U09, junto con el conteo de entregas completadas en `dispatches`) — no hay una columna agregada, se calcula al consultar.
