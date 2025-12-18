# Getting Started with TDD Implementation

This guide will help you implement the Transaction Ledger Service using the Test-Driven Development (TDD) approach with the provided test suite.

## Prerequisites

Before you start implementing:

1. **Review Documentation**
   - Read `requirements.md` - Complete API specifications
   - Read `README.md` - Service overview and use cases
   - Read `tests/README.md` - Test suite documentation
   - Read `tests/TEST_SPECIFICATION.md` - Detailed test cases

2. **Install Test Dependencies**
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install curl jq
   
   # On macOS
   brew install curl jq
   ```

3. **Set Up Database**
   - Install PostgreSQL 15+
   - Create database: `ledger_test` or `ledger_dev`
   - Run the DDL from `requirements.md`. For example:
     ```sql
     CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
     
     CREATE TABLE transactions (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       user_id UUID NOT NULL,
       amount NUMERIC(20, 8) NOT NULL,
       currency_code VARCHAR(3) NOT NULL,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now()
     );
     
     CREATE INDEX idx_transactions_user_currency_ts
       ON transactions (user_id, currency_code, created_at DESC);
     ```

## TDD Workflow

### Step 1: Run Tests (They Will Fail)

```bash
# This will fail because service doesn't exist yet
./tests/run_tests.sh
```

**Expected Output:**
```
❌ Cannot connect to http://localhost:8080
All 28 tests will fail
```

This is **GOOD** - tests failing means they're working!

### Step 2: Implement Minimal Service Skeleton

Choose your technology stack (examples provided):

#### Option A: Go
```bash
go mod init github.com/JorgeSaicoski/ledger-service
mkdir -p cmd/server
# Create main.go with HTTP server on port 8080
# Implement health check endpoint
```

#### Option B: Node.js
```bash
npm init -y
npm install express pg
# Create server.js with Express server
```

#### Option C: Python
```bash
python -m venv venv
source venv/bin/activate
pip install flask psycopg2-binary
# Create app.py with Flask server
```

### Step 3: Start Server and Verify Connection

```bash
# Terminal 1: Start your service
# For example: go run cmd/server/main.go
# Or: node server.js
# Or: python app.py

# Terminal 2: Test connection
curl http://localhost:8080
# Should return something (not connection error)
```

### Step 4: TDD Cycle - Implement One Endpoint at a Time

Follow this cycle for each endpoint:

#### 4.1 POST /transactions (Start Here)

**Run Tests:**
```bash
./tests/test_create_transaction.sh
```

**Implement Features:**
1. Origin header validation middleware
   - Check `Origin` header against `ALLOWED_ORIGIN` env var
   - Return 403 if mismatch or missing
   
2. Request validation
   - Verify user_id is non-empty string
   - Verify amount is valid number
   - Verify currency is non-empty string
   - Return 400 for validation failures

3. Database insertion
   - Generate UUID
   - Set current timestamp
   - Insert into transactions table
   - Return 201 with created object

**Re-run Tests:**
```bash
./tests/test_create_transaction.sh
```

Keep iterating until all 10 tests pass ✅

#### 4.2 GET /transactions/{id}

**Run Tests:**
```bash
./tests/test_get_transaction.sh
```

**Implement Features:**
1. UUID validation
2. Database query by ID
3. Return 404 if not found
4. Return 200 with transaction object

**Target:** All 4 tests pass ✅

#### 4.3 GET /transactions (List)

**Run Tests:**
```bash
./tests/test_list_transactions.sh
```

**Implement Features:**
1. Require user_id parameter (400 if missing)
2. Optional currency filter
3. Optional limit/offset pagination
4. ORDER BY timestamp DESC
5. Return transactions array

**Target:** All 7 tests pass ✅

#### 4.4 GET /balance

**Run Tests:**
```bash
./tests/test_balance.sh
```

**Implement Features:**
1. Require user_id parameter
2. If currency provided: return single balance
   - SQL: `SELECT SUM(amount) FROM transactions WHERE user_id = ? AND currency = ?`
3. If no currency: return all balances
   - SQL: `SELECT currency, SUM(amount) as balance FROM transactions WHERE user_id = ? GROUP BY currency`

**Target:** All 7 tests pass ✅

### Step 5: Run Full Test Suite

```bash
./tests/run_tests.sh
```

**Goal:** All 28 tests pass ✅

## Tips for TDD Success

### 1. Start Small
- Implement just enough to make one test pass
- Don't over-engineer
- Refactor after tests pass

### 2. Read Error Messages
Tests provide helpful error messages:
```
✗ FAIL: Create transaction with allowed origin
  Details: Expected status 201, got 500
```

This tells you exactly what's wrong!

### 3. Use Examples Script
```bash
./tests/examples.sh
```
Shows example API calls with responses.

### 4. Check One Test at a Time
```bash
# Focus on one test file
./tests/test_create_transaction.sh

# Or even one test function (edit the file temporarily)
```

### 5. Database Debugging
```sql
-- Check what's in the database
SELECT * FROM transactions ORDER BY timestamp DESC LIMIT 10;

-- Check balances manually
SELECT user_id, currency, SUM(amount) as balance 
FROM transactions 
GROUP BY user_id, currency;
```

### 6. Environment Variables
```bash
# Service configuration
export DATABASE_URL="postgres://user:pass@localhost/ledger_dev"
export ALLOWED_ORIGIN="http://internal-gateway.local"
export PORT="8080"

# Test configuration
export TEST_BASE_URL="http://localhost:8080"
export TEST_ALLOWED_ORIGIN="http://internal-gateway.local"
```

## Common Pitfalls & Solutions

### ❌ Tests timeout or hang
**Solution:** Check if service is running and accessible

### ❌ All create tests fail with 403
**Solution:** Verify ALLOWED_ORIGIN matches in both service and tests

### ❌ Balance calculations wrong
**Solution:** Check SQL SUM() query and ensure NUMERIC type in DB

### ❌ Timestamp format errors
**Solution:** Use ISO 8601 format: `2025-01-15T10:30:00Z`

### ❌ UUID errors
**Solution:** Use proper UUID v4 generation in your language

## Progress Tracking

Use this checklist:

```
Service Setup:
[ ] Database created and schema applied
[ ] Service starts without errors
[ ] Health/basic endpoint responds

POST /transactions (10 tests):
[ ] Security tests pass (3)
[ ] Validation tests pass (5)
[ ] Functional tests pass (2)

GET /transactions/{id} (4 tests):
[ ] All tests pass

GET /transactions list (7 tests):
[ ] All tests pass

GET /balance (7 tests):
[ ] All tests pass

Final:
[ ] All 28 tests pass
[ ] CI/CD enabled (uncomment in .github/workflows/tests.yml)
[ ] Documentation updated
```

## When You're Done

1. **Verify Everything:**
   ```bash
   ./tests/run_tests.sh
   # Should show: "All tests passed! ✅"
   ```

2. **Enable CI/CD:**
   - Edit `.github/workflows/tests.yml`
   - Uncomment the implementation steps
   - Push to GitHub

3. **Celebrate! 🎉**
   You've successfully implemented a fully tested service using TDD!

## Need Help?

- **Test failures:** Check `tests/TEST_SPECIFICATION.md` for detailed test specs
- **API questions:** Review `requirements.md` for exact specifications
- **Examples:** Run `./tests/examples.sh` to see working API calls
- **Architecture:** Review `README.md` for design decisions

## Next Steps After Implementation

1. Add logging (request ID, errors, slow queries)
2. Add metrics (request count, latency, error rate)
3. Add database connection pooling
4. Add more comprehensive error messages
5. Consider adding OpenAPI/Swagger docs
6. Deploy to production

---

**Remember:** The tests are your specification. When all tests pass, your implementation is complete!
