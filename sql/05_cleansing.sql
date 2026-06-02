-- ============================================================
-- Transport Cost Analytics – Data Cleansing Scripts
-- Run AFTER 04_quality_checks.sql to fix identified issues
-- Each section is idempotent (safe to re-run)
-- ============================================================

BEGIN;

-- ============================================================
-- 1. FIX NEGATIVE WEIGHTS
--    Strategy: take absolute value (data-entry sign error)
-- ============================================================
UPDATE shipments
SET    weight_kg = ABS(weight_kg)
WHERE  weight_kg < 0;

DO $$ BEGIN
    RAISE NOTICE 'Step 1 complete: negative weights corrected';
END $$;

-- ============================================================
-- 2. HANDLE NULL WEIGHTS
--    Strategy: impute with median weight for the same cargo_type
--    (preserves distribution shape better than mean)
-- ============================================================
WITH medians AS (
    SELECT cargo_type,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY weight_kg) AS median_weight
    FROM   shipments
    WHERE  weight_kg IS NOT NULL
    GROUP  BY cargo_type
)
UPDATE shipments s
SET    weight_kg = m.median_weight
FROM   medians m
WHERE  s.weight_kg IS NULL
  AND  s.cargo_type = m.cargo_type;

-- Fallback: if still NULL (no peers), use global median
UPDATE shipments
SET    weight_kg = (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY weight_kg)
    FROM   shipments
    WHERE  weight_kg IS NOT NULL
)
WHERE  weight_kg IS NULL;

DO $$ BEGIN
    RAISE NOTICE 'Step 2 complete: NULL weights imputed with cargo-type median';
END $$;

-- ============================================================
-- 3. REMOVE DUPLICATE COST RECORDS
--    Keep the row with the lowest cost_id (first inserted)
-- ============================================================
DELETE FROM costs
WHERE  cost_id NOT IN (
    SELECT MIN(cost_id)
    FROM   costs
    GROUP  BY shipment_id
);

DO $$ BEGIN
    RAISE NOTICE 'Step 3 complete: duplicate cost rows removed';
END $$;

-- ============================================================
-- 4. FIX STATUS FOR DELIVERED SHIPMENTS WITHOUT actual_delivery
--    Strategy: set actual_delivery = expected_delivery
--    (conservative — assume on-time)
-- ============================================================
UPDATE shipments
SET    actual_delivery = expected_delivery
WHERE  status = 'delivered'
  AND  actual_delivery IS NULL;

DO $$ BEGIN
    RAISE NOTICE 'Step 4 complete: delivered shipments missing actual_delivery patched';
END $$;

-- ============================================================
-- 5. FIX TIME-TRAVEL DATES
--    actual_delivery < shipment_date → set to shipment_date + 1
-- ============================================================
UPDATE shipments
SET    actual_delivery = shipment_date + INTERVAL '1 day'
WHERE  actual_delivery IS NOT NULL
  AND  actual_delivery < shipment_date;

DO $$ BEGIN
    RAISE NOTICE 'Step 5 complete: impossible delivery dates corrected';
END $$;

-- ============================================================
-- 6. STANDARDISE CARRIER NAMES (trim whitespace, proper case)
--    No name issues in this dataset, but script is defensive
-- ============================================================
UPDATE carriers
SET    carrier_name  = TRIM(carrier_name),
       contact_email = LOWER(TRIM(contact_email))
WHERE  carrier_name  <> TRIM(carrier_name)
   OR  contact_email <> LOWER(TRIM(contact_email));

DO $$ BEGIN
    RAISE NOTICE 'Step 6 complete: carrier names/emails standardised';
END $$;

-- ============================================================
-- 7. REMOVE SHIPMENTS FOR INACTIVE CARRIERS
--    Strategy: reassign to most similar active carrier by type
--    (in production you'd flag for manual review; here we reassign)
-- ============================================================
-- First, identify the most-used active carrier of the same type
WITH replacement AS (
    SELECT c_inactive.carrier_id AS old_id,
           (
               SELECT c2.carrier_id
               FROM   carriers c2
               WHERE  c2.carrier_type = c_inactive.carrier_type
                 AND  c2.is_active    = TRUE
               ORDER  BY c2.carrier_id
               LIMIT  1
           ) AS new_id
    FROM   carriers c_inactive
    WHERE  c_inactive.is_active = FALSE
)
UPDATE shipments s
SET    carrier_id = r.new_id
FROM   replacement r
WHERE  s.carrier_id = r.old_id
  AND  r.new_id IS NOT NULL;

DO $$ BEGIN
    RAISE NOTICE 'Step 7 complete: shipments reassigned away from inactive carriers';
END $$;

-- ============================================================
-- 8. REMOVE COST RECORDS WITH ALL-ZERO COMPONENTS
--    (likely dummy / placeholder rows)
-- ============================================================
DELETE FROM costs
WHERE  fuel_cost = 0
  AND  toll_cost = 0
  AND  labour_cost = 0
  AND  other_cost = 0;

DO $$ BEGIN
    RAISE NOTICE 'Step 8 complete: all-zero cost records removed';
END $$;

-- ============================================================
-- 9. FLAG OUTLIER SHIPMENTS (rather than delete)
--    weight > 35 000 kg → add note to cargo_type prefix
-- ============================================================
UPDATE shipments
SET    cargo_type = 'oversized'
WHERE  weight_kg > 35000
  AND  cargo_type <> 'oversized';

DO $$ BEGIN
    RAISE NOTICE 'Step 9 complete: extreme weight shipments reclassified as oversized';
END $$;

-- ============================================================
-- 10. POST-CLEANSING VALIDATION SUMMARY
-- ============================================================
SELECT
    'After cleansing' AS phase,
    COUNT(*)                                                    AS total_shipments,
    SUM(CASE WHEN weight_kg IS NULL  THEN 1 ELSE 0 END)        AS null_weight_remaining,
    SUM(CASE WHEN weight_kg < 0      THEN 1 ELSE 0 END)        AS negative_weight_remaining,
    (SELECT COUNT(*) FROM costs)                                AS cost_rows,
    (SELECT COUNT(shipment_id) FROM costs
     GROUP BY shipment_id HAVING COUNT(*) > 1)                 AS duplicate_costs_remaining
FROM shipments;

COMMIT;
