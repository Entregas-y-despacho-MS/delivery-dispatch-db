DROP INDEX IF EXISTS uq_delivery_complaint_cases_rma_id;
DROP INDEX IF EXISTS uq_delivery_complaint_cases_authorization_request_id;
DROP INDEX IF EXISTS idx_delivery_complaint_cases_decided_by_user_id;
DROP INDEX IF EXISTS idx_delivery_complaint_cases_assigned_user_id;
DROP INDEX IF EXISTS idx_delivery_complaint_cases_dispatch_status;
DROP INDEX IF EXISTS idx_delivery_complaint_cases_status_consumed_at;

ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_rma_references;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_decision;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_started_at;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_assignment;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_findings_length;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_verdict;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS chk_delivery_complaint_cases_investigation_status;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS fk_delivery_complaint_cases_decided_by_user_id;
ALTER TABLE delivery_complaint_cases DROP CONSTRAINT IF EXISTS fk_delivery_complaint_cases_assigned_user_id;

ALTER TABLE delivery_complaint_cases
    DROP COLUMN IF EXISTS rma_id,
    DROP COLUMN IF EXISTS authorization_request_id,
    DROP COLUMN IF EXISTS decided_at,
    DROP COLUMN IF EXISTS decided_by_user_id,
    DROP COLUMN IF EXISTS findings,
    DROP COLUMN IF EXISTS decision_reason,
    DROP COLUMN IF EXISTS verdict,
    DROP COLUMN IF EXISTS investigation_started_at,
    DROP COLUMN IF EXISTS assigned_at,
    DROP COLUMN IF EXISTS assigned_user_id,
    DROP COLUMN IF EXISTS investigation_status;
