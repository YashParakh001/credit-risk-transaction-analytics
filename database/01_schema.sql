CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    state CHAR(2) NOT NULL,
    annual_income NUMERIC(12,2) NOT NULL CHECK (annual_income >= 0),
    credit_score INT NOT NULL CHECK (credit_score BETWEEN 300 AND 850),
    created_at DATE NOT NULL
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    opened_at DATE NOT NULL,
    credit_limit NUMERIC(12,2) NOT NULL CHECK (credit_limit > 0),
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
    apr NUMERIC(5,2) NOT NULL,
    account_status TEXT NOT NULL CHECK (account_status IN ('ACTIVE','DELINQUENT','CLOSED'))
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    occurred_at TIMESTAMP NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    merchant TEXT NOT NULL,
    category TEXT NOT NULL,
    channel TEXT NOT NULL CHECK (channel IN ('CARD_PRESENT','ONLINE','MOBILE')),
    country CHAR(2) NOT NULL,
    declined BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE payments (
    payment_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    due_date DATE NOT NULL,
    paid_date DATE,
    amount_due NUMERIC(10,2) NOT NULL,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0
);

CREATE INDEX idx_transactions_account_time
    ON transactions(account_id, occurred_at);

CREATE INDEX idx_transactions_amount
    ON transactions(amount);

CREATE INDEX idx_payments_account_due
    ON payments(account_id, due_date);
