# Data Dictionary – Transport Cost Analytics

> Database: PostgreSQL 15+  
> Schema: `public`  
> Last updated: 2024

---

## Tables

### `carriers`

Logistics companies executing the shipments. Dimension table.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `carrier_id` | SERIAL | NOT NULL | Primary key, auto-increment |
| `carrier_name` | VARCHAR(100) | NOT NULL | Full company name |
| `country_code` | CHAR(2) | NOT NULL | ISO 3166-1 alpha-2 country code (e.g. `PL`, `DE`) |
| `carrier_type` | VARCHAR(50) | NOT NULL | Transport mode: `road`, `rail`, `air`, `sea` |
| `contact_email` | VARCHAR(150) | NULL | Operational contact email |
| `is_active` | BOOLEAN | NOT NULL | `TRUE` = active carrier; `FALSE` = deprecated/inactive |
| `created_at` | TIMESTAMP | NOT NULL | Row creation timestamp (defaults to NOW()) |

**Notes:**
- Shipments must only reference carriers where `is_active = TRUE` (enforced in cleansing script).
- 10 carriers seeded; carrier_id 10 (`BalticCargo UAB`) is intentionally inactive for QA demo.

---

### `routes`

Pre-defined origin–destination city pairs with static distance. Dimension table.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `route_id` | SERIAL | NOT NULL | Primary key |
| `origin_city` | VARCHAR(100) | NOT NULL | Departure city name |
| `origin_country` | CHAR(2) | NOT NULL | ISO country code of origin |
| `dest_city` | VARCHAR(100) | NOT NULL | Destination city name |
| `dest_country` | CHAR(2) | NOT NULL | ISO country code of destination |
| `distance_km` | NUMERIC(8,2) | NOT NULL | Route distance in kilometres (road distance or great-circle) |
| `route_type` | VARCHAR(50) | NOT NULL | `domestic` (same country) or `international` |
| `created_at` | TIMESTAMP | NOT NULL | Row creation timestamp |

**Notes:**
- 30 routes seeded, covering major European logistics corridors.
- `distance_km` is static (not recalculated per shipment). For sea/air routes this is an approximation.

---

### `shipments`

Individual shipment events. Central fact table.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `shipment_id` | SERIAL | NOT NULL | Primary key |
| `carrier_id` | INT | NOT NULL | FK → `carriers.carrier_id` |
| `route_id` | INT | NOT NULL | FK → `routes.route_id` |
| `shipment_date` | DATE | NOT NULL | Date the shipment was dispatched |
| `weight_kg` | NUMERIC(10,2) | NOT NULL | Gross weight in kilograms |
| `volume_m3` | NUMERIC(10,3) | NULL | Volume in cubic metres (optional) |
| `cargo_type` | VARCHAR(50) | NOT NULL | `general`, `refrigerated`, `hazardous`, `fragile`, `oversized` |
| `expected_delivery` | DATE | NOT NULL | Contractual delivery date agreed at booking |
| `actual_delivery` | DATE | NULL | Actual delivery date; `NULL` if not yet delivered |
| `status` | VARCHAR(30) | NOT NULL | `in_transit`, `delivered`, `cancelled`, `lost` |
| `created_at` | TIMESTAMP | NOT NULL | Row creation timestamp |

**Business rules:**
- `actual_delivery` must be ≥ `shipment_date`
- `expected_delivery` must be ≥ `shipment_date`
- For status = `delivered`, `actual_delivery` must be populated (enforced in 05_cleansing.sql)
- `weight_kg` must be > 0 (negatives corrected in cleansing)

---

### `costs`

Financial cost breakdown per shipment. One-to-one with `shipments`.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `cost_id` | SERIAL | NOT NULL | Primary key |
| `shipment_id` | INT | NOT NULL | FK → `shipments.shipment_id` (UNIQUE — one row per shipment) |
| `fuel_cost` | NUMERIC(10,2) | NOT NULL | Fuel expense in EUR |
| `toll_cost` | NUMERIC(10,2) | NOT NULL | Road/bridge toll expense in EUR |
| `labour_cost` | NUMERIC(10,2) | NOT NULL | Driver and handling labour cost in EUR |
| `other_cost` | NUMERIC(10,2) | NOT NULL | Miscellaneous costs (customs, packaging, etc.) |
| `total_cost` | NUMERIC(10,2) | COMPUTED | `fuel + toll + labour + other` (generated column) |
| `currency` | CHAR(3) | NOT NULL | ISO 4217 currency code (default `EUR`) |
| `recorded_at` | TIMESTAMP | NOT NULL | Record insertion timestamp |

**Notes:**
- `total_cost` is a PostgreSQL `GENERATED ALWAYS AS ... STORED` column — never update it directly.
- Seed data contains ~29 intentional duplicate rows (same `shipment_id`) removed by 05_cleansing.sql.

---

### `delays`

Delay incidents linked to shipments. One shipment may have multiple delay records (e.g. weather then customs).

| Column | Type | Nullable | Description |
|---|---|---|---|
| `delay_id` | SERIAL | NOT NULL | Primary key |
| `shipment_id` | INT | NOT NULL | FK → `shipments.shipment_id` |
| `delay_days` | INT | NOT NULL | Number of calendar days delayed (must be > 0) |
| `delay_reason` | VARCHAR(100) | NOT NULL | Reason category (see allowed values below) |
| `delay_cost` | NUMERIC(10,2) | NULL | Additional cost incurred due to delay (EUR) |
| `reported_at` | TIMESTAMP | NOT NULL | When the delay was recorded |

**Allowed `delay_reason` values:**

| Value | Meaning |
|---|---|
| `weather` | Adverse weather conditions |
| `customs` | Customs clearance delays |
| `mechanical` | Vehicle breakdown |
| `traffic` | Road congestion |
| `strike` | Labour strike action |
| `recipient_absent` | Recipient not available for delivery |
| `address_error` | Incorrect or incomplete address |
| `other` | Other/unclassified reason |

---

## Views

### `vw_cost_per_km`

Cost efficiency per shipment. Joins `shipments`, `carriers`, `routes`, `costs`.

**Key columns:**

| Column | Description |
|---|---|
| `cost_per_km` | `total_cost / distance_km` — primary efficiency KPI |
| `cost_per_kg` | `total_cost / weight_kg` — weight-adjusted cost |
| `shipment_month` | Truncated to first day of month (for time-series charts) |

**Filters applied:** excludes `cancelled` and `lost` shipments; excludes zero-cost rows.

---

### `vw_on_time_rate`

Delivery performance per shipment. Includes window-function aggregates.

**Key columns:**

| Column | Description |
|---|---|
| `is_on_time` | `1` = on time, `0` = late |
| `days_late` | Calendar days past expected delivery (0 if on time) |
| `carrier_on_time_rate_pct` | Running on-time rate for the carrier across all data |
| `route_on_time_rate_pct` | Running on-time rate for the route |
| `monthly_on_time_rate_pct` | On-time rate for that calendar month |

**Filter:** only `delivered` shipments.

---

### `vw_monthly_trends`

Monthly aggregated KPIs. One row per (month, carrier, route_type, origin_country, dest_country).

**Key columns:**

| Column | Description |
|---|---|
| `shipment_count` | Total dispatched shipments |
| `total_cost` | Sum of all costs for the period |
| `avg_cost_per_km` | Average cost per km across all shipments in the group |
| `on_time_rate_pct` | `on_time_count / delivered_count × 100` |
| `delay_rate_pct` | `late_count / delivered_count × 100` |
| `mom_cost_change_pct` | Month-over-month cost change percentage (LAG window) |

---

### `vw_kpi_summary`

Single-row executive summary used for Power BI KPI card visuals.

| Column | Description |
|---|---|
| `total_shipments` | All non-cancelled shipments |
| `total_cost_eur` | Grand total cost |
| `overall_cost_per_km` | Weighted average cost/km across all routes |
| `on_time_rate_pct` | Overall on-time delivery rate |
| `delay_rate_pct` | Overall delay rate |
| `data_from` / `data_to` | Date range of the dataset |

---

## Data Quality Notes

The seed dataset (03_seed_shipments_costs.sql) contains **intentional anomalies** for demonstration:

| Anomaly | Count (approx.) | Fixed by |
|---|---|---|
| Negative `weight_kg` | ~40 rows | 05_cleansing.sql Step 1 |
| NULL `weight_kg` | ~30 rows | 05_cleansing.sql Step 2 |
| Duplicate `costs` rows | ~29 shipment_ids | 05_cleansing.sql Step 3 |
| `delivered` with no `actual_delivery` | ~0 (status logic) | 05_cleansing.sql Step 4 |
| Shipments on inactive carrier | ~0 (carrier 10 rarely selected) | 05_cleansing.sql Step 7 |
