-- Grupo catalog: 4 catálogos administrables por el coordinador + warehouses, de solo lectura por
-- API (sembrado directo, sin endpoints de alta/edición). Sin dependencias entre sí.
\i schema/catalog/delivery_zones/init.sql
\i schema/catalog/service_levels/init.sql
\i schema/catalog/incident_reasons/init.sql
\i schema/catalog/reschedule_reasons/init.sql
\i schema/catalog/warehouses/init.sql
