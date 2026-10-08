# create_dispatch_reservations_and_ttl_setting

ST-48.2 (ES-48, RF-A40) — reserva suave de pedidos en la bandeja del coordinador.

- Crea `dispatch_reservations` (una fila por despacho reservado: quién, cuándo, última actividad y vencimiento).
- Siembra la clave `order_reservation_ttl_minutes` (15 por defecto) en `settings`.

`down.sql` borra la clave y la tabla.
