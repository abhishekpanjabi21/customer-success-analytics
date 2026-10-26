# Customer health score: method and validation

The health score turns five signals into one number from 0 to 100 for every active customer, so a Customer Success team can see who needs attention before a renewal is lost. It is built in SQL as the view `vw_account_health` (section 5 of `sql/customer_success_analysis.sql`) and rebuilt with formulas in the Excel workbook.

## Components

| Component | Weight | Input | Scoring |
| --- | --- | --- | --- |
| Product usage | 35% | Active users ÷ licensed seats, last 3 months | 90%+ = 100, otherwise proportional |
| NPS | 20% | Latest survey score | Score × 10; never surveyed = 50 |
| Support load | 15% | Tickets in the last 90 days | 0–1 = 100, 2–3 = 75, 4–6 = 50, 7+ = 20 |
| Onboarding | 10% | Onboarding outcome | On time = 100, late = 60, in progress = 50 |
| Revenue trend | 20% | MRR now vs 3 months ago | Up = 100, flat or new = 70, down = 30 |

```text
health_score = 0.35 × usage + 0.20 × NPS + 0.15 × support + 0.10 × onboarding + 0.20 × revenue trend
```

| Tier | Score |
| --- | --- |
| Healthy | 80 and above |
| Needs Attention | 65–79 |
| High Risk | below 65 |

## Why usage carries the most weight

Churned customers used 32.9% of their seats in their final 3 months, against 73.5% for active customers. Usage falls before a customer cancels, so it is the earliest warning signal in the data.

## Validation (backtest)

The score was recalculated as of September 2025, using only data available then, and compared with who actually churned over the next 12 months. Run it yourself: `sql/backtest_health_score.sql`.

| Tier (Sep 2025) | Customers | Churned by Sep 2026 |
| --- | --- | --- |
| Healthy | 848 | 6.3% |
| Needs Attention | 683 | 13.9% |
| High Risk | 89 | 42.7% |

High Risk customers churned about 7 times as often as Healthy ones (42.7% vs 6.3%), so the tiers separate risk well.

## Current results (Sep 2026)

| Tier | Customers | ARR |
| --- | --- | --- |
| Healthy | 1,102 | $33.9M |
| Needs Attention | 901 | $35.9M |
| High Risk | 118 | $5.7M |

## Limitations

- The weights and thresholds are judgement calls, not fitted by a model. A next step would be to fit them with logistic regression on historical churn.
- The data is synthetic, so the strength of each signal reflects how the data was generated.
- NPS is sparse for new customers, who get a neutral 50 until they are surveyed.
