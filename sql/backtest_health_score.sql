/* =====================================================================
   HEALTH SCORE BACKTEST
   Scores every customer who was paying in Sep 2025, using only data
   available up to that month, then checks who churned in the next 12 months.
   Same rules and weights as vw_account_health in customer_success_analysis.sql.
   Expected result: High Risk 42.7% churned, Needs Attention 13.9%, Healthy 6.3%.
   ===================================================================== */
WITH usage_3m AS (
    SELECT account_id, 1.0 * SUM(active_users) / SUM(licensed_seats) AS utilisation
    FROM product_usage
    WHERE month BETWEEN '2025-07-01' AND '2025-09-01'
    GROUP BY account_id
),
nps_latest AS (
    SELECT account_id, nps_score
    FROM (SELECT account_id, nps_score,
                 ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY survey_date DESC) AS rn
          FROM nps_responses
          WHERE survey_date < '2025-09-01') x
    WHERE rn = 1
),
tickets_90d AS (
    SELECT account_id, COUNT(*) AS tickets
    FROM support_tickets
    WHERE created_date >= '2025-06-01' AND created_date < '2025-09-01'
    GROUP BY account_id
),
mrr_trend AS (
    SELECT account_id,
           SUM(CASE WHEN month = '2025-09-01' THEN mrr ELSE 0 END) AS mrr_now,
           SUM(CASE WHEN month = '2025-06-01' THEN mrr ELSE 0 END) AS mrr_3m_ago
    FROM monthly_revenue
    WHERE month IN ('2025-06-01', '2025-09-01')
    GROUP BY account_id
),
scored AS (
    SELECT a.account_id, a.churn_date,
           ROUND(0.35 * CASE WHEN u.utilisation >= 0.90 THEN 100
                             ELSE ROUND(100 * u.utilisation / 0.90, 0) END
               + 0.20 * COALESCE(n.nps_score * 10, 50)
               + 0.15 * CASE WHEN COALESCE(t.tickets, 0) <= 1 THEN 100
                             WHEN t.tickets <= 3 THEN 75
                             WHEN t.tickets <= 6 THEN 50 ELSE 20 END
               + 0.10 * CASE o.onboarding_status WHEN 'Completed On Time' THEN 100
                                                 WHEN 'Completed Late' THEN 60 ELSE 50 END
               + 0.20 * CASE WHEN m.mrr_3m_ago = 0 THEN 70
                             WHEN m.mrr_now > m.mrr_3m_ago THEN 100
                             WHEN m.mrr_now = m.mrr_3m_ago THEN 70 ELSE 30 END, 0) AS health_score
    FROM accounts a
    JOIN mrr_trend m ON m.account_id = a.account_id AND m.mrr_now > 0
    JOIN usage_3m u ON u.account_id = a.account_id
    LEFT JOIN nps_latest n ON n.account_id = a.account_id
    LEFT JOIN tickets_90d t ON t.account_id = a.account_id
    JOIN onboarding o ON o.account_id = a.account_id
)
SELECT CASE WHEN health_score >= 80 THEN 'Healthy'
            WHEN health_score >= 65 THEN 'Needs Attention'
            ELSE 'High Risk' END AS risk_tier_sep_2025,
       COUNT(*) AS customers,
       SUM(CASE WHEN churn_date < '2026-09-01' THEN 1 ELSE 0 END) AS churned_next_12m,
       ROUND(100.0 * SUM(CASE WHEN churn_date < '2026-09-01' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_pct
FROM scored
GROUP BY risk_tier_sep_2025
ORDER BY churn_pct DESC;
