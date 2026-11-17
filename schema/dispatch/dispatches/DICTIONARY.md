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
| delivery_reference | TEXT | YES | — | Referencias adicionales de la dirección enviadas por Marketplace |
| delivery_latitude | NUMERIC(9,6) | YES | — | Latitud del destino. Llega ya resuelta del sistema origen (el usuario final marca la ubicación en un mapa al momento de su pedido) junto con `delivery_address` — Despachos no geocodifica nada, solo la recibe y la usa para el motor de ruteo (OSRM) |
| delivery_longitude | NUMERIC(9,6) | YES | — | Longitud del destino (mismo motivo que arriba) |
| contact_name | VARCHAR(150) | YES | — | Persona de contacto en el destino (cliente final, o encargado en planta del proveedor) |
| contact_phone | VARCHAR(30) | YES | — | Teléfono de contacto |
| contact_email | VARCHAR(150) | YES | — | Correo de contacto, usado para las notificaciones automáticas por cambio de estado (RF-U16) |
| payment_status_label | VARCHAR(50) | YES | — | Etiqueta informativa de pago recibida del sistema origen (ej. "Prepaid"), parte del detalle de pedido que ve el repartidor (RF-U03); de solo lectura, Despachos no gestiona pagos |
| package_contents | TEXT | YES | — | Resumen de los productos del paquete, parte del detalle de pedido que ve el repartidor (RF-U03: "dirección, productos, etiqueta de estado de pago"); de solo lectura, Despachos no gestiona inventario ni catálogo de productos |
| estimated_weight_kg | NUMERIC(10,2) | YES | — | Peso estimado de la carga, informado por el origen en el preaviso de preparación, antes de que el paquete esté físicamente listo |
| estimated_boxes | INT | YES | — | Cantidad estimada de cajas para la recogida al proveedor |
| estimated_volume_m3 | NUMERIC(10,3) | YES | — | Volumen estimado de la carga en metros cúbicos |
| transport_conditions | TEXT | YES | — | Condiciones especiales de transporte recibidas de Compras |
| return_reason | TEXT | YES | — | Motivo de la devolución o garantía (solo aplica si el tipo de despacho es un recojo de devolución o una devolución a proveedor) |
| preferred_pickup_date | TIMESTAMPTZ | YES | — | Fecha de recojo preferida, informada por Almacén al aprobar una devolución (RMA); distinta de `scheduled_window_start/end`, que define el planificador al armar la ruta |
| scheduled_window_start | TIMESTAMPTZ | YES | — | Inicio de la ventana horaria prometida; el cliente puede pedir su cambio dentro de la ventana permitida (RF-U21) |
| scheduled_window_end | TIMESTAMPTZ | YES | — | Fin de la ventana horaria prometida (mismo RF-U21 que arriba) |
| package_ready_at | TIMESTAMPTZ | YES | — | Momento en que el origen confirmó que el paquete/carga está físicamente listo para ser recogido — llega como un segundo aviso, después de que el despacho ya fue creado con el preaviso |
| shipment_ready | BOOLEAN | NO | TRUE | Indica si los bultos definidos por Almacén siguen listos para planificar; no equivale a estar físicamente empacados |
| tracking_token | VARCHAR(100) | YES | — | Token del enlace de seguimiento que usa el Cliente Final para ver su pedido sin necesitar una cuenta (RF-U14) |
| tracking_token_expires_at | TIMESTAMPTZ | YES | — | Vencimiento del token de seguimiento |
| last_latitude | NUMERIC(9,6) | YES | — | Última latitud conocida del despacho en curso, transmitida periódicamente por la app móvil del repartidor (RF-U11) y consultada por el Cliente Final (RF-U15) |
| last_longitude | NUMERIC(9,6) | YES | — | Última longitud conocida (mismo RF-U11/RF-U15 que arriba) |
| last_location_at | TIMESTAMPTZ | YES | — | Momento de la última actualización de ubicación |
| tracking_code | VARCHAR(20) | YES | — | Código de traslado `DSP-AAAA-NNNNN` (año y secuencia de 5 dígitos con reinicio anual). Único e inmutable; se genera con `next_tracking_code()` |
| evidence_policy | VARCHAR(30) | NO | 'hand_delivery_standard' | Política de evidencia exigida: `hand_delivery_standard`, `contactless_delivery` o `high_value_control` |
| confirmed_at | TIMESTAMPTZ | YES | — | Momento en que se confirmó la entrega, el recojo o la recepción en destino |
| version | INT | NO | 0 | Versión de planificación del pedido: solo cambia al aprobar, mover, fusionar o congelar. Las transiciones del repartidor y las posiciones GPS no la incrementan; no es un contador de cambios |
| customer_confirmation | VARCHAR(20) | NO | 'pending' | Respuesta del cliente a la promesa: `pending`, `confirmed`, `rescheduled` o `change_requested` |
| order_confirmed_at | TIMESTAMPTZ | YES | — | Confirmación comercial del pedido (D0), desde la que corre el plazo de entrega |
| promise_notified_at | TIMESTAMPTZ | YES | — | Primer aviso válido de la promesa al cliente. **No se renueva** al reprogramar |
| promise_firmed_at | TIMESTAMPTZ | YES | — | Momento en que la promesa quedó firme (confirmación del cliente, reprogramación o vencimiento de la ventana con aviso válido). Dispara `dispatch.shipment.prepare_requested` |
| origin_warehouse_id | INT | YES | — | Almacén de origen de la carga |
| destination_warehouse_id | INT | YES | — | Almacén de destino de los productos recogidos al proveedor |
| received_boxes | INT | YES | — | Total de cajas declaradas por el transportista al confirmar una recogida (proveedor o RMA); distinto de `estimated_boxes`, que informa Compras antes del traslado |
| custody_received_at | TIMESTAMPTZ | YES | — | Momento en que el transportista confirma la recogida y toma custodia física de la mercadería |
| arrived_at_warehouse_at | TIMESTAMPTZ | YES | — | Momento en que el transportista marca "Llegué al almacén"; no cambia el estado del despacho por sí solo |
| closed_at | TIMESTAMPTZ | YES | — | Momento en que el despacho llegó a un estado terminal (`delivered`, `not_delivered`, `returned`, `returned_to_warehouse`, `cancelled`). Es la hora del evento, no la de recepción; `NULL` mientras el despacho no esté en un estado terminal. Es la fecha que filtra y ordena el historial de despachos (RF-A08) |
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
| origin_warehouse_id | warehouses.warehouse_id | Almacén de origen de la carga |
| destination_warehouse_id | warehouses.warehouse_id | Almacén donde se recibirán los productos de una recogida al proveedor |

## Business rules

- Un despacho de tipo `delivery` se crea automáticamente a partir de un pedido confirmado y listo para despacho, recibido desde Inventarios y Almacén (RF-A02).
- El aviso de que un paquete está "físicamente listo" (`package_ready_at`) puede llegar después de que el despacho ya exista: el coordinador puede planificar la ruta del día con el preaviso, antes de que el paquete esté realmente listo para retirar.
- El coordinador agrupa despachos por zona y valida la capacidad del vehículo antes de asignar (RF-A03) armando una `route_batches`, le asigna repartidor y vehículo a esa ruta (RF-A04) — no despacho por despacho — reprograma entregas fallidas dejando registro en `dispatch_reschedules` (RF-A05), y puede marcar/filtrar por prioridad (RF-A11).
- Despachos no gestiona pagos: `payment_status_label` es solo informativo, recibido tal cual del sistema origen.
- **Promesa al cliente.** El sistema propone el lote (`in_planning`); con la 1.ª aprobación el pedido pasa a `scheduled` y se avisa al cliente (`promise_notified_at`). La promesa queda firme (`promise_firmed_at`) cuando el cliente confirma, reprograma o vence la ventana de respuesta con un aviso válido. `customer_confirmation` no reemplaza a `promise_firmed_at`: puede pasar a `change_requested` sin que la promesa haya quedado firme.
- La reprogramación por autoservicio del cliente cambia el lote del pedido y lo deja en `scheduled`; no pasa por el estado `rescheduled` (que es del coordinador o de una entrega fallida).
- **Despachos no geocodifica direcciones.** `delivery_latitude`/`delivery_longitude` llegan resueltas en el mismo mensaje que `delivery_address`, igual que `payment_status_label` — el usuario que genera el pedido marca la ubicación en un mapa aguas arriba (antes de que Despachos se entere del pedido), y esa coordenada viaja junto con el resto de los datos del preaviso. No hace falta ningún servicio externo de geocodificación en este microservicio.
- El coordinador consulta el detalle completo de un despacho específico en una vista unificada (RF-A09) — es simplemente `SELECT * FROM dispatches WHERE dispatch_id = ...` con sus relaciones, no requiere una vista o tabla aparte.
- **El tiempo estimado de llegada (ETA, RF-U17) no se guarda como columna** — se calcula dinámicamente (última ubicación conocida + `delivery_zones.estimated_time_min` o `service_levels.target_time_min`, según cuál aplique). Decisión confirmada con el usuario: no cachearlo en `dispatches`.

- **Fecha de cierre (`closed_at`).** Se escribe al pasar a un estado terminal con la hora real del evento: la app móvil sincroniza con retraso, así que el backend guarda el `occurredAt` del dispositivo y no la hora de recepción. `confirmed_at` no la reemplaza (ningún proceso la escribe). Un despacho que sale de los estados terminales (por ejemplo, un `not_delivered` que se reprograma) vuelve a `closed_at = NULL` y deja de aparecer en el historial.

## Technical notes

- `tracking_token` es único; se usa en vez del `dispatch_id` para no exponer un identificador secuencial interno al Cliente Final.
- `route_batch_id` usa `ON DELETE SET NULL`: si la ruta se elimina, el despacho no se pierde, solo queda sin ruta asignada. Un lote con eventos en `route_batch_events` (FK `RESTRICT`) no se puede borrar.
- Restricciones nombradas: `chk_dispatches_priority` (`urgent` o `normal`), `chk_dispatches_evidence_policy` y `uq_dispatches_tracking_code` (único sobre `tracking_code`).
- `chk_dispatches_customer_confirmation` restringe `customer_confirmation` a sus 4 valores. `origin_warehouse_id` no tiene `ON DELETE` (restrictivo) y tiene su índice `idx_dispatches_origin_warehouse_id`.
- Columnas `version`, `customer_confirmation`, `order_confirmed_at`, `promise_notified_at`, `promise_firmed_at` y `origin_warehouse_id` agregadas por la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3). Las filas previas quedaron con `version = 0`, `customer_confirmation = 'pending'` y el resto en NULL.
- `dispatch_events` referencia al despacho con `ON DELETE RESTRICT`: un despacho con historial no se borra; se anula (`cancelled`).
- `uq_dispatches_route_batch_sequence` (único parcial sobre `route_batch_id, sequence_order`) impide que dos despachos de la misma ruta queden con el mismo orden de visita.
- `tracking_code`: `next_tracking_code()` incrementa `tracking_code_counters` (una fila por año) con un UPSERT que bloquea la fila, por lo que es seguro ante concurrencia y reinicia cada año. El trigger `trg_dispatches_tracking_code_immutable` (función `prevent_tracking_code_change()`) impide cambiarlo una vez asignado. Es nullable para no romper filas previas.
- `idx_dispatches_delivery_point`: índice GiST parcial sobre `point(longitud, latitud)` para consultas espaciales; usa tipos nativos porque la imagen `postgres:18-alpine` no trae PostGIS.
- `uq_dispatches_delivery_source_order_ref` impide dos entregas con la misma referencia de pedido, incluso si se cancela una; no afecta los otros tipos de despacho.
- `delivery_reference` y `shipment_ready` fueron añadidos en la migración 014. La primera completa el mapeo acordado en ST-49.3 que faltó en la 013.
- Los bultos del despacho (peso y medidas reales) viven en `dispatch_packages`.
- Los productos esperados y recibidos en una recogida al proveedor viven en `dispatch_pickup_items`; el despacho conserva solo las estimaciones generales de carga.
- `estimated_boxes`, `estimated_volume_m3`, `transport_conditions` y `destination_warehouse_id` fueron añadidos por la migración 015 para modelar recogidas al proveedor sin modificar la orden de compra de origen.
- `closed_at` fue añadida por la migración `020_..._add_dispatches_closed_at` (ST-55.2). `trg_dispatches_set_closed_at` (función `fn_dispatches_set_closed_at()`, `BEFORE UPDATE OF dispatch_status_id`) es un respaldo: al pasar a un estado terminal sin que el escritor informe `closed_at` lo llena con `NOW()`, y al salir de los terminales lo pone en `NULL`. `idx_dispatches_closed_at` es un índice parcial (`closed_at DESC WHERE closed_at IS NOT NULL`) para el historial.
- `preferred_pickup_date` fue añadida por la migración `021_..._model_rma_pickup_order` (ST-238.1). `uq_dispatches_warehouse_return_pickup_source_order_ref` (mismo patrón que `uq_dispatches_delivery_source_order_ref`) impide dos recojos de devolución con el mismo `rmaId` en `source_order_ref`. El estado de sincronización por `rmaId` (versión recibida) vive aparte, en `rma_sync_states`.
- `received_boxes`, `custody_received_at` y `arrived_at_warehouse_at` fueron añadidas por la migración `022_..._add_supplier_pickup_custody` (ST-239.1). Las dos columnas de fecha son compartidas entre `supplier_pickup` y `warehouse_return_pickup` (RMA, `ST-80.2`): mismo hecho de negocio ("tomé custodia" / "llegué al almacén"), no hace falta una columna por tipo de despacho.
