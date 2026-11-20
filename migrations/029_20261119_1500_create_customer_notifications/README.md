# create_customer_notifications

ST-39.2 (ES-39, RF-U16) — registra cada aviso por correo al cliente con su estado de envío, para que
el backend lo envíe una sola vez por evento y pueda recuperarlo si el proveedor falla.

## Por qué hacía falta

ST-39.1 reservaba el aviso en `dispatch_events`, que es append-only (un trigger bloquea el `UPDATE`):
no puede llevar un contador de intentos ni un estado que cambia, y la unicidad dependía de un lock
advisory y de un `NOT EXISTS`, no de un índice. Una tabla propia permite una clave idempotente única
y un barrido de recuperación por estado.

## Qué cambia

| Objeto | Cambio |
|---|---|
| `customer_notifications` | Tabla nueva. |
| `uq_customer_notifications_idempotency_key` | Índice único sobre `idempotency_key` (tipo de notificación + evento origen): dos entregas del mismo evento dejan una sola fila. |
| `idx_customer_notifications_pending` | Índice parcial sobre `next_attempt_at` (`status IN ('sending','retrying')`) para el barrido de recuperación. |
| `chk_customer_notifications_sent_at` | `sent_at` presente si y solo si `status = 'sent'`. |
| `trg_customer_notifications_set_updated_at` | Mantiene `updated_at`. |

## Filas existentes

Ninguna: la tabla es nueva. Los eventos `customer_status_notice_*` que ST-39.1 dejó en
`dispatch_events` quedan como historial y no se migran.

## `down.sql`

Elimina el trigger, la función y la tabla. No hay backfill que revertir, pero **el rollback pierde los
avisos registrados** (estado, intentos y errores): la tabla no tiene copia en otro lugar.
