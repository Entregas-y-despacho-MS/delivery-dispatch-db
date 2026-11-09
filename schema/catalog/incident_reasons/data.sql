INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt) VALUES
    ('INC-CUST-ABSENT',  'Customer absent',           true,  true),
    ('INC-ADDR-INVALID', 'Incorrect address',         true,  true),
    ('INC-PROD-DAMAGED', 'Damaged product',           true,  false),
    ('INC-COMP-FAILURE', 'Company or vehicle failure', false, false),
    ('INC-CUST-REJECTED', 'Rechazo del paquete por el cliente', true, true),
    ('INC-RECEIPT-DIFF', 'Diferencia en recepción de almacén', false, false);
