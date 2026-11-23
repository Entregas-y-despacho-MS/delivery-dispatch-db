# planning_cutoffs

Un corte de planificación: cada corrida del corte de D-1 que dejó un snapshot del universo de planificación del día operativo siguiente. Es la cabecera de `planning_cutoff_dispatches`, que guarda qué despachos eran elegibles o quedaron excluidos en ese corte. Sirve para que la cobertura al corte (ES-302, Dashboard 2) devuelva siempre el mismo denominador aunque las rutas avancen.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| planning_cutoff_id | SERIAL | NO | auto | Identificador del corte |
| shift_date | DATE | NO | — | Día operativo de las rutas que el corte planifica (el próximo día operativo respecto del corte) |
| cutoff_at | TIMESTAMPTZ | NO | — | Instante UTC del corte: el inicio de la corrida |
| operating_timezone | VARCHAR(40) | NO | — | Zona operativa en que se interpreta `shift_date` (`America/La_Paz`) |
| trigger_type | VARCHAR(20) | NO | — | `scheduled` (tarea programada a la hora de `route_cutoff_time`) o `manual` (corrida a pedido) |
| occurrence | VARCHAR(60) | YES | — | Ocurrencia de la tarea (`route-cutoff@AAAA-MM-DDTHH:mm`); NULL si el corte fue manual. Único |
| created_at | TIMESTAMPTZ | NO | NOW() | Cuándo se guardó el snapshot |

## Relationships

Ninguna FK propia. Es referenciada por `planning_cutoff_dispatches.planning_cutoff_id` (`ON DELETE RESTRICT`).

## Business rules

- Origen funcional: ES-302 / ST-302.2 (Dashboard 2: planificación y ejecución de rutas) y la regla de cobertura al corte de la HU 5.17.
- **Un snapshot por ocurrencia**: `occurrence` es único, así que repetir la misma ocurrencia programada no reescribe el snapshot; se conserva el primero y el denominador no cambia aunque la corrida se repita y ya no encuentre lotes `provisional`.
- `chk_planning_cutoffs_occurrence`: un corte `scheduled` siempre tiene `occurrence`; uno `manual` nunca.
- **Corte oficial del día**: el primer snapshot `scheduled` de un `shift_date`. Los demás (otras horas programadas, corridas manuales) se listan con su `trigger_type` y no lo sustituyen. Es una regla de lectura del backend, no una restricción.
- Una corrida sin lotes que procesar también deja snapshot (con cero despachos). Una corrida bloqueada por configuración incompleta o fuera de día de corte no deja ninguno.
- **Sin backfill**: los cortes anteriores a la migración `033` no tienen fila y se leen como desconocidos (N/D); no se reconstruyen desde estados actuales.

## Technical notes

- **Tabla de historia append-only**: no tiene `updated_at`. La inmutabilidad la imponen los triggers `trg_planning_cutoffs_prevent_update` / `fn_planning_cutoffs_prevent_update()` (bloquea todo `UPDATE`) y `trg_planning_cutoffs_prevent_delete` / `fn_planning_cutoffs_prevent_delete()` (bloquea `DELETE` salvo que la sesión tenga `app.allow_event_purge = 'on'`, uso reservado a la limpieza de pruebas). `TRUNCATE` no se bloquea: es convención.
- **Restricciones e índices**: `chk_planning_cutoffs_trigger_type` (`scheduled` o `manual`) y `chk_planning_cutoffs_occurrence` (`scheduled` ⇔ `occurrence` presente). `uq_planning_cutoffs_occurrence` es un índice único **parcial** (`WHERE occurrence IS NOT NULL`): los cortes manuales, sin ocurrencia, pueden repetirse. `idx_planning_cutoffs_shift_date` sirve para listar los cortes de un día operativo.
- **Referencia funcional**: la HU 5.17 (Jira ES-302) no está en `docs/` ni tiene aún un RF; el origen es esa historia.
- Creada por la migración `033_20261122_1100_create_planning_cutoffs_and_route_manifests` (ST-302.2). El backend debe agregar la entidad correspondiente.
