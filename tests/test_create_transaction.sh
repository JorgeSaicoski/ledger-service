#!/bin/bash
# Tests for POST /transactions endpoint

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo "========================================="
echo "Testing POST /transactions"
echo "========================================="

# Use a valid lowercase UUID for all user_id fields
TEST_USER_ID="550e8400-e29b-41d4-a716-446655440000"
TEST_USER_ID_2="11111111-1111-1111-1111-111111111111"
TEST_USER_ID_3="22222222-2222-2222-2222-222222222222"

# Helper to create a transaction and optionally return only the ID
_create_transaction() {
    local user_id
    local amount
    local currency
    user_id="$1"
    amount="$2"
    currency="$3"

    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": $amount,\
            \"currency\": \"$currency\"\
        }")

    local body
    body=$(echo "$response" | sed '$d')
    local status
    status=$(echo "$response" | tail -n1)

    # If QUIET_OUTPUT is set to 1, print only the ID (or empty on failure)
    if [ "${QUIET_OUTPUT:-0}" -eq 1 ]; then
        if check_status_code "$status" 201; then
            # Response is just the ID as a JSON string
            echo "$body" | jq -r '.' 2>/dev/null || echo ""
            return 0
        else
            echo ""
            return 1
        fi
    fi

    # Otherwise return full body and status separated by a marker (for human-readable run)
    echo "$body"; echo "$status"
}

# Test 1: Create transaction with valid data and allowed origin
test_create_transaction_success() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$TEST_USER_ID'",
            "amount": 10050,
            "currency": "usd"
        }')
    local body
    body=$(echo "$response" | sed '$d')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 201; then
        # Response is just the ID as a JSON string
        local id
        id=$(echo "$body" | jq -r '.' 2>/dev/null)

        # Check if ID is a valid UUID format
        if [[ "$id" =~ ^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$ ]]; then
            print_test_result "Create transaction with valid data" "PASS"
            # Write transaction ID to file for use by other tests/scripts
            if [ -n "$TRANSACTION_ID_FILE" ]; then
                echo "$id" > "$TRANSACTION_ID_FILE"
            fi
        else
            print_test_result "Create transaction with valid data" "FAIL" "Invalid ID format: $id"
        fi
    else
        print_test_result "Create transaction with valid data" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 2: Create transaction with missing user_id (should return 400)
test_create_transaction_missing_user_id() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "amount": 10000,
            "currency": "usd"
        }')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing user_id returns 400" "PASS"
    else
        print_test_result "Create transaction with missing user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 3: Create transaction with missing amount (should return 400)
test_create_transaction_missing_amount() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$TEST_USER_ID'",
            "currency": "usd"
        }')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing amount returns 400" "PASS"
    else
        print_test_result "Create transaction with missing amount returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 4: Create transaction with missing currency (should return 400)
test_create_transaction_missing_currency() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$TEST_USER_ID'",
            "amount": 10000
        }')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing currency returns 400" "PASS"
    else
        print_test_result "Create transaction with missing currency returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 5: Create transaction with negative amount (should succeed)
test_create_transaction_negative_amount() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$TEST_USER_ID_2'",
            "amount": -7525,
            "currency": "usd"
        }')
    local body
    body=$(echo "$response" | sed '$d')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 201; then
        # Response is just the ID as a JSON string
        local id
        id=$(echo "$body" | jq -r '.' 2>/dev/null)

        if [[ "$id" =~ ^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$ ]]; then
            print_test_result "Create transaction with negative amount" "PASS"
        else
            print_test_result "Create transaction with negative amount" "FAIL" "Invalid ID format"
        fi
    else
        print_test_result "Create transaction with negative amount" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 6: Create transaction with different currency
test_create_transaction_different_currency() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$TEST_USER_ID_3'",
            "amount": 1000,
            "currency": "loyalty_points"
        }')
    local body
    body=$(echo "$response" | sed '$d')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 201; then
        # Response is just the ID as a JSON string
        local id
        id=$(echo "$body" | jq -r '.' 2>/dev/null)

        if [[ "$id" =~ ^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$ ]]; then
            print_test_result "Create transaction with loyalty_points currency" "PASS"
        else
            print_test_result "Create transaction with loyalty_points currency" "FAIL" "Invalid ID format"
        fi
    else
        print_test_result "Create transaction with loyalty_points currency" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 7: Create transaction with invalid JSON (should return 400)
test_create_transaction_invalid_json() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{invalid json}')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 400; then
        print_test_result "Create transaction with invalid JSON returns 400" "PASS"
    else
        print_test_result "Create transaction with invalid JSON returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 8: Create transaction with empty user_id (should return 400)
test_create_transaction_empty_user_id() {
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "",
            "amount": 10000,
            "currency": "usd"
        }')
    local status
    status=$(echo "$response" | tail -n1)

    if check_status_code "$status" 400; then
        print_test_result "Create transaction with empty user_id returns 400" "PASS"
    else
        print_test_result "Create transaction with empty user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Run all tests
# Use QUIET_OUTPUT=1 when calling _create_transaction in command substitution to get just the ID
# Create a transaction and capture its ID (quiet)
QUIET_OUTPUT=1 TRANSACTION_ID="$(_create_transaction "'$TEST_USER_ID'" 10050 "usd")"
# If previous call failed, fall back to running the verbose test which will also write the ID to file
if [ -z "$TRANSACTION_ID" ]; then
    test_create_transaction_success
    if [ -f "$TRANSACTION_ID_FILE" ]; then
        TRANSACTION_ID=$(cat "$TRANSACTION_ID_FILE" 2>/dev/null || true)
    fi
else
    # Save ID to file for other tests
    if [ -n "$TRANSACTION_ID_FILE" ]; then
        echo "$TRANSACTION_ID" > "$TRANSACTION_ID_FILE"
    fi
    # Also run the verbose test to register the PASS/FAIL counters
    test_create_transaction_success
fi

export TEST_TRANSACTION_ID="$TRANSACTION_ID"

# Explicitly run all test functions
# (test_create_transaction_success is already run above, so skip duplicate)
test_create_transaction_missing_user_id
test_create_transaction_missing_amount
test_create_transaction_missing_currency
test_create_transaction_negative_amount
test_create_transaction_different_currency
test_create_transaction_invalid_json
test_create_transaction_empty_user_id
