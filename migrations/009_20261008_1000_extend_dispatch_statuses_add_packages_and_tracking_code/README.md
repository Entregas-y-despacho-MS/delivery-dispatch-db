# extend_dispatch_statuses_add_packages_and_tracking_code

ST-49.2 (ES-49, RF-A02) — prepara la BD para la generación automática de órdenes de despacho.

- Agrega 10 estados a `dispatch_statuses` (se conserva `in_transit`).
- Crea `dispatch_packages` (bultos reales de Almacén) y agrega a `dispatches` `tracking_code` (único,
  inmutable, `DSP-AAAA-NNNNN`) y `evidence_policy`.
- `next_tracking_code()` + `tracking_code_counters` dan la secuencia anual segura ante concurrencia.
- Agrega `delivery_zones.boundary` (POLYGON nativo) e índices GiST sobre ese polígono y el punto de destino.

`down.sql` solo elimina los estados que ningún despacho usa.
