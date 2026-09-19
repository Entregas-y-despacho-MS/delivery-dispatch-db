# dispatch_events

Log de eventos de negocio de cada despacho: creación, asignación, cambios de estado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_event_id | SERIAL | NO | auto | Identificador del evento |
| dispatch_id | INT | NO | — | Despacho al que corresponde |
| event_type | VARCHAR(50) | NO | — | Tipo de evento (ej. `created`, `assigned`, `status_changed`) |
| detail | TEXT | YES | — | Detalle libre del evento (ej. estado anterior → nuevo) |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que ocurrió el evento |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho al que pertenece el evento |

## Business rules

- Se genera automáticamente por la aplicación ante cada pedido/despacho: creación, asignación, cambios de estado (RF-A36), para dar trazabilidad completa.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at` porque un evento ya registrado nunca se modifica — es intencional, distinto del resto de las tablas del proyecto.
