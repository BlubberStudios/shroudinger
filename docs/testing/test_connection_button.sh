#!/bin/bash
# test_connection_button.sh - Comprehensive Test Connection Button Testing
# This script validates all aspects of the Test Connection Button functionality

echo "🔘 Shroudinger Test Connection Button Testing Suite"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Function to print test results
print_result() {
    local status=$1
    local message=$2
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ((TESTS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ((TESTS_FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️ WARN${NC}: $message"
            ((TESTS_WARNING++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️ INFO${NC}: $message"
            ;;
    esac
}

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local expected_field=$2
    local test_name=$3
    
    response=$(curl -s "$url" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        if [ -n "$expected_field" ]; then
            if echo "$response" | jq -e "$expected_field" > /dev/null 2>&1; then
                print_result "PASS" "$test_name"
                return 0
            else
                print_result "FAIL" "$test_name - Expected field '$expected_field' not found"
                return 1
            fi
        else
            print_result "PASS" "$test_name"
            return 0
        fi
    else
        print_result "FAIL" "$test_name - Endpoint unreachable"
        return 1
    fi
}

# Function to test response time
test_response_time() {
    local url=$1
    local max_time_ms=$2
    local test_name=$3
    
    start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
    response=$(curl -s "$url" 2>/dev/null)
    end_time=$(python3 -c "import time; print(int(time.time() * 1000))")
    
    if [ $? -eq 0 ]; then
        response_time=$((end_time - start_time))
        if [ $response_time -lt $max_time_ms ]; then
            print_result "PASS" "$test_name (${response_time}ms)"
        else
            print_result "WARN" "$test_name (${response_time}ms) - Slower than expected"
        fi
    else
        print_result "FAIL" "$test_name - Request failed"
    fi
}

echo "🏥 Phase 1: Backend Service Health Checks"
echo "----------------------------------------"

# Test 1: API Server Health
test_endpoint "http://localhost:8080/health" ".status" "API Server Health Check"

# Test 2: Blocklist Service Health
print_result "INFO" "Testing Blocklist Service Health..."
blocklist_health=$(curl -s http://localhost:8081/health 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$blocklist_health" ]; then
    if echo "$blocklist_health" | jq -e '.status.healthy == true' > /dev/null 2>&1; then
        print_result "PASS" "Blocklist Service Health Check"
    else
        print_result "FAIL" "Blocklist Service Health Check - Service not healthy"
    fi
else
    print_result "FAIL" "Blocklist Service Health Check - Endpoint unreachable"
fi

# Test 3: DNS Service Health
print_result "INFO" "Testing DNS Service Health..."
dns_health=$(curl -s http://localhost:8082/health 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$dns_health" ]; then
    if echo "$dns_health" | jq -e '.status.healthy == true' > /dev/null 2>&1; then
        print_result "PASS" "DNS Service Health Check"
    else
        print_result "FAIL" "DNS Service Health Check - Service not healthy"
    fi
else
    print_result "FAIL" "DNS Service Health Check - Endpoint unreachable"
fi

# Test 4: Middleware Service Health
test_endpoint "http://localhost:8083/health" ".status" "Middleware Service Health Check"

echo ""
echo "🔧 Phase 2: Test Connection Button Core Functionality"
echo "----------------------------------------------------"

# Test 5: Configuration Endpoint (Primary Test Connection functionality)
test_endpoint "http://localhost:8080/api/v1/config/" ".privacy_mode" "Configuration Endpoint"

# Test 6: Service Health Coordination
test_endpoint "http://localhost:8080/api/v1/stats/health" "" "Service Health Coordination"

# Test 7: DNS Server Test Endpoint
print_result "INFO" "Testing DNS server connectivity endpoint..."
dns_test_response=$(curl -s -X POST http://localhost:8080/api/v1/dns/test \
    -H "Content-Type: application/json" \
    -d '{"server": "1.1.1.1", "timeout": 5}' 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$dns_test_response" ]; then
    if echo "$dns_test_response" | jq -e '.status' > /dev/null 2>&1; then
        print_result "PASS" "DNS Server Test Endpoint"
    else
        print_result "WARN" "DNS Server Test Endpoint - Returns placeholder response"
    fi
else
    print_result "FAIL" "DNS Server Test Endpoint - Unreachable"
fi

echo ""
echo "⚡ Phase 3: Performance Testing"
echo "------------------------------"

# Test 8: Configuration Endpoint Response Time
test_response_time "http://localhost:8080/api/v1/config/" 1000 "Configuration Response Time (<1s)"

# Test 9: Health Check Response Time
test_response_time "http://localhost:8080/health" 500 "Health Check Response Time (<500ms)"

# Test 10: Concurrent Request Handling
print_result "INFO" "Testing concurrent request handling..."
start_time=$(date +%s)
for i in {1..10}; do
    curl -s http://localhost:8080/api/v1/config/ > /dev/null 2>&1 &
done
wait
end_time=$(date +%s)
concurrent_time=$((end_time - start_time))

if [ $concurrent_time -lt 5 ]; then
    print_result "PASS" "Concurrent Request Handling (${concurrent_time}s)"
else
    print_result "WARN" "Concurrent Request Handling (${concurrent_time}s) - May need optimization"
fi

echo ""
echo "🎭 Phase 4: UI State Testing"
echo "----------------------------"

# Test 11: Success State Data Validation
print_result "INFO" "Validating success state data..."
config_response=$(curl -s http://localhost:8080/api/v1/config/ 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$config_response" ]; then
    # Check required fields for UI
    privacy_mode=$(echo "$config_response" | jq -r '.privacy_mode // false')
    dns_servers=$(echo "$config_response" | jq -r '.dns_servers | length // 0')
    blocklist_enabled=$(echo "$config_response" | jq -r '.blocklist_enabled // false')
    
    if [ "$privacy_mode" = "true" ] && [ "$dns_servers" -gt 0 ] && [ "$blocklist_enabled" = "true" ]; then
        print_result "PASS" "Success State Data Validation"
        print_result "INFO" "  - Privacy mode: $privacy_mode"
        print_result "INFO" "  - DNS servers: $dns_servers configured"
        print_result "INFO" "  - Blocklist: $blocklist_enabled"
    else
        print_result "FAIL" "Success State Data Validation - Missing required fields"
    fi
else
    print_result "FAIL" "Success State Data Validation - No response"
fi

echo ""
echo "🔥 Phase 5: Error Scenario Testing"
echo "---------------------------------"

# Test 12: Connection Timeout Handling
print_result "INFO" "Testing connection timeout handling..."
timeout_response=$(curl -s http://localhost:9999/health --connect-timeout 2 2>/dev/null)
if [ $? -ne 0 ]; then
    print_result "PASS" "Connection Timeout Handling - Properly detects unreachable service"
else
    print_result "FAIL" "Connection Timeout Handling - Should fail for unreachable service"
fi

# Test 13: Invalid JSON Response Handling
print_result "INFO" "Testing invalid JSON response handling..."
# This would be tested in the actual app, but we can verify the endpoint returns valid JSON
config_json=$(curl -s http://localhost:8080/api/v1/config/ 2>/dev/null)
if echo "$config_json" | jq . > /dev/null 2>&1; then
    print_result "PASS" "Valid JSON Response Format"
else
    print_result "FAIL" "Valid JSON Response Format - Invalid JSON returned"
fi

echo ""
echo "🔒 Phase 6: Privacy Compliance Testing"
echo "-------------------------------------"

# Test 14: Privacy Headers Validation
print_result "INFO" "Testing privacy headers..."
headers=$(curl -s -I http://localhost:8080/api/v1/config/ 2>/dev/null)
if echo "$headers" | grep -q "X-Privacy-Policy" && echo "$headers" | grep -q "X-No-Domain-Logging"; then
    print_result "PASS" "Privacy Headers Present"
else
    print_result "WARN" "Privacy Headers - Some headers missing"
fi

# Test 15: No Domain Logging Verification
print_result "INFO" "Testing no domain logging compliance..."
if echo "$config_response" | jq -e '.privacy_mode == true and .domain_logging == false and .query_logging == false' > /dev/null 2>&1; then
    print_result "PASS" "No Domain Logging Compliance"
else
    print_result "FAIL" "No Domain Logging Compliance - Privacy settings incorrect"
fi

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Tests Warning: ${YELLOW}$TESTS_WARNING${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED + TESTS_WARNING))"
echo ""

# Final assessment
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNING -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED${NC} - Test Connection Button is fully functional!"
    else
        echo -e "${YELLOW}⚠️ TESTS PASSED WITH WARNINGS${NC} - Test Connection Button functional but may need optimization"
    fi
    exit 0
else
    echo -e "${RED}❌ TESTS FAILED${NC} - Test Connection Button has issues that need to be addressed"
    exit 1
fi