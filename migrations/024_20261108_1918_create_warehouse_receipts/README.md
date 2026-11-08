# create_warehouse_receipts

ST-240.1 (ES-240, ERP-08) — modela lo que necesita el consumidor de `inventory.receipt.confirmed`
(ST-240.2) para cerrar el traslado de una devolución (RMA) o de una recogida en proveedor cuando
Almacén confirma la recepción física, con el detalle por ítem (faltantes, dañados) y la
idempotencia por `receiptId`/`recordVersion`.

## Por qué hacía falta

`dispatch_pickup_items.received_quantity` (migración 015) y `dispatches.received_boxes`/
`custody_received_at` (migración 022) ya cubren la custodia del transportista en ruta, pero no
hay dónde registrar lo que Almacén confirma al recibir físicamente la carga — un hecho distinto,
posterior y potencialmente parcial o rechazado (Escenario 3 de ES-240). Tampoco existía forma de
dejar registrada una confirmación cuya referencia no resuelve a ningún traslado (Escenario 4) sin
inventar un estado de despacho para eso.

`warehouse_receipts.receipt_id` se usa como PK natural (igual que `rma_sync_states.rma_id` en la
migración 021) en vez de un `SERIAL`: es el identificador externo del mensaje y es, además, la
clave de idempotencia junto con `record_version` — un `SERIAL` propio no aportaría nada y
duplicaría la clave real.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `warehouse_receipts` | Tabla nueva, `receipt_id` como PK natural, `dispatch_id` nullable (recepción huérfana), `reference_type`/`reference_id` para resolver el traslado de origen, `result`, `status`. |
| `warehouse_receipt_items` | Tabla nueva, detalle por ítem (`accepted_quantity`, `missing_quantity`, `damaged_quantity`), identificado por `package_id` o `item_code` de forma excluyente. |
| `idx_warehouse_receipts_reference` | Índice compuesto (`reference_type`, `reference_id`). |
| `idx_warehouse_receipts_dispatch_id`, `idx_warehouse_receipt_items_receipt_id`, `idx_warehouse_receipt_items_package_id` | Índices de soporte. |

## `down.sql`

Elimina ambas tablas (ítems primero), sus triggers y sus funciones. No hay backfill: ningún
consumidor escribió estas tablas todavía.
