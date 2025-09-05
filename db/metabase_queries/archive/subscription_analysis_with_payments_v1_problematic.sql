-- PROBLEMATIC QUERY - DO NOT USE IN PRODUCTION
-- This query has data integrity issues with ORDER BY affecting CTE results
-- See subscription_analysis_with_payments_v2.sql for the corrected version
-- 
-- Issue Description:
-- When ORDER BY is applied in the final SELECT, the data in the 'subs' CTE
-- does not show real subscription information, causing incorrect results.
-- 
-- Specific Problems:
-- 1. ORDER BY clause interfering with CTE data integrity
-- 2. Complex JOINs between CTEs causing cardinality issues
-- 3. DISTINCT ON in payment_subs may be dropping necessary data
-- 4. LEFT JOIN in final SELECT may be producing unexpected results
--
-- Date: Original query causing issues
-- Status: DEPRECATED - Use v2 instead

WITH filtered_devices AS ( 
    SELECT wi.device_id 
    FROM warehouse_items wi 
    INNER JOIN warehouse_transaction_items wti ON wi.id = wti.warehouse_item_id 
    INNER JOIN warehouse_transactions wt ON wti.warehouse_transaction_id = wt.id 
    INNER JOIN (SELECT * FROM purchase_orders WHERE {{orden}}) po ON wt.purchase_order_id = po.id 
    INNER JOIN suppliers s ON po.supplier_id = s.id 
    -- WHERE po.id =1517 
), 
retired_phantoms AS ( 
    SELECT substring(log, 'suscripcione?s? (\d+)')::int as subscription_id 
    FROM appointments_logs al 
    INNER JOIN devices d ON substring(log, 'equipo (\d+)')::int = d.id 
    INNER JOIN filtered_devices fd ON d.id=fd.device_id 
    WHERE al.appointment_type = 6 -- uninstall 
    AND log ILIKE '%desinstalo el equipo % y retiro la suscripcion%' 
    AND d.brand = 'PHANTOM WIFI 6' 
), 
subs AS ( 
    SELECT TO_CHAR(s.start_date, 'YYYY-MM') start_month, 
           s.id AS subscription_id, 
           s.start_date 
    FROM subscriptions s 
    INNER JOIN services se on s.service_id = se.id 
    LEFT JOIN devices d ON s.id = d.subscription_id AND d.brand = 'PHANTOM WIFI 6' 
    LEFT JOIN filtered_devices fd ON s.device_id=fd.device_id 
    --category IN (2, 3) 
    WHERE start_date >= '2025-01-01' 
    AND s.billable = true 
    AND s.status !=6 
    AND (d.id IS NOT NULL OR EXISTS (SELECT 1 FROM retired_phantoms rp WHERE rp.subscription_id = s.id )) 
), 
payment_subs AS ( 
    SELECT DISTINCT ON (subs.subscription_id, start_month, bill_number) 
           start_month, 
           DATE(p.paid_at - INTERVAL '5 hour') paid_at, 
           bill_number period, 
           subs.subscription_id 
    FROM subs 
    INNER JOIN invoice_items ii ON subs.subscription_id = ii.subscription_id AND ii.charged_days = 30 
    INNER JOIN payments p ON ii.invoice_id = p.invoice_id 
    WHERE DATE(p.paid_at - INTERVAL '5 hour') >= start_date 
    -- GROUP BY start_month, bill_number 
    ORDER BY subs.subscription_id, start_month, bill_number 
), 
subs_start_month AS ( 
    SELECT start_month, 
           COUNT(*) total_subs, 
           string_agg(subscription_id::text, ',') AS agregation 
    FROM subs 
    GROUP BY start_month 
    ORDER BY start_month 
) 
SELECT ssm.total_subs, 
       ssm.start_month, 
       period, 
       (COUNT(*)::float / MAX(ssm.total_subs))*100 "%", 
       agregation, 
       COUNT(*) 
FROM subs_start_month ssm 
LEFT JOIN payment_subs ps ON ps.start_month = ssm.start_month 
WHERE period < ((DATE_TRUNC('month', current_date)::DATE - to_date(ssm.start_month, 'YYYY-MM'))/30) + 1 
GROUP BY ssm.start_month, period, agregation, ssm.total_subs 
ORDER BY ssm.start_month, period;