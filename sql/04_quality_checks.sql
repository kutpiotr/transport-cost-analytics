-- ============================================================
-- Transport Cost Analytics – Data Quality Checks
-- Run BEFORE cleansing to document baseline issues
-- ============================================================

-- ============================================================
-- 1. NULL CHECKS
-- ============================================================

-- Shipments with NULL weight (should always be provided)
SELECT 'shipments.weight_kg IS NULL' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments
WHERE  weight_kg IS NULL;

-- Shipments with NULL actual_delivery but status = 'delivered'
SELECT 'delivered but no actual_delivery' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments
WHERE  status = 'delivered'
  AND  actual_delivery IS NULL;

-- Shipments missing a cost record
SELECT 'shipments without cost record' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments s
LEFT   JOIN costs c ON s.shipment_id = c.shipment_id
WHERE  c.cost_id IS NULL
  AND  s.status <> 'cancelled';

-- Routes with NULL or zero distance
SELECT 'routes with distance <= 0' AS check_name,
       COUNT(*) AS issue_count
FROM   routes
WHERE  distance_km IS NULL OR distance_km <= 0;

-- ============================================================
-- 2. OUT-OF-RANGE / INVALID VALUES
-- ============================================================

-- Negative weight
SELECT 'negative weight_kg' AS check_name,
       COUNT(*) AS issue_count,
       MIN(weight_kg) AS min_val,
       MAX(weight_kg) AS max_val
FROM   shipments
WHERE  weight_kg < 0;

-- Unrealistically heavy shipments (> 40 000 kg — max truck payload)
SELECT 'weight_kg > 40000 kg' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments
WHERE  weight_kg > 40000;

-- Negative cost components
SELECT 'negative cost components' AS check_name,
       COUNT(*) AS issue_count
FROM   costs
WHERE  fuel_cost < 0 OR toll_cost < 0 OR labour_cost < 0 OR other_cost < 0;

-- Actual delivery before shipment date (time-travel bug)
SELECT 'actual_delivery before shipment_date' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments
WHERE  actual_delivery IS NOT NULL
  AND  actual_delivery < shipment_date;

-- Expected delivery before shipment date
SELECT 'expected_delivery before shipment_date' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments
WHERE  expected_delivery < shipment_date;

-- ============================================================
-- 3. DUPLICATE DETECTION
-- ============================================================

-- Duplicate cost records (same shipment_id appears more than once)
SELECT 'duplicate cost rows (same shipment_id)' AS check_name,
       COUNT(*) AS issue_count
FROM (
    SELECT shipment_id
    FROM   costs
    GROUP  BY shipment_id
    HAVING COUNT(*) > 1
) dup;

-- List of duplicated shipment_ids in costs
SELECT shipment_id,
       COUNT(*) AS row_count
FROM   costs
GROUP  BY shipment_id
HAVING COUNT(*) > 1
ORDER  BY row_count DESC
LIMIT  20;

-- Near-duplicate shipments (same carrier, route, date, weight)
SELECT 'near-duplicate shipments' AS check_name,
       COUNT(*) AS issue_count
FROM (
    SELECT carrier_id, route_id, shipment_date, weight_kg
    FROM   shipments
    GROUP  BY carrier_id, route_id, shipment_date, weight_kg
    HAVING COUNT(*) > 1
) nd;

-- ============================================================
-- 4. REFERENTIAL INTEGRITY CHECKS
-- ============================================================

-- Shipments referencing non-existent carriers
SELECT 'orphan carrier_id in shipments' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments s
WHERE  NOT EXISTS (SELECT 1 FROM carriers c WHERE c.carrier_id = s.carrier_id);

-- Shipments referencing non-existent routes
SELECT 'orphan route_id in shipments' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments s
WHERE  NOT EXISTS (SELECT 1 FROM routes r WHERE r.route_id = s.route_id);

-- Delays referencing non-existent shipments
SELECT 'orphan shipment_id in delays' AS check_name,
       COUNT(*) AS issue_count
FROM   delays d
WHERE  NOT EXISTS (SELECT 1 FROM shipments s WHERE s.shipment_id = d.shipment_id);

-- ============================================================
-- 5. BUSINESS-RULE CHECKS
-- ============================================================

-- Shipments assigned to inactive carriers
SELECT 'shipments with inactive carrier' AS check_name,
       COUNT(*) AS issue_count
FROM   shipments s
JOIN   carriers  c ON s.carrier_id = c.carrier_id
WHERE  c.is_active = FALSE;

-- Delays recorded for on-time or non-delivered shipments
SELECT 'delays for non-late deliveries' AS check_name,
       COUNT(*) AS issue_count
FROM   delays d
JOIN   shipments s ON d.shipment_id = s.shipment_id
WHERE  s.actual_delivery IS NULL
   OR  s.actual_delivery <= s.expected_delivery;

-- ============================================================
-- 6. SUMMARY DASHBOARD  (quick overview)
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM shipments)                                     AS total_shipments,
    (SELECT COUNT(*) FROM shipments WHERE weight_kg IS NULL)             AS null_weight,
    (SELECT COUNT(*) FROM shipments WHERE weight_kg < 0)                 AS negative_weight,
    (SELECT COUNT(*) FROM costs GROUP BY shipment_id HAVING COUNT(*)>1)  AS dup_cost_groups,
    (SELECT COUNT(*) FROM delays)                                        AS total_delays,
    (SELECT COUNT(*) FROM shipments WHERE status = 'delivered')          AS delivered_count;
