# add_incident_reason_criticality

ST-66.1 (ES-66) — distingue las incidencias que deben generar una alerta crítica en la torre de control.

## Cambios

- Agrega `incident_reasons.criticality`, con valores `low` y `high`; el valor por defecto es `low`.
- Marca como alta la criticidad de daño de producto, falla de empresa/vehículo y diferencia de recepción. Las demás razones existentes permanecen en nivel bajo.
- El backend solo crea una alerta de tipo `critical_incident` cuando la razón reportada está clasificada como `high`.

## Reversión

`down.sql` elimina la restricción y la columna. No borra ni cambia incidentes existentes.
