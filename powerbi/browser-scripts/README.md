# Rebuild in the Power BI web editor (no Windows needed)

The scripts build the **data model only** (relationships and measures). The 5 report pages are not created by them; you add the visuals by hand in the web report editor.

## 1. Load the data
In Power BI, go to **My workspace → New item → Semantic model → Excel** (or CSV) and load the 8 files from `data/`. Change every date column to type **Date**. Choose **Create a semantic model only**.

## 2. Build the model
Open the model, switch to the **TMDL view** tab, then:
1. Paste `Script_1_Relationships.txt` and click **Apply** (7 relationships).
2. Paste `Script_2_Measures.txt` and click **Apply** (40 measures, added to the `accounts` table).
Check: a card with **Total ARR** shows $75,595,284.

## 3. Build the 5 pages
Create a report from the model, add 5 pages, and drag in these visuals. Add Segment, Region and Plan slicers (from `accounts`) to every page.

| Page | Visual | Fields |
| --- | --- | --- |
| 1 Executive Overview | 6 cards | Total ARR, Total MRR, Active Customers, NRR, GRR, NPS |
| | Line chart | X: monthly_revenue[month] · Y: Total MRR |
| | Donut | Legend: account_health[risk_tier] · Values: Health Customers |
| | Bar chart | Y: accounts[segment] · X: Total ARR |
| 2 Revenue Performance | 4 cards | MRR Growth YoY, New MRR (12M), Expansion MRR (12M), Churned MRR (12M) |
| | Clustered column | X: monthly_revenue[month] · Y: New MRR, Expansion MRR, Contraction MRR, Churned MRR |
| | Matrix | Rows: accounts[region] · Columns: accounts[plan] · Values: Total ARR |
| 3 Churn & Retention | 4 cards | Avg Monthly Logo Churn (12M), Churned Customers (12M), Logo Retention, GRR |
| | Line chart | X: monthly_revenue[month] · Y: Logo Churn Rate |
| | Bar chart | Y: accounts[churn_reason] · X: Customers · filter: churn_reason is not blank |
| | Column chart | X: onboarding[onboarding_status] · Y: Churn Rate |
| | Bar chart | Y: accounts[segment] · X: Churn Rate |
| 4 Customer Health | 4 cards | Avg Health Score, High Risk ARR, Seat Utilisation, Renewals at Risk ARR |
| | Scatter | Values: account_health[account_id] · X: utilisation (Average) · Y: health_score (Average) · Legend: risk_tier · Size: mrr_now |
| | Bar chart | Y: account_health[csm_owner] · X: High Risk Customers |
| | Table | account_health: company_name, segment, csm_owner, renewal_date, health_score, risk_tier, plus measure Renewals at Risk ARR (rows without a value drop out) |
| 5 Growth Opportunities | 4 cards | Expansion Pipeline ARR, Expansion Opportunities, On-time Onboarding %, Avg Days to Go-Live |
| | Bar chart | Y: expansion_opportunities[opportunity_type] · X: Expansion Pipeline ARR |
| | Column chart | X: accounts[segment] · Y: NPS |
| | Table | expansion_opportunities: company_name, segment, plan, opportunity_type, health_score, potential_added_mrr |

Theme: **View → Themes → Browse for themes** → `CS Analytics.Report/StaticResources/RegisteredResources/CS_Theme.json`.
