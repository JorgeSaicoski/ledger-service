# Ledger Service Test Suite

This directory contains automated integration tests for the Transaction Ledger Service API following Test-Driven Development (TDD) principles.

## Overview

The test suite uses curl commands to validate all API endpoints against the requirements specified in `requirements.md`. Tests are written in Bash and can be run locally or integrated into CI/CD pipelines.

## Test Structure

```
tests/
├── run_tests.sh                    # Main test runner
├── test_config.sh                  # Shared configuration and helper functions
├── test_create_transaction.sh      # Tests for POST /transactions
├── test_get_transaction.sh         # Tests for GET /transactions/{id}
├── test_list_transactions.sh       # Tests for GET /transactions (list)
└── test_balance.sh                 # Tests for GET /balance
```

## Prerequisites

- **curl**: For making HTTP requests
- **jq**: For JSON parsing (install with `apt-get install jq` or `brew install jq`)
- **bash**: Version 4.0 or higher

## Running Tests

### Quick Start

1. Start the ledger service on `http://localhost:8080` (default)
2. Run all tests:
   ```bash
   ./tests/run_tests.sh
   ```

### Custom Configuration

You can customize the test configuration using environment variables:

```bash
# Test against a different URL
TEST_BASE_URL=http://localhost:3000 ./tests/run_tests.sh

# Use a different allowed origin
TEST_ALLOWED_ORIGIN=http://my-gateway.local ./tests/run_tests.sh

# Combine multiple configurations
TEST_BASE_URL=https://staging.example.com \
TEST_ALLOWED_ORIGIN=http://staging-gateway.local \
./tests/run_tests.sh
```

### Running Individual Test Suites

You can run individual test suites separately:

```bash
# Test only transaction creation
./tests/test_create_transaction.sh

# Test only balance calculations
./tests/test_balance.sh

# Test only transaction retrieval
./tests/test_get_transaction.sh

# Test only transaction listing
./tests/test_list_transactions.sh
```

## Test Coverage

### POST /transactions (10 tests)
- ✓ Create transaction with valid data and allowed origin (201)
- ✓ Create transaction with disallowed origin returns 403
- ✓ Create transaction without Origin header returns 403
- ✓ Create transaction with missing user_id returns 400
- ✓ Create transaction with missing amount returns 400
- ✓ Create transaction with missing currency returns 400
- ✓ Create transaction with negative amount (201)
- ✓ Create transaction with different currency (loyalty_points)
- ✓ Create transaction with invalid JSON returns 400
- ✓ Create transaction with empty user_id returns 400

### GET /transactions/{id} (4 tests)
- ✓ Get transaction by valid ID (200)
- ✓ Get transaction with non-existent ID returns 404
- ✓ Get transaction with invalid UUID format returns 400
- ✓ Verify transaction data integrity

### GET /transactions (list) (7 tests)
- ✓ List transactions by user_id (200)
- ✓ List transactions by user_id and currency (200)
- ✓ List transactions without user_id returns 400
- ✓ List transactions with limit parameter
- ✓ List transactions with offset parameter
- ✓ Verify transactions are ordered by timestamp DESC
- ✓ List transactions for user with no transactions returns empty array

### GET /balance (7 tests)
- ✓ Get balance for specific user and currency (200)
- ✓ Get all balances for user (200)
- ✓ Get balance without user_id returns 400
- ✓ Get balance for user with no transactions returns 0
- ✓ Get all balances for user with no transactions returns empty array
- ✓ Balance calculation with only negative transactions
- ✓ Balance calculation with decimal precision

**Total: 28 comprehensive tests**

## Test Output

The test suite provides color-coded output:
- 🟢 **GREEN**: Test passed
- 🔴 **RED**: Test failed (with details)
- 🟡 **YELLOW**: Warnings

Example output:
```
=========================================
Ledger Service API Test Suite
=========================================
Base URL: http://localhost:8080
Allowed Origin: http://internal-gateway.local
=========================================

=========================================
Testing POST /transactions
=========================================
✓ PASS: Create transaction with allowed origin
✓ PASS: Create transaction with disallowed origin returns 403
✓ PASS: Create transaction without Origin header returns 403
...

=========================================
Test Summary
=========================================
Total tests run: 28
Passed: 28
Failed: 0
=========================================
All tests passed!
```

## CI/CD Integration

### GitHub Actions

Add this workflow to `.github/workflows/test.yml`:

```yaml
name: API Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: ledger_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
      
      - name: Build service
        run: go build -o ledger-service ./cmd/server
      
      - name: Run service
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/ledger_test?sslmode=disable
          ALLOWED_ORIGIN: http://internal-gateway.local
        run: |
          ./ledger-service &
          sleep 5  # Wait for service to start
      
      - name: Run tests
        env:
          TEST_BASE_URL: http://localhost:8080
          TEST_ALLOWED_ORIGIN: http://internal-gateway.local
        run: |
          chmod +x tests/*.sh
          ./tests/run_tests.sh
```

### GitLab CI

Add this to `.gitlab-ci.yml`:

```yaml
test:
  stage: test
  image: golang:1.21
  
  services:
    - postgres:15
  
  variables:
    POSTGRES_DB: ledger_test
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    DATABASE_URL: "postgres://postgres:postgres@postgres:5432/ledger_test?sslmode=disable"
    ALLOWED_ORIGIN: "http://internal-gateway.local"
  
  before_script:
    - apt-get update && apt-get install -y jq curl
    - go build -o ledger-service ./cmd/server
  
  script:
    - ./ledger-service &
    - sleep 5
    - chmod +x tests/*.sh
    - TEST_BASE_URL=http://localhost:8080 TEST_ALLOWED_ORIGIN=http://internal-gateway.local ./tests/run_tests.sh
```

### Jenkins

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                sh 'apt-get update && apt-get install -y jq'
            }
        }
        
        stage('Build') {
            steps {
                sh 'go build -o ledger-service ./cmd/server'
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    ./ledger-service &
                    sleep 5
                    chmod +x tests/*.sh
                    TEST_BASE_URL=http://localhost:8080 ./tests/run_tests.sh
                '''
            }
        }
    }
}
```

## Test Development Guidelines

When adding new tests:

1. **Follow TDD**: Write tests before implementation
2. **Test one thing**: Each test should verify a single behavior
3. **Use descriptive names**: Test names should clearly describe what they test
4. **Check status codes**: Always verify the HTTP status code
5. **Validate response structure**: Check for required JSON fields
6. **Test edge cases**: Include negative tests and boundary conditions
7. **Clean test data**: Each test should be independent and not rely on other tests
8. **Add to summary**: Update this README with new test counts

## Troubleshooting

### Tests fail to connect
- Ensure the service is running: `curl http://localhost:8080`
- Check the BASE_URL matches your service URL
- Verify no firewall is blocking connections

### JSON parsing errors
- Install jq: `apt-get install jq` or `brew install jq`
- Verify jq is in PATH: `which jq`

### Permission denied
- Make scripts executable: `chmod +x tests/*.sh`

### Origin header tests fail
- Ensure ALLOWED_ORIGIN environment variable is set correctly in the service
- Verify the test is using the same ALLOWED_ORIGIN value

## Contributing

When adding new features to the ledger service:

1. Write tests first (TDD approach)
2. Run existing tests to ensure no regression
3. Add new test files for new endpoints
4. Update this README with new test coverage
5. Ensure all tests pass before submitting PR

## License

Same as the parent project.
