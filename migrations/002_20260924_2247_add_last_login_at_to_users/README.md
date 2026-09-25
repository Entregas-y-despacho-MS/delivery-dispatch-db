# add_last_login_at_to_users

The user list story (RF-A28) requires showing each user's last access date next to their status, and the table had no such column. Added as a migration (and in `schema/`) because the team already has local databases with data.

Existing users end up with `last_login_at = NULL` ("never logged in"): their past logins were never recorded. The value is filled in from the next successful login onwards.
