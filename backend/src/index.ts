import express from "express";
import cors from "cors";
import { pool } from "./db";

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json());

app.get("/api/health", async (_req, res) => {
  const result = await pool.query("SELECT NOW() AS now");
  res.json({ ok: true, databaseTime: result.rows[0].now });
});

app.get("/api/dashboard/summary", async (_req, res) => {
  const result = await pool.query(`
    SELECT
      (SELECT COUNT(*)::int FROM transactions) AS transactions,
      (SELECT COUNT(*)::int FROM customers) AS customers,
      ROUND(AVG(risk_score)::numeric, 2) AS avg_risk_score,
      COUNT(*) FILTER (WHERE risk_score >= 60)::int AS high_risk_accounts,
      ROUND(AVG(utilization)::numeric, 4) AS avg_utilization
    FROM ranked_account_risk
  `);
  res.json(result.rows[0]);
});

app.get("/api/dashboard/monthly-trends", async (_req, res) => {
  const result = await pool.query(`
    SELECT * FROM monthly_transaction_trends ORDER BY month
  `);
  res.json(result.rows);
});

app.get("/api/dashboard/risk-distribution", async (_req, res) => {
  const result = await pool.query(`
    SELECT
      CASE
        WHEN risk_score < 25 THEN 'Low'
        WHEN risk_score < 45 THEN 'Moderate'
        WHEN risk_score < 60 THEN 'Elevated'
        ELSE 'High'
      END AS risk_band,
      COUNT(*)::int AS accounts,
      ROUND(AVG(risk_score)::numeric, 2) AS avg_score
    FROM ranked_account_risk
    GROUP BY 1
    ORDER BY MIN(risk_score)
  `);
  res.json(result.rows);
});

app.get("/api/dashboard/high-risk-accounts", async (req, res) => {
  const requested = Number(req.query.limit ?? 20);
  const limit = Math.max(1, Math.min(requested, 100));

  const result = await pool.query(`
    SELECT
      account_id,
      customer_id,
      state,
      credit_score,
      utilization,
      late_or_missed_payments,
      avg_days_late,
      risk_score,
      risk_rank
    FROM ranked_account_risk
    ORDER BY risk_score DESC
    LIMIT $1
  `, [limit]);

  res.json(result.rows);
});

app.get("/api/dashboard/cohorts", async (_req, res) => {
  const result = await pool.query(`
    SELECT * FROM customer_cohorts ORDER BY cohort_month
  `);
  res.json(result.rows);
});

app.get("/api/dashboard/fraud-patterns", async (req, res) => {
  const threshold = Math.max(100, Number(req.query.threshold ?? 1500));

  const result = await pool.query(`
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
    )
    SELECT
      transaction_id,
      account_id,
      occurred_at,
      amount,
      merchant,
      country,
      txns_in_15m,
      spend_in_15m,
      CASE
        WHEN amount >= $1 THEN 'HIGH_VALUE'
        WHEN txns_in_15m >= 4 THEN 'VELOCITY'
        WHEN spend_in_15m >= ($1 * 1.75) THEN 'BURST_SPEND'
        WHEN country <> 'US' AND amount >= ($1 * 0.5) THEN 'FOREIGN_HIGH_VALUE'
      END AS fraud_pattern
    FROM ordered_txns
    WHERE
      amount >= $1
      OR txns_in_15m >= 4
      OR spend_in_15m >= ($1 * 1.75)
      OR (country <> 'US' AND amount >= ($1 * 0.5))
    ORDER BY occurred_at DESC
    LIMIT 100
  `, [threshold]);

  res.json(result.rows);
});

app.listen(port, () => {
  console.log(`Credit Risk Analytics API running on port ${port}`);
});
