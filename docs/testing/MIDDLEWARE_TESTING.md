# Middleware Testing Guide

This document provides comprehensive testing instructions for the Shroudinger middleware service that coordinates between the macOS NetworkExtension and backend services.

## Overview

The middleware service (port 8083) handles:
- NetworkExtension coordination
- DNS query processing pipeline
- Service health monitoring
- System-wide DNS interception

## Prerequisites

```bash
# Install testing tools
brew install curl jq httpie watch
go install github.com/rakyll/hey@latest

# Navigate to project root
cd /Users/rexliu/shroudinger

# Ensure middleware dependencies are current
cd middleware && go mod tidy
```

## Starting Middleware Service

```bash
# Terminal 1: Start middleware service
cd middleware/cmd/middleware && go run main.go

# Should see output:
# 🚀 Middleware Service starting on port 8083
# 🔒 Privacy mode: No DNS query logging
# 🔗 NetworkExtension coordination enabled
```

## Health Check Testing

```bash
# Basic health check
curl http://localhost:8083/health | jq

# Expected response:
# {
#   "status": "healthy",
#   "service": "middleware",
#   "version": "1.0.0",
#   "uptime": "5m30s",
#   "privacy": "no-query-logging"
# }

# Performance metrics
curl http://localhost:8083/metrics | jq
```

## DNS Query Processing Tests

### Single DNS Query Processing
```bash
# Test DNS query processing (PRIVACY CRITICAL - no domain logging)
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "test-001",
    "domain": "example.com",
    "type": "A",
    "source": "NetworkExtension"
  }' | jq

# Expected response (NO domain in response):
# {
#   "query_id": "test-001",
#   "status": "resolved",
#   "blocked": false,
#   "response_time": "3ms",
#   "resolver": "encrypted",
#   "cache_hit": false
# }
```

### Batch DNS Query Processing
```bash
# Test batch DNS processing
curl -X POST http://localhost:8083/api/v1/dns/batch \
  -H "Content-Type: application/json" \
  -d '{
    "queries": [
      {"query_id": "batch-001", "domain": "example.com", "type": "A"},
      {"query_id": "batch-002", "domain": "google.com", "type": "A"},
      {"query_id": "batch-003", "domain": "github.com", "type": "A"}
    ]
  }' | jq
```

## NetworkExtension Integration Tests

### Extension Registration
```bash
# Test NetworkExtension registration
curl -X POST http://localhost:8083/api/v1/extension/register \
  -H "Content-Type: application/json" \
  -d '{
    "extension_id": "com.blubberstudios.shroudinger.extension",
    "version": "1.0.0",
    "capabilities": ["dns_proxy", "content_filter"]
  }' | jq
```

### Extension Status
```bash
# Check extension status
curl http://localhost:8083/api/v1/extension/status | jq

# Expected response:
# {
#   "extension_registered": true,
#   "extension_active": true,
#   "dns_interception": "enabled",
#   "queries_processed": 1234
# }
```

## Service Coordination Tests

### Backend Service Health
```bash
# Check backend service connectivity
curl http://localhost:8083/api/v1/services/health | jq

# Expected response:
# {
#   "api_server": "healthy",
#   "blocklist_service": "healthy", 
#   "dns_service": "healthy",
#   "last_check": "2025-07-15T10:30:45Z"
# }
```

### Service Discovery
```bash
# Test service discovery
curl http://localhost:8083/api/v1/services/discover | jq
```

## Privacy Testing (CRITICAL)

### Domain Privacy Compliance
```bash
# Test 1: Verify no domain logging in responses
RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{"query_id": "privacy-test", "domain": "secret-domain.com", "type": "A"}')

if echo "$RESPONSE" | grep -q "secret-domain.com"; then
    echo "❌ PRIVACY VIOLATION: Domain found in response"
else
    echo "✅ Privacy compliant: No domain in response"
fi

# Test 2: Check privacy headers
curl -I http://localhost:8083/health | grep -E "(X-Privacy|X-No-)"

# Should see:
# X-Privacy-Policy: no-query-logging
# X-No-Domain-Logging: true
# X-Data-Retention: none
```

### Query Logging Compliance
```bash
# Test 3: Verify no query persistence
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{"query_id": "logging-test", "domain": "test-logging.com", "type": "A"}' | jq

# Check logs should show NO domain names
# grep -i "test-logging.com" logs/*.log
# Should return no results
```

## Performance Testing

### DNS Query Performance
```bash
# Load test DNS query processing (target: <5ms per query)
hey -n 1000 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"query_id": "perf-test", "domain": "example.com", "type": "A"}' \
  http://localhost:8083/api/v1/dns/query
```

### Concurrent Query Handling
```bash
# Test concurrent query handling
for i in {1..10}; do
  curl -X POST http://localhost:8083/api/v1/dns/query \
    -H "Content-Type: application/json" \
    -d "{\"query_id\": \"concurrent-$i\", \"domain\": \"test$i.com\", \"type\": \"A\"}" &
done
wait
```

## System Integration Tests

### Full Pipeline Test
```bash
# Test complete DNS processing pipeline
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "pipeline-test",
    "domain": "example.com",
    "type": "A",
    "source": "NetworkExtension",
    "client_ip": "127.0.0.1"
  }' | jq
```

### Error Handling Tests
```bash
# Test invalid domain
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{"query_id": "error-test", "domain": "", "type": "A"}' | jq

# Test invalid query type
curl -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{"query_id": "error-test", "domain": "example.com", "type": "INVALID"}' | jq
```

## Automated Testing Script

```bash
#!/bin/bash
# test_middleware.sh - Automated middleware testing

echo "🚀 Starting Middleware Service Tests"

# Check if middleware is running
if curl -s http://localhost:8083/health > /dev/null; then
    echo "✅ Middleware service is running"
else
    echo "❌ Middleware service is not responding"
    exit 1
fi

echo "🔒 Running Privacy Tests"

# Test domain privacy
RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/dns/query \
  -H "Content-Type: application/json" \
  -d '{"query_id": "privacy-test", "domain": "privacy-test-domain.com", "type": "A"}')

if echo "$RESPONSE" | grep -q "privacy-test-domain.com"; then
    echo "❌ PRIVACY VIOLATION: Domain found in response"
    exit 1
else
    echo "✅ Privacy test passed: No domain in response"
fi

echo "⚡ Running Performance Tests"

# Test query performance
echo "Testing DNS query performance..."
hey -n 100 -c 5 -m POST \
  -H "Content-Type: application/json" \
  -d '{"query_id": "perf-test", "domain": "example.com", "type": "A"}' \
  http://localhost:8083/api/v1/dns/query

echo "🔗 Testing NetworkExtension Integration"

# Test extension status
curl -s http://localhost:8083/api/v1/extension/status | jq

echo "📊 Testing Service Coordination"

# Test backend service health
curl -s http://localhost:8083/api/v1/services/health | jq

echo "✅ All middleware tests completed successfully"
```

## NetworkExtension Coordination

### macOS System Extension Testing
```bash
# Check system extension status
systemextensionsctl list

# Should show Shroudinger extension as approved
# com.blubberstudios.shroudinger.extension [approved]
```

### DNS Interception Testing
```bash
# Test DNS interception is working
nslookup example.com
dig example.com

# Should route through middleware on port 8083
```

## Performance Targets

| Component | Target | Test Method |
|-----------|--------|-------------|
| DNS Query Processing | <5ms | Single query response |
| Batch Processing | <10ms | Batch query response |
| NetworkExtension Response | <2ms | Extension coordination |
| Service Health Check | <1ms | Health endpoint |

## Privacy Compliance Checklist

- ✅ No domain names in API responses
- ✅ No DNS query logging to disk
- ✅ No user IP address storage
- ✅ No query history persistence
- ✅ Anonymous metrics only
- ✅ Privacy headers present
- ✅ In-memory processing only

## Troubleshooting

### Common Issues
1. **NetworkExtension not responding**: Check system extension approval
2. **DNS queries not intercepted**: Verify DNS proxy configuration
3. **High latency**: Check backend service connectivity
4. **Privacy violations**: Verify no domain names in logs

### Debug Commands
```bash
# Check middleware process
ps aux | grep middleware

# Monitor middleware logs
tail -f logs/middleware.log

# Test connectivity to backend services
curl -v http://localhost:8080/health
curl -v http://localhost:8081/health
curl -v http://localhost:8082/health

# Check system DNS configuration
scutil --dns

# Monitor network traffic
sudo tcpdump -i any port 53
```

This comprehensive testing ensures the middleware service maintains privacy while providing high-performance DNS coordination.