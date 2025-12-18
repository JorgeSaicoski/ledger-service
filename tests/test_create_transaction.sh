#!/bin/bash
# Tests for POST /transactions endpoint

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo "========================================="
echo "Testing POST /transactions"
echo "========================================="

# Test 1: Create transaction with valid data and allowed origin
test_create_transaction_success() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -H "Origin: $ALLOWED_ORIGIN" \
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
                print_test_result "Create transaction with allowed origin" "PASS"
                echo "$body" | jq -r '.id'  # Return transaction ID for other tests
            else
                print_test_result "Create transaction with allowed origin" "FAIL" "Response data mismatch"
            fi
        else
            print_test_result "Create transaction with allowed origin" "FAIL" "Missing required fields in response"
        fi
    else
        print_test_result "Create transaction with allowed origin" "FAIL" "Expected status 201, got $status"
    fi
}

# Test 2: Create transaction with disallowed origin (should return 403)
test_create_transaction_forbidden() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -H "Origin: $DISALLOWED_ORIGIN" \
        -d '{
            "user_id": "user123",
            "amount": 50.00,
            "currency": "usd"
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 403; then
        print_test_result "Create transaction with disallowed origin returns 403" "PASS"
    else
        print_test_result "Create transaction with disallowed origin returns 403" "FAIL" "Expected status 403, got $status"
    fi
}

# Test 3: Create transaction without Origin header (should return 403)
test_create_transaction_no_origin() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "user123",
            "amount": 50.00,
            "currency": "usd"
        }')
    
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 403; then
        print_test_result "Create transaction without Origin header returns 403" "PASS"
    else
        print_test_result "Create transaction without Origin header returns 403" "FAIL" "Expected status 403, got $status"
    fi
}

# Test 4: Create transaction with missing user_id (should return 400)
test_create_transaction_missing_user_id() {
    local response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
        -H "Origin: $ALLOWED_ORIGIN" \
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
TRANSACTION_ID=$(test_create_transaction_success)
test_create_transaction_forbidden
test_create_transaction_no_origin
test_create_transaction_missing_user_id
test_create_transaction_missing_amount
test_create_transaction_missing_currency
test_create_transaction_negative_amount
test_create_transaction_different_currency
test_create_transaction_invalid_json
test_create_transaction_empty_user_id

# Export transaction ID for other test files
export TEST_TRANSACTION_ID="$TRANSACTION_ID"
