CREATE OR REPLACE VIEW account_risk_features AS
WITH payment_stats AS (
    SELECT
        account_id,
        COUNT(*) AS payment_cycles,
        COUNT(*) FILTER (
            WHERE paid_date IS NULL OR paid_date > due_date
        ) AS late_or_missed_payments,
        AVG(
            CASE
                WHEN paid_date IS NULL THEN 30
                ELSE GREATEST(paid_date - due_date, 0)
            END
        ) AS avg_days_late
    FROM payments
    GROUP BY account_id
),
transaction_stats AS (
    SELECT
        account_id,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_spend,
        AVG(amount) AS avg_transaction_amount,
        MAX(amount) AS max_transaction_amount,
        COUNT(*) FILTER (WHERE country <> 'US') AS foreign_transactions,
        COUNT(*) FILTER (WHERE declined) AS declined_transactions
    FROM transactions
    GROUP BY account_id
)
SELECT
    a.account_id,
    a.customer_id,
    a.credit_limit,
    a.current_balance,
    ROUND((a.current_balance / NULLIF(a.credit_limit, 0))::numeric, 4) AS utilization,
    COALESCE(p.payment_cycles, 0) AS payment_cycles,
    COALESCE(p.late_or_missed_payments, 0) AS late_or_missed_payments,
    ROUND(COALESCE(p.avg_days_late, 0)::numeric, 2) AS avg_days_late,
    COALESCE(t.transaction_count, 0) AS transaction_count,
    ROUND(COALESCE(t.total_spend, 0)::numeric, 2) AS total_spend,
    ROUND(COALESCE(t.avg_transaction_amount, 0)::numeric, 2) AS avg_transaction_amount,
    ROUND(COALESCE(t.max_transaction_amount, 0)::numeric, 2) AS max_transaction_amount,
    COALESCE(t.foreign_transactions, 0) AS foreign_transactions,
    COALESCE(t.declined_transactions, 0) AS declined_transactions,
    ROUND((
        LEAST((a.current_balance / NULLIF(a.credit_limit, 0)) * 35, 35)
        + LEAST(COALESCE(p.late_or_missed_payments, 0) * 8, 32)
        + LEAST(COALESCE(p.avg_days_late, 0) * 0.8, 18)
        + LEAST(COALESCE(t.declined_transactions, 0) * 1.5, 8)
        + LEAST(COALESCE(t.foreign_transactions, 0) * 0.3, 7)
    )::numeric, 2) AS risk_score
FROM accounts a
LEFT JOIN payment_stats p USING (account_id)
LEFT JOIN transaction_stats t USING (account_id);

CREATE OR REPLACE VIEW ranked_account_risk AS
SELECT
    arf.*,
    c.credit_score,
    c.annual_income,
    c.state,
    NTILE(5) OVER (ORDER BY arf.risk_score DESC) AS risk_quintile,
    DENSE_RANK() OVER (ORDER BY arf.risk_score DESC) AS risk_rank
FROM account_risk_features arf
JOIN customers c USING (customer_id);

CREATE OR REPLACE VIEW monthly_transaction_trends AS
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', occurred_at)::date AS month,
        COUNT(*) AS transaction_count,
        SUM(amount) AS transaction_volume,
        AVG(amount) AS avg_ticket,
        COUNT(*) FILTER (WHERE declined) AS declines,
        COUNT(*) FILTER (WHERE country <> 'US') AS foreign_txns
    FROM transactions
    GROUP BY 1
)
SELECT
    month,
    transaction_count,
    ROUND(transaction_volume::numeric, 2) AS transaction_volume,
    ROUND(avg_ticket::numeric, 2) AS avg_ticket,
    declines,
    foreign_txns,
    ROUND(
        100.0 * (transaction_volume - LAG(transaction_volume) OVER (ORDER BY month))
        / NULLIF(LAG(transaction_volume) OVER (ORDER BY month), 0),
        2
    ) AS volume_growth_pct
FROM monthly
ORDER BY month;

CREATE OR REPLACE VIEW customer_cohorts AS
WITH cohort_accounts AS (
    SELECT
        a.account_id,
        a.customer_id,
        DATE_TRUNC('month', a.opened_at)::date AS cohort_month,
        a.current_balance / NULLIF(a.credit_limit, 0) AS utilization,
        CASE WHEN a.account_status = 'DELINQUENT' THEN 1 ELSE 0 END AS delinquent
    FROM accounts a
)
SELECT
    cohort_month,
    COUNT(*) AS accounts,
    ROUND(AVG(ca.utilization)::numeric, 4) AS avg_utilization,
    ROUND(100.0 * AVG(ca.delinquent)::numeric, 2) AS delinquency_rate_pct,
    ROUND(AVG(r.risk_score)::numeric, 2) AS avg_risk_score
FROM cohort_accounts ca
JOIN ranked_account_risk r USING (account_id)
GROUP BY cohort_month
ORDER BY cohort_month;
