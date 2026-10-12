# Estado de sincronización de pedidos de venta

ST-72.1 y ST-72.2 conservan un payload canónico por origen y necesitan guardar la última versión,
la recepción del mensaje base, las cancelaciones y las solicitudes de recuperación por pedido.
Las filas `pending_*` permanecen después de consolidar para procesar cambios posteriores. Un índice
único parcial impide crear una segunda entrega para el mismo pedido, incluso tras cancelarlo.

La migración también agrega `delivery_reference`, acordado para ST-49.3 pero ausente de la 013 ya
integrada. La 013 permanece intacta. `shipment_ready` es distinto de `package_ready_at`: este último
solo registra cuándo se empacaron físicamente los bultos.

Al recuperar datos anteriores, Marketplace reconoce el mensaje base por la clave exacta `confirmedAt`.
Almacén queda en `FALSE` porque un payload antiguo no demuestra que llegó `ready`. Un origen faltante
puede comenzar en la versión 0; los contratos reales exigen `recordVersion >= 1`.

El índice único resuelve el tipo de despacho por nombre y detiene la migración si encuentra referencias
duplicadas. Hay que resolver esos duplicados antes de aplicarla. `down.sql` elimina el estado agregado
y sus datos, sin borrar despachos ni payloads pendientes existentes.
