DROP TRIGGER IF EXISTS trg_warehouse_receipt_items_set_updated_at ON warehouse_receipt_items;
DROP FUNCTION IF EXISTS fn_warehouse_receipt_items_set_updated_at();
DROP TABLE IF EXISTS warehouse_receipt_items;

DROP TRIGGER IF EXISTS trg_warehouse_receipts_set_updated_at ON warehouse_receipts;
DROP FUNCTION IF EXISTS fn_warehouse_receipts_set_updated_at();
DROP TABLE IF EXISTS warehouse_receipts;
