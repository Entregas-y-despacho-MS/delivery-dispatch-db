# sales_order_sync_states

Estado de recepción y recuperación de cada pedido de venta, separado entre Marketplace y Almacén.
Permite conservar la última versión incluso después de crear el despacho.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| sales_order_id | VARCHAR(100) | NO | — | Pedido de venta al que pertenece el estado |
| source | VARCHAR(20) | NO | — | Origen: `marketplace` o `inventory` |
| last_record_version | BIGINT | NO | 0 | Versión más alta recibida de ese origen; 0 indica que aún no llegó ninguna |
| base_received | BOOLEAN | NO | FALSE | Indica si llegó el mensaje base `confirmed` o `ready` |
| cancelled_at | TIMESTAMPTZ | YES | — | Momento de cancelación terminal comunicado por el origen |
| cancelled_record_version | BIGINT | YES | — | Versión del mensaje que canceló el pedido o envío |
| sync_attempts | SMALLINT | NO | 0 | Solicitudes de recuperación enviadas para este pedido y origen, máximo tres |
| last_sync_requested_at | TIMESTAMPTZ | YES | — | Momento de la solicitud de recuperación más reciente |
| incomplete_alerted_at | TIMESTAMPTZ | YES | — | Momento en que se alertó que falta la base de este origen |
| created_at | TIMESTAMPTZ | NO | NOW() | Primera vez que se registró el estado |
| updated_at | TIMESTAMPTZ | NO | NOW() | Último cambio del estado |

## Business rules

- La clave `(sales_order_id, source)` permite versiones independientes de Marketplace y Almacén.
- `base_received = FALSE` permite conservar un `updated` llegado antes de su mensaje base.
- Una cancelación es terminal hasta que exista un contrato explícito de reapertura.
- El recuperador puede crear una fila con versión 0 para un origen que nunca envió un mensaje.
- Tras la tercera solicitud se espera otro intervalo antes de marcar `incomplete_alerted_at`.

## Technical notes

- El trigger `trg_sales_order_sync_states_set_updated_at` actualiza `updated_at`.
- `source`, las versiones, la pareja de datos de cancelación y el intervalo de intentos tienen restricciones CHECK.
