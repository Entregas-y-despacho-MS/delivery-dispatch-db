-- Natural-key catalog for the terminal result of an inbound message.
CREATE TABLE inbound_message_statuses (
    status       VARCHAR(20)    NOT NULL,                                -- processed | rejected
    description  TEXT           NOT NULL,                                -- meaning of the status
    PRIMARY KEY (status)
);
