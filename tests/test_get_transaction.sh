#!/bin/bash
# Tests for GET /transactions/{id} endpoint

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo ""
echo "========================================="
echo "Testing GET /transactions/{id}"
echo "========================================="

# Test 1: Get transaction by valid ID
test_get_transaction_by_id() {
    # First, create a transaction to retrieve
    local create_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "550e8400-e29b-41d4-a716-446655440000",
            "amount": 25075,
            "currency": "usd"
        }')
    
    local create_body=$(echo "$create_response" | sed '$d')
    local create_status=$(echo "$create_response" | tail -n1)
    
    if ! check_status_code "$create_status" 201; then
        print_test_result "Get transaction by valid ID" "FAIL" "Failed to create test transaction"
        return
    fi
    
    # Response is just the ID as a JSON string
    local transaction_id=$(echo "$create_body" | jq -r '.' 2>/dev/null)

    # Now retrieve it using query parameter
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?id=$transaction_id")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        if check_json_field "$body" "id" && \
           check_json_field "$body" "user_id" && \
           check_json_field "$body" "amount" && \
           check_json_field "$body" "currency" && \
           check_json_field "$body" "timestamp"; then
            
            local retrieved_id=$(get_json_field "$body" "id")
            if [ "$retrieved_id" = "$transaction_id" ]; then
                print_test_result "Get transaction by valid ID" "PASS"
            else
                print_test_result "Get transaction by valid ID" "FAIL" "ID mismatch"
            fi
        else
            print_test_result "Get transaction by valid ID" "FAIL" "Missing required fields"
        fi
    else
        print_test_result "Get transaction by valid ID" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 2: Get transaction with non-existent ID (should return 404)
test_get_transaction_not_found() {
    local fake_id="00000000-0000-0000-0000-000000000000"
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?id=$fake_id")
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 404; then
        print_test_result "Get transaction with non-existent ID returns 404" "PASS"
    else
        print_test_result "Get transaction with non-existent ID returns 404" "FAIL" "Expected status 404, got $status"
    fi
}

# Test 3: Get transaction with invalid UUID format (should return 400)
test_get_transaction_invalid_uuid() {
    local invalid_id="not-a-valid-uuid"
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?id=$invalid_id")
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Get transaction with invalid UUID returns 400" "PASS"
    else
        print_test_result "Get transaction with invalid UUID returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 4: Verify transaction data matches creation
test_get_transaction_data_integrity() {
    # Create a transaction with specific data
    local create_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "550e8400-e29b-41d4-a716-446655440000",
            "amount": 9999,
            "currency": "brl"
        }')
    
    local create_body=$(echo "$create_response" | sed '$d')
    local create_status=$(echo "$create_response" | tail -n1)

    if ! check_status_code "$create_status" 201; then
        print_test_result "Get transaction data integrity check" "FAIL" "Failed to create test transaction"
        return
    fi

    # Response is just the ID as a JSON string
    local transaction_id=$(echo "$create_body" | jq -r '.' 2>/dev/null)

    # Retrieve and verify using query parameter
    local response=$(curl -s -X GET "$BASE_URL/transactions?id=$transaction_id")

    local user_id=$(get_json_field "$response" "user_id")
    local amount=$(get_json_field "$response" "amount")
    local currency=$(get_json_field "$response" "currency")
    
    if [ "$user_id" = "550e8400-e29b-41d4-a716-446655440000" ] && \
       [ "$amount" = "9999" ] && \
       [ "$currency" = "brl" ]; then
        print_test_result "Get transaction data integrity check" "PASS"
    else
        print_test_result "Get transaction data integrity check" "FAIL" "Data mismatch: user=$user_id, amount=$amount, currency=$currency"
    fi
}

# Run all tests
test_get_transaction_by_id
test_get_transaction_not_found
test_get_transaction_invalid_uuid
test_get_transaction_data_integrity