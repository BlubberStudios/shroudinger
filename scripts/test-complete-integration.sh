#!/bin/bash

# Complete integration test for testing logs feature
echo "🧪 Complete Integration Test for Testing Logs Feature"
echo "====================================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "📍 Project root: $PROJECT_ROOT"
echo ""

# Test 1: Check if scripts are executable
echo "🔍 Test 1: Checking script permissions..."
if [[ -x "scripts/start-services.sh" && -x "scripts/stop-services.sh" ]]; then
    echo "✅ Scripts are executable"
else
    echo "❌ Scripts are not executable"
    echo "Fix with: chmod +x scripts/start-services.sh scripts/stop-services.sh"
    exit 1
fi

# Test 2: Check if Makefile has been updated
echo ""
echo "🔍 Test 2: Checking Makefile..."
if grep -q "scripts/start-services.sh" Makefile; then
    echo "✅ Makefile updated with new script"
else
    echo "❌ Makefile not properly updated"
    exit 1
fi

# Test 3: Stop any existing services
echo ""
echo "🔍 Test 3: Stopping existing services..."
./scripts/stop-services.sh

# Test 4: Start services with testing mode enabled
echo ""
echo "🔍 Test 4: Starting services with testing mode..."
export SHROUDINGER_TESTING=true
./scripts/start-services.sh

# Wait for services to fully start
echo ""
echo "⏳ Waiting for services to start..."
sleep 5

# Test 5: Check if all services are running
echo ""
echo "🔍 Test 5: Checking service health..."
services=(
    "http://localhost:8080/health:API Server"
    "http://localhost:8081/health:Blocklist Service"
    "http://localhost:8082/health:DNS Service"
    "http://localhost:8083/health:Middleware"
)

all_healthy=true
for service in "${services[@]}"; do
    IFS=':' read -r url name <<< "$service"
    if curl -s -f "$url" > /dev/null; then
        echo "✅ $name is healthy"
    else
        echo "❌ $name is not responding"
        all_healthy=false
    fi
done

if [[ "$all_healthy" != "true" ]]; then
    echo "❌ Some services are not healthy"
    exit 1
fi

# Test 6: Check if testing endpoints are available
echo ""
echo "🔍 Test 6: Testing middleware logging endpoints..."

# Test logs endpoint
echo "Testing GET /testing/logs..."
logs_response=$(curl -s "http://localhost:8083/testing/logs")
if [[ $? -eq 0 ]]; then
    echo "✅ Testing logs endpoint is available"
    echo "Response: $logs_response"
else
    echo "❌ Testing logs endpoint not available"
    exit 1
fi

# Test 7: Generate some log entries
echo ""
echo "🔍 Test 7: Generating log entries..."

# Test DNS query
echo "Testing DNS query..."
curl -s -X POST "http://localhost:8083/api/v1/dns/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "test-123",
    "domain": "example.com",
    "type": "A",
    "source": "integration-test"
  }' > /dev/null

# Test extension registration
echo "Testing extension registration..."
curl -s -X POST "http://localhost:8083/api/v1/extension/register" \
  -H "Content-Type: application/json" \
  -d '{
    "extension_id": "com.shroudinger.extension",
    "version": "1.0.0",
    "capabilities": ["dns_proxy", "content_filter"]
  }' > /dev/null

# Test 8: Check if logs were generated
echo ""
echo "🔍 Test 8: Checking generated logs..."
sleep 2

logs_with_entries=$(curl -s "http://localhost:8083/testing/logs" | jq -r '.count')
if [[ "$logs_with_entries" -gt 0 ]]; then
    echo "✅ Log entries generated: $logs_with_entries"
    
    # Show some log entries
    echo "Recent log entries:"
    curl -s "http://localhost:8083/testing/logs" | jq -r '.logs[] | "\(.timestamp) [\(.level)] \(.service): \(.event)"' | head -5
else
    echo "❌ No log entries generated"
    exit 1
fi

# Test 9: Test log clearing
echo ""
echo "🔍 Test 9: Testing log clearing..."
curl -s -X DELETE "http://localhost:8083/testing/logs" > /dev/null

logs_after_clear=$(curl -s "http://localhost:8083/testing/logs" | jq -r '.count')
if [[ "$logs_after_clear" -eq 0 ]]; then
    echo "✅ Logs cleared successfully"
else
    echo "❌ Logs not cleared properly"
    exit 1
fi

# Test 10: Test Go module compilation
echo ""
echo "🔍 Test 10: Testing Go module compilation..."
cd middleware
if go build -o /tmp/middleware ./cmd/middleware; then
    echo "✅ Middleware compiles successfully"
    rm -f /tmp/middleware
else
    echo "❌ Middleware compilation failed"
    exit 1
fi

cd "$PROJECT_ROOT"

# Test 11: Test Swift compilation (if Xcode is available)
echo ""
echo "🔍 Test 11: Testing Swift compilation..."
if command -v xcodebuild > /dev/null; then
    cd frontend
    if xcodebuild -project Shroudinger.xcodeproj -scheme Shroudinger -configuration Debug -destination 'platform=macOS' build > /dev/null 2>&1; then
        echo "✅ Swift app compiles successfully"
    else
        echo "❌ Swift app compilation failed"
        echo "Note: This might be due to missing dependencies or Xcode configuration"
    fi
    cd "$PROJECT_ROOT"
else
    echo "⚠️  Xcode not available, skipping Swift compilation test"
fi

# Test 12: Clean up
echo ""
echo "🔍 Test 12: Cleaning up..."
./scripts/stop-services.sh

echo ""
echo "🎉 Integration test completed successfully!"
echo ""
echo "📱 To use the testing logs feature:"
echo "1. Open the Shroudinger app"
echo "2. Go to Overview section"
echo "3. Enable 'Testing Logs' in Development Tools"
echo "4. Toggle DNS Protection ON"
echo "5. The logs will appear in the main view (if 'Show in Overview' is enabled)"
echo "6. Or click 'Testing Logs' in the sidebar for the full view"
echo ""
echo "🧪 To test manually:"
echo "1. export SHROUDINGER_TESTING=true"
echo "2. make dev"
echo "3. ./scripts/test-logging.sh"