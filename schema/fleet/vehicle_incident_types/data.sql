INSERT INTO vehicle_incident_types (code, name, severity, disables_vehicle) VALUES
    ('MEC-GEN-01', 'Mechanical failure',             'critical', TRUE),
    ('TIR-DAM-01', 'Damaged tire',                    'moderate', FALSE),
    ('ACC-TRF-01', 'Traffic accident',                'critical', TRUE),
    ('MNT-OVD-01', 'Overdue preventive maintenance',  'minor',    FALSE);
