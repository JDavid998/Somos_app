# Metabase Queries

This directory contains SQL queries used in Metabase for business intelligence and reporting.

## Structure

- `subscriptions/` - Queries related to subscription analysis and reporting
- `archive/` - Deprecated or problematic queries for reference

## Guidelines

1. Each query file should include:
   - Purpose and description
   - Expected parameters
   - Output description
   - Last tested date
   - Known limitations or issues

2. Use descriptive filenames with version numbers when applicable
3. Document any fixes or optimizations in commit messages
4. Test queries thoroughly before deploying to Metabase

## Database Schema References

The queries in this directory assume the following main tables:
- `subscriptions` - User subscriptions data
- `devices` - Device information and tracking
- `warehouse_items` - Inventory management
- `warehouse_transactions` - Inventory movements
- `warehouse_transaction_items` - Transaction line items
- `purchase_orders` - Purchase order data
- `suppliers` - Supplier information
- `payments` - Payment records
- `invoice_items` - Invoice line items
- `appointments_logs` - Service appointment logs