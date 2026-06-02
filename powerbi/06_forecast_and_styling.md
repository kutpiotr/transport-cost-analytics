# Power BI – Forecast and Final Styling

## Forecast

Applied to the Monthly Cost Trend line chart on page 1 using Power BI's
built-in Analytics panel (no external ML model required).

| Setting | Value |
|---|---|
| Forecast periods | 6 months |
| Confidence interval | 95% |
| Algorithm | Exponential smoothing (ETS) — Power BI default |
| Seasonality | Auto-detected |

**Interpretation:** The forecast extrapolates the 2023–2024 cost trend
into the first half of 2025. The wide confidence interval (95%) reflects
the high month-to-month volatility in the dataset — in a real scenario
with more data points and clearer seasonality, the interval would be narrower.

The forecast is useful for budget planning: the central line gives the
expected cost level, while the shaded band shows the realistic range
of outcomes under normal conditions.

## Visual Design Decisions

### Color palette

Power BI default blue (#118DFF) used throughout for consistency.
No custom theme applied — keeping the focus on data rather than aesthetics
for a technical portfolio project.

Key color usage:
- Bar charts: single solid blue — avoids false categorical distinctions
- Pie chart: Power BI default categorical palette (8 colors for 8 delay reasons)
- KPI cards: white background, black text — clean and readable

### Layout principles

- KPI cards always in top row — summary before detail
- Charts in lower 2/3 of canvas — more space for data-dense visuals
- Slicers positioned top-right — out of main reading flow but easily accessible
- No decorative elements — every visual element carries information

### Formatting applied

| Element | Setting |
|---|---|
| Bar chart | Sorted descending by value |
| Line chart | Markers off (too many data points) |
| Pie chart | Data labels: value + percentage |
| Tables | Banded rows on, totals row on |
| All charts | Grid lines on, legend where needed |

## Summary — Dashboard capabilities

| Capability | Implementation |
|---|---|
| Cost monitoring | Total Cost KPI + monthly trend |
| Carrier benchmarking | Bar chart with cross-filter |
| Delivery reliability | On-Time Rate %, Delay Rate % KPIs |
| Root cause analysis | Delay breakdown table + pie chart |
| Time filtering | Year slicer on page 1 |
| Carrier filtering | Carrier slicer on page 2 |
| Forecasting | 6-month ETS forecast with 95% CI |
| Data freshness | Manual refresh from PostgreSQL source |
