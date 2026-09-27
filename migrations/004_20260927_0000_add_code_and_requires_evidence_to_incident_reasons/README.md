# add_code_and_requires_evidence_to_incident_reasons

RF-A32 (ES-24) — the coordinator/supervisor catalog of incident reasons needs a unique reference
code (e.g. `INC-CLI-AUS`), whether logging that reason requires photographic evidence (so the
mobile app knows when to demand a photo before letting the driver submit the report), and whether
it is still assignable (Escenario 2: deactivating one must leave its historical incidents intact).

`incident_reasons` already existed (seeded with 3 rows, referenced by `dispatch_incidents`) but had
none of these columns — it was never exposed through the API before this ticket.

`active` follows the exact same pattern as `service_levels` (migration 003): a separate boolean, not
tied to the soft delete (`deleted_at`). This ticket's own Escenario 2 only exercises "desactivar", not
deleting, so the backend does not expose a delete endpoint for this catalog for now.

The 3 already-seeded reasons get a placeholder code and a best-guess `requires_evidence` (only
`Damaged product` set to `true` — a photo makes sense there, not for an absent customer or a wrong
address); all 3 stay active. Adjust the codes if the real operational ones differ.
