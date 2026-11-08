# warehouse_receipts

Confirmación de recepción física que Almacén publica (`inventory.receipt.confirmed`) al recibir una devolución (RMA) o una recogida en proveedor. Cierra el traslado correspondiente y es la fuente de verdad de qué se aceptó, qué faltó y qué llegó dañado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| receipt_id | VARCHAR(100) | NO | — | `receiptId` asignado por Almacén al mensaje; identifica la recepción de forma única |
| dispatch_id | INT | YES | — | Traslado (RMA o recogida en proveedor) que esta recepción cierra; NULL si la referencia no pudo resolverse (recepción huérfana) |
| reference_type | VARCHAR(20) | NO | — | Tipo de origen que generó el traslado: `rma` (devolución) o `purchase_order` (recogida a proveedor) |
| reference_id | VARCHAR(100) | NO | — | `rmaId` o id de la orden de compra que Almacén usó para identificar lo recibido |
| result | VARCHAR(20) | NO | — | Resultado informado por Almacén: `complete`, `with_differences` o `rejected` |
| received_at | TIMESTAMPTZ | NO | — | Momento en que Almacén recibió físicamente la mercadería |
| record_version | BIGINT | NO | 0 | Versión del mensaje; permite ignorar reintentos o mensajes desordenados para el mismo `receipt_id` |
| notes | TEXT | YES | — | Observaciones libres de Almacén sobre la recepción |
| status | VARCHAR(20) | NO | — | `applied` si se pudo asociar y cerrar un traslado, `orphan` si la referencia no correspondía a ninguno |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Traslado que esta recepción cierra; se desvincula (`ON DELETE SET NULL`) si el despacho se elimina, sin perder el historial de la recepción |

## Business rules

- Una recepción `orphan` no cambia el estado de ningún despacho — queda registrada para que el coordinador la revise, pero no se reintenta sola.
- `result: with_differences` o `rejected` implica que se deben registrar las cantidades por ítem en `warehouse_receipt_items` (faltantes, dañadas).
- Dos mensajes con el mismo `receipt_id` se resuelven por `record_version`: uno con versión menor o igual a la ya guardada se ignora, nunca duplica ni reprocesa la recepción.

## Technical notes

- Índice compuesto `idx_warehouse_receipts_reference` sobre (`reference_type`, `reference_id`) para resolver el traslado de origen al llegar el mensaje.
- `chk_warehouse_receipts_status_dispatch` obliga la correlación entre `status` y `dispatch_id`: `orphan` exige `dispatch_id IS NULL`, `applied` exige `dispatch_id IS NOT NULL` — mismo patrón que `chk_inbound_messages_error_detail` en `schema/messaging/inbound_messages`.
- `updated_at` se mantiene con el trigger `trg_warehouse_receipts_set_updated_at`.
