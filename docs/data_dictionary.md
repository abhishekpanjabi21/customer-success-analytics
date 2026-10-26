# Data dictionary

All tables join on `account_id`. Dates are ISO format (`YYYY-MM-DD`). The data is synthetic.

## accounts — 2,600 rows, one per customer

| Column | Description |
| --- | --- |
| account_id | Unique customer ID (`ACC-10001`…) |
| company_name | Customer company name (invented) |
| industry | Customer industry |
| region | North America, EMEA, APAC or LATAM |
| segment | SMB, Mid-Market or Enterprise |
| plan | Starter ($12/seat/month), Growth ($25) or Enterprise ($45) |
| csm_owner | Customer Success Manager who owns the account |
| acquisition_channel | Inbound, Outbound, Partner or Self-serve |
| signup_date | Date the contract started |
| renewal_date | Next renewal date (blank if churned) |
| status | Active or Churned |
| churn_date | Date the customer cancelled (blank if active) |
| churn_reason | Stated reason for cancelling (blank if active) |
| price_per_seat | Monthly price per seat, USD |
| contracted_seats_at_start | Seats bought at signup |

## monthly_revenue — 46,476 rows, one per customer per month

| Column | Description |
| --- | --- |
| account_id | Customer |
| month | First day of the month |
| seats | Seats billed that month |
| mrr | Monthly recurring revenue, USD. A row with `mrr = 0` marks the month the customer churned |

## product_usage — 45,997 rows, one per customer per month

| Column | Description |
| --- | --- |
| account_id | Customer |
| month | First day of the month |
| licensed_seats | Seats paid for |
| active_users | Users who logged in that month |
| logins | Total logins |
| features_adopted | Number of product features used (out of 12) |

## nps_responses — 7,297 rows, one per survey answer

| Column | Description |
| --- | --- |
| response_id | Unique response ID |
| account_id | Customer |
| survey_date | Date of the response |
| nps_score | 0–10 likelihood to recommend |

## onboarding — 2,600 rows, one per customer

| Column | Description |
| --- | --- |
| account_id | Customer |
| kickoff_date | Onboarding start |
| go_live_date | Date the customer went live (blank if in progress) |
| days_to_go_live | Days from kickoff to go-live |
| target_days | Target for the segment: SMB 21, Mid-Market 45, Enterprise 75 |
| onboarding_status | Completed On Time, Completed Late or In Progress |
| training_sessions | Training sessions delivered |
| onboarding_csat | Onboarding satisfaction, 1–5 |

## support_tickets — 31,107 rows, one per ticket

| Column | Description |
| --- | --- |
| ticket_id | Unique ticket ID |
| account_id | Customer |
| created_date | Date the ticket was opened |
| category | Bug, How-to, Billing, Integration or Feature request |
| priority | Low, Medium, High or Urgent |
| resolution_hours | Hours to resolve |
| ticket_csat | Ticket satisfaction, 1–5 |

## account_health — 2,121 rows, one per active customer (output of SQL view `vw_account_health`)

| Column | Description |
| --- | --- |
| account_id, company_name, segment, plan, region, industry, csm_owner, renewal_date, price_per_seat | Copied from `accounts` |
| mrr_now / mrr_3m_ago | MRR in Sep 2026 and Jun 2026 |
| utilisation | Active users ÷ licensed seats, Jul–Sep 2026 |
| avg_features | Average features adopted, Jul–Sep 2026 |
| latest_nps | Most recent NPS score (blank if never surveyed) |
| tickets_90d | Tickets opened since 1 Jun 2026 |
| onboarding_status | From `onboarding` |
| usage_score, nps_component, support_score, onboarding_score, growth_score | Component scores, 0–100 |
| health_score | Weighted health score, 0–100 |
| risk_tier | Healthy, Needs Attention or High Risk |

## expansion_opportunities — 344 rows (output of SQL query `expansion_opportunities`)

| Column | Description |
| --- | --- |
| account_id, company_name, segment, plan, csm_owner | Customer details |
| health_score, utilisation, avg_features, mrr_now | From `account_health` |
| opportunity_type | Seat expansion (90%+ seats used) or Plan upgrade (heavy feature use on Starter/Growth) |
| potential_added_mrr | Estimated added MRR: +20% seats, or the price difference to the next plan |
