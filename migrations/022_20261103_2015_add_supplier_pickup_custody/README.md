# add_supplier_pickup_custody

ST-239.1 (ES-239, ERP-06) — modela la custodia de una recogida en proveedor: cuántas cajas
recibió el transportista, cuándo tomó custodia de la mercadería y cuándo llegó al almacén
destino. `received_boxes` es el total declarado por el transportista al confirmar la recogida
(distinto de `estimated_boxes`, que informa Compras antes del traslado).

## Por qué hacía falta

`dispatch_pickup_items.received_quantity` (migración 015) ya guarda la cantidad recibida por
ítem, pero no hay dónde registrar el total de cajas ni los dos momentos de la custodia física.
Ambas columnas de fecha son compartidas con el recojo de devolución RMA (`ST-80.2`, mismo
escenario de "llegué al almacén" para `warehouse_return_pickup`): no tiene sentido una columna
por tipo de despacho para el mismo hecho.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `dispatches.received_boxes` | Columna nueva `INT`, nullable, `>= 0`. |
| `dispatches.custody_received_at` | Columna nueva `TIMESTAMPTZ`, nullable — momento en que el transportista confirma la recogida (conforme o con diferencia). |
| `dispatches.arrived_at_warehouse_at` | Columna nueva `TIMESTAMPTZ`, nullable — momento en que el transportista marca «Llegué al almacén»; no cambia el estado por sí sola. |

## `down.sql`

Elimina las 3 columnas y su restricción. No hay backfill: ningún consumidor escribió estas
columnas todavía.
