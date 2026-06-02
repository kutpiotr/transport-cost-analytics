# Transport Cost Analytics Dashboard

## Project Overview

A full-stack data analytics project for a fictional logistics company, demonstrating end-to-end BI pipeline:  
**PostgreSQL** (schema + ETL) → **Power BI** (interactive dashboard with forecasting).

The dataset is synthetic, modelled after real logistics KPIs (cost per km, on-time delivery, carrier performance), inspired by public sources (Eurostat transport statistics, GUS).

---

## Architecture

```
sql/
  01_schema.sql              # Table definitions (DDL)
  02_seed_carriers_routes.sql # Static reference data
  03_seed_shipments_costs.sql # Fact data (~1000 rows)
  04_quality_checks.sql      # Data quality / anomaly detection
  05_cleansing.sql           # Data cleansing scripts
  06_views.sql               # Analytical views for Power BI

powerbi/
  transport_dashboard.pbix   # Power BI dashboard file
  powerbi_setup.md           # Step-by-step connection & DAX guide

docs/
  data_dictionary.md         # Table & column descriptions
```

---

## Database Schema

| Table       | Description                                      |
|-------------|--------------------------------------------------|
| `carriers`  | Logistics carriers (name, country, type)         |
| `routes`    | Origin–destination pairs with distance (km)      |
| `shipments` | Individual shipment records (weight, date, etc.) |
| `costs`     | Cost per shipment (fuel, toll, labour, total)    |
| `delays`    | Delay records linked to shipments                |

---

## Power BI Dashboard

**Page 1 – Cost Overview**
- Total Cost KPI card
- Avg Cost per KM card
- Cost by carrier (bar chart)
- Monthly cost trend (line chart)

**Page 2 – Delivery Performance**
- On-Time Rate % KPI
- Delay Rate % KPI
- On-time rate by carrier
- Top 10 delayed routes
- Forecast (built-in Power BI analytics)

---

## How to Run

### 1. Set up PostgreSQL database

```sql
-- Run in order:
psql -U postgres -d your_db -f sql/01_schema.sql
psql -U postgres -d your_db -f sql/02_seed_carriers_routes.sql
psql -U postgres -d your_db -f sql/03_seed_shipments_costs.sql
psql -U postgres -d your_db -f sql/04_quality_checks.sql
psql -U postgres -d your_db -f sql/05_cleansing.sql
psql -U postgres -d your_db -f sql/06_views.sql
```

### 2. Connect Power BI

Open `powerbi/transport_dashboard.pbix` and update the connection string to your PostgreSQL server.  
See `powerbi/powerbi_setup.md` for full DAX measures and data model instructions.

---

## Tech Stack

- **Database**: PostgreSQL 15+
- **ETL / SQL**: Pure SQL (compatible with SQL Server with minor adjustments)
- **Visualisation**: Microsoft Power BI Desktop
- **Data**: Synthetic, ~1 000 shipment records

---

## Author

Portfolio project — Transport Cost Analytics  
Contact: kutpiotr1@gmail.com
