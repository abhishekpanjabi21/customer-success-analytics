/* =====================================================================
   SaaS CUSTOMER SUCCESS ANALYTICS — SQL SCRIPT
   Works in MySQL 8+, PostgreSQL, SQLite 3.25+ (and SQL Server with the
   small changes noted). Run sections in order.

   Reporting date ("as of") = 2026-09-01  (latest month in the data)

   Tables (load the 6 CSVs with these names):
     accounts          1 row per customer (2,600)
     monthly_revenue   1 row per customer per month (MRR, seats)
                       a row with mrr = 0 marks the month a customer churned
     product_usage     1 row per customer per month (active users, logins)
     nps_responses     survey answers 0-10
     onboarding        1 row per customer (kickoff, go-live, status)
     support_tickets   1 row per ticket
   ===================================================================== */


/* ---------------------------------------------------------------------
   SECTION 0 — CREATE TABLES  (skip if you import CSVs with a wizard)
   --------------------------------------------------------------------- */
CREATE TABLE accounts (
    account_id               VARCHAR(12) PRIMARY KEY,
    company_name             VARCHAR(100),
    industry                 VARCHAR(50),
    region                   VARCHAR(30),
    segment                  VARCHAR(20),   -- SMB / Mid-Market / Enterprise
    plan                     VARCHAR(20),   -- Starter / Growth / Enterprise
    csm_owner                VARCHAR(50),
    acquisition_channel      VARCHAR(20),
    signup_date              DATE,
    renewal_date             DATE,
    status                   VARCHAR(10),   -- Active / Churned
    churn_date               DATE,
    churn_reason             VARCHAR(50),
    price_per_seat           DECIMAL(10,2),
    contracted_seats_at_start INT
);
CREATE TABLE monthly_revenue (account_id VARCHAR(12), month DATE, seats INT, mrr DECIMAL(12,2));
CREATE TABLE product_usage   (account_id VARCHAR(12), month DATE, licensed_seats INT,
                              active_users INT, logins INT, features_adopted INT);
CREATE TABLE nps_responses   (response_id VARCHAR(12), account_id VARCHAR(12),
                              survey_date DATE, nps_score INT);
CREATE TABLE onboarding      (account_id VARCHAR(12), kickoff_date DATE, go_live_date DATE,
                              days_to_go_live INT, target_days INT, onboarding_status VARCHAR(20),
                              training_sessions INT, onboarding_csat INT);
CREATE TABLE support_tickets (ticket_id VARCHAR(12), account_id VARCHAR(12), created_date DATE,
                              category VARCHAR(30), priority VARCHAR(10),
                              resolution_hours DECIMAL(8,1), ticket_csat INT);


/* ---------------------------------------------------------------------
   SECTION 1 — DATA QUALITY CHECKS  (always do this first!)
   --------------------------------------------------------------------- */
-- @query dq_row_counts
SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM accounts
UNION ALL SELECT 'monthly_revenue', COUNT(*) FROM monthly_revenue
UNION ALL SELECT 'product_usage',   COUNT(*) FROM product_usage
UNION ALL SELECT 'nps_responses',   COUNT(*) FROM nps_responses
UNION ALL SELECT 'onboarding',      COUNT(*) FROM onboarding
UNION ALL SELECT 'support_tickets', COUNT(*) FROM support_tickets;

-- @query dq_duplicates_and_orphans
SELECT
  (SELECT COUNT(*) - COUNT(DISTINCT account_id) FROM accounts)                         AS duplicate_accounts,
  (SELECT COUNT(*) FROM monthly_revenue r
     WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.account_id = r.account_id))   AS orphan_revenue_rows,
  (SELECT COUNT(*) FROM accounts WHERE status = 'Churned' AND churn_date IS NULL)      AS churned_missing_date;


/* ---------------------------------------------------------------------
   SECTION 2 — REVENUE KPIs: MRR, ARR, MRR MOVEMENTS
   --------------------------------------------------------------------- */
-- @query kpi_mrr_arr_trend
-- Total MRR and ARR per month, plus paying customers
SELECT month,
       SUM(mrr)                                   AS total_mrr,
       SUM(mrr) * 12                              AS total_arr,
       SUM(CASE WHEN mrr > 0 THEN 1 ELSE 0 END)   AS paying_customers
FROM monthly_revenue
GROUP BY month
ORDER BY month;

-- @query kpi_mrr_movements
-- Classify every account-month as New / Expansion / Contraction / Churned
-- LAG() looks at the same account's previous month.
WITH mrr_with_prev AS (
    SELECT account_id, month, mrr,
           LAG(mrr) OVER (PARTITION BY account_id ORDER BY month) AS prev_mrr
    FROM monthly_revenue
)
SELECT month,
       SUM(CASE WHEN prev_mrr IS NULL AND mrr > 0       THEN mrr            ELSE 0 END) AS new_mrr,
       SUM(CASE WHEN prev_mrr > 0 AND mrr > prev_mrr    THEN mrr - prev_mrr ELSE 0 END) AS expansion_mrr,
       SUM(CASE WHEN mrr > 0 AND mrr < prev_mrr         THEN prev_mrr - mrr ELSE 0 END) AS contraction_mrr,
       SUM(CASE WHEN prev_mrr > 0 AND mrr = 0           THEN prev_mrr       ELSE 0 END) AS churned_mrr
FROM mrr_with_prev
WHERE month >= '2024-02-01'          -- Jan 2024 has no prior month, so skip it
GROUP BY month
ORDER BY month;


/* ---------------------------------------------------------------------
   SECTION 3 — CHURN & RETENTION
   --------------------------------------------------------------------- */
-- @query kpi_monthly_logo_churn
-- Logo churn rate = customers lost this month / paying customers last month
WITH mrr_with_prev AS (
    SELECT account_id, month, mrr,
           LAG(mrr) OVER (PARTITION BY account_id ORDER BY month) AS prev_mrr
    FROM monthly_revenue
),
monthly AS (
    SELECT month,
           SUM(CASE WHEN prev_mrr > 0 THEN 1 ELSE 0 END)              AS customers_start,
           SUM(CASE WHEN prev_mrr > 0 AND mrr = 0 THEN 1 ELSE 0 END)  AS customers_churned
    FROM mrr_with_prev
    WHERE month >= '2024-02-01'
    GROUP BY month
)
SELECT month, customers_start, customers_churned,
       ROUND(100.0 * customers_churned / customers_start, 2) AS logo_churn_rate_pct
FROM monthly
ORDER BY month;

-- @query kpi_nrr_grr_ttm
-- Net & Gross Revenue Retention, last 12 months (Sep 2025 -> Sep 2026)
-- Only customers who were paying in Sep 2025 are in the cohort.
WITH start_mrr AS (
    SELECT account_id, mrr AS mrr_start FROM monthly_revenue
    WHERE month = '2025-09-01' AND mrr > 0
),
end_mrr AS (
    SELECT account_id, mrr AS mrr_end FROM monthly_revenue WHERE month = '2026-09-01'
)
SELECT
    COUNT(*)                                                         AS cohort_customers,
    SUM(s.mrr_start)                                                 AS cohort_start_mrr,
    SUM(COALESCE(e.mrr_end, 0))                                      AS cohort_end_mrr,
    ROUND(100.0 * SUM(COALESCE(e.mrr_end, 0)) / SUM(s.mrr_start), 1) AS nrr_pct,
    ROUND(100.0 * SUM(CASE WHEN COALESCE(e.mrr_end,0) < s.mrr_start
                           THEN COALESCE(e.mrr_end,0) ELSE s.mrr_start END)
          / SUM(s.mrr_start), 1)                                     AS grr_pct,
    ROUND(100.0 * SUM(CASE WHEN COALESCE(e.mrr_end,0) > 0 THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                     AS logo_retention_pct
FROM start_mrr s
LEFT JOIN end_mrr e ON e.account_id = s.account_id;

-- @query churn_by_segment
SELECT segment,
       COUNT(*)                                                   AS customers,
       SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END)        AS churned,
       ROUND(100.0 * SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_pct
FROM accounts
GROUP BY segment
ORDER BY churn_pct DESC;

-- @query churn_reasons
SELECT churn_reason, COUNT(*) AS churned_customers,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM accounts WHERE status = 'Churned'), 1) AS pct_of_churn
FROM accounts
WHERE status = 'Churned'
GROUP BY churn_reason
ORDER BY churned_customers DESC;

-- @query churn_by_onboarding
-- Does a late onboarding lead to more churn?
SELECT o.onboarding_status,
       COUNT(*)                                                     AS customers,
       ROUND(100.0 * SUM(CASE WHEN a.status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_pct
FROM accounts a
JOIN onboarding o ON o.account_id = a.account_id
GROUP BY o.onboarding_status
ORDER BY churn_pct DESC;


/* ---------------------------------------------------------------------
   SECTION 4 — NPS, ENGAGEMENT, ONBOARDING
   --------------------------------------------------------------------- */
-- @query kpi_nps_by_segment
-- NPS = % promoters (9-10) minus % detractors (0-6), last 12 months
SELECT a.segment,
       COUNT(*) AS responses,
       ROUND(100.0 * SUM(CASE WHEN n.nps_score >= 9 THEN 1 ELSE 0 END) / COUNT(*), 1) AS promoters_pct,
       ROUND(100.0 * SUM(CASE WHEN n.nps_score <= 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS detractors_pct,
       ROUND(100.0 * (SUM(CASE WHEN n.nps_score >= 9 THEN 1 ELSE 0 END)
                    - SUM(CASE WHEN n.nps_score <= 6 THEN 1 ELSE 0 END)) / COUNT(*), 0) AS nps
FROM nps_responses n
JOIN accounts a ON a.account_id = n.account_id
WHERE n.survey_date >= '2025-09-01'
GROUP BY a.segment;

-- @query engagement_trend
-- Seat utilisation = active users / licensed seats
SELECT month,
       ROUND(100.0 * SUM(active_users) / SUM(licensed_seats), 1) AS seat_utilisation_pct,
       ROUND(AVG(features_adopted), 1)                           AS avg_features_adopted
FROM product_usage
GROUP BY month
ORDER BY month;

-- @query churn_warning_signal
-- Usage in a churned customer's final 3 months vs. healthy customers' last 3 months
WITH ranked AS (
    SELECT u.account_id, a.status, u.active_users, u.licensed_seats,
           ROW_NUMBER() OVER (PARTITION BY u.account_id ORDER BY u.month DESC) AS rn
    FROM product_usage u
    JOIN accounts a ON a.account_id = u.account_id
)
SELECT status,
       ROUND(100.0 * SUM(active_users) / SUM(licensed_seats), 1) AS utilisation_last_3_months_pct
FROM ranked
WHERE rn <= 3
GROUP BY status;

-- @query onboarding_by_segment
SELECT a.segment,
       COUNT(*)                                     AS customers,
       ROUND(AVG(o.days_to_go_live), 1)             AS avg_days_to_go_live,
       MAX(o.target_days)                           AS target_days,
       ROUND(100.0 * SUM(CASE WHEN o.onboarding_status = 'Completed On Time' THEN 1 ELSE 0 END)
             / SUM(CASE WHEN o.onboarding_status <> 'In Progress' THEN 1 ELSE 0 END), 1) AS on_time_pct,
       ROUND(AVG(o.onboarding_csat), 2)             AS avg_onboarding_csat
FROM accounts a
JOIN onboarding o ON o.account_id = a.account_id
GROUP BY a.segment;


/* ---------------------------------------------------------------------
   SECTION 5 — CUSTOMER HEALTH SCORE  (the heart of the project)
   One row per ACTIVE customer. Import this view into Power BI & Excel.

   Component              Weight   How it is scored (0-100)
   Product usage            35%    seat utilisation, 90%+ = 100
   NPS                      20%    latest score x 10 (no survey = 50)
   Support load             15%    tickets in last 90 days (fewer = better)
   Onboarding               10%    on time 100 / late 60 / in progress 50
   Revenue trend            20%    MRR now vs 3 months ago (up 100/flat 70/down 30)

   Risk tier:  80+ Healthy · 65-79 Needs Attention · <65 High Risk
   --------------------------------------------------------------------- */
CREATE VIEW vw_account_health AS
WITH usage_3m AS (
    SELECT account_id,
           1.0 * SUM(active_users) / SUM(licensed_seats) AS utilisation,
           AVG(features_adopted)                         AS avg_features
    FROM product_usage
    WHERE month >= '2026-07-01'
    GROUP BY account_id
),
nps_latest AS (
    SELECT account_id, nps_score
    FROM (SELECT account_id, nps_score,
                 ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY survey_date DESC) AS rn
          FROM nps_responses) x
    WHERE rn = 1
),
tickets_90d AS (
    SELECT account_id, COUNT(*) AS tickets
    FROM support_tickets
    WHERE created_date >= '2026-06-01'
    GROUP BY account_id
),
mrr_trend AS (
    SELECT account_id,
           SUM(CASE WHEN month = '2026-09-01' THEN mrr ELSE 0 END) AS mrr_now,
           SUM(CASE WHEN month = '2026-06-01' THEN mrr ELSE 0 END) AS mrr_3m_ago
    FROM monthly_revenue
    WHERE month IN ('2026-06-01', '2026-09-01')
    GROUP BY account_id
),
scored AS (
    SELECT a.account_id, a.company_name, a.segment, a.plan, a.region, a.industry,
           a.csm_owner, a.renewal_date, a.price_per_seat,
           m.mrr_now, m.mrr_3m_ago,
           ROUND(u.utilisation, 3)               AS utilisation,
           ROUND(u.avg_features, 1)              AS avg_features,
           n.nps_score                           AS latest_nps,
           COALESCE(t.tickets, 0)                AS tickets_90d,
           o.onboarding_status,
           -- component scores
           CASE WHEN u.utilisation >= 0.90 THEN 100
                ELSE ROUND(100 * u.utilisation / 0.90, 0) END              AS usage_score,
           COALESCE(n.nps_score * 10, 50)                                   AS nps_component,
           CASE WHEN COALESCE(t.tickets,0) <= 1 THEN 100
                WHEN t.tickets <= 3 THEN 75
                WHEN t.tickets <= 6 THEN 50 ELSE 20 END                     AS support_score,
           CASE o.onboarding_status WHEN 'Completed On Time' THEN 100
                                    WHEN 'Completed Late'    THEN 60 ELSE 50 END AS onboarding_score,
           CASE WHEN m.mrr_3m_ago = 0           THEN 70      -- new customer
                WHEN m.mrr_now > m.mrr_3m_ago   THEN 100
                WHEN m.mrr_now = m.mrr_3m_ago   THEN 70 ELSE 30 END         AS growth_score
    FROM accounts a
    JOIN mrr_trend  m ON m.account_id = a.account_id
    JOIN usage_3m   u ON u.account_id = a.account_id
    LEFT JOIN nps_latest  n ON n.account_id = a.account_id
    LEFT JOIN tickets_90d t ON t.account_id = a.account_id
    JOIN onboarding o ON o.account_id = a.account_id
    WHERE a.status = 'Active'
),
weighted AS (
    SELECT s.*,
           ROUND(0.35*usage_score + 0.20*nps_component + 0.15*support_score
               + 0.10*onboarding_score + 0.20*growth_score, 0)            AS health_score
    FROM scored s
)
SELECT w.*,
       CASE WHEN health_score >= 80 THEN 'Healthy'
            WHEN health_score >= 65 THEN 'Needs Attention'
            ELSE 'High Risk' END                                           AS risk_tier
FROM weighted w;

-- @query health_distribution
SELECT risk_tier,
       COUNT(*)            AS customers,
       SUM(mrr_now) * 12   AS arr,
       ROUND(AVG(health_score), 0) AS avg_health
FROM vw_account_health
GROUP BY risk_tier
ORDER BY avg_health DESC;


/* ---------------------------------------------------------------------
   SECTION 6 — ACTION LISTS FOR THE CS TEAM
   --------------------------------------------------------------------- */
-- @query renewals_at_risk
-- Renewals in the next 6 months that are NOT healthy, biggest ARR first
SELECT account_id, company_name, segment, csm_owner, renewal_date,
       mrr_now * 12 AS arr, health_score, risk_tier, utilisation, latest_nps
FROM vw_account_health
WHERE renewal_date < '2027-03-01'
  AND risk_tier <> 'Healthy'
ORDER BY arr DESC;

-- @query expansion_opportunities
-- Healthy customers that are nearly out of seats -> upsell 20% more seats
-- Healthy Starter/Growth customers using many features -> plan upgrade
SELECT account_id, company_name, segment, plan, csm_owner, health_score,
       utilisation, avg_features, mrr_now,
       CASE WHEN utilisation >= 0.90 THEN 'Seat expansion'
            ELSE 'Plan upgrade' END                               AS opportunity_type,
       CASE WHEN utilisation >= 0.90 THEN ROUND(mrr_now * 0.20, 0)
            WHEN plan = 'Starter'    THEN ROUND(mrr_now * (25.0/12 - 1), 0)
            ELSE                          ROUND(mrr_now * (45.0/25 - 1), 0) END AS potential_added_mrr
FROM vw_account_health
WHERE risk_tier = 'Healthy'
  AND (utilisation >= 0.90 OR (plan <> 'Enterprise' AND avg_features >= 10.5))
ORDER BY potential_added_mrr DESC;

-- @query csm_portfolio
SELECT csm_owner,
       COUNT(*)                     AS accounts,
       SUM(mrr_now) * 12            AS arr_managed,
       ROUND(AVG(health_score), 0)  AS avg_health,
       SUM(CASE WHEN risk_tier = 'High Risk' THEN 1 ELSE 0 END) AS high_risk_accounts
FROM vw_account_health
GROUP BY csm_owner
ORDER BY arr_managed DESC;


/* ---------------------------------------------------------------------
   SECTION 7 — PROVE THE HEALTH SCORE WORKS (backtest)
   The ready-to-run version is sql/backtest_health_score.sql.
   The idea: copy vw_account_health, shift every date back 12 months
   ('2026-07-01' -> '2025-07-01', '2026-06-01' -> '2025-06-01',
    '2026-09-01' -> '2025-09-01'), save it as vw_health_2025, then:

   SELECT h.risk_tier, COUNT(*) AS customers,
          ROUND(100.0 * SUM(CASE WHEN a.churn_date < '2026-09-01' THEN 1 ELSE 0 END)
                / COUNT(*), 1) AS churned_next_12m_pct
   FROM vw_health_2025 h JOIN accounts a ON a.account_id = h.account_id
   GROUP BY h.risk_tier;

   Result on this dataset: High Risk 42.7% churned, Needs Attention 13.9%,
   Healthy 6.3%  -> High Risk customers churned ~7x more often.
   (The view filters status = 'Active' today; for the backtest remove
    that filter, because the join to monthly_revenue already limits it to
    customers who were paying in Sep 2025.)
   --------------------------------------------------------------------- */
