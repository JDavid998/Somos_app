-- Validation Queries for Subscription Analysis
-- Use these queries to validate the corrected subscription analysis query

-- Query 1: Validate subscription counts by month
-- This should match the total_subs values in the main query
SELECT 
    TO_CHAR(s.start_date, 'YYYY-MM') as start_month,
    COUNT(*) as total_subscriptions
FROM subscriptions s 
INNER JOIN services se ON s.service_id = se.id 
LEFT JOIN devices d ON s.id = d.subscription_id AND d.brand = 'PHANTOM WIFI 6'
WHERE s.start_date >= '2025-01-01' 
  AND s.billable = true 
  AND s.status != 6 
  AND d.id IS NOT NULL  -- Simplified for validation
GROUP BY TO_CHAR(s.start_date, 'YYYY-MM')
ORDER BY start_month;

-- Query 2: Validate payment counts per subscription
-- Check for subscriptions with multiple payments in the same period
SELECT 
    s.id as subscription_id,
    TO_CHAR(s.start_date, 'YYYY-MM') as start_month,
    p.bill_number as period,
    COUNT(*) as payment_count,
    string_agg(p.id::text, ',' ORDER BY p.paid_at) as payment_ids
FROM subscriptions s 
INNER JOIN invoice_items ii ON s.subscription_id = ii.subscription_id AND ii.charged_days = 30 
INNER JOIN payments p ON ii.invoice_id = p.invoice_id 
WHERE s.start_date >= '2025-01-01'
  AND DATE(p.paid_at - INTERVAL '5 hour') >= s.start_date 
GROUP BY s.id, TO_CHAR(s.start_date, 'YYYY-MM'), p.bill_number
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;

-- Query 3: Check for data integrity issues
-- Verify that subscription IDs in payment_subs exist in subs CTE
WITH subs AS (
    SELECT s.id AS subscription_id
    FROM subscriptions s 
    INNER JOIN services se ON s.service_id = se.id 
    LEFT JOIN devices d ON s.id = d.subscription_id AND d.brand = 'PHANTOM WIFI 6'
    WHERE s.start_date >= '2025-01-01' 
      AND s.billable = true 
      AND s.status != 6 
      AND d.id IS NOT NULL
),
payment_subs AS (
    SELECT DISTINCT ii.subscription_id
    FROM invoice_items ii 
    INNER JOIN payments p ON ii.invoice_id = p.invoice_id
    WHERE ii.charged_days = 30
)
-- Should return no rows if data integrity is maintained
SELECT ps.subscription_id
FROM payment_subs ps
LEFT JOIN subs s ON ps.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL;

-- Query 4: Validate payment period calculation
-- Check if the period filter logic is working correctly
SELECT 
    '2025-01' as test_month,
    DATE_TRUNC('month', CURRENT_DATE)::DATE as current_month_start,
    TO_DATE('2025-01', 'YYYY-MM') as test_month_date,
    ((DATE_TRUNC('month', CURRENT_DATE)::DATE - TO_DATE('2025-01', 'YYYY-MM')) / 30) + 1 as max_period;

-- Query 5: Compare original vs corrected query results (structure only)
-- Use this to verify the corrected query produces expected column types and counts
SELECT 
    'v2_corrected' as query_version,
    COUNT(*) as result_rows,
    COUNT(DISTINCT start_month) as unique_months,
    MIN(percentage) as min_percentage,
    MAX(percentage) as max_percentage,
    AVG(total_subs) as avg_subs_per_month
FROM (
    -- Insert the corrected query results here for comparison
    SELECT 1 as total_subs, '2025-01' as start_month, 1 as period, 
           50.0 as percentage, '1,2,3' as subscription_ids, 2 as payment_count
) comparison;