# Metabase Implementation Guide

## Deploying the Corrected Subscription Analysis Query

### Step 1: Backup Current Query
Before implementing the fix, save a backup of your current Metabase query:
1. Open the problematic query in Metabase
2. Copy the SQL to a text file
3. Save it with the current date for reference

### Step 2: Implement the Corrected Query
1. Navigate to your Metabase dashboard
2. Open the subscription analysis query
3. Replace the existing SQL with the content from `subscription_analysis_with_payments_v2.sql`
4. Ensure the parameter `{{orden}}` is properly configured in Metabase

### Step 3: Parameter Configuration
Verify the Metabase parameter settings:
- **Variable name**: `orden`
- **Variable type**: Number or Text (depending on your purchase_orders.id type)
- **Default value**: Set an appropriate default value for testing

### Step 4: Validation Testing
Before saving, run these validation steps:

1. **Test with known data**:
   - Use a specific `{{orden}}` value that you know has data
   - Compare results with manual database queries
   - Verify subscription counts match expected values

2. **Test ORDER BY functionality**:
   - Run the query with default ORDER BY
   - Change the ORDER BY clause (if Metabase allows)
   - Verify results remain consistent

3. **Test edge cases**:
   - Empty result sets (orden with no data)
   - Months with no payments
   - Months with 100% payment rates

### Step 5: Performance Testing
1. **Check query execution time**:
   - Note the execution time of the new query
   - Compare with the original query performance
   - If significantly slower, consider adding database indexes

2. **Recommended indexes** (consult with your DBA):
   ```sql
   -- Indexes to improve query performance
   CREATE INDEX IF NOT EXISTS idx_subscriptions_start_date_billable_status 
   ON subscriptions(start_date, billable, status);
   
   CREATE INDEX IF NOT EXISTS idx_devices_subscription_brand 
   ON devices(subscription_id, brand);
   
   CREATE INDEX IF NOT EXISTS idx_invoice_items_subscription_charged_days 
   ON invoice_items(subscription_id, charged_days);
   
   CREATE INDEX IF NOT EXISTS idx_payments_invoice_paid_at 
   ON payments(invoice_id, paid_at);
   ```

### Step 6: Documentation Update
1. Update any Metabase dashboard descriptions
2. Add notes about the query fix and date implemented
3. Document any parameter changes or new requirements

### Step 7: Stakeholder Communication
Inform relevant stakeholders about:
- The fix implementation
- Any changes in result format or values
- New validation procedures
- Performance improvements

## Troubleshooting

### Common Issues and Solutions

1. **"Column doesn't exist" errors**:
   - Verify all table names match your database schema
   - Check that column names are correct (especially `bill_number` in payments table)

2. **Parameter not working**:
   - Ensure `{{orden}}` is defined in Metabase parameters
   - Check that the parameter type matches your `purchase_orders.id` column type

3. **No results returned**:
   - Verify the date filter (`start_date >= '2025-01-01'`)
   - Check that test data exists in the expected date range
   - Validate that the `{{orden}}` parameter has associated data

4. **Performance issues**:
   - Consider adding the recommended indexes
   - If the query is still slow, consider breaking it into smaller parts
   - Contact your DBA for query plan analysis

### Rollback Plan
If issues occur after deployment:
1. Immediately restore the backup query (despite its issues)
2. Document the specific problem encountered
3. Review the validation queries to understand the root cause
4. Implement fixes and re-test in a development environment

## Monitoring
After deployment, monitor:
- Query execution times
- Result accuracy compared to known benchmarks
- User feedback on data quality
- Any error reports from Metabase

## Support Contact
For technical issues with this implementation:
1. Check the validation queries first
2. Review the query fix explanation documentation
3. Consult with your database administrator
4. If needed, refer back to the original problematic query for comparison

## Version History
- **v1.0 (Original)**: Problematic query with ORDER BY issues
- **v2.0 (Current)**: Corrected query with proper JOIN logic and CTE structure
- **Future versions**: Document any additional optimizations or fixes