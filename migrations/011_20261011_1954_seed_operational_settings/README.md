# seed_operational_settings

ST-57.2 (ES-57) — agrega a `settings` los parámetros operativos de planificación y entrega.

- Inserta las 26 claves operativas con sus valores iniciales y descripciones.
- Inicializa `settings_version` en `0` para las bases que ya existían antes del cambio.
- `ON CONFLICT (setting_key) DO NOTHING` conserva los valores que ya estén configurados.

`down.sql` elimina las claves agregadas por esta migración.
