#!/bin/bash
# Main test runner for Ledger Service API tests
# This script executes all test suites and reports overall results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_config.sh"

echo "========================================="
echo "Ledger Service API Test Suite"
echo "========================================="
echo "Base URL: $BASE_URL"
echo "========================================="

# Non-interactive check if service is running (uses endpoint expected in spec)
echo "Checking service availability..."
if ! check_service_health; then
    echo -e "${YELLOW}WARNING: Cannot connect to $BASE_URL${NC}"
    echo "Please ensure the ledger service is running before executing tests."
    echo "Continuing in best-effort mode; tests may fail if service is down."
fi

echo ""

# Verify documented test count matches implemented tests (best-effort)
DOC_TEST_COUNT=28
# Count functions named test_* in test files
IMPLEMENTED_TEST_COUNT=$(grep -rhoP "^test_[a-zA-Z0-9_]+\b" "$SCRIPT_DIR" | sort -u | wc -l | tr -d ' ')
if [ -n "$IMPLEMENTED_TEST_COUNT" ] && [ "$IMPLEMENTED_TEST_COUNT" -ne "$DOC_TEST_COUNT" ]; then
    echo -e "${YELLOW}NOTE: Test specification documents ${DOC_TEST_COUNT} tests but ${IMPLEMENTED_TEST_COUNT} unique test functions were found.${NC}"
    echo "Please update TEST_SPECIFICATION.md if this is intentional."
fi

# Run all test suites
bash "$SCRIPT_DIR/test_create_transaction.sh"
bash "$SCRIPT_DIR/test_get_transaction.sh"
bash "$SCRIPT_DIR/test_list_transactions.sh"
bash "$SCRIPT_DIR/test_balance.sh"

# Print final summary
print_summary

exit $?
