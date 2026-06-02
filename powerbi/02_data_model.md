# Power BI – Data Model

## Relationships

Power BI auto-detected all relationships from the PostgreSQL foreign keys.

| From (Many) | Column | To (One) | Column | Cardinality |
|---|---|---|---|---|
| `shipments` | `carrier_id` | `carriers` | `carrier_id` | Many-to-one |
| `shipments` | `route_id` | `routes` | `route_id` | Many-to-one |
| `costs` | `shipment_id` | `shipments` | `shipment_id` | One-to-one |
| `delays` | `shipment_id` | `shipments` | `shipment_id` | Many-to-one |

The four analytical views (`vw_*`) are standalone — they are pre-joined in SQL
and used directly as reporting tables without additional relationships in Power BI.

## Schema diagram

```
carriers ──────┐
               │ (carrier_id)
routes ────────┤──► shipments ◄──── costs
               │ (route_id)    │
               │               └──► delays
               └───────────────────────────
```

## Design decisions

**Why use both base tables AND views?**

- Base tables (`shipments`, `costs`, `delays`) power DAX measures that need
  row-level filtering with CALCULATE — e.g. counting delivered vs cancelled shipments
- Views (`vw_cost_per_km`, `vw_on_time_rate`, `vw_monthly_trends`) are used for
  chart visuals where the aggregation logic is complex and better expressed in SQL
  than replicated in DAX

**Cross-filtering**

All relationships use single-direction filtering (carriers → shipments, routes → shipments).
This avoids ambiguity in filter propagation and is best practice for star schemas in Power BI.
