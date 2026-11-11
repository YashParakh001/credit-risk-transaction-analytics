-- 1. Highest-risk accounts
SELECT
    account_id,
    customer_id,
    risk_score,
    utilization,
    late_or_missed_payments,
    avg_days_late,
    credit_score,
    risk_rank
FROM ranked_account_risk
ORDER BY risk_score DESC
LIMIT 25;

-- 2. Fraud-pattern pipeline:
-- combines threshold analysis with rolling-window activity
WITH ordered_txns AS (
    SELECT
        t.*,
        COUNT(*) OVER (
            PARTITION BY account_id
            ORDER BY occurred_at
            RANGE BETWEEN INTERVAL '15 minutes' PRECEDING AND CURRENT ROW
        ) AS txns_in_15m,
        SUM(amount) OVER (
            PARTITION BY account_id
            ORDER BY occurred_at
            RANGE BETWEEN INTERVAL '15 minutes' PRECEDING AND CURRENT ROW
        ) AS spend_in_15m
    FROM transactions t
),
flags AS (
    SELECT *,
        CASE
            WHEN amount >= 1500 THEN 'HIGH_VALUE'
            WHEN txns_in_15m >= 4 THEN 'VELOCITY'
            WHEN spend_in_15m >= 2500 THEN 'BURST_SPEND'
            WHEN country <> 'US' AND amount >= 700 THEN 'FOREIGN_HIGH_VALUE'
            ELSE NULL
        END AS fraud_pattern
    FROM ordered_txns
)
SELECT *
FROM flags
WHERE fraud_pattern IS NOT NULL
ORDER BY occurred_at DESC;

-- 3. Risk by credit-score band
SELECT
    CASE
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score < 670 THEN 'Fair'
        WHEN credit_score < 740 THEN 'Good'
        WHEN credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END AS score_band,
    COUNT(*) AS accounts,
    ROUND(AVG(risk_score)::numeric, 2) AS avg_risk_score,
    ROUND(AVG(utilization)::numeric, 4) AS avg_utilization
FROM ranked_account_risk
GROUP BY 1
ORDER BY MIN(credit_score);

-- 4. Cohort analytics
SELECT * FROM customer_cohorts;
