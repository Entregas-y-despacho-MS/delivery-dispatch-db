# reschedule_reasons

Catálogo de motivos por los que se reprograma o reasigna un despacho.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| reschedule_reason_id | SERIAL | NO | auto | Identificador del motivo |
| code | VARCHAR(30) | NO | — | Código de referencia único (ej. `RES-CLI-EXP`) |
| name | VARCHAR(150) | NO | — | Descripción del motivo de reprogramación o reasignación |
| description | VARCHAR(255) | YES | — | Detalle opcional del motivo |
| category | VARCHAR(20) | NO | — | Origen/responsabilidad del motivo: `client`, `operations` o `force_majeure` |
| active | BOOLEAN | NO | TRUE | Asignable a reprogramaciones/reasignaciones nuevas. Desactivarlo no afecta a las reprogramaciones ya registradas con este motivo |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El coordinador administra este catálogo (RF-A33), distinto del catálogo de motivos de incidencia: este es sobre decisiones de reprogramación/reasignación (RF-A05, RF-A16), no sobre problemas ocurridos durante la entrega.
- Un motivo categorizado como `client` marca, cuando se usa para reprogramar un despacho, que el retraso no penaliza la métrica de puntualidad interna del equipo de logística — ese cómputo se hace al registrar la reprogramación (`dispatch_reschedules`), no en este catálogo.
- No hay borrado: la salida para retirar un motivo de uso es desactivarlo (`active = false`), que solo impide asignarlo a reprogramaciones nuevas — las ya registradas con ese motivo no se ven afectadas.

## Technical notes

- `code` y `name` únicos cada uno por separado, solo entre motivos no borrados (`WHERE deleted_at IS NULL`) — un intento de guardar cualquiera de los dos ya en uso responde 409 (Escenario 3).
- `category` restringido por `chk_reschedule_reasons_category` a exactamente `client`, `operations` o `force_majeure` (minúsculas, sin tilde — mismo criterio que el resto de los enums del proyecto, ej. `RoleEnum`).
- `description`, `category` y `active` se agregaron con la migración `005_..._add_description_category_and_active_to_reschedule_reasons` (RF-A33). No había filas sembradas que migrar.
- `code` se agregó con la migración `006_..._add_code_to_reschedule_reasons` — un ajuste sobre la 005, que lo había dejado afuera pese a que el propio Escenario 3 de la historia ya lo pedía ("nombre o código").
