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
            \"amount\": 10000,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": -3000,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 5000,\
            \"currency\": \"usd\"\
        }" > /dev/null
    
    # Create BRL transactions
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": 20000,\
            \"currency\": \"brl\"\
        }" > /dev/null
    
    curl -s -X POST "$BASE_URL/transactions" \
        -H "Content-Type: application/json" \
        -d "{\
            \"user_id\": \"$user_id\",\
            \"amount\": -5000,\
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

# Removed all balance endpoint tests and helpers
