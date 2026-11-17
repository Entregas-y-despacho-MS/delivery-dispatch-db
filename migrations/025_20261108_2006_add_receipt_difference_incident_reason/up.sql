-- ST-240.2 (ES-251, ERP-08): a receipt of warehouse_receipts with result with_differences/rejected
-- needs an incident_reasons row to attach to the dispatch_incidents row it creates. The system
-- creates it (processing inventory.receipt.confirmed), not the driver, so neither flag applies.

INSERT INTO incident_reasons (code, name, requires_evidence, counts_as_attempt) VALUES
    ('INC-RECEIPT-DIFF', 'Diferencia en recepción de almacén', FALSE, FALSE)
ON CONFLICT (code) WHERE deleted_at IS NULL DO NOTHING;
