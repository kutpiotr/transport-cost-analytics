-- ============================================================
-- Transport Cost Analytics – Analytical Views
-- Run AFTER cleansing (05_cleansing.sql)
-- All views are DROP+CREATE for idempotency
-- ============================================================


-- ============================================================
-- VIEW 1: vw_cost_per_km
-- Cost efficiency per carrier and route
-- Added: commit 7 – "sql: view – cost per km by carrier"
-- ============================================================
DROP VIEW IF EXISTS vw_cost_per_km CASCADE;

CREATE VIEW vw_cost_per_km AS
SELECT
    s.shipment_id,
    s.shipment_date,
    c.carrier_id,
    c.carrier_name,
    c.carrier_type,
    c.country_code                                          AS carrier_country,
    r.route_id,
    r.origin_city,
    r.origin_country,
    r.dest_city,
    r.dest_country,
    r.distance_km,
    s.weight_kg,
    s.cargo_type,
    co.fuel_cost,
    co.toll_cost,
    co.labour_cost,
    co.other_cost,
    co.total_cost,
    ROUND(co.total_cost / NULLIF(r.distance_km, 0), 4)     AS cost_per_km,
    ROUND(co.total_cost / NULLIF(s.weight_kg,    0), 4)    AS cost_per_kg,
    DATE_TRUNC('month', s.shipment_date)::DATE             AS shipment_month,
    DATE_TRUNC('quarter', s.shipment_date)::DATE           AS shipment_quarter,
    EXTRACT(YEAR FROM s.shipment_date)::INT                AS shipment_year
FROM      shipments s
JOIN      carriers  c  ON s.carrier_id  = c.carrier_id
JOIN      routes    r  ON s.route_id    = r.route_id
JOIN      costs     co ON s.shipment_id = co.shipment_id
WHERE     s.status  NOT IN ('cancelled', 'lost')
  AND     co.total_cost > 0;

COMMENT ON VIEW vw_cost_per_km IS
    'Cost efficiency metrics per shipment: cost/km, cost/kg, enriched with carrier and route info';


-- ============================================================
-- VIEW 2: vw_on_time_rate
-- Delivery performance per carrier and route
-- Added: commit 8 – "sql: view – on-time delivery rate"
-- ============================================================
DROP VIEW IF EXISTS vw_on_time_rate CASCADE;

CREATE VIEW vw_on_time_rate AS
WITH delivery_base AS (
    SELECT
        s.shipment_id,
        s.carrier_id,
        s.route_id,
        s.shipment_date,
        s.cargo_type,
        s.expected_delivery,
        s.actual_delivery,
        s.status,
        CASE
            WHEN s.actual_delivery IS NOT NULL
             AND s.actual_delivery <= s.expected_delivery THEN 1
            ELSE 0
        END                                                  AS is_on_time,
        CASE
            WHEN s.actual_delivery IS NOT NULL
             AND s.actual_delivery > s.expected_delivery
            THEN (s.actual_delivery - s.expected_delivery)
            ELSE 0
        END                                                  AS days_late,
        DATE_TRUNC('month',   s.shipment_date)::DATE         AS shipment_month,
        DATE_TRUNC('quarter', s.shipment_date)::DATE         AS shipment_quarter,
        EXTRACT(YEAR FROM s.shipment_date)::INT              AS shipment_year
    FROM  shipments s
    WHERE s.status = 'delivered'
)
SELECT
    db.*,
    c.carrier_name,
    c.carrier_type,
    c.country_code    AS carrier_country,
    r.origin_city,
    r.origin_country,
    r.dest_city,
    r.dest_country,
    r.distance_km,
    r.route_type,
    -- Aggregated rates (window functions – useful for Power BI)
    ROUND(
        100.0 * AVG(db.is_on_time) OVER (PARTITION BY db.carrier_id),
        2
    )                 AS carrier_on_time_rate_pct,
    ROUND(
        100.0 * AVG(db.is_on_time) OVER (PARTITION BY db.route_id),
        2
    )                 AS route_on_time_rate_pct,
    ROUND(
        100.0 * AVG(db.is_on_time) OVER (PARTITION BY db.shipment_month),
        2
    )                 AS monthly_on_time_rate_pct
FROM       delivery_base db
JOIN       carriers      c  ON db.carrier_id = c.carrier_id
JOIN       routes        r  ON db.route_id   = r.route_id;

COMMENT ON VIEW vw_on_time_rate IS
    'Delivery performance: on-time flag, days late, and rolling rates by carrier/route/month';


-- ============================================================
-- VIEW 3: vw_monthly_trends
-- Monthly aggregates for trend analysis and forecasting
-- Added: commit 9 – "sql: view – monthly cost trends"
-- ============================================================
DROP VIEW IF EXISTS vw_monthly_trends CASCADE;

CREATE VIEW vw_monthly_trends AS
WITH monthly_base AS (
    SELECT
        DATE_TRUNC('month', s.shipment_date)::DATE            AS month,
        EXTRACT(YEAR  FROM s.shipment_date)::INT              AS year,
        EXTRACT(MONTH FROM s.shipment_date)::INT              AS month_num,
        c.carrier_id,
        c.carrier_name,
        c.carrier_type,
        r.route_type,
        r.origin_country,
        r.dest_country,

        -- Volume KPIs
        COUNT(s.shipment_id)                                  AS shipment_count,
        SUM(s.weight_kg)                                      AS total_weight_kg,

        -- Cost KPIs
        SUM(co.total_cost)                                    AS total_cost,
        AVG(co.total_cost)                                    AS avg_cost_per_shipment,
        SUM(co.fuel_cost)                                     AS total_fuel_cost,
        SUM(co.toll_cost)                                     AS total_toll_cost,
        SUM(co.labour_cost)                                   AS total_labour_cost,
        SUM(co.other_cost)                                    AS total_other_cost,
        ROUND(SUM(co.total_cost) / NULLIF(SUM(r.distance_km), 0), 4)
                                                              AS avg_cost_per_km,

        -- Delivery KPIs
        SUM(CASE WHEN s.status = 'delivered' THEN 1 ELSE 0 END)          AS delivered_count,
        SUM(CASE WHEN s.actual_delivery <= s.expected_delivery
                  AND s.status = 'delivered' THEN 1 ELSE 0 END)          AS on_time_count,
        SUM(CASE WHEN s.actual_delivery > s.expected_delivery
                  AND s.status = 'delivered' THEN 1 ELSE 0 END)          AS late_count,
        SUM(CASE WHEN s.status = 'cancelled' THEN 1 ELSE 0 END)          AS cancelled_count,

        -- Delay KPIs
        COUNT(DISTINCT d.delay_id)                            AS delay_incidents,
        SUM(COALESCE(d.delay_days, 0))                        AS total_delay_days,
        SUM(COALESCE(d.delay_cost, 0))                        AS total_delay_cost

    FROM       shipments s
    JOIN       carriers  c  ON s.carrier_id  = c.carrier_id
    JOIN       routes    r  ON s.route_id    = r.route_id
    JOIN       costs     co ON s.shipment_id = co.shipment_id
    LEFT JOIN  delays    d  ON s.shipment_id = d.shipment_id
    GROUP BY
        DATE_TRUNC('month', s.shipment_date),
        EXTRACT(YEAR  FROM s.shipment_date),
        EXTRACT(MONTH FROM s.shipment_date),
        c.carrier_id, c.carrier_name, c.carrier_type,
        r.route_type, r.origin_country, r.dest_country
)
SELECT
    mb.*,
    ROUND(100.0 * on_time_count  / NULLIF(delivered_count, 0), 2) AS on_time_rate_pct,
    ROUND(100.0 * late_count     / NULLIF(delivered_count, 0), 2) AS late_rate_pct,
    ROUND(100.0 * cancelled_count / NULLIF(shipment_count, 0), 2) AS cancellation_rate_pct,
    -- MoM cost change (lag window)
    LAG(total_cost) OVER (
        PARTITION BY carrier_id, route_type
        ORDER BY month
    )                                                              AS prev_month_cost,
    ROUND(
        100.0 * (total_cost - LAG(total_cost) OVER (
            PARTITION BY carrier_id, route_type ORDER BY month
        )) / NULLIF(LAG(total_cost) OVER (
            PARTITION BY carrier_id, route_type ORDER BY month
        ), 0),
    2)                                                             AS mom_cost_change_pct
FROM monthly_base mb
ORDER BY month, carrier_id;

COMMENT ON VIEW vw_monthly_trends IS
    'Monthly aggregated KPIs by carrier: costs, volumes, on-time rates, MoM change. Use for trend charts and Power BI forecasting.';


-- ============================================================
-- HELPER VIEW: vw_kpi_summary
-- Single-row executive summary (for Power BI KPI cards)
-- ============================================================
DROP VIEW IF EXISTS vw_kpi_summary CASCADE;

CREATE VIEW vw_kpi_summary AS
SELECT
    COUNT(DISTINCT s.shipment_id)                              AS total_shipments,
    SUM(co.total_cost)                                         AS total_cost_eur,
    ROUND(AVG(co.total_cost), 2)                               AS avg_cost_per_shipment,
    ROUND(SUM(co.total_cost) / NULLIF(SUM(r.distance_km),0),4) AS overall_cost_per_km,
    ROUND(
        100.0 * SUM(CASE WHEN s.actual_delivery <= s.expected_delivery
                          AND s.status = 'delivered' THEN 1 ELSE 0 END)
              / NULLIF(SUM(CASE WHEN s.status = 'delivered' THEN 1 ELSE 0 END), 0),
        2
    )                                                          AS on_time_rate_pct,
    ROUND(
        100.0 * COUNT(DISTINCT d.shipment_id)
              / NULLIF(COUNT(DISTINCT s.shipment_id), 0),
        2
    )                                                          AS delay_rate_pct,
    MIN(s.shipment_date)                                       AS data_from,
    MAX(s.shipment_date)                                       AS data_to
FROM      shipments s
JOIN      costs     co ON s.shipment_id = co.shipment_id
JOIN      routes    r  ON s.route_id    = r.route_id
LEFT JOIN delays    d  ON s.shipment_id = d.shipment_id
WHERE     s.status NOT IN ('cancelled', 'lost');

COMMENT ON VIEW vw_kpi_summary IS
    'Single-row executive KPI summary for Power BI card visuals';
