# pod_evidence_metadata

ST-31.5 (ES-200) completes the POD evidence metadata and configures the operational incident
reasons that require a photo. It also adds the customer package rejection reason, which counts as
a delivery attempt. The alert setting is already owned by migration 011 and remains in place on
rollback. OTP values must not be stored in `otp_code` as plaintext.
