#!/bin/bash
# Tests for POST /transactions endpoint

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo "========================================="
echo "Testing POST /transactions"
echo "========================================="

# Helper to create a transaction and optionally return only the ID
_create_transaction() {
    local user_id="$1"
    local amount="$2"
    local currency="$3"

    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": $amount,\
            \"currency\": \"$currency\"\
        }")

    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)

    # If QUIET_OUTPUT is set to 1, print only the ID (or empty on failure)
    if [ "${QUIET_OUTPUT:-0}" -eq 1 ]; then
        if check_status_code "$status" 201; then
            echo "$body" | jq -r '.id' 2>/dev/null || echo ""
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
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user123",
            "amount": 100.50,
            "currency": "usd"
        }')
    
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 201; then
        if check_json_field "$body" "id" && \
           check_json_field "$body" "user_id" && \
           check_json_field "$body" "amount" && \
           check_json_field "$body" "currency" && \
           check_json_field "$body" "timestamp"; then
            
            local user_id=$(get_json_field "$body" "user_id")
            local amount=$(get_json_field "$body" "amount")
            local currency=$(get_json_field "$body" "currency")
            
            if [ "$user_id" = "user123" ] && \
               [ "$amount" = "100.5" ] && \
               [ "$currency" = "usd" ]; then
                print_test_result "Create transaction with valid data" "PASS"
                # Write transaction ID to file for use by other tests/scripts
                if [ -n "$TRANSACTION_ID_FILE" ]; then
                    echo "$body" | jq -r '.id' > "$TRANSACTION_ID_FILE"
                fi
            else
                print_test_result "Create transaction with valid data" "FAIL" "Response data mismatch"
            fi
        else
            print_test_result "Create transaction with valid data" "FAIL" "Missing required fields in response"
        fi
    else
        print_test_result "Create transaction with valid data" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 2: Create transaction with missing user_id (should return 400)
test_create_transaction_missing_user_id() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "amount": 100.00,
            "currency": "usd"
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing user_id returns 400" "PASS"
    else
        print_test_result "Create transaction with missing user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 5: Create transaction with missing amount (should return 400)
test_create_transaction_missing_amount() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user123",
            "currency": "usd"
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing amount returns 400" "PASS"
    else
        print_test_result "Create transaction with missing amount returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 6: Create transaction with missing currency (should return 400)
test_create_transaction_missing_currency() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user123",
            "amount": 100.00
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Create transaction with missing currency returns 400" "PASS"
    else
        print_test_result "Create transaction with missing currency returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 7: Create transaction with negative amount (should succeed)
test_create_transaction_negative_amount() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user456",
            "amount": -75.25,
            "currency": "usd"
        }')
    
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 201; then
        local amount=$(get_json_field "$body" "amount")
        if [ "$amount" = "-75.25" ]; then
            print_test_result "Create transaction with negative amount" "PASS"
        else
            print_test_result "Create transaction with negative amount" "FAIL" "Amount not correctly stored"
        fi
    else
        print_test_result "Create transaction with negative amount" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 8: Create transaction with different currency
test_create_transaction_different_currency() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user789",
            "amount": 1000,
            "currency": "loyalty_points"
        }')
    
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 201; then
        local currency=$(get_json_field "$body" "currency")
        if [ "$currency" = "loyalty_points" ]; then
            print_test_result "Create transaction with loyalty_points currency" "PASS"
        else
            print_test_result "Create transaction with loyalty_points currency" "FAIL" "Currency not correctly stored"
        fi
    else
        print_test_result "Create transaction with loyalty_points currency" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 9: Create transaction with invalid JSON (should return 400)
test_create_transaction_invalid_json() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{invalid json}')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Create transaction with invalid JSON returns 400" "PASS"
    else
        print_test_result "Create transaction with invalid JSON returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 10: Create transaction with empty user_id (should return 400)
test_create_transaction_empty_user_id() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "",
            "amount": 100.00,
            "currency": "usd"
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Create transaction with empty user_id returns 400" "PASS"
    else
        print_test_result "Create transaction with empty user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Run all tests
# Use QUIET_OUTPUT=1 when calling _create_transaction in command substitution to get just the ID
# Create a transaction and capture its ID (quiet)
QUIET_OUTPUT=1 TRANSACTION_ID="$(_create_transaction "user123" 100.50 "usd")"
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
