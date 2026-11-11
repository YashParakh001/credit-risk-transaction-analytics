# Credit Risk & Transaction Analytics

A full-stack analytics project for exploring synthetic credit-card transaction data, delinquency risk, fraud patterns, and customer cohorts.

## Stack
- PostgreSQL
- SQL (CTEs, window functions, cohort analysis)
- Node.js + Express + TypeScript
- Angular + TypeScript
- Docker Compose

## What the project demonstrates
- Relational modeling for customers, accounts, transactions, and payments
- 100,000+ synthetic credit-card transactions generated directly in PostgreSQL
- SQL risk analysis using CTEs and window functions
- Threshold-based fraud-pattern analysis
- Cohort-level credit insights
- REST endpoints for dashboard data
- Angular dashboard for KPIs, risk distribution, trends, and high-risk accounts

## Quick start

### 1. Start PostgreSQL and API
```bash
docker compose up --build
```

The database initializes automatically with:
- schema
- 2,000 synthetic customers
- 2,000 accounts
- 120,000 transactions
- payment history
- analytical views

API:
`http://localhost:3000/api`

### 2. Run Angular frontend
In another terminal:

```bash
cd frontend
npm install
npm start
```

Frontend:
`http://localhost:4200`

## Main API routes

- `GET /api/health`
- `GET /api/dashboard/summary`
- `GET /api/dashboard/monthly-trends`
- `GET /api/dashboard/risk-distribution`
- `GET /api/dashboard/high-risk-accounts?limit=20`
- `GET /api/dashboard/cohorts`
- `GET /api/dashboard/fraud-patterns?threshold=1500`

## Example analytics

### Delinquency risk
Uses payment behavior, utilization, balance, and missed-payment streaks.

### Fraud patterns
Flags:
- unusually high-value transactions
- rapid transaction bursts
- high foreign-transaction share
- abnormal merchant/category concentration

### Cohort analysis
Groups customers by account-open month and calculates average utilization, delinquency rate, and transaction volume.

## Resume-aligned scope
This reconstructed project is designed to match the project description:
- complex SQL using CTEs and window functions
- 100,000+ synthetic credit-card transactions
- delinquency-risk analysis
- fraud-pattern and cohort pipelines
- Angular/TypeScript dashboard
