SELECT setseed(0.42);

INSERT INTO customers (
    first_name, last_name, state, annual_income, credit_score, created_at
)
SELECT
    'Customer' || g,
    'User' || g,
    (ARRAY['NC','NY','CA','TX','FL','VA','GA','IL'])[1 + floor(random()*8)::int],
    round((30000 + random()*170000)::numeric, 2),
    (520 + floor(random()*300))::int,
    DATE '2023-01-01' + floor(random()*900)::int
FROM generate_series(1, 2000) g;

INSERT INTO accounts (
    customer_id, opened_at, credit_limit, current_balance, apr, account_status
)
SELECT
    c.customer_id,
    c.created_at,
    round((1500 + random()*23500)::numeric, 2),
    round((random()*9000)::numeric, 2),
    round((13 + random()*16)::numeric, 2),
    CASE
        WHEN random() < 0.06 THEN 'DELINQUENT'
        ELSE 'ACTIVE'
    END
FROM customers c;

INSERT INTO transactions (
    account_id, occurred_at, amount, merchant, category, channel, country, declined
)
SELECT
    1 + floor(random()*2000)::bigint,
    TIMESTAMP '2025-01-01'
        + (random() * INTERVAL '365 days'),
    round((
        CASE
            WHEN random() < 0.015 THEN 1200 + random()*4500
            ELSE 5 + random()*450
        END
    )::numeric, 2),
    (ARRAY['Amazon','Target','Walmart','Shell','Starbucks','Apple','Uber','Delta','Best Buy','Costco'])
        [1 + floor(random()*10)::int],
    (ARRAY['GROCERY','DINING','TRAVEL','GAS','RETAIL','ELECTRONICS','SERVICES'])
        [1 + floor(random()*7)::int],
    (ARRAY['CARD_PRESENT','ONLINE','MOBILE'])
        [1 + floor(random()*3)::int],
    CASE WHEN random() < 0.045
        THEN (ARRAY['GB','CA','MX','IN','DE'])[1 + floor(random()*5)::int]
        ELSE 'US'
    END,
    random() < 0.025
FROM generate_series(1, 120000);

INSERT INTO payments (
    account_id, due_date, paid_date, amount_due, amount_paid
)
SELECT
    a.account_id,
    d::date,
    CASE
        WHEN random() < 0.10 THEN NULL
        WHEN random() < 0.18 THEN (d + (1 + floor(random()*25)) * INTERVAL '1 day')::date
        ELSE (d - floor(random()*5) * INTERVAL '1 day')::date
    END,
    round((50 + random()*900)::numeric, 2),
    round((20 + random()*900)::numeric, 2)
FROM accounts a
CROSS JOIN generate_series(
    DATE '2025-01-15',
    DATE '2025-12-15',
    INTERVAL '1 month'
) d;

UPDATE accounts a
SET current_balance = LEAST(
    a.credit_limit * 1.15,
    COALESCE(t.total_spend, 0) * (0.10 + random()*0.20)
)
FROM (
    SELECT account_id, SUM(amount) AS total_spend
    FROM transactions
    GROUP BY account_id
) t
WHERE a.account_id = t.account_id;
