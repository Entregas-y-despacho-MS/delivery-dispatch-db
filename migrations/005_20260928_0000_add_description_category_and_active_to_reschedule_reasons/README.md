# add_description_category_and_active_to_reschedule_reasons

RF-A33 (ES-25) — the dispatch coordinator's catalog of reschedule/reassignment reasons needs an
optional description, and the origin/responsibility category (`client` | `operations` |
`force_majeure`) a reason is classified under. Escenario 2 of the story: a reschedule that uses a
`client`-categorized reason should not count against the logistics team's internal punctuality
metric — that computation belongs to whatever eventually writes to `dispatch_reschedules` (not
built yet, out of scope here); this migration only adds the column the category is read from.

Also adds `active` (same pattern as `service_levels`/`incident_reasons`): a separate boolean, not
tied to the soft delete, so a reason can be retired from new reschedules without touching the
history of reschedules that already used it. The story has no scenario about deleting a reason (only
alta and duplicate prevention), so the backend does not expose a delete endpoint for this catalog.

No existing rows to backfill — `reschedule_reasons.data.sql` has none (unlike `incident_reasons`,
which shipped with 3 seeded rows).
