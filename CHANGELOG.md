# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-09
Amplía el modelo de despachos para soportar planificación semiautomática, recogidas y devoluciones
con proveedores, mensajería asíncrona con sistemas externos y alertas operativas. El schema sigue
en desarrollo activo; se esperan cambios antes de un release 1.0.0.

### Agregado
- Migración 009 — estados ampliados, `dispatch_packages`, `tracking_code` (`DSP-AAAA-NNNNN`), `evidence_policy` e índices GiST.
- Migración 010 — `dispatch_reservations` (reserva suave de pedidos) y clave `order_reservation_ttl_minutes` en `settings`.
- Migración 011 — siembra de parámetros operativos de planificación y entrega en `settings`.
- Migración 012 — almacenamiento de mensajes asíncronos (inbound/outbound) para deduplicar e idempotencia en integraciones con sistemas externos.
- Migración 013 — modelo de datos para la planificación semiautomática.
- Migración 014 — estado de sincronización de pedidos de venta por origen, con filas `pending_*` para recuperación posterior.
- Migración 015 — campos opcionales y productos esperados para modelar recogidas a proveedor.
- Migración 016 — seguimiento de versiones de mensajes del sistema de Compras.
- Migración 017 — siembra `plan_min_orders_per_route`, advertencia del generador de lotes provisionales.
- Migración 018 — metadata de evidencia de entrega y motivo de incidencia por rechazo de paquete del cliente.
- Migración 019 — `push_tokens`, token de notificaciones push por dispositivo del repartidor.
- Migración 020 — `dispatches.closed_at`, fecha de cierre en estado terminal.
- Migración 021 — modela la orden de recojo de devolución (RMA) y su sincronización por `recordVersion`.
- Migración 022 — custodia de la recogida en proveedor: cajas recibidas, toma de custodia y llegada al almacén.
- Migración 023 — siembra los tres umbrales que disparan las alertas de desempeño del Supervisor.
- Migración 024 — `warehouse_receipts`/`warehouse_receipt_items` para cerrar el traslado de un RMA o recogida en proveedor al confirmar Almacén la recepción física.
- Migración 025 — motivo de incidencia por diferencias en la recepción de Almacén.
- Migración 026 — `operational_alerts`, modelo para las alertas que levanta el evaluador del backend (incidencia crítica, GPS sin reportar, SLA de zona bajo umbral).
- Migración 027 — criticidad (`low`/`high`) de motivos de incidencia, para distinguir cuáles disparan una alerta crítica.
- Tabla `warehouses` con almacenes mínimos sembrados.

### Corregido
- `db-output.sql` ahora registra las migraciones ya existentes, para que una carga desde cero no las vuelva a reproducir.
- Los scripts de migración leen las credenciales de la base también desde variables de entorno, no solo desde `.env`.

### Cambiado
- Las imágenes Docker de la base de datos quedan fijadas por digest, para builds reproducibles.

### Infraestructura
- CI: en cada pull request y push a `dev`/`test`/`main`, genera `db-output.sql` y lo carga contra un Postgres real de servicio, para detectar errores de SQL o de orden de dependencias.
- `.gitignore`/`.dockerignore` corregidos para excluir cualquier variante de `.env`, no solo el literal — evita que un archivo con secretos reales termine en git o en el contexto de build de Docker.

## [0.1.0] - 2026-10-06
Primer release etiquetado: schema inicial completo. Sigue en desarrollo activo; se esperan cambios
antes de un release 1.0.0.

### Agregado
- Schema inicial completo: 20 tablas en 6 dominios (`auth`, `fleet`, `catalog`, `dispatch`,
  `audit`, `settings`), con diccionario de datos (`DICTIONARY.md`) por tabla.
- Soporte Docker para levantar la base con el schema cargado automáticamente al primer arranque.
- Esquema de política de contraseñas.
- Código único por zona de reparto.
- `client_event_id` en `dispatch_events` para idempotencia de sincronización offline.
- Migración 001 — `model`/`capacity_m3` en `vehicles`.
- Migración 002 — `last_login_at` en `users`.
- Migración 003 — `description`/`priority_level`/`active` en `service_levels`.
- Migración 004 — `code`/`requires_evidence`/`active` en `incident_reasons`.
- Migración 005 — `description`/`category`/`active` en `reschedule_reasons`.
- Migración 007 — `code`/`severity`/`disables_vehicle` en `vehicle_incident_types`.

### Corregido
- Migración 006 — a `reschedule_reasons` le faltaba `code`.
