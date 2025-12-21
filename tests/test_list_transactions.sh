#!/bin/bash
# Tests for GET /transactions endpoint (list transactions)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo ""
echo "========================================="
echo "Testing GET /transactions (list)"
echo "========================================="

# Setup: Create multiple transactions for testing
setup_test_transactions() {
    local user_id="$1"
    local currency="$2"
    local count="$3"
    
    for i in $(seq 1 $count); do
        curl -s -X POST "$BASE_URL/transactions" \
            -H "Content-Type: application/json" \
            -d "{\
                \"user_id\": \"$user_id\",\
                \"amount\": $((i * 10)),\
                \"currency\": \"$currency\"\
            }" > /dev/null
        sleep 0.1  # Small delay to ensure different timestamps
    done
}

# Helper to safely parse jq integer results, returns number or 0
_safe_jq_count() {
    local json="$1"
    local expr="$2"
    local out
    out=$(echo "$json" | jq -r "$expr" 2>/dev/null) || out=""
    if [[ "$out" =~ ^[0-9]+$ ]]; then
        echo "$out"
    else
        echo "0"
    fi
}

# Test 1: List transactions by user_id
test_list_transactions_by_user() {
    local test_user="list_test_user_1"
    
    # Create test transactions
    setup_test_transactions "$test_user" "usd" 3
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?user_id=$test_user")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        if check_json_field "$body" "transactions"; then
            local count=$(_safe_jq_count "$body" '.transactions | length')
            if [ "$count" -ge 3 ]; then
                print_test_result "List transactions by user_id" "PASS"
            else
                print_test_result "List transactions by user_id" "FAIL" "Expected at least 3 transactions, got $count"
            fi
        else
            print_test_result "List transactions by user_id" "FAIL" "Missing 'transactions' field"
        fi
    else
        print_test_result "List transactions by user_id" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 2: List transactions by user_id and currency
test_list_transactions_by_user_and_currency() {
    local test_user="list_test_user_2"
    
    # Create transactions in different currencies
    setup_test_transactions "$test_user" "usd" 2
    setup_test_transactions "$test_user" "brl" 3
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?user_id=$test_user&currency=brl")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local count=$(_safe_jq_count "$body" '.transactions | length')
        local all_brl=$(echo "$body" | jq -r '[.transactions[] | select(.currency != "brl")] | length' 2>/dev/null || echo "0")
        if [ "$count" -ge 3 ] && [ "$all_brl" -eq 0 ]; then
            print_test_result "List transactions by user_id and currency" "PASS"
        else
            print_test_result "List transactions by user_id and currency" "FAIL" "Expected 3+ BRL transactions only, got $count total with $all_brl non-BRL"
        fi
    else
        print_test_result "List transactions by user_id and currency" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 3: List transactions without user_id (should return 400)
test_list_transactions_missing_user_id() {
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions")
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "List transactions without user_id returns 400" "PASS"
    else
        print_test_result "List transactions without user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 4: List transactions with pagination (limit)
test_list_transactions_with_limit() {
    local test_user="list_test_user_3"
    
    # Create 5 transactions
    setup_test_transactions "$test_user" "usd" 5
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?user_id=$test_user&limit=3")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local count=$(_safe_jq_count "$body" '.transactions | length')
        if [ "$count" -eq 3 ]; then
            print_test_result "List transactions with limit parameter" "PASS"
        else
            print_test_result "List transactions with limit parameter" "FAIL" "Expected 3 transactions, got $count"
        fi
    else
        print_test_result "List transactions with limit parameter" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 5: List transactions with pagination (offset)
test_list_transactions_with_offset() {
    local test_user="list_test_user_4"
    
    # Create 5 transactions
    setup_test_transactions "$test_user" "usd" 5
    
    # Get all transactions
    local all_response=$(curl -s -X GET "$BASE_URL/transactions?user_id=$test_user")
    local total_count=$(_safe_jq_count "$all_response" '.transactions | length')

    # Get with offset=2
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?user_id=$test_user&offset=2")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local count=$(_safe_jq_count "$body" '.transactions | length')
        local expected=$((total_count - 2))
        if [ "$count" -eq "$expected" ]; then
            print_test_result "List transactions with offset parameter" "PASS"
        else
            print_test_result "List transactions with offset parameter" "FAIL" "Expected $expected transactions, got $count"
        fi
    else
        print_test_result "List transactions with offset parameter" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 6: Verify transactions are ordered by timestamp descending
test_list_transactions_order() {
    local test_user="list_test_user_5"
    
    # Create transactions with delays to ensure different timestamps
    for i in 1 2 3; do
        curl -s -X POST "$BASE_URL/transactions" \
            -H "Content-Type: application/json" \
            -d "{\
                \"user_id\": \"$test_user\",\
                \"amount\": $((i * 100)),\
                \"currency\": \"usd\"\
            }" > /dev/null
        sleep 0.2
    done
    
    local response=$(curl -s -X GET "$BASE_URL/transactions?user_id=$test_user")
    
    # Get timestamps and check they are in descending order
    local timestamp1=$(echo "$response" | jq -r '.transactions[0].timestamp' 2>/dev/null || echo "")
    local timestamp2=$(echo "$response" | jq -r '.transactions[1].timestamp' 2>/dev/null || echo "")

    if [ -z "$timestamp1" ] || [ -z "$timestamp2" ]; then
        print_test_result "List transactions ordered by timestamp DESC" "FAIL" "Failed to parse timestamps"
        return
    fi

    if [[ "$timestamp1" > "$timestamp2" ]] || [[ "$timestamp1" == "$timestamp2" ]]; then
        print_test_result "List transactions ordered by timestamp DESC" "PASS"
    else
        print_test_result "List transactions ordered by timestamp DESC" "FAIL" "Transactions not in descending timestamp order"
    fi
}

# Test 7: List transactions for user with no transactions
test_list_transactions_empty() {
    local test_user="nonexistent_user_123456789"
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/transactions?user_id=$test_user")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local count=$(_safe_jq_count "$body" '.transactions | length')
        if [ "$count" -eq 0 ]; then
            print_test_result "List transactions for user with no transactions" "PASS"
        else
            print_test_result "List transactions for user with no transactions" "FAIL" "Expected empty array, got $count transactions"
        fi
    else
        print_test_result "List transactions for user with no transactions" "FAIL" "Expected status 200, got $status"
    fi
}

# Run all tests
test_list_transactions_by_user
test_list_transactions_by_user_and_currency
test_list_transactions_missing_user_id
test_list_transactions_with_limit
test_list_transactions_with_offset
test_list_transactions_order
test_list_transactions_empty
