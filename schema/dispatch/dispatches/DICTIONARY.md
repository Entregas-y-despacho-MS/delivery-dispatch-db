# dispatches

La entidad central del microservicio. Representa cualquier operación de transporte que coordina Despachos: una entrega a un cliente, un recojo de devolución en domicilio, un traslado de mercadería desde un proveedor, o una devolución de mercadería al proveedor — el `dispatch_type_id` distingue cuál.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_id | SERIAL | NO | auto | Identificador del despacho |
| dispatch_type_id | INT | NO | — | Tipo de operación (entrega, recojo de devolución, traslado o devolución a proveedor) |
| dispatch_status_id | INT | NO | — | Estado actual |
| delivery_zone_id | INT | YES | — | Zona de reparto; solo aplica a entregas y recojos de devolución al cliente |
| service_level_id | INT | YES | — | Nivel de servicio contratado |
| route_batch_id | INT | YES | — | Ruta a la que pertenece este despacho; NULL hasta que el coordinador lo asigna a una ruta. El repartidor y el vehículo se consultan a través de esta ruta, no directo en el despacho — es lo que resuelve "datos del repartidor asignado" (RF-U18), la lista de pedidos del día de un repartidor (RF-U02) y su resumen de desempeño (RF-U09) |
| sequence_order | SMALLINT | YES | — | Orden de visita dentro de su `route_batch`. No es un requerimiento base del documento — es una funcionalidad extra del grupo, calculada por el motor de ruteo (OSRM) |
| source_order_ref | VARCHAR(100) | NO | — | Referencia del pedido u orden en el sistema que originó el despacho (Inventarios y Almacén o Compras y Proveedores) |
| priority | VARCHAR(10) | NO | 'normal' | `urgent` o `normal` |
| delivery_address | TEXT | NO | — | Dirección de destino: domicilio del cliente, o planta del proveedor según el tipo de despacho |
| delivery_latitude | NUMERIC(9,6) | YES | — | Latitud del destino. Llega ya resuelta del sistema origen (el usuario final marca la ubicación en un mapa al momento de su pedido) junto con `delivery_address` — Despachos no geocodifica nada, solo la recibe y la usa para el motor de ruteo (OSRM) |
| delivery_longitude | NUMERIC(9,6) | YES | — | Longitud del destino (mismo motivo que arriba) |
| contact_name | VARCHAR(150) | YES | — | Persona de contacto en el destino (cliente final, o encargado en planta del proveedor) |
| contact_phone | VARCHAR(30) | YES | — | Teléfono de contacto |
| contact_email | VARCHAR(150) | YES | — | Correo de contacto, usado para las notificaciones automáticas por cambio de estado (RF-U16) |
| payment_status_label | VARCHAR(50) | YES | — | Etiqueta informativa de pago recibida del sistema origen (ej. "Prepaid"), parte del detalle de pedido que ve el repartidor (RF-U03); de solo lectura, Despachos no gestiona pagos |
| package_contents | TEXT | YES | — | Resumen de los productos del paquete, parte del detalle de pedido que ve el repartidor (RF-U03: "dirección, productos, etiqueta de estado de pago"); de solo lectura, Despachos no gestiona inventario ni catálogo de productos |
| estimated_weight_kg | NUMERIC(10,2) | YES | — | Peso estimado de la carga, informado por el origen en el preaviso de preparación, antes de que el paquete esté físicamente listo |
| return_reason | TEXT | YES | — | Motivo de la devolución o garantía (solo aplica si el tipo de despacho es un recojo de devolución o una devolución a proveedor) |
| scheduled_window_start | TIMESTAMPTZ | YES | — | Inicio de la ventana horaria prometida; el cliente puede pedir su cambio dentro de la ventana permitida (RF-U21) |
| scheduled_window_end | TIMESTAMPTZ | YES | — | Fin de la ventana horaria prometida (mismo RF-U21 que arriba) |
| package_ready_at | TIMESTAMPTZ | YES | — | Momento en que el origen confirmó que el paquete/carga está físicamente listo para ser recogido — llega como un segundo aviso, después de que el despacho ya fue creado con el preaviso |
| tracking_token | VARCHAR(100) | YES | — | Token del enlace de seguimiento que usa el Cliente Final para ver su pedido sin necesitar una cuenta (RF-U14) |
| tracking_token_expires_at | TIMESTAMPTZ | YES | — | Vencimiento del token de seguimiento |
| last_latitude | NUMERIC(9,6) | YES | — | Última latitud conocida del despacho en curso, transmitida periódicamente por la app móvil del repartidor (RF-U11) y consultada por el Cliente Final (RF-U15) |
| last_longitude | NUMERIC(9,6) | YES | — | Última longitud conocida (mismo RF-U11/RF-U15 que arriba) |
| last_location_at | TIMESTAMPTZ | YES | — | Momento de la última actualización de ubicación |
| confirmed_at | TIMESTAMPTZ | YES | — | Momento en que se confirmó la entrega, el recojo o la recepción en destino |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_type_id | dispatch_types.dispatch_type_id | Qué tipo de operación es este despacho |
| dispatch_status_id | dispatch_statuses.dispatch_status_id | En qué etapa está |
| delivery_zone_id | delivery_zones.delivery_zone_id | Zona de reparto asignada |
| service_level_id | service_levels.service_level_id | Nivel de servicio contratado |
| route_batch_id | route_batches.route_batch_id | Ruta (repartidor + vehículo + turno) a la que pertenece este despacho |

## Business rules

- Un despacho de tipo `delivery` se crea automáticamente a partir de un pedido confirmado y listo para despacho, recibido desde Inventarios y Almacén (RF-A02).
- El aviso de que un paquete está "físicamente listo" (`package_ready_at`) puede llegar después de que el despacho ya exista: el coordinador puede planificar la ruta del día con el preaviso, antes de que el paquete esté realmente listo para retirar.
- El coordinador agrupa despachos por zona y valida la capacidad del vehículo antes de asignar (RF-A03) armando una `route_batches`, le asigna repartidor y vehículo a esa ruta (RF-A04) — no despacho por despacho — reprograma entregas fallidas dejando registro en `dispatch_reschedules` (RF-A05), y puede marcar/filtrar por prioridad (RF-A11).
- Despachos no gestiona pagos: `payment_status_label` es solo informativo, recibido tal cual del sistema origen.
- **Despachos no geocodifica direcciones.** `delivery_latitude`/`delivery_longitude` llegan resueltas en el mismo mensaje que `delivery_address`, igual que `payment_status_label` — el usuario que genera el pedido marca la ubicación en un mapa aguas arriba (antes de que Despachos se entere del pedido), y esa coordenada viaja junto con el resto de los datos del preaviso. No hace falta ningún servicio externo de geocodificación en este microservicio.
- El coordinador consulta el detalle completo de un despacho específico en una vista unificada (RF-A09) — es simplemente `SELECT * FROM dispatches WHERE dispatch_id = ...` con sus relaciones, no requiere una vista o tabla aparte.
- **El tiempo estimado de llegada (ETA, RF-U17) no se guarda como columna** — se calcula dinámicamente (última ubicación conocida + `delivery_zones.estimated_time_min` o `service_levels.target_time_min`, según cuál aplique). Decisión confirmada con el usuario: no cachearlo en `dispatches`.

## Technical notes

- `tracking_token` es único; se usa en vez del `dispatch_id` para no exponer un identificador secuencial interno al Cliente Final.
- `route_batch_id` usa `ON DELETE SET NULL`: si la ruta se elimina, el despacho no se pierde, solo queda sin ruta asignada.
- `uq_dispatches_route_batch_sequence` (único parcial sobre `route_batch_id, sequence_order`) impide que dos despachos de la misma ruta queden con el mismo orden de visita.
