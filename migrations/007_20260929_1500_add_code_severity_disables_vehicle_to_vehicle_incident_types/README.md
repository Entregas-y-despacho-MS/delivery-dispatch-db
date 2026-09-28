# add_code_severity_disables_vehicle_to_vehicle_incident_types

RF-A34 (ES-26) — the fleet supervisor's catalog of vehicle incident types needs a unique reference
code, a mandatory severity (`minor` | `moderate` | `critical` — Escenario 3), and whether an
incident of this type immediately disables the vehicle it's registered against (Escenario 2). The
actual status-flip trigger lives in the app (`POST /vehicle-maintenances`, which reads this flag) —
this migration only adds the column it reads.
