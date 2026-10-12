-- Natural-key catalog for the outgoing message delivery lifecycle.
CREATE TABLE outbound_message_statuses (
    status       VARCHAR(20)    NOT NULL,                                -- pending | sent | failed
    description  TEXT           NOT NULL,                                -- meaning of the status
    PRIMARY KEY (status)
);
