-- ES-66: only high-criticality delivery incidents raise an operational critical alert.
ALTER TABLE incident_reasons
    ADD COLUMN criticality VARCHAR(10) NOT NULL DEFAULT 'low',
    ADD CONSTRAINT chk_incident_reasons_criticality CHECK (criticality IN ('low', 'high'));

UPDATE incident_reasons
   SET criticality = 'high', updated_at = NOW()
 WHERE code IN ('INC-PROD-DAMAGED', 'INC-COMP-FAILURE', 'INC-RECEIPT-DIFF');
