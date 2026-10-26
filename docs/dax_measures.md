# DAX measures

All 42 measures live in the `_Measures` table of the Power BI model, grouped in display folders.

## Helpers

### Latest Month

Latest month in the data (Sep 2026); anchors the "last 12 months" measures.

```dax
Latest Month =
    CALCULATE ( MAX ( monthly_revenue[month] ), REMOVEFILTERS ( monthly_revenue ) )
```

## Revenue

### Total MRR

Monthly recurring revenue for the latest month in context.

```dax
Total MRR =
    VAR m = MAX ( monthly_revenue[month] )
    RETURN
        CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = m )
```

### Total ARR

MRR × 12.

```dax
Total ARR =
    [Total MRR] * 12
```

### Active Customers

Customers paying in the latest month in context.

```dax
Active Customers =
    VAR m = MAX ( monthly_revenue[month] )
    RETURN
        CALCULATE ( COUNTROWS ( monthly_revenue ), monthly_revenue[month] = m, monthly_revenue[mrr] > 0 )
```

### Avg ARR per Customer

ARR ÷ active customers.

```dax
Avg ARR per Customer =
    DIVIDE ( [Total ARR], [Active Customers] )
```

### MRR 12M Ago

MRR 12 months before the month in context.

```dax
MRR 12M Ago =
    VAR m = MAX ( monthly_revenue[month] )
    RETURN
        CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = EDATE ( m, -12 ) )
```

### MRR Growth YoY

Change in MRR versus 12 months earlier.

```dax
MRR Growth YoY =
    DIVIDE ( [Total MRR] - [MRR 12M Ago], [MRR 12M Ago] )
```

### New MRR

MRR from customers in their first month (no prior month).

```dax
New MRR =
    VAR firstM = CALCULATE ( MIN ( monthly_revenue[month] ), REMOVEFILTERS ( monthly_revenue ) )
    RETURN
        SUMX (
            FILTER ( monthly_revenue, monthly_revenue[month] > firstM && monthly_revenue[mrr] > 0 ),
            VAR acc = monthly_revenue[account_id]
            VAR m = monthly_revenue[month]
            VAR cur = monthly_revenue[mrr]
            VAR prev = CALCULATE ( SUM ( monthly_revenue[mrr] ), REMOVEFILTERS ( monthly_revenue ), monthly_revenue[account_id] = acc, monthly_revenue[month] = EDATE ( m, -1 ) )
            RETURN IF ( ISBLANK ( prev ), cur )
        )
```

### Expansion MRR

MRR increase from existing customers who added seats.

```dax
Expansion MRR =
    VAR firstM = CALCULATE ( MIN ( monthly_revenue[month] ), REMOVEFILTERS ( monthly_revenue ) )
    RETURN
        SUMX (
            FILTER ( monthly_revenue, monthly_revenue[month] > firstM && monthly_revenue[mrr] > 0 ),
            VAR acc = monthly_revenue[account_id]
            VAR m = monthly_revenue[month]
            VAR cur = monthly_revenue[mrr]
            VAR prev = CALCULATE ( SUM ( monthly_revenue[mrr] ), REMOVEFILTERS ( monthly_revenue ), monthly_revenue[account_id] = acc, monthly_revenue[month] = EDATE ( m, -1 ) )
            RETURN IF ( prev > 0 && cur > prev, cur - prev )
        )
```

### Contraction MRR

MRR decrease from existing customers who removed seats.

```dax
Contraction MRR =
    VAR firstM = CALCULATE ( MIN ( monthly_revenue[month] ), REMOVEFILTERS ( monthly_revenue ) )
    RETURN
        SUMX (
            FILTER ( monthly_revenue, monthly_revenue[month] > firstM && monthly_revenue[mrr] > 0 ),
            VAR acc = monthly_revenue[account_id]
            VAR m = monthly_revenue[month]
            VAR cur = monthly_revenue[mrr]
            VAR prev = CALCULATE ( SUM ( monthly_revenue[mrr] ), REMOVEFILTERS ( monthly_revenue ), monthly_revenue[account_id] = acc, monthly_revenue[month] = EDATE ( m, -1 ) )
            RETURN IF ( prev > 0 && cur < prev, prev - cur )
        )
```

### Churned MRR

Previous-month MRR of customers who cancelled.

```dax
Churned MRR =
    VAR firstM = CALCULATE ( MIN ( monthly_revenue[month] ), REMOVEFILTERS ( monthly_revenue ) )
    RETURN
        SUMX (
            FILTER ( monthly_revenue, monthly_revenue[month] > firstM && monthly_revenue[mrr] = 0 ),
            VAR acc = monthly_revenue[account_id]
            VAR m = monthly_revenue[month]
            VAR cur = monthly_revenue[mrr]
            VAR prev = CALCULATE ( SUM ( monthly_revenue[mrr] ), REMOVEFILTERS ( monthly_revenue ), monthly_revenue[account_id] = acc, monthly_revenue[month] = EDATE ( m, -1 ) )
            RETURN prev
        )
```

### Net New MRR

New + Expansion − Contraction − Churned.

```dax
Net New MRR =
    [New MRR] + [Expansion MRR] - [Contraction MRR] - [Churned MRR]
```

### New MRR (12M)

New MRR over the last 12 months.

```dax
New MRR (12M) =
    VAR lm = [Latest Month]
    RETURN
        CALCULATE ( [New MRR], monthly_revenue[month] > EDATE ( lm, -12 ), monthly_revenue[month] <= lm )
```

### Expansion MRR (12M)

Expansion MRR over the last 12 months.

```dax
Expansion MRR (12M) =
    VAR lm = [Latest Month]
    RETURN
        CALCULATE ( [Expansion MRR], monthly_revenue[month] > EDATE ( lm, -12 ), monthly_revenue[month] <= lm )
```

### Churned MRR (12M)

Churned MRR over the last 12 months.

```dax
Churned MRR (12M) =
    VAR lm = [Latest Month]
    RETURN
        CALCULATE ( [Churned MRR], monthly_revenue[month] > EDATE ( lm, -12 ), monthly_revenue[month] <= lm )
```

## Retention

### Churned Customers

Customers who cancelled in the period.

```dax
Churned Customers =
    CALCULATE ( COUNTROWS ( monthly_revenue ), monthly_revenue[mrr] = 0 )
```

### Churned Customers (12M)

Customers who cancelled in the last 12 months.

```dax
Churned Customers (12M) =
    VAR lm = [Latest Month]
    RETURN
        CALCULATE ( [Churned Customers], monthly_revenue[month] > EDATE ( lm, -12 ), monthly_revenue[month] <= lm )
```

### Customers at Start

Paying customers in the previous month.

```dax
Customers at Start =
    VAR m = MAX ( monthly_revenue[month] )
    RETURN
        CALCULATE ( COUNTROWS ( monthly_revenue ), monthly_revenue[month] = EDATE ( m, -1 ), monthly_revenue[mrr] > 0 )
```

### Logo Churn Rate

Customers lost ÷ customers at start of month.

```dax
Logo Churn Rate =
    DIVIDE ( [Churned Customers], [Customers at Start] )
```

### Avg Monthly Logo Churn (12M)

Average monthly logo churn rate over the last 12 months.

```dax
Avg Monthly Logo Churn (12M) =
    VAR lm = [Latest Month]
    RETURN
        AVERAGEX ( FILTER ( VALUES ( monthly_revenue[month] ), monthly_revenue[month] > EDATE ( lm, -12 ) && monthly_revenue[month] <= lm ), [Logo Churn Rate] )
```

### NRR

MRR today from customers paying 12 months ago ÷ their MRR then (includes expansion).

```dax
NRR =
    VAR EndM = MAX ( monthly_revenue[month] )
    VAR StartM = EDATE ( EndM, -12 )
    VAR Cohort = CALCULATETABLE ( VALUES ( monthly_revenue[account_id] ), monthly_revenue[month] = StartM, monthly_revenue[mrr] > 0 )
    VAR StartMRR = CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = StartM, Cohort )
    VAR EndMRR = CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = EndM, Cohort )
    RETURN
        DIVIDE ( EndMRR, StartMRR )
```

### GRR

Same cohort, each customer capped at its starting MRR (excludes expansion).

```dax
GRR =
    VAR EndM = MAX ( monthly_revenue[month] )
    VAR StartM = EDATE ( EndM, -12 )
    VAR Cohort = CALCULATETABLE ( VALUES ( monthly_revenue[account_id] ), monthly_revenue[month] = StartM, monthly_revenue[mrr] > 0 )
    VAR StartMRR = CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = StartM, Cohort )
    VAR Kept =
        SUMX (
            Cohort,
            VAR s = CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = StartM )
            VAR e = COALESCE ( CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = EndM ), 0 )
            RETURN IF ( e < s, e, s )
        )
    RETURN
        DIVIDE ( Kept, StartMRR )
```

### Logo Retention

Share of the 12-month-old cohort still paying.

```dax
Logo Retention =
    VAR EndM = MAX ( monthly_revenue[month] )
    VAR StartM = EDATE ( EndM, -12 )
    VAR Cohort = CALCULATETABLE ( VALUES ( monthly_revenue[account_id] ), monthly_revenue[month] = StartM, monthly_revenue[mrr] > 0 )
    VAR Kept = COUNTROWS ( FILTER ( Cohort, CALCULATE ( SUM ( monthly_revenue[mrr] ), monthly_revenue[month] = EndM ) > 0 ) )
    RETURN
        DIVIDE ( Kept, COUNTROWS ( Cohort ) )
```

### Customers

Number of accounts (all statuses).

```dax
Customers =
    COUNTROWS ( accounts )
```

### Churn Rate

Churned accounts ÷ all accounts.

```dax
Churn Rate =
    DIVIDE ( CALCULATE ( COUNTROWS ( accounts ), accounts[status] = "Churned" ), COUNTROWS ( accounts ) )
```

### Churned Accounts

Accounts with status Churned.

```dax
Churned Accounts =
    CALCULATE ( COUNTROWS ( accounts ), accounts[status] = "Churned" )
```

## Engagement

### NPS

% promoters (9–10) minus % detractors (0–6), last 12 months.

```dax
NPS =
    VAR lm = [Latest Month]
    VAR r = CALCULATETABLE ( nps_responses, nps_responses[survey_date] >= EDATE ( lm, -12 ) )
    VAR total = COUNTROWS ( r )
    VAR promoters = COUNTROWS ( FILTER ( r, nps_responses[nps_score] >= 9 ) )
    VAR detractors = COUNTROWS ( FILTER ( r, nps_responses[nps_score] <= 6 ) )
    RETURN
        ROUND ( DIVIDE ( promoters - detractors, total ) * 100, 0 )
```

### Seat Utilisation

Active users ÷ licensed seats for the month in context.

```dax
Seat Utilisation =
    VAR m = MAX ( product_usage[month] )
    RETURN
        CALCULATE ( DIVIDE ( SUM ( product_usage[active_users] ), SUM ( product_usage[licensed_seats] ) ), product_usage[month] = m )
```

### Avg Days to Go-Live

Average onboarding duration in days.

```dax
Avg Days to Go-Live =
    AVERAGE ( onboarding[days_to_go_live] )
```

### On-time Onboarding %

Onboardings completed on time ÷ completed onboardings.

```dax
On-time Onboarding % =
    DIVIDE (
        CALCULATE ( COUNTROWS ( onboarding ), onboarding[onboarding_status] = "Completed On Time" ),
        CALCULATE ( COUNTROWS ( onboarding ), onboarding[onboarding_status] <> "In Progress" )
    )
```

### Tickets

Number of support tickets.

```dax
Tickets =
    COUNTROWS ( support_tickets )
```

### Avg Resolution Hours

Average ticket resolution time.

```dax
Avg Resolution Hours =
    AVERAGE ( support_tickets[resolution_hours] )
```

## Health

### Avg Health Score

Average health score of active customers.

```dax
Avg Health Score =
    AVERAGE ( account_health[health_score] )
```

### Health Customers

Active customers with a health score.

```dax
Health Customers =
    COUNTROWS ( account_health )
```

### Health ARR

ARR of scored customers.

```dax
Health ARR =
    SUM ( account_health[mrr_now] ) * 12
```

### High Risk Customers

Customers with health score below 65.

```dax
High Risk Customers =
    CALCULATE ( COUNTROWS ( account_health ), account_health[risk_tier] = "High Risk" )
```

### High Risk ARR

ARR held by High Risk customers.

```dax
High Risk ARR =
    CALCULATE ( [Health ARR], account_health[risk_tier] = "High Risk" )
```

### Renewals at Risk

Non-healthy customers renewing before 1 Mar 2027.

```dax
Renewals at Risk =
    CALCULATE ( COUNTROWS ( account_health ), account_health[risk_tier] <> "Healthy", account_health[renewal_date] < DATE ( 2027, 3, 1 ) )
```

### Renewals at Risk ARR

ARR of those renewals.

```dax
Renewals at Risk ARR =
    CALCULATE ( [Health ARR], account_health[risk_tier] <> "Healthy", account_health[renewal_date] < DATE ( 2027, 3, 1 ) )
```

### Avg Utilisation

Average seat utilisation over the last 3 months (health inputs).

```dax
Avg Utilisation =
    AVERAGE ( account_health[utilisation] )
```

## Growth

### Expansion Opportunities

Healthy customers flagged for seat expansion or plan upgrade.

```dax
Expansion Opportunities =
    COUNTROWS ( expansion_opportunities )
```

### Expansion Pipeline ARR

Potential added ARR from those opportunities.

```dax
Expansion Pipeline ARR =
    SUM ( expansion_opportunities[potential_added_mrr] ) * 12
```
