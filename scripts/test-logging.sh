#!/bin/bash

# Test script for middleware logging functionality
# This script demonstrates how to enable and test the logging window

echo "🧪 Testing Shroudinger Middleware Logging"
echo "========================================="

# Check if testing mode is enabled
if [[ "$SHROUDINGER_TESTING" != "true" ]]; then
    echo "⚠️  Testing mode is not enabled"
    echo "To enable testing mode, run:"
    echo "export SHROUDINGER_TESTING=true"
    echo ""
    echo "Then start services with:"
    echo "make dev"
    echo ""
    echo "Or use the Swift app:"
    echo "1. Open the Shroudinger app"
    echo "2. Enable 'Testing Logs' in Overview -> Development Tools"
    echo "3. Toggle DNS Protection on"
    echo ""
    exit 1
fi

# Check if middleware is running
echo "🔍 Checking if middleware is running..."
if curl -s http://localhost:8083/health > /dev/null; then
    echo "✅ Middleware is running on port 8083"
else
    echo "❌ Middleware is not running"
    echo "Start the services first with:"
    echo "SHROUDINGER_TESTING=true make dev"
    echo ""
    echo "Or use the Swift app with testing logs enabled"
    exit 1
fi

# Test logging endpoints
echo ""
echo "🔍 Testing logging endpoints..."

# Test getting logs
echo "📋 Getting current logs..."
curl -s -X GET http://localhost:8083/testing/logs | jq '.' || echo "No logs yet"

# Test DNS query logging
echo ""
echo "🔍 Testing DNS query logging..."
curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "test-123",
    "domain": "example.com",
    "type": "A",
    "source": "test"
  }' | jq '.'

# Test extension registration logging
echo ""
echo "🔍 Testing extension registration logging..."
curl -s -X POST http://localhost:8083/api/v1/extension/register \
  -H "Content-Type: application/json" \
  -d '{
    "extension_id": "com.shroudinger.extension",
    "version": "1.0.0",
    "capabilities": ["dns_proxy", "content_filter"]
  }' | jq '.'

# Get logs after tests
echo ""
echo "📋 Getting logs after tests..."
curl -s -X GET http://localhost:8083/testing/logs | jq '.'

# Test clearing logs
echo ""
echo "🧹 Testing log clearing..."
curl -s -X DELETE http://localhost:8083/testing/logs | jq '.'

# Verify logs are cleared
echo ""
echo "📋 Verifying logs are cleared..."
curl -s -X GET http://localhost:8083/testing/logs | jq '.'

echo ""
echo "✅ Testing complete!"
echo ""
echo "📱 To view logs in the app:"
echo "1. Make sure SHROUDINGER_TESTING=true is set"
echo "2. Start the middleware with testing mode"
echo "3. Open the Shroudinger app"
echo "4. Navigate to 'Testing Logs' in the sidebar"
echo "5. The logs will auto-refresh every 2 seconds"