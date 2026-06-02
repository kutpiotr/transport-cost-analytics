# Power BI – Page 1: Cost Overview

## Purpose

High-level cost performance overview for logistics management.
Answers: How much did we spend? Who are our most expensive carriers? How do costs trend over time?

## Visuals

### KPI Cards (top row)

| Card | Measure | Value (full dataset) |
|---|---|---|
| Total Cost | `Total Cost` | 268 420 EUR |
| Avg Cost per KM | `Avg Cost per KM` | 16.06 EUR/km |
| Shipments | `Shipment Count` | 891 |

Cards respond to the year slicer — selecting 2023 or 2024 updates all three values instantly.

### Horizontal Bar Chart — Total Cost by Carrier

Shows cost distribution across all 9 active carriers, sorted descending.

**Key insight:** PolaRoad Sp. z o.o. (PL) is the most expensive carrier,
followed by AlphaLogistics S.A. (FR) and EuroFreight GmbH (DE).
Rail and air carriers (AdriaRail, CentralRail, SkyBridge) have significantly
lower total costs, reflecting lower shipment volumes on those modes.

Data source: `costs` table joined to `carriers` via `shipments`.  
X axis: `Total Cost` measure | Y axis: `carriers[carrier_name]`

### Line Chart — Monthly Cost Trend (2023–2024)

Plots total freight cost per calendar month across the full 2-year period.

**Key insight:** Costs show high month-to-month volatility (8k–18k EUR range),
with a notable peak in October 2024. No clear seasonal pattern is visible,
which reflects the random distribution of the synthetic dataset.
In a real dataset this view would highlight seasonal peaks (e.g. Q4 pre-Christmas surge).

Data source: `vw_monthly_trends[month]` × `vw_monthly_trends[total_cost]`

### Year Slicer

Filters all visuals on the page to 2023 or 2024 individually, or both combined.
Implemented as a list-style slicer on `vw_monthly_trends[year]`.

## Interactivity

- Clicking a carrier bar cross-filters the line chart to show only that carrier's monthly trend
- Year slicer updates KPI cards, bar chart and line chart simultaneously
