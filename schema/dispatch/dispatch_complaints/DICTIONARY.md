# dispatch_complaints

Reclamos que el Cliente Final presenta sobre una entrega ya finalizada.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_complaint_id | SERIAL | NO | auto | Identificador del reclamo |
| dispatch_id | INT | NO | — | Despacho sobre el que se reclama |
| description | TEXT | NO | — | Detalle del reclamo |
| status | VARCHAR(20) | NO | 'open' | `open` o `closed` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho sobre el que se reclama |

## Business rules

- El Cliente Final reporta un reclamo sobre una entrega ya finalizada (RF-U22), desde el portal web.
