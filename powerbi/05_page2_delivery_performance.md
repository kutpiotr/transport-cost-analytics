# Power BI – Page 2: Delivery Performance

## Purpose

Operational performance view focused on delivery reliability and delay analysis.
Answers: Are we delivering on time? Which carriers underperform? What causes delays?

## Visuals

### KPI Cards (top row)

| Card | Measure | Value (full dataset) |
|---|---|---|
| On-Time Rate % | `On-Time Rate %` | 78.57% |
| Delay Rate % | `Delay Rate %` | 21.43% |
| Delivered Count | `Delivered Count` | 700 |

**Interpretation:** ~1 in 5 deliveries arrives after the promised date.
Industry benchmark for road freight is typically 85–95% on-time,
so this dataset reflects a below-average performing carrier mix.

### Horizontal Bar Chart — On-Time Rate by Carrier

Compares delivery reliability across all carriers using pre-aggregated
`carrier_on_time_rate_pct` from `vw_on_time_rate`.

**Key insight:** PolaRoad Sp. z o.o. leads in both cost (page 1) and volume,
which correlates with higher absolute on-time counts. Rail carriers
(AdriaRail, CentralRail) show lower on-time rates, reflecting
the complexity of intermodal coordination. SkyBridge Air B.V.
has the lowest on-time rate despite air transport typically being faster —
suggesting that air shipments in this dataset involve more complex
customs and handling steps.

### Delay Breakdown Table

Summarises delay incidents by root cause category (NST delay reason taxonomy).

| Reason | Delay Days | Delay Cost (EUR) |
|---|---|---|
| mechanical | 27 | 2 542 |
| weather | 20 | 2 375 |
| customs | 16 | 1 966 |
| recipient_absent | 15 | 1 755 |
| strike | 14 | 1 470 |
| traffic | 18 | 957 |
| address_error | 10 | 1 162 |
| other | 7 | 355 |

**Key insight:** Mechanical failures account for the most delay days (27),
suggesting fleet maintenance as a priority area.
Traffic causes fewer days lost but 18 incidents — high frequency, low severity.

### Pie Chart — Delay Days by Reason

Visual breakdown of delay day distribution across all reason categories.
Mechanical (21%) and weather (16%) dominate, together accounting
for over a third of all delay days.

Data source: `delays[delay_reason]` × `delays[delay_days]`

### Carrier Slicer

Filters all visuals to a single carrier, enabling per-carrier performance deep-dive.
Implemented as a list slicer on `carriers[carrier_name]`.

## Interactivity

- Clicking a reason in the pie chart highlights that reason's row in the table
- Carrier slicer updates all KPI cards and charts simultaneously
- Cross-page filtering: carrier selection on page 2 does not affect page 1
  (slicers are page-scoped by default in Power BI)
