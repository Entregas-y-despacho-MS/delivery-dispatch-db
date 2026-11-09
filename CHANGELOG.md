# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-09
Sprint 2 y Sprint 3 combinados — no hubo un release intermedio al cerrar el Sprint 2, así que esta
versión junta ambos. El schema sigue en desarrollo activo; se esperan cambios antes de un release
1.0.0.

### Agregado
- Migración 009 — estados ampliados, `dispatch_packages`, `tracking_code` (`DSP-AAAA-NNNNN`), `evidence_policy` e índices GiST (ST-49.2).
- Migración 010 — `dispatch_reservations` (reserva suave de pedidos) y clave `order_reservation_ttl_minutes` en `settings` (ST-48.2).
- Migración 011 — siembra los 26 parámetros operativos de planificación y entrega en `settings` (ST-57.2).
- Migración 012 — almacenamiento de mensajes async (inbound/outbound) para deduplicar e idempotencia de los consumidores de integración (ST-72.3).
- Migración 013 — modelo de datos de la planificación semiautomática (plan v3) (ST-49.3).
- Migración 014 — estado de sincronización de pedidos de venta por origen, con filas `pending_*` para recuperación posterior (ST-72.1/ST-72.2).
- Migración 015 — campos opcionales y productos esperados para modelar recogidas a proveedor (ST-74.2).
- Migración 016 — habilita el seguimiento de versiones de mensajes de Compras (ST-74.1).
- Migración 017 — siembra `plan_min_orders_per_route`, advertencia del generador de lotes provisionales (ST-50.2).
- Migración 018 — metadata de evidencia POD y motivo de incidencia por rechazo de paquete del cliente (ST-31.5).
- Migración 019 — `push_tokens`, token de notificaciones push por dispositivo del repartidor (ST-36.3).
- Migración 020 — `dispatches.closed_at`, fecha de cierre en estado terminal (ST-55.2).
- Migración 021 — modela la orden de recojo de devolución (RMA) y su sincronización por `recordVersion` (ST-238.1).
- Migración 022 — custodia de la recogida en proveedor: cajas recibidas, toma de custodia y llegada al almacén (ST-239.1).
- Migración 023 — siembra los tres umbrales que disparan las alertas de desempeño del Supervisor (ST-67.1).
- Migración 024 — `warehouse_receipts`/`warehouse_receipt_items` para cerrar el traslado de un RMA o recogida en proveedor al confirmar Almacén la recepción física (ST-240.1).
- Migración 025 — motivo de incidencia por diferencias en la recepción de Almacén (ST-240.2).
- Migración 026 — `operational_alerts`, modelo para las alertas que levanta el evaluador del backend (incidencia crítica, GPS sin reportar, SLA de zona bajo umbral) (ST-66.1).
- Tabla `warehouses` con almacenes mínimos sembrados.

### Corregido
- `db-output.sql` ahora registra las migraciones ya existentes, para que una carga desde cero no las vuelva a reproducir.
- Los scripts de migración leen las credenciales de la base también desde variables de entorno, no solo desde `.env`.

### Cambiado
- Las imágenes Docker de la base de datos quedan fijadas por digest en el `docker-compose.yml` local, para builds reproducibles.

## [0.1.0] - 2026-10-06
Primer hito etiquetado — fin del Sprint 1. El schema sigue en desarrollo activo; se esperan
cambios antes de un release 1.0.0.

### Agregado
- Schema inicial completo: 20 tablas en 6 dominios (`auth`, `fleet`, `catalog`, `dispatch`,
  `audit`, `settings`), con diccionario de datos (`DICTIONARY.md`) por tabla.
- Soporte Docker para levantar la base con el schema cargado automáticamente al primer arranque.
- Esquema de política de contraseñas (RF-A25).
- Código único por zona de reparto (RF-A29).
- `client_event_id` en `dispatch_events` para idempotencia de sincronización offline (RF-U13).
- Migración 001 — `model`/`capacity_m3` en `vehicles` (RF-A30).
- Migración 002 — `last_login_at` en `users` (RF-A28).
- Migración 003 — `description`/`priority_level`/`active` en `service_levels` (RF-A31).
- Migración 004 — `code`/`requires_evidence`/`active` en `incident_reasons` (RF-A32).
- Migración 005 — `description`/`category`/`active` en `reschedule_reasons` (RF-A33).
- Migración 007 — `code`/`severity`/`disables_vehicle` en `vehicle_incident_types` (RF-A34).

### Corregido
- Migración 006 — a `reschedule_reasons` le faltaba `code` (RF-A33).
