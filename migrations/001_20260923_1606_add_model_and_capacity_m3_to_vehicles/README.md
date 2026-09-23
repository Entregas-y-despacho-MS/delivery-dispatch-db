# add_model_and_capacity_m3_to_vehicles

The fleet user story (RF-A30) requires registering the vehicle model and its capacity in m3, and the table only had plate, type and kg. This is the project's first migration: it is done as a migration (and not just by editing `schema/`) because the team already has local databases with data and should not have to recreate them from scratch.

Rows already in `vehicles` end up with `model = 'Unspecified'` and `capacity_m3 = 0` as placeholders - fix them with `PUT /vehicles/:id`.
