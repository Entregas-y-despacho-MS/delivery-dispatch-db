INSERT INTO outbound_message_statuses (status, description) VALUES
    ('pending', 'Message is waiting to be published or retried.'),
    ('sent', 'Message was published successfully.'),
    ('failed', 'Message exhausted its retry policy and will not be published again.')
ON CONFLICT (status) DO NOTHING;
