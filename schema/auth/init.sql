-- Grupo auth: orden de carga (roles antes que users; password_history después de users, por la FK)
\i schema/auth/roles/init.sql
\i schema/auth/users/init.sql
\i schema/auth/password_history/init.sql
