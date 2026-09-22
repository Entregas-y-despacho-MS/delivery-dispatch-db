# dispatch_events

Log de eventos de negocio de cada despacho: creación, asignación, cambios de estado.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_event_id | SERIAL | NO | auto | Identificador del evento |
| dispatch_id | INT | NO | — | Despacho al que corresponde |
| event_type | VARCHAR(50) | NO | — | Tipo de evento (ej. `created`, `assigned`, `status_changed`) |
| detail | TEXT | YES | — | Detalle libre del evento (ej. estado anterior → nuevo) |
| client_event_id | UUID | YES | — | Id generado por la app móvil del repartidor cuando el evento se creó offline (RF-U13); NULL en eventos generados por el propio backend |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que ocurrió el evento |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho al que pertenece el evento |

## Business rules

- Se genera automáticamente por la aplicación ante cada pedido/despacho: creación, asignación, cambios de estado (RF-A36), para dar trazabilidad completa.
- Los cambios de estado que llegan desde la app móvil offline (RF-U13) traen su propio `client_event_id`: si el mismo evento se reintenta (por un corte de red durante la sincronización), no se duplica — se trata como ya aplicado.

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at` porque un evento ya registrado nunca se modifica — es intencional, distinto del resto de las tablas del proyecto.
- `client_event_id` es único solo cuando no es NULL (`WHERE client_event_id IS NOT NULL`) — permite que eventos generados por el propio backend (sin este id) convivan sin restricción de unicidad entre ellos.
