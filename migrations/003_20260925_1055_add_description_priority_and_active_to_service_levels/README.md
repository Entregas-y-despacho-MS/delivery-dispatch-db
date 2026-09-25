# add_description_priority_and_active_to_service_levels

The service levels story (RF-A31) requires a description, a priority hierarchy between levels and an enabled/disabled state (a level with active dispatches cannot be deleted, only disabled). The table only had name and target time. Done as a migration (and in `schema/`) because the team already has local databases with data.

Existing levels are enabled and get `priority_level` by target time: the shortest target time is priority 1. Their `description` stays NULL.
