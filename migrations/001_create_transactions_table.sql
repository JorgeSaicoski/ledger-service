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

-- Add constraints
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'amount_check') THEN
        ALTER TABLE transactions ADD CONSTRAINT amount_check CHECK (amount <> 0);
    END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp);

