# add_code_to_reschedule_reasons

Fix — migration 005 (RF-A33) added `description`, `category` and `active` to `reschedule_reasons`
but missed `code`: the story's own Escenario 3 ("Prevención de duplicidad") checks for a duplicate
by "nombre o código", meaning a unique reference code, same as the sibling `incident_reasons`
catalog (migration 004), was always part of the requirement — not a new feature.
