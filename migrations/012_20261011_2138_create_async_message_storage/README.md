# create_async_message_storage

ST-72.3 (ES-72) — persists integration receipts and out-of-order order/shipment data so the async consumers can deduplicate messages and consolidate complete sales orders. The outbox stores outgoing messages until they are published or fail permanently.
