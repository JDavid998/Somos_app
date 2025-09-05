# Subscription Analysis Query Fix Documentation

## Problem Identified

The original subscription analysis query had critical data integrity issues when the ORDER BY clause was applied in the final SELECT statement. The issue manifested as incorrect or missing subscription data in the results.

## Root Cause Analysis

### Issue 1: Incorrect JOIN Logic in Final SELECT
The original query performed a LEFT JOIN between `subs_start_month` and `payment_subs` using only the `start_month` field:

```sql
FROM subs_start_month ssm 
LEFT JOIN payment_subs ps ON ps.start_month = ssm.start_month
```

**Problem**: This created a Cartesian product where each subscription in a given month was matched against ALL payments from that same month, regardless of which subscription made the payment. This caused incorrect percentage calculations and data duplication.

### Issue 2: String Aggregation in GROUP BY
The original query included `agregation` (a comma-separated list of subscription IDs) in the GROUP BY clause:

```sql
GROUP BY ssm.start_month, period, agregation, ssm.total_subs
```

**Problem**: This caused unexpected grouping behavior because different combinations of subscription IDs created separate groups, leading to incorrect aggregations.

### Issue 3: DISTINCT ON Ambiguity
The `payment_subs` CTE used `DISTINCT ON` without ensuring deterministic results:

```sql
SELECT DISTINCT ON (subs.subscription_id, start_month, bill_number)
```

**Problem**: When multiple payments existed for the same subscription in the same period, the query didn't specify which payment to keep, leading to inconsistent results.

### Issue 4: CTE Materialization Order
PostgreSQL's query planner was optimizing the query in a way that the ORDER BY clause affected the materialization of the CTEs, causing the `subs` CTE to not reflect the actual subscription data.

## Solution Implementation

### Fix 1: Corrected JOIN Logic
**Before**:
```sql
FROM subs_start_month ssm 
LEFT JOIN payment_subs ps ON ps.start_month = ssm.start_month
```

**After**:
```sql
FROM subs_by_month sm
LEFT JOIN payment_summary ps ON sm.start_month = ps.start_month
```

The new approach:
1. Creates `subs_by_month` with aggregated subscription counts per month
2. Creates `payment_summary` with aggregated payment counts per month and period
3. Joins these aggregated results, eliminating the Cartesian product issue

### Fix 2: Removed String Aggregation from GROUP BY
**Before**:
```sql
GROUP BY ssm.start_month, period, agregation, ssm.total_subs
```

**After**:
```sql
-- Moved string_agg to separate CTE for debugging purposes only
string_agg(subscription_id::text, ',' ORDER BY subscription_id) as subscription_ids
-- Not included in GROUP BY of final query
```

### Fix 3: Deterministic DISTINCT ON
**Before**:
```sql
SELECT DISTINCT ON (subs.subscription_id, start_month, bill_number)
ORDER BY subs.subscription_id, start_month, bill_number
```

**After**:
```sql
SELECT DISTINCT ON (s.subscription_id, s.start_month, p.bill_number)
ORDER BY s.subscription_id, s.start_month, p.bill_number, p.paid_at DESC
```

Added `p.paid_at DESC` to ensure the most recent payment is selected when duplicates exist.

### Fix 4: Proper CTE Structure
Reorganized CTEs to ensure proper materialization:
1. `filtered_devices` - Device filtering (unchanged)
2. `retired_phantoms` - Phantom device tracking (unchanged)
3. `subs` - Base subscription data (simplified)
4. `payment_subs` - Payment data with proper subscription matching
5. `subs_by_month` - Aggregated subscription counts
6. `payment_summary` - Aggregated payment counts
7. Final SELECT with proper JOIN logic

## Key Changes Summary

| Component | Original Issue | Fix Applied |
|-----------|---------------|-------------|
| Final JOIN | Cartesian product on start_month only | Proper aggregated JOIN |
| GROUP BY | Included string aggregation | Removed problematic fields |
| DISTINCT ON | Non-deterministic selection | Added ordering by paid_at |
| CTE Structure | Complex interdependencies | Simplified with clear separation |
| Percentage Calculation | Based on inflated counts | Based on actual unique subscriptions |

## Validation

The corrected query provides:
1. **Accurate subscription counts** by month
2. **Correct payment percentages** based on actual subscription-to-payment relationships  
3. **Deterministic results** that don't change based on ORDER BY clauses
4. **Consistent data integrity** across multiple query executions

## Performance Considerations

The new query structure should perform better because:
1. Eliminates Cartesian products
2. Uses proper aggregation at CTE level
3. Reduces the number of rows processed in final JOIN
4. Provides clearer execution plan for PostgreSQL optimizer

## Testing Recommendations

Before deploying to Metabase:
1. Run validation queries to verify subscription counts
2. Compare percentage calculations with manual verification
3. Test with different ORDER BY clauses to ensure consistency
4. Verify performance on production data size