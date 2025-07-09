#!/bin/bash

# Integration Test Script for Shroudinger DNS App
# Tests all services and their integration

echo "🧪 Running Integration Tests for Shroudinger DNS App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_contains="$3"
    
    echo -n "📋 Testing $test_name... "
    
    result=$(eval "$test_command" 2>/dev/null)
    
    if echo "$result" | grep -q "$expected_contains"; then
        echo -e "${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected: $expected_contains"
        echo "   Got: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test service health endpoints
echo "🏥 Testing Service Health..."
run_test "API Server Health" "curl -s http://localhost:8080/health" "healthy"
run_test "Blocklist Service Health" "curl -s http://localhost:8081/health" "healthy"
run_test "DNS Service Health" "curl -s http://localhost:8082/health" "healthy"
run_test "Middleware Health" "curl -s http://localhost:8083/health" "healthy"

# Test privacy headers
echo ""
echo "🔒 Testing Privacy Headers..."
run_test "API Server Privacy Header" "curl -s -I http://localhost:8080/health | grep -i privacy" "no-logging"
run_test "Blocklist Privacy Header" "curl -s -I http://localhost:8081/health | grep -i privacy" "no-user-data-storage"
run_test "DNS Privacy Header" "curl -s -I http://localhost:8082/health | grep -i privacy" "no-query-logging"
run_test "Middleware Privacy Header" "curl -s -I http://localhost:8083/health | grep -i privacy" "no-user-tracking"

# Test API endpoints
echo ""
echo "🔌 Testing API Endpoints..."
run_test "API Config Endpoint" "curl -s http://localhost:8080/api/v1/config" "privacy_mode"
run_test "API Stats Endpoint" "curl -s http://localhost:8080/api/v1/stats/summary" "queries_processed"
run_test "DNS Servers Endpoint" "curl -s http://localhost:8082/api/v1/dns/servers" "Cloudflare"
run_test "Blocklist Sources Endpoint" "curl -s http://localhost:8081/api/v1/blocklist/sources" "StevenBlack"

# Test DNS resolution (without logging)
echo ""
echo "🌐 Testing DNS Resolution (Privacy-First)..."
run_test "DNS Resolution Test" "curl -s -X POST http://localhost:8080/api/v1/dns/resolve -H 'Content-Type: application/json' -d '{\"domain\": \"example.com\"}'" "resolved"
run_test "DNS Service Resolution" "curl -s -X POST http://localhost:8082/api/v1/dns/resolve -H 'Content-Type: application/json' -d '{\"domain\": \"test.com\"}'" "resolved"

# Test middleware integration
echo ""
echo "🔗 Testing Middleware Integration..."
run_test "Backend Status Check" "curl -s http://localhost:8083/api/v1/backend/status" "healthy"
run_test "Extension Configuration" "curl -s -X POST http://localhost:8083/api/v1/extension/configure -H 'Content-Type: application/json' -d '{\"dns_servers\": [\"1.1.1.1\"], \"blocklist_enabled\": true}'" "configured"

# Test blocklist management
echo ""
echo "📋 Testing Blocklist Management..."
run_test "Blocklist Update Trigger" "curl -s -X POST http://localhost:8080/api/v1/blocklist/update" "update_triggered"
run_test "Blocklist Status Check" "curl -s http://localhost:8080/api/v1/blocklist/status" "domains_count"

# Test DNS server connectivity
echo ""
echo "🔐 Testing DNS Server Connectivity..."
run_test "DNS Server Test" "curl -s -X POST http://localhost:8082/api/v1/dns/test -H 'Content-Type: application/json' -d '{\"server\": \"1.1.1.1\"}'" "test_complete"

# Test privacy compliance
echo ""
echo "🔒 Testing Privacy Compliance..."
run_test "No Domain Logging in DNS Response" "curl -s -X POST http://localhost:8080/api/v1/dns/resolve -H 'Content-Type: application/json' -d '{\"domain\": \"example.com\"}' | grep -v 'domain'" "resolved"
run_test "Stats Without User Data" "curl -s http://localhost:8080/api/v1/stats/summary | grep -v 'user\\|query_history\\|domain_list'" "queries_processed"

# Performance tests
echo ""
echo "⚡ Testing Performance..."
start_time=$(date +%s%N)
curl -s http://localhost:8080/api/v1/config > /dev/null
end_time=$(date +%s%N)
response_time=$((($end_time - $start_time) / 1000000))

if [ $response_time -lt 100 ]; then
    echo -e "📋 Testing API Response Time... ${GREEN}✅ PASS${NC} (${response_time}ms)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "📋 Testing API Response Time... ${RED}❌ FAIL${NC} (${response_time}ms > 100ms)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Final results
echo ""
echo "📊 Integration Test Results:"
echo -e "   ${GREEN}✅ Passed: $TESTS_PASSED${NC}"
echo -e "   ${RED}❌ Failed: $TESTS_FAILED${NC}"
echo "   Total: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL INTEGRATION TESTS PASSED!${NC}"
    echo -e "${GREEN}🔒 Privacy-first DNS app is ready for development${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo "Please check the failed tests above"
    exit 1
fi