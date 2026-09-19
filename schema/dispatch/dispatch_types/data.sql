INSERT INTO dispatch_types (name) VALUES
    ('delivery'),
    ('warehouse_return_pickup'),
    ('supplier_pickup'),
    ('supplier_return');
-- delivery: entrega estándar de un pedido al cliente final (escenario 1).
-- warehouse_return_pickup: recojo de una devolución/garantía aprobada en el domicilio del cliente, con destino al almacén (escenario 2).
-- supplier_pickup: traslado de mercadería nueva desde la planta de un proveedor hacia el centro de distribución (escenario 3).
-- supplier_return: devolución de mercadería defectuosa o rechazada desde el almacén hacia el proveedor (escenario 4).
