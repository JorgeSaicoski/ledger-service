#!/bin/bash
# Quick test script for manual testing during development
# This script demonstrates example API calls for all endpoints

BASE_URL="${TEST_BASE_URL:-http://localhost:8080}"
ALLOWED_ORIGIN="${TEST_ALLOWED_ORIGIN:-http://internal-gateway.local}"

echo "========================================="
echo "Ledger Service API Examples"
echo "========================================="
echo "Base URL: $BASE_URL"
echo "Allowed Origin: $ALLOWED_ORIGIN"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_section() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

print_request() {
    echo -e "${GREEN}Request:${NC} $1"
}

# Example 1: Create a transaction
print_section "Example 1: Create Transaction (Valid)"
print_request "POST /transactions"
echo ""
curl -i -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "amount": 100.50,
    "currency": "usd"
  }'

# Save transaction ID for later use
TRANSACTION_ID=$(curl -s -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "amount": 50.00,
    "currency": "usd"
  }' | jq -r '.id' 2>/dev/null)

# Example 2: Create transaction with disallowed origin
print_section "Example 2: Create Transaction (Disallowed Origin - Should Fail)"
print_request "POST /transactions with wrong origin"
echo ""
curl -i -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: http://evil.example.com" \
  -d '{
    "user_id": "demo_user_1",
    "amount": 100.00,
    "currency": "usd"
  }'

# Example 3: Create transaction with negative amount
print_section "Example 3: Create Transaction (Negative Amount)"
print_request "POST /transactions with negative amount"
echo ""
curl -i -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "amount": -30.25,
    "currency": "usd"
  }'

# Example 4: Create transactions in different currencies
print_section "Example 4: Create Transactions (Multiple Currencies)"
print_request "POST /transactions with BRL"
echo ""
curl -s -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "amount": 500.00,
    "currency": "brl"
  }' | jq '.'

print_request "POST /transactions with loyalty_points"
echo ""
curl -s -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "amount": 1000,
    "currency": "loyalty_points"
  }' | jq '.'

# Example 5: Get transaction by ID
if [ -n "$TRANSACTION_ID" ] && [ "$TRANSACTION_ID" != "null" ]; then
    print_section "Example 5: Get Transaction by ID"
    print_request "GET /transactions/$TRANSACTION_ID"
    echo ""
    curl -s -X GET "$BASE_URL/transactions/$TRANSACTION_ID" | jq '.'
fi

# Example 6: List all transactions for user
print_section "Example 6: List All Transactions for User"
print_request "GET /transactions?user_id=demo_user_1"
echo ""
curl -s -X GET "$BASE_URL/transactions?user_id=demo_user_1" | jq '.'

# Example 7: List transactions for user and currency
print_section "Example 7: List Transactions (User + Currency)"
print_request "GET /transactions?user_id=demo_user_1&currency=usd"
echo ""
curl -s -X GET "$BASE_URL/transactions?user_id=demo_user_1&currency=usd" | jq '.'

# Example 8: List transactions with pagination
print_section "Example 8: List Transactions (Pagination)"
print_request "GET /transactions?user_id=demo_user_1&limit=2&offset=0"
echo ""
curl -s -X GET "$BASE_URL/transactions?user_id=demo_user_1&limit=2&offset=0" | jq '.'

# Example 9: Get balance for user and currency
print_section "Example 9: Get Balance (Single Currency)"
print_request "GET /balance?user_id=demo_user_1&currency=usd"
echo ""
curl -s -X GET "$BASE_URL/balance?user_id=demo_user_1&currency=usd" | jq '.'

# Example 10: Get all balances for user
print_section "Example 10: Get All Balances for User"
print_request "GET /balance?user_id=demo_user_1"
echo ""
curl -s -X GET "$BASE_URL/balance?user_id=demo_user_1" | jq '.'

# Example 11: Error cases
print_section "Example 11: Error Cases"

print_request "Missing required field (should return 400)"
echo ""
curl -i -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{
    "user_id": "demo_user_1",
    "currency": "usd"
  }'

print_request "Invalid JSON (should return 400)"
echo ""
curl -i -X POST "$BASE_URL/transactions" \
  -H "Content-Type: application/json" \
  -H "Origin: $ALLOWED_ORIGIN" \
  -d '{invalid json}'

print_request "Missing user_id parameter (should return 400)"
echo ""
curl -i -X GET "$BASE_URL/transactions"

print_section "Examples Complete"
echo "You can modify BASE_URL and ALLOWED_ORIGIN:"
echo "  TEST_BASE_URL=http://localhost:3000 ./tests/examples.sh"
echo ""
