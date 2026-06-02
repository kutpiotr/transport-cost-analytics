# DAX Measures Reference
See powerbi_setup.md for full DAX code.

Measures:
- Total Cost = SUM(costs[total_cost])
- Avg Cost per KM = total_cost / SUM(distance_km)
- On-Time Rate % = on_time_count / delivered_count * 100
- Delay Rate % = late_count / delivered_count * 100
- Cost MoM Change % = (current - prev) / prev * 100
