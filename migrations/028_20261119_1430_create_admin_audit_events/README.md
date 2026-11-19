# create_admin_audit_events

RF-A35 needs every sensitive administrative action recorded with actor, role, entity, result, correlation and trusted IP, both when it runs and when it is denied. `audit_logs` only has `user_id`, `action` and free-text `detail`, and it already holds system traces (scheduler, outbox, planning alerts), so these events get their own append-only table that the audit search and export can filter without mixing both. `actor_user_id` has no foreign key on purpose: deleting a user must not rewrite its audit events.
