# Power BI – Data Connection

## Source

| Property | Value |
|---|---|
| Database engine | PostgreSQL 18 |
| Host | localhost |
| Database | transport_analytics |
| Connection mode | Import |
| Authentication | Basic (postgres user) |

## Objects loaded

| Object | Type | Rows |
|---|---|---|
| `shipments` | Table | 1 000 |
| `carriers` | Table | 10 |
| `routes` | Table | 30 |
| `costs` | Table | 1 000 |
| `delays` | Table | 140 |
| `vw_cost_per_km` | View | 891 |
| `vw_on_time_rate` | View | 700 |
| `vw_monthly_trends` | View | 24 months × carrier |
| `vw_kpi_summary` | View | 1 (summary row) |

## Why Import mode?

Import loads data into Power BI's in-memory engine (VertiPaq), which gives:
- Sub-second response on all visuals
- Full DAX measure support
- No live dependency on the database during presentation

Trade-off: data must be refreshed manually (or via scheduled refresh in Power BI Service)
to reflect changes in the source database.
