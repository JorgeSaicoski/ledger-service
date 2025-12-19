#!/bin/bash
# Test Configuration
# This file contains common configuration for all tests

# Service base URL (override with TEST_BASE_URL environment variable)
BASE_URL="${TEST_BASE_URL:-http://localhost:8080}"

# Allowed origin for security tests (override with TEST_ALLOWED_ORIGIN)
ALLOWED_ORIGIN="${TEST_ALLOWED_ORIGIN:-http://internal-gateway.local}"

# Disallowed origin for negative security tests
DISALLOWED_ORIGIN="http://evil.example.com"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Default transaction ID file (used to share created ID between test files)
# Can be overridden with TRANSACTION_ID_FILE env var
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSACTION_ID_FILE="${TRANSACTION_ID_FILE:-$SCRIPT_DIR/.last_transaction_id}"

# Ensure required tools are available
command -v curl >/dev/null 2>&1 || { echo -e "${RED}ERROR:${NC} curl is required to run tests"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}ERROR:${NC} jq is required to run tests"; exit 1; }

# Helper function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        if [ -n "$message" ]; then
            echo -e "  ${YELLOW}Details:${NC} $message"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to check HTTP status code
check_status_code() {
    local actual="$1"
    local expected="$2"
    
    if [ "$actual" -eq "$expected" ]; then
        return 0
    else
        return 1
    fi
}

# Helper function to check if JSON response contains a field
check_json_field() {
    local json="$1"
    local field="$2"
    
    echo "$json" | jq -e ".$field" > /dev/null 2>&1
    return $?
}

# Helper function to extract value from JSON
get_json_field() {
    local json="$1"
    local field="$2"
    
    echo "$json" | jq -r ".$field"
}

# Helper function to check if service is running
check_service_health() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/transactions" 2>/dev/null)

    if [ -z "$response" ]; then
        echo -e "${RED}ERROR: Cannot connect to service at $BASE_URL${NC}"
        echo "Please ensure the service is running before executing tests."
        return 1
    fi
    
    return 0
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "========================================="
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}
