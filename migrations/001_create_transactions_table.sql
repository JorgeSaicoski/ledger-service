-- migrations/001_create_transactions_table.sql
-- Create transactions table according to project requirements

-- Enable pgcrypto for gen_random_uuid (may require superuser). If not available, the app can generate UUIDs.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  amount BIGINT NOT NULL,
  currency TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure lowercase UUID format for user_id via a CHECK using regex
ALTER TABLE transactions
  ADD CONSTRAINT IF NOT EXISTS user_id_uuid_lowercase_chk CHECK (user_id ~ '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$');

-- Currency constraint: lowercase letters, numbers and underscores only
ALTER TABLE transactions
  ADD CONSTRAINT IF NOT EXISTS currency_format_chk CHECK (currency ~ '^[a-z0-9_]+$');

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_transactions_user_currency ON transactions (user_id, currency);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions (timestamp);

