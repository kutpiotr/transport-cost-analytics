# Power BI – DAX Measures

All measures are stored in a dedicated `_Measures` table to keep the model clean.

## Cost Measures

```dax
Total Cost =
SUM(costs[total_cost])
-- Result: 268 420 EUR (all carriers, 2023-2024)
```

```dax
Avg Cost per KM =
DIVIDE(SUM(costs[total_cost]), SUM(routes[distance_km]), 0)
-- Result: 16.06 EUR/km average across all routes
```

## Volume Measures

```dax
Shipment Count =
COUNTROWS(FILTER(shipments, shipments[status] <> "cancelled"))
-- Result: 891 active shipments (excludes cancelled)
```

```dax
Delivered Count =
CALCULATE(COUNTROWS(shipments), shipments[status] = "delivered")
-- Result: 700 delivered shipments
```

## Delivery Performance Measures

```dax
On-Time Count =
CALCULATE(
    COUNTROWS(shipments),
    shipments[status] = "delivered",
    shipments[actual_delivery] <= shipments[expected_delivery]
)
```

```dax
On-Time Rate % =
DIVIDE([On-Time Count], [Delivered Count], 0) * 100
-- Result: 78.57% — meaning ~1 in 5 deliveries arrives late
```

```dax
Delay Rate % =
DIVIDE(
    CALCULATE(
        COUNTROWS(shipments),
        shipments[status] = "delivered",
        shipments[actual_delivery] > shipments[expected_delivery]
    ),
    [Delivered Count], 0
) * 100
-- Result: 21.43%
```

## DAX patterns used

| Pattern | Used in |
|---|---|
| `CALCULATE` with filter arguments | On-Time Count, Delay Rate % |
| `DIVIDE` with safe denominator | All ratio measures (avoids division-by-zero) |
| `FILTER` iterator | Shipment Count (exclude cancelled) |
| `SUM` | Total Cost, Avg Cost per KM |

## How measures respond to slicers

All measures react to:
- **Year slicer** (via `vw_monthly_trends[year]`) — filters the monthly trend chart
- **Carrier slicer** (via `carriers[carrier_name]`) — filters all base table visuals
- Clicking a bar in the carrier chart cross-filters all other visuals on the page
