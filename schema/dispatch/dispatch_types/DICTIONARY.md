# dispatch_types

Catálogo de los tipos de operación que puede representar un despacho: no todo despacho es una entrega a cliente.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| dispatch_type_id | SERIAL | NO | auto | Identificador del tipo |
| name | VARCHAR(50) | NO | — | `delivery`, `warehouse_return_pickup`, `supplier_pickup` o `supplier_return` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- `delivery`: entrega estándar de un pedido confirmado al cliente final.
- `warehouse_return_pickup`: recojo de una devolución o garantía aprobada en el domicilio del cliente, con destino al almacén (RF-A39, RF-U23).
- `supplier_pickup`: traslado de mercadería nueva desde la planta de un proveedor hacia el centro de distribución (abastecimiento, coordinado con Compras y Proveedores).
- `supplier_return`: devolución de mercadería defectuosa o rechazada desde el almacén hacia el proveedor (logística inversa, coordinado con Compras y Proveedores).
- Es un catálogo estructural (el código de la aplicación ramifica su lógica según este valor), no administrable por interfaz — por eso no tiene `deleted_at`.
