# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
