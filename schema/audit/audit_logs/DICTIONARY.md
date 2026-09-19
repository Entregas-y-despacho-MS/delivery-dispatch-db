# audit_logs

Log de auditoría de inicios de sesión y acciones administrativas relevantes en el sistema.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| audit_log_id | SERIAL | NO | auto | Identificador del registro |
| user_id | INT | YES | — | Usuario que ejecutó la acción; NULL si el usuario fue eliminado |
| action | VARCHAR(100) | NO | — | Acción realizada (ej. `login`, `password_change`, `user_created`) |
| detail | TEXT | YES | — | Detalle libre de la acción |
| created_at | TIMESTAMPTZ | NO | NOW() | Momento en que ocurrió la acción |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| user_id | users.user_id | Usuario que ejecutó la acción |

## Business rules

- Se registra un log de auditoría de cada inicio de sesión y acción relevante (RF-A35), consultable y filtrable por usuario, fecha o tipo de evento (RF-A37), y exportable a archivo (RF-A38).

## Technical notes

- **Tabla de log append-only**: no tiene `updated_at`, un registro de auditoría ya escrito nunca se modifica.
