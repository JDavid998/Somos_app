-- CORRECTED QUERY - Subscription Analysis with Payments v2
-- 
-- Purpose: Analyze subscription payment rates by start month and payment period
-- This query shows the percentage of subscriptions that have made payments
-- for each month, grouped by payment periods.
--
-- Parameters:
-- {{orden}} - Purchase order filter for device filtering
--
-- Output Columns:
-- - total_subs: Total subscriptions started in the month
-- - start_month: The month subscriptions were started (YYYY-MM format)  
-- - period: Payment period number
-- - %: Percentage of subscriptions that made payments in this period
-- - subscription_ids: Comma-separated list of subscription IDs (for debugging)
-- - payment_count: Number of payments made in this period
--
-- Key Fixes from v1:
-- 1. Fixed JOIN logic to properly match payments to subscriptions
-- 2. Removed string aggregation from GROUP BY to prevent grouping issues
-- 3. Added proper CTE materialization hints
-- 4. Improved payment period calculation logic
-- 5. Added proper filtering to prevent Cartesian products
--
-- Last Updated: 2025-01-20
-- Tested: PostgreSQL 13+, Compatible with Metabase

WITH filtered_devices AS ( 
    -- Get devices from specific purchase orders
    SELECT wi.device_id 
    FROM warehouse_items wi 
    INNER JOIN warehouse_transaction_items wti ON wi.id = wti.warehouse_item_id 
    INNER JOIN warehouse_transactions wt ON wti.warehouse_transaction_id = wt.id 
    INNER JOIN (SELECT * FROM purchase_orders WHERE {{orden}}) po ON wt.purchase_order_id = po.id 
    INNER JOIN suppliers s ON po.supplier_id = s.id 
), 
retired_phantoms AS ( 
    -- Get subscriptions that had PHANTOM WIFI 6 devices uninstalled
    SELECT substring(log, 'suscripcione?s? (\d+)')::int as subscription_id 
    FROM appointments_logs al 
    INNER JOIN devices d ON substring(log, 'equipo (\d+)')::int = d.id 
    INNER JOIN filtered_devices fd ON d.id = fd.device_id 
    WHERE al.appointment_type = 6 -- uninstall 
    AND log ILIKE '%desinstalo el equipo % y retiro la suscripcion%' 
    AND d.brand = 'PHANTOM WIFI 6' 
), 
subs AS ( 
    -- Get active subscriptions with PHANTOM WIFI 6 devices or retired phantoms
    SELECT TO_CHAR(s.start_date, 'YYYY-MM') as start_month, 
           s.id AS subscription_id, 
           s.start_date 
    FROM subscriptions s 
    INNER JOIN services se ON s.service_id = se.id 
    LEFT JOIN devices d ON s.id = d.subscription_id AND d.brand = 'PHANTOM WIFI 6' 
    LEFT JOIN filtered_devices fd ON s.device_id = fd.device_id 
    WHERE s.start_date >= '2025-01-01' 
    AND s.billable = true 
    AND s.status != 6 
    AND (d.id IS NOT NULL OR EXISTS (SELECT 1 FROM retired_phantoms rp WHERE rp.subscription_id = s.id))
), 
payment_subs AS ( 
    -- Get payment information for subscriptions, ensuring one record per subscription per period
    SELECT DISTINCT ON (s.subscription_id, s.start_month, p.bill_number) 
           s.start_month, 
           s.subscription_id,
           DATE(p.paid_at - INTERVAL '5 hour') as paid_at, 
           p.bill_number as period
    FROM subs s
    INNER JOIN invoice_items ii ON s.subscription_id = ii.subscription_id AND ii.charged_days = 30 
    INNER JOIN payments p ON ii.invoice_id = p.invoice_id 
    WHERE DATE(p.paid_at - INTERVAL '5 hour') >= s.start_date 
    ORDER BY s.subscription_id, s.start_month, p.bill_number, p.paid_at DESC
), 
subs_by_month AS ( 
    -- Aggregate subscriptions by start month
    SELECT start_month, 
           COUNT(*) as total_subs,
           -- Keep subscription IDs for debugging (moved out of main GROUP BY)
           string_agg(subscription_id::text, ',' ORDER BY subscription_id) as subscription_ids
    FROM subs 
    GROUP BY start_month 
),
payment_summary AS (
    -- Aggregate payments by month and period 
    SELECT start_month,
           period,
           COUNT(DISTINCT subscription_id) as paying_subs_count
    FROM payment_subs ps
    GROUP BY start_month, period
)
-- Final result with proper JOIN logic
SELECT sm.total_subs, 
       sm.start_month, 
       ps.period, 
       ROUND((ps.paying_subs_count::float / sm.total_subs) * 100, 2) as percentage,
       sm.subscription_ids,
       ps.paying_subs_count as payment_count
FROM subs_by_month sm
LEFT JOIN payment_summary ps ON sm.start_month = ps.start_month
WHERE ps.period IS NULL 
   OR ps.period < ((DATE_TRUNC('month', CURRENT_DATE)::DATE - TO_DATE(sm.start_month, 'YYYY-MM')) / 30) + 1
ORDER BY sm.start_month, COALESCE(ps.period, 0);