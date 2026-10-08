# warehouses

Catálogo de almacenes/centros de distribución desde donde se originan los despachos y hacia donde
llegan las recogidas de devolución.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| warehouse_id | SERIAL | NO | auto | Identificador del almacén |
| code | VARCHAR(30) | NO | — | Código único del almacén (ej. `WH-LPZ-01`) |
| name | VARCHAR(100) | NO | — | Nombre del almacén |
| address | TEXT | NO | — | Dirección física |
| latitude | NUMERIC(9,6) | NO | — | Latitud del almacén |
| longitude | NUMERIC(9,6) | NO | — | Longitud del almacén |
| contact_name | VARCHAR(150) | YES | — | Nombre de la persona de contacto en el almacén (opcional) |
| contact_phone | VARCHAR(30) | YES | — | Teléfono de contacto (opcional) |
| reception_start_time | TIME | NO | — | Inicio de la ventana horaria en que el almacén recibe mercadería |
| reception_end_time | TIME | NO | — | Fin de la ventana horaria en que el almacén recibe mercadería |
| active | BOOLEAN | NO | TRUE | Habilitado para usarse como origen/destino de nuevos despachos |
| deleted_at | TIMESTAMPTZ | YES | — | Soft delete |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- Catálogo mínimo y de solo lectura por API — no administrable desde el backend (RF, corrección de
  ES-26). Se siembra directamente con datos reales, no vía endpoints de alta/edición.
- `reception_end_time` debe ser posterior a `reception_start_time` (no se soportan ventanas que
  cruzan la medianoche).
- Las coordenadas (`latitude`/`longitude`) son el punto de origen que usa OSRM para calcular rutas
  cuando el almacén actúa como centro de distribución.

## Technical notes

- Único solo entre almacenes no borrados (`WHERE deleted_at IS NULL`).
- `chk_warehouses_reception_window` exige `reception_end_time > reception_start_time`.
- Agregada en la migración `008_..._create_warehouses` — corrección de ES-26/ST-26.1, la tabla
  figuraba como entregada en el Sprint 1 pero nunca se creó. La necesitan ST-74.2, ST-50.2 y
  ST-75.1 del Sprint 2.
