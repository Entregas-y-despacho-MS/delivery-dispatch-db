INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt, criticality) VALUES
    ('INC-CUST-ABSENT',  'Customer absent',           true,  true,  'low'),
    ('INC-ADDR-INVALID', 'Incorrect address',         true,  true,  'low'),
    ('INC-PROD-DAMAGED', 'Damaged product',           true,  false, 'high'),
    ('INC-COMP-FAILURE', 'Company or vehicle failure', false, false, 'high'),
    ('INC-CUST-REJECTED', 'Rechazo del paquete por el cliente', true, true, 'low'),
    ('INC-RECEIPT-DIFF', 'Diferencia en recepción de almacén', false, false, 'high');
