# dispatch_incidents

Incidencias registradas por el repartidor durante la ejecución de un despacho (cliente ausente, dirección incorrecta, producto dañado, etc.).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_incident_id | UUID | NO | — (generado por la app móvil) | Identificador de la incidencia |
| dispatch_id | INT | NO | — | Despacho donde ocurrió |
| incident_reason_id | INT | NO | — | Motivo de la incidencia |
| description | TEXT | YES | — | Detalle adicional |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho afectado |
| incident_reason_id | incident_reasons.incident_reason_id | Motivo de la incidencia (catálogo) |

## Business rules

- El repartidor registra incidencias durante la entrega (RF-U06). Una incidencia deja de tener sentido si se elimina su despacho (`ON DELETE CASCADE`).
- Registrar una incidencia acá es lo que dispara la alerta automática al supervisor cuando es crítica (RF-A19) — no hay una columna de "severidad" en el schema; qué motivos cuentan como críticos es una regla de aplicación, no de datos.

## Technical notes

- **PK en UUID, no SERIAL** — mismo motivo que `delivery_evidences`: la crea la app móvil del repartidor, que puede estar sin conexión (RF-U13), y necesita generar el ID en el dispositivo antes de sincronizar. Sin `DEFAULT`: el ID lo genera la app.
- **Usar UUID v7, no v4** — mismo motivo que `delivery_evidences` (orden temporal, mejor para el índice). El backend NestJS debe validar este ID con `version: '7'` explícito en `ParseUUIDPipe`/`@IsUUID()`, porque el default de ambos (verificado en la documentación oficial de NestJS) solo acepta v3/v4/v5.
