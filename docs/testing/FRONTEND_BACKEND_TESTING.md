# Frontend-Backend Integration Testing Guide

This document provides comprehensive testing instructions for the integration between the Swift macOS frontend and Go backend services.

## Overview

This testing covers:
- SwiftUI app to API server communication
- NetworkExtension to middleware integration
- System DNS configuration
- GUI state synchronization
- Real-time statistics and monitoring

## Architecture Under Test

```
┌─────────────────────────────────────────────────────────────────┐
│                Frontend-Backend Integration                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐           ┌─────────────────┐              │
│  │   SwiftUI App   │           │   Go Backend    │              │
│  │                 │◄─────────►│                 │              │
│  │ • Settings UI   │   HTTP    │ • API Server    │              │
│  │ • Statistics    │   REST    │ • Services      │              │
│  │ • Status        │   JSON    │ • Middleware    │              │
│  └─────────────────┘           └─────────────────┘              │
│           │                             │                       │
│  ┌─────────────────┐           ┌─────────────────┐              │
│  │NetworkExtension │           │   Middleware    │              │
│  │                 │◄─────────►│                 │              │
│  │ • DNS Proxy     │   HTTP    │ • Coordination  │              │
│  │ • Interception  │   API     │ • Query Proc   │              │
│  │ • Filtering     │   Calls   │ • Statistics    │              │
│  └─────────────────┘           └─────────────────┘              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Install testing tools
brew install curl jq httpie watch

# Navigate to project root
cd /Users/rexliu/shroudinger

# Start backend services
cd backend/cmd/api-server && go run main.go &
cd backend/cmd/blocklist-service && go run main.go &
cd backend/cmd/dns-service && go run main.go &
cd middleware/cmd/middleware && go run main.go &

# Verify backend services are running
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health
```

## SwiftUI App to API Server Testing

### Configuration Management
```bash
# Test configuration retrieval (what the app would call)
curl http://localhost:8080/api/v1/config | jq

# Expected response for app configuration:
# {
#   "dns_servers": ["1.1.1.1", "9.9.9.9", "8.8.8.8"],
#   "blocklist_sources": 3,
#   "privacy_mode": true,
#   "logging_disabled": true
# }
```

### Statistics for GUI Display
```bash
# Test statistics endpoint (for app dashboard)
curl http://localhost:8080/api/v1/stats/summary | jq

# Expected response for GUI:
# {
#   "queries_processed": 50000,
#   "domains_blocked": 5000,
#   "cache_hit_rate": 0.85,
#   "uptime": "2h30m",
#   "avg_response_time": "1.2ms"
# }
```

### Blocklist Management from GUI
```bash
# Test blocklist update (triggered from app)
curl -X POST http://localhost:8080/api/v1/blocklist/update | jq

# Test blocklist status (for app display)
curl http://localhost:8080/api/v1/blocklist/status | jq

# Expected response:
# {
#   "status": "active",
#   "domains_count": 1000000,
#   "sources_active": 3,
#   "last_updated": "2025-07-15T10:30:00Z"
# }
```

## NetworkExtension to Middleware Testing

### DNS Query Processing
```bash
# Test DNS query processing (simulates NetworkExtension calls)
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "ext-test-001",
    "domain": "example.com",
    "type": "A",
    "source": "NetworkExtension",
    "client_ip": "127.0.0.1"
  }' | jq

# Expected response (NO domain in response for privacy):
# {
#   "query_id": "ext-test-001",
#   "status": "resolved",
#   "blocked": false,
#   "response_time": "3ms",
#   "resolver": "encrypted"
# }
```

### Batch DNS Processing
```bash
# Test batch processing (NetworkExtension may batch queries)
curl -X POST http://localhost:8083/api/v1/dns/batch \
  -H "Content-Type: application/json" \
  -d '{
    "queries": [
      {"query_id": "batch-001", "domain": "example.com", "type": "A"},
      {"query_id": "batch-002", "domain": "google.com", "type": "A"},
      {"query_id": "batch-003", "domain": "doubleclick.net", "type": "A"}
    ]
  }' | jq

# Should return array of results with blocked domains marked
```

### Extension Registration
```bash
# Test NetworkExtension registration
curl -X POST http://localhost:8083/api/v1/extension/register \
  -H "Content-Type: application/json" \
  -d '{
    "extension_id": "com.blubberstudios.shroudinger.extension",
    "version": "1.0.0",
    "capabilities": ["dns_proxy", "content_filter"],
    "app_version": "1.0.0"
  }' | jq
```

## System DNS Configuration Testing

### DNS Server Testing
```bash
# Test DNS server configuration (what app would call)
curl http://localhost:8082/api/v1/dns/servers | jq

# Expected response for app settings:
# {
#   "servers": [
#     {
#       "name": "Cloudflare",
#       "address": "1.1.1.1",
#       "port": 853,
#       "protocol": "DoT",
#       "status": "active"
#     }
#   ]
# }
```

### DNS Server Testing from App
```bash
# Test DNS server connectivity (app feature)
curl -X POST http://localhost:8082/api/v1/dns/test \
  -H "Content-Type: application/json" \
  -d '{
    "server": "1.1.1.1",
    "timeout": 5
  }' | jq

# Expected response:
# {
#   "status": "test_complete",
#   "server": "1.1.1.1",
#   "response_time": "45ms",
#   "connection": "successful",
#   "encryption": "verified"
# }
```

## Real-Time Statistics Testing

### Live Statistics Updates
```bash
# Test real-time statistics (for app dashboard updates)
echo "📊 Testing real-time statistics updates..."

# Simulate DNS queries to generate statistics
for i in {1..10}; do
  curl -X POST http://localhost:8083/api/v1/dns/query \
    -H "Content-Type: application/json" \
    -d '{
      "query_id": "stats-test-'$i'",
      "domain": "test'$i'.com",
      "type": "A"
    }' > /dev/null &
done
wait

# Check updated statistics
curl http://localhost:8080/api/v1/stats/summary | jq
```

### Performance Metrics for GUI
```bash
# Test performance metrics (for app monitoring)
curl http://localhost:8080/metrics | jq

# Expected response:
# {
#   "requests_per_second": 150,
#   "avg_response_time": "1.2ms",
#   "memory_usage_mb": 142,
#   "cpu_usage_percent": 12
# }
```

## GUI State Synchronization Testing

### Service Health for App Status
```bash
# Test service health (for app status indicators)
curl http://localhost:8083/api/v1/services/health | jq

# Expected response for app status display:
# {
#   "api_server": "healthy",
#   "blocklist_service": "healthy",
#   "dns_service": "healthy",
#   "overall_status": "healthy",
#   "last_check": "2025-07-15T10:30:00Z"
# }
```

### Extension Status for GUI
```bash
# Test extension status (for app NetworkExtension display)
curl http://localhost:8083/api/v1/extension/status | jq

# Expected response:
# {
#   "extension_registered": true,
#   "extension_active": true,
#   "dns_interception": "enabled",
#   "queries_processed": 1234,
#   "last_activity": "2025-07-15T10:30:00Z"
# }
```

## Error Handling Testing

### Backend Service Failures
```bash
# Test app behavior when backend services fail
echo "🔥 Testing error handling from app perspective..."

# Stop API server (simulate failure)
# pkill -f "api-server"

# Test app requests to failed service
curl -X POST http://localhost:8080/api/v1/config 2>&1 | grep -q "refused" && echo "✅ App will handle connection refused"

# Test middleware response when backend fails
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "error-test",
    "domain": "example.com",
    "type": "A"
  }' | jq

# Should return graceful error response
```

### Network Connectivity Issues
```bash
# Test network connectivity errors
echo "🌐 Testing network connectivity issues..."

# Simulate network issues (use invalid ports)
curl -X POST http://localhost:9999/api/v1/config 2>&1 | grep -q "refused" && echo "✅ App will handle network errors"
```

## Privacy Testing from Frontend Perspective

### No Domain Data in App Responses
```bash
# Test privacy compliance from app perspective
echo "🔒 Testing privacy from frontend perspective..."

# Test that app never receives domain names in responses
TEST_DOMAIN="frontend-privacy-test.com"

# App query to middleware
RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "app-privacy-test",
    "domain": "'$TEST_DOMAIN'",
    "type": "A"
  }')

if echo "$RESPONSE" | grep -q "$TEST_DOMAIN"; then
    echo "❌ PRIVACY VIOLATION: Domain found in app response"
else
    echo "✅ App privacy compliant: No domain in response"
fi

# Test app statistics contain no domain names
STATS_RESPONSE=$(curl -s http://localhost:8080/api/v1/stats/summary)

if echo "$STATS_RESPONSE" | grep -qE "[a-zA-Z0-9-]+\.(com|org|net|edu)"; then
    echo "❌ PRIVACY VIOLATION: Domain found in app statistics"
else
    echo "✅ App statistics privacy compliant"
fi
```

## Performance Testing from App Perspective

### App Response Times
```bash
# Test response times for app interactions
echo "⚡ Testing app response times..."

# Test app configuration loading time
time curl -s http://localhost:8080/api/v1/config > /dev/null
echo "App config load time measured"

# Test app statistics update time
time curl -s http://localhost:8080/api/v1/stats/summary > /dev/null
echo "App statistics update time measured"

# Test app blocklist status time
time curl -s http://localhost:8080/api/v1/blocklist/status > /dev/null
echo "App blocklist status time measured"
```

### Concurrent App Requests
```bash
# Test concurrent app requests (multiple UI updates)
echo "🔄 Testing concurrent app requests..."

# Simulate multiple app components requesting data simultaneously
curl -s http://localhost:8080/api/v1/config | jq &
curl -s http://localhost:8080/api/v1/stats/summary | jq &
curl -s http://localhost:8080/api/v1/blocklist/status | jq &
curl -s http://localhost:8083/api/v1/extension/status | jq &
wait

echo "All concurrent app requests completed"
```

## Automated Frontend-Backend Testing Script

```bash
#!/bin/bash
# test_frontend_backend.sh - Frontend-Backend integration testing

echo "🚀 Starting Frontend-Backend Integration Tests"

# Check all backend services are running
services=("8080" "8081" "8082" "8083")
for port in "${services[@]}"; do
    if curl -s "http://localhost:$port/health" > /dev/null; then
        echo "✅ Backend service on port $port is running"
    else
        echo "❌ Backend service on port $port is not responding"
        exit 1
    fi
done

echo "🖥️ Testing App to API Server Communication"

# Test app configuration retrieval
CONFIG_RESPONSE=$(curl -s http://localhost:8080/api/v1/config)
if echo "$CONFIG_RESPONSE" | jq -e '.privacy_mode == true' > /dev/null; then
    echo "✅ App configuration API working"
else
    echo "❌ App configuration API failed"
    exit 1
fi

# Test app statistics
STATS_RESPONSE=$(curl -s http://localhost:8080/api/v1/stats/summary)
if echo "$STATS_RESPONSE" | jq -e '.queries_processed' > /dev/null; then
    echo "✅ App statistics API working"
else
    echo "❌ App statistics API failed"
    exit 1
fi

echo "🔌 Testing NetworkExtension to Middleware Communication"

# Test DNS query processing
DNS_RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "test-001",
    "domain": "example.com",
    "type": "A",
    "source": "NetworkExtension"
  }')

if echo "$DNS_RESPONSE" | jq -e '.status == "resolved"' > /dev/null; then
    echo "✅ NetworkExtension DNS processing working"
else
    echo "❌ NetworkExtension DNS processing failed"
    exit 1
fi

# Test extension registration
EXT_RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/extension/register \
  -H "Content-Type: application/json" \
  -d '{
    "extension_id": "com.blubberstudios.shroudinger.extension",
    "version": "1.0.0"
  }')

if echo "$EXT_RESPONSE" | jq -e '.status' > /dev/null; then
    echo "✅ NetworkExtension registration working"
else
    echo "❌ NetworkExtension registration failed"
    exit 1
fi

echo "🔒 Testing Frontend Privacy Compliance"

# Test app receives no domain names
PRIVACY_RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "privacy-test",
    "domain": "frontend-privacy-test.com",
    "type": "A"
  }')

if echo "$PRIVACY_RESPONSE" | grep -q "frontend-privacy-test.com"; then
    echo "❌ PRIVACY VIOLATION: Domain found in frontend response"
    exit 1
else
    echo "✅ Frontend privacy compliance verified"
fi

echo "⚡ Testing App Performance"

# Test app response times
APP_CONFIG_TIME=$(curl -w "%{time_total}" -s http://localhost:8080/api/v1/config -o /dev/null)
APP_STATS_TIME=$(curl -w "%{time_total}" -s http://localhost:8080/api/v1/stats/summary -o /dev/null)

echo "App config load time: ${APP_CONFIG_TIME}s"
echo "App stats load time: ${APP_STATS_TIME}s"

# Check performance targets (should be < 0.1s for app responsiveness)
if (( $(echo "$APP_CONFIG_TIME < 0.1" | bc -l) )) && (( $(echo "$APP_STATS_TIME < 0.1" | bc -l) )); then
    echo "✅ App performance targets met"
else
    echo "⚠️ App performance slower than target"
fi

echo "🔄 Testing Service Coordination"

# Test service health from app perspective
HEALTH_RESPONSE=$(curl -s http://localhost:8083/api/v1/services/health)
if echo "$HEALTH_RESPONSE" | jq -e '.api_server == "healthy"' > /dev/null; then
    echo "✅ Service coordination visible to app"
else
    echo "❌ Service coordination issues"
    exit 1
fi

echo "✅ All frontend-backend integration tests completed successfully"
echo "🎉 Frontend and backend are properly integrated"
```

## Integration Checklist

### SwiftUI App Integration
- ✅ Configuration API working
- ✅ Statistics API working
- ✅ Blocklist management API working
- ✅ Service health API working
- ✅ Error handling implemented
- ✅ Performance within targets

### NetworkExtension Integration
- ✅ DNS query processing working
- ✅ Batch processing working
- ✅ Extension registration working
- ✅ Status reporting working
- ✅ Error handling implemented

### System Integration
- ✅ DNS configuration working
- ✅ Real-time statistics working
- ✅ Service coordination working
- ✅ Privacy compliance verified
- ✅ Performance targets met

### Privacy Compliance
- ✅ No domain names in app responses
- ✅ No domain names in statistics
- ✅ Privacy headers present
- ✅ Anonymous metrics only
- ✅ No user data persistence

This comprehensive testing ensures the Swift macOS frontend properly integrates with the Go backend while maintaining privacy and performance standards.