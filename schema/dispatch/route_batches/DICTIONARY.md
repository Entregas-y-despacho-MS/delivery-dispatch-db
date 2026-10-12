# route_batches

Agrupa uno o varios despachos de **una zona y una fecha** bajo un mismo repartidor y vehículo — la unidad real de trabajo que el sistema propone y el coordinador aprueba, en vez de asignar despacho por despacho. Tiene su propio ciclo de vida (`status`), independiente del de cada pedido.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| route_batch_id | SERIAL | NO | auto | Identificador de la ruta |
| status | VARCHAR(30) | NO | — | Ciclo de vida del lote: `provisional`, `pending_final_review`, `confirmed`, `in_execution`, `closed` o `cancelled` (ver *Statuses*). Sin default: quien inserta debe indicarlo |
| version | INT | NO | 0 | Versión de planificación del lote: solo cambia al aprobar, mover, fusionar o congelar. Las transiciones del repartidor y las posiciones GPS no la incrementan |
| driver_id | INT | YES | — | Repartidor asignado a la ruta; NULL hasta que el coordinador lo asigna |
| vehicle_id | INT | YES | — | Vehículo asignado a la ruta; NULL hasta que el coordinador lo asigna |
| proposed_driver_id | INT | YES | — | Repartidor propuesto por el generador, antes de que la 2.ª aprobación lo confirme en `driver_id` |
| reviewer_user_id | INT | YES | — | Coordinador revisor del lote (quien lo aprueba en las dos etapas) |
| delivery_zone_id | INT | YES | — | Zona de reparto del lote. Nullable: los lotes manuales del Sprint 1 no la tienen |
| origin_warehouse_id | INT | YES | — | Almacén desde el que sale el lote |
| shift_date | DATE | NO | — | Fecha/turno en que se ejecuta la ruta |
| route_geometry | TEXT | YES | — | Polyline codificado del recorrido completo, calculado una vez por el motor de ruteo (OSRM) y cacheado — no se recalcula en cada vista del mapa |
| accepted_at | TIMESTAMPTZ | YES | — | Momento en que el repartidor aceptó el lote y cotejó la carga contra los bultos |
| closed_at | TIMESTAMPTZ | YES | — | Momento en que el lote pasó a `closed` (ya no queda ninguna parada abierta). NULL en los lotes del Sprint 1 cerrados por backfill: el momento real no se conoce |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Statuses

| Status | Significado |
|--------|-------------|
| `provisional` | Propuesto por el generador, asignado a un coordinador para la 1.ª aprobación (promesas). Admite pedidos nuevos sin mover las paradas ya notificadas |
| `pending_final_review` | Tras el corte de D-1, optimizado y validado; espera la 2.ª aprobación. Si falla la validación o la revisión, vuelve a `provisional` |
| `confirmed` | Aprobado: lote, pedidos, repartidor y vehículo confirmados y **congelado**. El repartidor puede aceptarlo y cotejar la carga |
| `in_execution` | El repartidor inició la ruta |
| `closed` | Ya no queda ninguna parada abierta (`assigned`, `out_for_delivery` o `in_transit`) |
| `cancelled` | Anulado. No cuenta para los índices únicos de vehículo y conductor |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| driver_id | users.user_id | Repartidor/transportista asignado a la ruta |
| vehicle_id | vehicles.vehicle_id | Vehículo asignado a la ruta |
| proposed_driver_id | users.user_id | Repartidor propuesto por el generador |
| reviewer_user_id | users.user_id | Coordinador revisor |
| delivery_zone_id | delivery_zones.delivery_zone_id | Zona de reparto del lote |
| origin_warehouse_id | warehouses.warehouse_id | Almacén de origen |

## Business rules

- El sistema propone lotes por zona, fecha y franja; el coordinador valida la capacidad del vehículo (RF-A03) y los aprueba en dos pasos (RF-A04): primero la promesa al cliente (lote `provisional`) y después el lote definitivo con repartidor y vehículo (`confirmed`). La asignación queda en `route_batches`, no en cada despacho individual.
- El orden en que el repartidor visita las paradas queda en `dispatches.sequence_order`, calculado a partir de esta ruta (motor OSRM, funcionalidad extra del grupo).
- Una ruta puede existir sin repartidor/vehículo asignado todavía (recién propuesta, antes de decidir quién la ejecuta).
- Un vehículo o un conductor no puede estar en dos lotes vigentes (no `cancelled`) la misma `shift_date`.
- Cada cambio relevante del lote deja un registro en `route_batch_events` (append-only).

## Technical notes

- `driver_id`, `vehicle_id`, `proposed_driver_id` y `reviewer_user_id` usan `ON DELETE SET NULL`: si el usuario o el vehículo se elimina, la ruta no se pierde, solo queda sin ese dato. `delivery_zone_id` y `origin_warehouse_id` no tienen `ON DELETE` (restrictivo).
- `route_geometry` se guarda como polyline codificado (no GeoJSON crudo) por ser mucho más compacto — se decodifica en el cliente al dibujar el mapa.
- `chk_route_batches_status` restringe `status` a los 6 valores de arriba.
- `uq_route_batches_vehicle_shift_date` y `uq_route_batches_driver_shift_date` (únicos parciales sobre `(vehicle_id, shift_date)` y `(driver_id, shift_date)`) excluyen los lotes `cancelled` y los valores nulos.
- Columnas agregadas por la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3): `status`, `version`, `delivery_zone_id`, `origin_warehouse_id`, `proposed_driver_id`, `reviewer_user_id`, `accepted_at` y `closed_at`.
  - **Filas del Sprint 1**: `status` = `closed` si `shift_date` es anterior a la fecha de la migración (en `America/La_Paz`) y `confirmed` en otro caso (nunca `provisional`); `version` = 0; el resto, NULL.
  - **Duplicados**: antes de crear los índices únicos, en cada grupo de lotes no cancelados con el mismo vehículo (o conductor) y la misma fecha se conserva la asignación del lote con más despachos (a igualdad, el de mayor `route_batch_id`); en los demás esa columna pasa a NULL. Incluye lotes históricos `closed`, porque el índice único los abarca. El valor original queda en `route_batch_events` (`event_type = 'migration_013_assignment_cleared'`, `actor_type = 'system'`, con `metadata` que incluye `field`, el valor anterior, `shift_date` y `kept_route_batch_id`), y `down.sql` lo restaura. Es una decisión propia de ST-49.3: el plan v3 exigía detectar y documentar el tratamiento pero no lo fijaba.
