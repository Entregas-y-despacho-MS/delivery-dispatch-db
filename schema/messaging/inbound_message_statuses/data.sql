INSERT INTO inbound_message_statuses (status, description) VALUES
    ('processed', 'Message passed validation and was processed successfully.'),
    ('rejected', 'Message was invalid or could not be processed and must be sent to the dead-letter topic.')
ON CONFLICT (status) DO NOTHING;
