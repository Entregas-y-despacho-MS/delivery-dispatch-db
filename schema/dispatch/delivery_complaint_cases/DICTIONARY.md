# delivery_complaint_cases

Inbox y referencia única de los reclamos que el CRM (simulado) publica por Pub/Sub sobre entregas completadas (ES-298, ST-298.2). Una fila es un caso de CRM resuelto a un despacho concreto. Es también el caso que ES-45 investiga: ST-45.1 la extendió con estado de investigación, responsable, dictamen, hallazgos y referencias RMA, sin crear otro inbox. No reemplaza a `dispatch_complaints` (reclamo simple del portal).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| delivery_complaint_case_id | SERIAL | NO | auto | Identificador del caso |
| message_id | UUID | NO | — | `messageId` del broker del último mensaje aplicado al caso. Único |
| source | VARCHAR(100) | NO | — | Sistema productor (`crm`) |
| crm_case_id | VARCHAR(64) | NO | — | Id del caso en CRM. Con `source` forma la clave funcional única |
| case_version | INT | NO | — | Versión del caso en CRM (`>= 1`) |
| dispatch_id | INT | NO | — | Despacho individual (parada) al que resuelve el reclamo |
| tracking_code | VARCHAR(20) | YES | — | Código `DSP-AAAA-NNNNN` tal como llegó; NULL si el mensaje solo trajo `dispatchId` |
| reason_code | VARCHAR(40) | NO | — | Código de motivo del catálogo de CRM; patrón `^[A-Z][A-Z0-9_]{1,39}$`, no enum |
| affected_items | JSONB | NO | — | Producto/bulto afectado: arreglo de 1 a 100 elementos (`packageId` o `itemCode`, y `quantity`), sin datos personales |
| opened_at | TIMESTAMPTZ | NO | — | Apertura del caso en CRM |
| intake_status | VARCHAR(20) | NO | `received` | `received` (persistido) o `acknowledged` (acuse publicado) |
| consumed_at | TIMESTAMPTZ | NO | NOW() | Cuándo Despachos consumió el mensaje |
| acknowledged_at | TIMESTAMPTZ | YES | — | Cuándo se publicó el acuse `received` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |
| investigation_status | VARCHAR(20) | NO | `received` | Estado de la investigación: `received`, `assigned`, `in_investigation` o `decided`. Independiente de `intake_status` (migración `032`) |
| assigned_user_id | INT | YES | — | Usuario responsable de la investigación; NULL mientras el caso está `received` |
| assigned_at | TIMESTAMPTZ | YES | — | Cuándo se tomó o asignó el caso |
| investigation_started_at | TIMESTAMPTZ | YES | — | Cuándo se inició la investigación |
| verdict | VARCHAR(30) | YES | — | Dictamen: `no_return_required`, `not_confirmed` o `request_RMA`; NULL hasta decidir |
| decision_reason | VARCHAR(500) | YES | — | Causal saneada del dictamen; obligatoria al decidir |
| findings | TEXT | YES | — | Hallazgos saneados (hasta 4000 caracteres); sin expediente CRM, secretos ni evidencia binaria |
| decided_by_user_id | INT | YES | — | Usuario que emitió el dictamen |
| decided_at | TIMESTAMPTZ | YES | — | Cuándo se emitió el dictamen |
| authorization_request_id | VARCHAR(100) | YES | — | Solicitud de autorización RMA enviada a Inventarios; NULL si el caso no tiene RMA |
| rma_id | VARCHAR(100) | YES | — | Id externo del RMA tras la aprobación de Inventarios; NULL si no hay RMA |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho del reclamo (`ON DELETE RESTRICT`: el caso no se pierde) |
| assigned_user_id | users.user_id | Responsable asignado (`ON DELETE RESTRICT`) |
| decided_by_user_id | users.user_id | Autor del dictamen (`ON DELETE RESTRICT`) |
| rma_id | rma_sync_states.rma_id | Referencia lógica, **sin FK**: el caso puede apuntar al RMA antes de que Inventarios lo sincronice |

## Business rules

- Origen funcional: RF-U22 (reclamos sobre entregas finalizadas) vía el reclamo de CRM de ES-298.
- **Un caso por clave funcional**: `(source, crm_case_id)` es único, y `message_id` también. Reinsertar el mismo mensaje o el mismo caso no crea otra fila: el backend inserta con `ON CONFLICT DO NOTHING`, y solo una `case_version` mayor modifica la fila existente (con un `UPDATE` condicionado por versión, ver más abajo).
- **Cada caso resuelve un despacho específico**: `dispatch_id` es obligatorio. Un pedido con varios despachos no se resuelve por `salesOrderId`; que `dispatch_id` y `tracking_code` sean el mismo despacho lo valida el backend.
- Solo entra un reclamo de un despacho `delivered`, aunque su lote siga `in_execution`; esa elegibilidad también la valida el backend, no la base. Los mensajes inválidos, ambiguos o no elegibles no crean caso: quedan en `inbound_messages` como `rejected`.
- **Versionado**: una `case_version` mayor actualiza la fila (y su `message_id`); una menor o igual se ignora en el backend. El reenvío de un `messageId` ya procesado lo frena `inbound_messages`.
- **Intake**: `received` significa persistencia idempotente, no confirmación comercial ni aprobación RMA. `acknowledged_at` está presente si y solo si `intake_status = 'acknowledged'`. Un caso `received` es un acuse pendiente de publicar (recuperable si el broker cae).
- Sin datos personales, conversación comercial, secretos ni evidencia binaria: la evidencia se consulta por referencia autorizada.
- **Investigación (ST-45.1, RF-U22)**: el caso avanza `received` → `assigned` → `in_investigation` → `decided`. La elegibilidad (despacho `delivered`) y las transiciones válidas las valida el backend; la base garantiza la coherencia de los datos: un estado distinto de `received` exige responsable y su instante; `in_investigation` y `decided` exigen `investigation_started_at`; `decided` exige dictamen, causal, autor e instante, y un caso no decidido no puede tener ninguno de los cuatro.
- **Dictamen**: `no_return_required` y `not_confirmed` no crean RMA ni parada, así que dejan `authorization_request_id` y `rma_id` en NULL. `request_RMA` es el único dictamen que admite esas referencias; un caso sin RMA persiste con ambas en NULL. El recojo solo se crea tras la aprobación externa de Inventarios.
- **Versiones**: `case_version` sigue siendo la del CRM; un cambio repetido o una versión atrasada no revierte el dictamen más reciente (lo aplica el backend).
- Dispatch no guarda conversación, compensación, reembolso ni cierre comercial: eso es del CRM.
- Un despacho con casos no se puede borrar físicamente; cualquier limpieza de datos (seeds, e2e) debe borrar antes sus filas de esta tabla.

## Technical notes

- `uq_delivery_complaint_cases_message_id` y `uq_delivery_complaint_cases_source_crm_case_id` son las guardas reales de idempotencia (el backend las usa con `ON CONFLICT`).
- `idx_delivery_complaint_cases_dispatch_id` indexa la FK `dispatch_id` (consultas por despacho).
- `CHECK`: `chk_delivery_complaint_cases_case_version` (`case_version >= 1`), `chk_delivery_complaint_cases_reason_code` (patrón del código de motivo), `chk_delivery_complaint_cases_affected_items` (arreglo JSONB de 1 a 100 elementos), `chk_delivery_complaint_cases_intake_status` (`received` o `acknowledged`) y `chk_delivery_complaint_cases_acknowledged_at` (`acknowledged_at` presente si y solo si `acknowledged`).
- `idx_delivery_complaint_cases_pending_ack` es parcial (`intake_status = 'received'`) para el barrido de acuses pendientes.
- Investigación (migración `032_20261122_1000_extend_delivery_complaint_cases_with_investigation`, ST-45.1): `CHECK` `chk_delivery_complaint_cases_investigation_status`, `_verdict`, `_findings_length` (`<= 4000`), `_assignment`, `_started_at`, `_decision` (dictamen, causal, autor e instante todos presentes si y solo si `decided`) y `_rma_references` (referencias RMA solo con `request_RMA` y no vacías). FK `fk_delivery_complaint_cases_assigned_user_id` y `fk_delivery_complaint_cases_decided_by_user_id` a `users`.
- Índices de la bandeja: `idx_delivery_complaint_cases_status_consumed_at` (`investigation_status`, `consumed_at DESC`) para consultas por estado y fecha, e `idx_delivery_complaint_cases_dispatch_status` (`dispatch_id`, `investigation_status`) para consultas por despacho y estado. `idx_delivery_complaint_cases_dispatch_id` se conserva (lo creó la `030`). Los parciales `idx_delivery_complaint_cases_assigned_user_id` e `idx_delivery_complaint_cases_decided_by_user_id` indexan las FK a `users`.
- `uq_delivery_complaint_cases_authorization_request_id` y `uq_delivery_complaint_cases_rma_id` son únicos parciales (`IS NOT NULL`): una referencia externa pertenece a un solo caso.
- Las columnas de investigación van al final de la tabla para coincidir con el orden de la migración `032`.
- `updated_at` se mantiene con el trigger `trg_delivery_complaint_cases_set_updated_at` (función `fn_delivery_complaint_cases_set_updated_at`).
- Creada por la migración `030_20261121_1000_create_delivery_complaint_cases`. Contrato: `contracts/messages/schemas/crm.delivery_complaint.opened.schema.json` en `delivery-dispatch-svc`.
- Entidad TypeORM: se mapea en ST-298.3 (backend).
