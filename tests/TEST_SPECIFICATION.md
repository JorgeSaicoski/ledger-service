# Test Specification Document
# Transaction Ledger Service - TDD Test Cases

## Overview
This document outlines all test cases for the Transaction Ledger Service API, organized by endpoint and requirement. These tests are implemented in the `tests/` directory following TDD principles.

## Test Environment Configuration

### Required Environment Variables
- `TEST_BASE_URL`: Service endpoint (default: http://localhost:8080)

### Prerequisites
- Service running and accessible
- PostgreSQL database initialized
- curl and jq installed

## Test Cases by Endpoint

### 1. POST /transactions

#### 1.1 Validation Tests

**Test Case 1.1.1: Valid Transaction Creation**
- **Description**: Transaction creation should succeed with valid data
- **Request**: POST /transactions
- **Request Body**: Valid transaction data
- **Expected**: 201 Created
- **Expected Response**: Transaction object with id, user_id, amount, currency, timestamp
- **Script**: test_create_transaction.sh::test_create_transaction_success

**Test Case 1.1.2: Missing user_id**
- **Description**: Request with missing user_id should fail
- **Requirement**: requirements.md - user_id non-empty
- **Request Body**: {"amount": 100, "currency": "usd"}
- **Expected**: 400 Bad Request
- **Script**: test_create_transaction.sh::test_create_transaction_missing_user_id

**Test Case 1.2.2: Missing amount**
- **Description**: Request with missing amount should fail
- **Requirement**: requirements.md - amount required
- **Request Body**: {"user_id": "user123", "currency": "usd"}
- **Expected**: 400 Bad Request
- **Script**: test_create_transaction.sh::test_create_transaction_missing_amount

**Test Case 1.2.3: Missing currency**
- **Description**: Request with missing currency should fail
- **Requirement**: requirements.md - currency required
- **Request Body**: {"user_id": "user123", "amount": 100}
- **Expected**: 400 Bad Request
- **Script**: test_create_transaction.sh::test_create_transaction_missing_currency

**Test Case 1.2.4: Empty user_id**
- **Description**: Request with empty user_id should fail
- **Requirement**: requirements.md - user_id non-empty
- **Request Body**: {"user_id": "", "amount": 100, "currency": "usd"}
- **Expected**: 400 Bad Request
- **Script**: test_create_transaction.sh::test_create_transaction_empty_user_id

**Test Case 1.2.5: Invalid JSON**
- **Description**: Malformed JSON should fail
- **Requirement**: requirements.md - invalid JSON returns 400
- **Request Body**: {invalid json}
- **Expected**: 400 Bad Request
- **Script**: test_create_transaction.sh::test_create_transaction_invalid_json

#### 1.3 Functional Tests

**Test Case 1.3.1: Negative Amount**
- **Description**: Transaction with negative amount should succeed
- **Requirement**: README.md - amounts can be negative
- **Request Body**: {"user_id": "user456", "amount": -7525, "currency": "usd"}
- **Expected**: 201 Created
- **Verification**: Response amount is -7525 (representing -$75.25)
- **Script**: test_create_transaction.sh::test_create_transaction_negative_amount
- **Note**: Amounts are stored in cents (smallest currency unit)

**Test Case 1.3.2: Multiple Currencies**
- **Description**: Different currency types should be supported
- **Requirement**: README.md - currency examples (usd, brl, loyalty_points)
- **Request Body**: {"user_id": "user789", "amount": 1000, "currency": "loyalty_points"}
- **Expected**: 201 Created
- **Verification**: Response currency is "loyalty_points"
- **Script**: test_create_transaction.sh::test_create_transaction_different_currency

**Test Case 1.3.3: UUID Generation**
- **Description**: Service should generate valid UUID for transaction
- **Requirement**: requirements.md - id (uuid, auto-generated)
- **Expected**: Response contains valid UUID in id field
- **Script**: test_create_transaction.sh::test_create_transaction_success

**Test Case 1.3.4: Timestamp Generation**
- **Description**: Service should auto-generate timestamp
- **Requirement**: requirements.md - timestamp (auto-generated)
- **Expected**: Response contains ISO 8601 timestamp
- **Script**: test_create_transaction.sh::test_create_transaction_success

---

### 2. GET /transactions/{id}

#### 2.1 Success Cases

**Test Case 2.1.1: Retrieve Existing Transaction**
- **Description**: Should return transaction when valid ID provided
- **Requirement**: requirements.md - GET /transactions/{id} returns single transaction
- **Request**: GET /transactions/{valid-uuid}
- **Expected**: 200 OK
- **Expected Response**: Full transaction object
- **Script**: test_get_transaction.sh::test_get_transaction_by_id

**Test Case 2.1.2: Data Integrity**
- **Description**: Retrieved data should match created data
- **Requirement**: Immutable transactions
- **Verification**: All fields match original creation
- **Script**: test_get_transaction.sh::test_get_transaction_data_integrity

#### 2.2 Error Cases

**Test Case 2.2.1: Non-existent ID**
- **Description**: Should return 404 for non-existent transaction
- **Requirement**: requirements.md - 404 when id not found
- **Request**: GET /transactions/{non-existent-uuid}
- **Expected**: 404 Not Found
- **Script**: test_get_transaction.sh::test_get_transaction_not_found

**Test Case 2.2.2: Invalid UUID Format**
- **Description**: Should return 400 for malformed UUID
- **Requirement**: requirements.md - 400 for invalid uuid
- **Request**: GET /transactions/not-a-valid-uuid
- **Expected**: 400 Bad Request
- **Script**: test_get_transaction.sh::test_get_transaction_invalid_uuid

---

### 3. GET /transactions (List)

#### 3.1 Filtering Tests

**Test Case 3.1.1: List by User ID**
- **Description**: Should return all transactions for user
- **Requirement**: requirements.md - user_id required parameter
- **Request**: GET /transactions?user_id=user123
- **Expected**: 200 OK
- **Expected Response**: Array of transactions for user123
- **Script**: test_list_transactions.sh::test_list_transactions_by_user

**Test Case 3.1.2: List by User ID and Currency**
- **Description**: Should filter by both user and currency
- **Requirement**: requirements.md - optional currency parameter
- **Request**: GET /transactions?user_id=user123&currency=usd
- **Expected**: 200 OK
- **Expected Response**: Only USD transactions for user123
- **Script**: test_list_transactions.sh::test_list_transactions_by_user_and_currency

**Test Case 3.1.3: Missing User ID**
- **Description**: Should fail when user_id not provided
- **Requirement**: requirements.md - user_id required
- **Request**: GET /transactions
- **Expected**: 400 Bad Request
- **Script**: test_list_transactions.sh::test_list_transactions_missing_user_id

#### 3.2 Pagination Tests

**Test Case 3.2.1: Limit Parameter**
- **Description**: Should respect limit parameter
- **Requirement**: requirements.md - limit parameter (default 100)
- **Request**: GET /transactions?user_id=user123&limit=3
- **Expected**: 200 OK with max 3 transactions
- **Script**: test_list_transactions.sh::test_list_transactions_with_limit

**Test Case 3.2.2: Offset Parameter**
- **Description**: Should skip transactions based on offset
- **Requirement**: requirements.md - offset parameter (default 0)
- **Request**: GET /transactions?user_id=user123&offset=2
- **Expected**: 200 OK with transactions starting from position 2
- **Script**: test_list_transactions.sh::test_list_transactions_with_offset

#### 3.3 Ordering Tests

**Test Case 3.3.1: Timestamp Descending**
- **Description**: Transactions should be ordered newest first
- **Requirement**: requirements.md - ordered by timestamp desc
- **Expected**: Most recent transaction first
- **Script**: test_list_transactions.sh::test_list_transactions_order

#### 3.4 Edge Cases

**Test Case 3.4.1: Empty Result Set**
- **Description**: Should return empty array for user with no transactions
- **Requirement**: Normal operation, not 404
- **Request**: GET /transactions?user_id=nonexistent_user
- **Expected**: 200 OK with empty transactions array
- **Script**: test_list_transactions.sh::test_list_transactions_empty

---

### 4. GET /balance

#### 4.1 Single Currency Balance

**Test Case 4.1.1: Calculate Single Currency Balance**
- **Description**: Should sum all amounts for user+currency
- **Requirement**: requirements.md - balance = SUM(amount)
- **Setup**: Create transactions: +10000, -3000, +5000 USD (in cents)
- **Request**: GET /balance?user_id=user123&currency=usd
- **Expected**: 200 OK
- **Expected Response**: {"user_id": "user123", "currency": "usd", "balance": 12000}
- **Note**: Balance of 12000 represents $120.00
- **Script**: test_balance.sh::test_get_balance_single_currency

**Test Case 4.1.2: Balance with Negative Only**
- **Description**: Balance can be negative
- **Requirement**: README.md - negative amounts supported
- **Setup**: Create transactions: -5000, -2500 (in cents)
- **Request**: GET /balance?user_id=user456&currency=usd
- **Expected**: {"balance": -7500}
- **Note**: Balance of -7500 represents -$75.00
- **Script**: test_balance.sh::test_get_balance_negative_only

**Test Case 4.1.3: Integer Precision**
- **Description**: Should handle integer amounts correctly
- **Requirement**: requirements.md - BIGINT for precise calculations
- **Setup**: Create transactions with various integer amounts
- **Expected**: Accurate integer calculation (no floating-point errors)
- **Script**: test_balance.sh::test_get_balance_decimal_precision

**Test Case 4.1.4: Zero Balance**
- **Description**: Should return 0 for user with no transactions
- **Request**: GET /balance?user_id=new_user&currency=usd
- **Expected**: {"balance": 0}
- **Script**: test_balance.sh::test_get_balance_no_transactions

#### 4.2 All Balances

**Test Case 4.2.1: Multiple Currency Balances**
- **Description**: Should return balances for all currencies
- **Requirement**: requirements.md - GET /balance?user_id={}
- **Setup**: Create USD, BRL, and loyalty_points transactions
- **Request**: GET /balance?user_id=user123
- **Expected**: 200 OK
- **Expected Response**: {"user_id": "user123", "balances": [{"currency": "usd", "balance": 12000}, ...]}
- **Note**: All amounts in smallest currency units
- **Script**: test_balance.sh::test_get_all_balances

**Test Case 4.2.2: Empty Balances**
- **Description**: Should return empty array for user with no transactions
- **Request**: GET /balance?user_id=new_user
- **Expected**: 200 OK with empty balances array
- **Script**: test_balance.sh::test_get_all_balances_no_transactions

#### 4.3 Validation Tests

**Test Case 4.3.1: Missing User ID**
- **Description**: Should fail when user_id not provided
- **Requirement**: requirements.md - user_id required
- **Request**: GET /balance?currency=usd
- **Expected**: 400 Bad Request
- **Script**: test_balance.sh::test_get_balance_missing_user_id

---

## Test Execution Matrix

| Test Suite | Total Tests | Critical | High Priority | Medium Priority |
|------------|-------------|----------|---------------|-----------------|
| POST /transactions | 10 | 3 (security) | 5 (validation) | 2 (functional) |
| GET /transactions/{id} | 4 | 1 | 2 | 1 |
| GET /transactions (list) | 7 | 1 | 3 | 3 |
| GET /balance | 7 | 0 | 4 | 3 |
| **TOTAL** | **28** | **5** | **14** | **9** |

## Test Data Requirements

### Test Users
- demo_user_1, demo_user_2, etc. - General testing
- list_test_user_X - Listing/filtering tests
- balance_test_user_X - Balance calculation tests

### Test Currencies
- usd - US Dollar
- brl - Brazilian Real
- loyalty_points - Non-monetary currency

### Test Amounts (in cents/smallest currency unit)
- Positive: 1000, 5000, 10000, 10050, 25075
- Negative: -2500, -3000, -7525
- Examples: 9999, 12576
- Note: All amounts are integers representing smallest currency units

## Success Criteria

### Individual Test
- ✓ Returns expected HTTP status code
- ✓ Response contains required fields
- ✓ Data matches expected values
- ✓ Timestamp format is ISO 8601
- ✓ UUIDs are valid format

### Overall Suite
- ✓ All 28 tests pass
- ✓ No false positives/negatives
- ✓ Tests are reproducible
- ✓ Tests run in < 2 minutes
- ✓ Clear error messages on failure

## Maintenance Guidelines

### Adding New Tests
1. Document test case in this specification
2. Implement in appropriate test file
3. Update test count in README.md
4. Ensure test is idempotent

### Modifying Existing Tests
1. Update this specification
2. Ensure backward compatibility
3. Re-run full test suite
4. Update documentation

### Test Review Checklist
- [ ] Test name clearly describes scenario
- [ ] Requirements reference included
- [ ] Expected results documented
- [ ] Edge cases considered
- [ ] Error messages are helpful
- [ ] Test is independent of others
