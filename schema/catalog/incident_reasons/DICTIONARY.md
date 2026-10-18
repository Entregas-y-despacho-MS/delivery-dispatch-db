# incident_reasons

Catálogo de motivos de incidencia durante una entrega (ej. cliente ausente, dirección incorrecta).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| incident_reason_id | SERIAL | NO | auto | Identificador del motivo |
| code | VARCHAR(30) | NO | — | Código único de referencia (ej. `INC-CLI-AUS`), en mayúsculas |
| name | VARCHAR(150) | NO | — | Descripción del motivo de incidencia |
| requires_evidence | BOOLEAN | NO | FALSE | Si registrar una incidencia con este motivo exige foto de evidencia |
| counts_as_attempt | BOOLEAN | NO | FALSE | Si registrar una incidencia con este motivo **consume un intento de entrega** del pedido (se compara con `settings.max_delivery_attempts`) |
| active | BOOLEAN | NO | TRUE | Asignable a incidencias nuevas. Desactivarlo no afecta a las incidencias ya registradas con este motivo |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador de logística y el supervisor de operaciones administran este catálogo (RF-A32). El repartidor lo usa (vía la app móvil, descargado para uso offline) para registrar una incidencia durante la entrega (RF-U06).
- No hay borrado: la salida para retirar un motivo de uso es desactivarlo (`active = false`), que solo impide asignarlo a incidencias nuevas — las ya registradas con ese motivo no se ven afectadas. No se borra en duro por el historial de incidencias que lo referencian.
- **Evidencia fotográfica.** Los motivos operativos de entrega `INC-CUST-ABSENT`, `INC-ADDR-INVALID`, `INC-PROD-DAMAGED` e `INC-CUST-REJECTED` exigen evidencia (`requires_evidence = TRUE`). `INC-COMP-FAILURE` no exige foto porque el conductor puede no estar en condiciones de capturarla.
- **Intentos de entrega (D-48).** `INC-CUST-ABSENT`, `INC-ADDR-INVALID` e `INC-CUST-REJECTED` cuentan como intento (`counts_as_attempt = TRUE`); `INC-PROD-DAMAGED` e `INC-COMP-FAILURE` no. Un motivo nuevo nace en `FALSE`: quien lo crea debe decidirlo.
- `INC-ADDR-INVALID` puede ser causa nuestra si el punto de entrega lo fijó el coordinador desde `address_review`; aun así cuenta como intento por regla del plan.
- `INC-COMP-FAILURE` (falla de la empresa o del vehículo) no consume intento del cliente y no exige foto (`requires_evidence = FALSE`: tras una avería el conductor puede no poder tomarla). Se trata como caso 5.2: alerta al coordinador y promesa original conservada.

## Technical notes

- Único solo entre motivos no borrados, tanto por `name` como por `code` (`WHERE deleted_at IS NULL`).
- `code`, `requires_evidence` y `active` se agregaron con la migración `004_..._add_code_and_requires_evidence_to_incident_reasons` (RF-A32); los 3 motivos sembrados originalmente recibieron un código y una evidencia inventados en esa migración.
- `counts_as_attempt` y el motivo `INC-COMP-FAILURE` (nombre «Company or vehicle failure») los agregó la migración `013_..._extend_dispatch_model_for_semiautomatic_planning` (ST-49.3). En bases existentes, solo `INC-CUST-ABSENT` e `INC-ADDR-INVALID` pasaron a `TRUE`; los motivos creados por el equipo quedaron en `FALSE`.
- La migración `018_..._pod_evidence_metadata` (ST-31.5) activa la evidencia fotográfica para los motivos operativos y agrega `INC-CUST-REJECTED` («Rechazo del paquete por el cliente»), que cuenta como intento.
