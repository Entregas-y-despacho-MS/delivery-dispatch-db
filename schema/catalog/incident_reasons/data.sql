INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt) VALUES
    ('INC-CUST-ABSENT',  'Customer absent',           false, true),
    ('INC-ADDR-INVALID', 'Incorrect address',         false, true),
    ('INC-PROD-DAMAGED', 'Damaged product',           true,  false),
    ('INC-COMP-FAILURE', 'Company or vehicle failure', false, false);
