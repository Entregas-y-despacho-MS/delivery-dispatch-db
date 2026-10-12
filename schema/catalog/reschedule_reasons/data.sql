-- El resto del catálogo lo administra el coordinador. Este motivo se siembra porque
-- dispatch_reschedules.reschedule_reason_id es NOT NULL y la reprogramación por autoservicio
-- del cliente no la ejecuta ningún usuario.
INSERT INTO reschedule_reasons (code, name, description, category) VALUES
    ('RES-CLI-SELF', 'Customer self-service reschedule', 'The customer rescheduled the delivery from the tracking link', 'client');
