#!/bin/bash
# Tests for GET /balance endpoint

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo ""
echo "========================================="
echo "Testing GET /balance"
echo "========================================="

# Setup: Create transactions for balance testing
setup_balance_transactions() {
    local user_id="$1"
    
    # Create USD transactions
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 100.00,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": -30.00,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 50.00,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    # Create BRL transactions
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 200.00,\
            \"currency\": \"brl\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": -50.00,\
            \"currency\": \"brl\"\
        }" > /dev/null
    
    # Create loyalty_points transactions
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 1000,\
            \"currency\": \"loyalty_points\"\
        }" > /dev/null
}

# Helper to safely extract jq values (numbers or strings); returns empty string on failure
_safe_jq_value() {
    local json="$1"
    local expr="$2"
    local out
    out=$(echo "$json" | jq -r "$expr" 2>/dev/null) || out=""
    echo "$out"
}

# Test 1: Get balance for specific user and currency
test_get_balance_single_currency() {
    local test_user="balance_test_user_1"
    setup_balance_transactions "$test_user"
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user&currency=usd")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        if check_json_field "$body" "user_id" && \
           check_json_field "$body" "currency" && \
           check_json_field "$body" "balance"; then
            
            local balance=$(_safe_jq_value "$body" '.balance')
            # Normalize balance (remove trailing zeros when possible)
            balance=$(echo "$balance" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')
            # Expected: 100 - 30 + 50 = 120
            if [ "$balance" = "120" ]; then
                print_test_result "Get balance for user and currency" "PASS"
            else
                print_test_result "Get balance for user and currency" "FAIL" "Expected balance 120, got $balance"
            fi
        else
            print_test_result "Get balance for user and currency" "FAIL" "Missing required fields"
        fi
    else
        print_test_result "Get balance for user and currency" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 2: Get all balances for user
test_get_all_balances() {
    local test_user="balance_test_user_2"
    setup_balance_transactions "$test_user"
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        if check_json_field "$body" "user_id" && \
           check_json_field "$body" "balances"; then
            
            local count=$(echo "$body" | jq '.balances | length' 2>/dev/null || echo "0")
            if [ "$count" -ge 3 ]; then
                # Check if USD balance is correct (120)
                local usd_balance_raw=$(_safe_jq_value "$body" '.balances[] | select(.currency=="usd") | .balance')
                local brl_balance_raw=$(_safe_jq_value "$body" '.balances[] | select(.currency=="brl") | .balance')

                # Normalize
                local usd_balance=$(echo "$usd_balance_raw" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')
                local brl_balance=$(echo "$brl_balance_raw" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')

                local usd_ok=false
                local brl_ok=false
                
                if [ "$usd_balance" = "120" ]; then
                    usd_ok=true
                fi
                
                if [ "$brl_balance" = "150" ]; then
                    brl_ok=true
                fi
                
                if [ "$usd_ok" = true ] && [ "$brl_ok" = true ]; then
                    print_test_result "Get all balances for user" "PASS"
                else
                    print_test_result "Get all balances for user" "FAIL" "Balance calculation incorrect: USD=$usd_balance (expected 120), BRL=$brl_balance (expected 150)"
                fi
            else
                print_test_result "Get all balances for user" "FAIL" "Expected 3 currencies, got $count"
            fi
        else
            print_test_result "Get all balances for user" "FAIL" "Missing required fields"
        fi
    else
        print_test_result "Get all balances for user" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 3: Get balance without user_id (should return 400)
test_get_balance_missing_user_id() {
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?currency=usd")
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 400; then
        print_test_result "Get balance without user_id returns 400" "PASS"
    else
        print_test_result "Get balance without user_id returns 400" "FAIL" "Expected status 400, got $status"
    fi
}

# Test 4: Get balance for user with no transactions in specified currency
test_get_balance_no_transactions() {
    local test_user="balance_test_user_empty"
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user&currency=usd")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local balance_raw=$(_safe_jq_value "$body" '.balance')
        local balance=$(echo "$balance_raw" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')
        if [ -z "$balance" ]; then
            balance="0"
        fi
        if [ "$balance" = "0" ]; then
            print_test_result "Get balance for user with no transactions returns 0" "PASS"
        else
            print_test_result "Get balance for user with no transactions returns 0" "FAIL" "Expected balance 0, got $balance"
        fi
    else
        print_test_result "Get balance for user with no transactions returns 0" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 5: Get all balances for user with no transactions
test_get_all_balances_no_transactions() {
    local test_user="balance_test_user_empty_all"
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local count=$(echo "$body" | jq '.balances | length' 2>/dev/null || echo "0")
        if [ "$count" -eq 0 ]; then
            print_test_result "Get all balances for user with no transactions" "PASS"
        else
            print_test_result "Get all balances for user with no transactions" "FAIL" "Expected empty balances array, got $count items"
        fi
    else
        print_test_result "Get all balances for user with no transactions" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 6: Balance calculation with only negative transactions
test_get_balance_negative_only() {
    local test_user="balance_test_user_negative"
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$test_user\",\
            \"amount\": -50.00,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$test_user\",\
            \"amount\": -25.00,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user&currency=usd")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local balance_raw=$(_safe_jq_value "$body" '.balance')
        local balance=$(echo "$balance_raw" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')
        if [ "$balance" = "-75" ]; then
            print_test_result "Get balance with only negative transactions" "PASS"
        else
            print_test_result "Get balance with only negative transactions" "FAIL" "Expected balance -75, got $balance"
        fi
    else
        print_test_result "Get balance with only negative transactions" "FAIL" "Expected status 200, got $status"
    fi
}

# Test 7: Balance calculation with decimal amounts
test_get_balance_decimal_precision() {
    local test_user="balance_test_user_decimal"
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$test_user\",\
            \"amount\": 100.55,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$test_user\",\
            \"amount\": 50.33,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$test_user\",\
            \"amount\": -25.12,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    local response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/balance?user_id=$test_user&currency=usd")
    local body=$(echo "$response" | sed '$d')
    local status=$(echo "$response" | tail -n1)
    
    if check_status_code "$status" 200; then
        local balance_raw=$(_safe_jq_value "$body" '.balance')
        local balance=$(echo "$balance_raw" | sed -E 's/\.0+$//; s/(\.[0-9]*[1-9])0+$/\1/')
        # Expected: 100.55 + 50.33 - 25.12 = 125.76
        if [ "$balance" = "125.76" ]; then
            print_test_result "Get balance with decimal precision" "PASS"
        else
            print_test_result "Get balance with decimal precision" "FAIL" "Expected balance 125.76, got $balance"
        fi
    else
        print_test_result "Get balance with decimal precision" "FAIL" "Expected status 200, got $status"
    fi
}

# Run all tests
test_get_balance_single_currency
test_get_all_balances
test_get_balance_missing_user_id
test_get_balance_no_transactions
test_get_all_balances_no_transactions
test_get_balance_negative_only
test_get_balance_decimal_precision
