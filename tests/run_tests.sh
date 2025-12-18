#!/bin/bash
# Main test runner for Ledger Service API tests
# This script executes all test suites and reports overall results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo "========================================="
echo "Ledger Service API Test Suite"
echo "========================================="
echo "Base URL: $BASE_URL"
echo "Allowed Origin: $ALLOWED_ORIGIN"
echo "========================================="

# Check if service is running (if health endpoint exists)
# If not, just continue and tests will show connection errors
echo "Checking service availability..."
if ! curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Cannot connect to $BASE_URL${NC}"
    echo "Please ensure the ledger service is running before executing tests."
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
else
    echo -e "${GREEN}Service is reachable${NC}"
fi

echo ""

# Run all test suites
bash "$SCRIPT_DIR/test_create_transaction.sh"
bash "$SCRIPT_DIR/test_get_transaction.sh"
bash "$SCRIPT_DIR/test_list_transactions.sh"
bash "$SCRIPT_DIR/test_balance.sh"

# Print final summary
print_summary

exit $?
