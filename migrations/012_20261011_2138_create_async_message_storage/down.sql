DROP TRIGGER IF EXISTS trg_outbound_messages_set_updated_at ON outbound_messages;
DROP FUNCTION IF EXISTS fn_outbound_messages_set_updated_at();
DROP TRIGGER IF EXISTS trg_inbound_messages_set_updated_at ON inbound_messages;
DROP FUNCTION IF EXISTS fn_inbound_messages_set_updated_at();
DROP TRIGGER IF EXISTS trg_pending_shipments_set_updated_at ON pending_shipments;
DROP FUNCTION IF EXISTS fn_pending_shipments_set_updated_at();
DROP TRIGGER IF EXISTS trg_pending_sales_orders_set_updated_at ON pending_sales_orders;
DROP FUNCTION IF EXISTS fn_pending_sales_orders_set_updated_at();

DROP TABLE IF EXISTS outbound_messages;
DROP TABLE IF EXISTS pending_shipments;
DROP TABLE IF EXISTS pending_sales_orders;
DROP TABLE IF EXISTS inbound_messages;
DROP TABLE IF EXISTS outbound_message_statuses;
DROP TABLE IF EXISTS inbound_message_statuses;
