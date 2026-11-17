# dispatch_packages

Bultos reales de un despacho, informados por Inventarios y Almacén cuando el pedido está empacado (peso bruto y medidas).

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_package_id | SERIAL | NO | auto | Identificador del bulto |
| dispatch_id | INT | NO | — | Despacho al que pertenece |
| external_package_id | VARCHAR(100) | NO | — | `packageId` asignado por Almacén; único por despacho |
| length_cm | NUMERIC(8,2) | NO | — | Largo en cm (> 0) |
| width_cm | NUMERIC(8,2) | NO | — | Ancho en cm (> 0) |
| height_cm | NUMERIC(8,2) | NO | — | Alto en cm (> 0) |
| gross_weight_kg | NUMERIC(10,3) | NO | — | Peso bruto en kg (> 0) |
| handling_conditions | TEXT[] | NO | '{}' | Condiciones de manejo (frágil, etc.) |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|-------------|
| dispatch_id | dispatches.dispatch_id | Despacho dueño del bulto (`ON DELETE CASCADE`) |

## Business rules

- El peso total de un despacho es la suma de `gross_weight_kg`; el volumen es la suma de `largo × ancho × alto / 1 000 000` (m³). Con ellos se valida la capacidad del vehículo (RF-A03) y se muestra la bandeja de pedidos.
