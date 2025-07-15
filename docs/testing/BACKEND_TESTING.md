# Backend Service Testing Guide

This document provides comprehensive testing instructions for the Shroudinger backend services (API server, blocklist service, and DNS service).

## Overview

The backend consists of three microservices:
- **API Server** (port 8080): Central coordination service
- **Blocklist Service** (port 8081): High-performance domain blocking
- **DNS Service** (port 8082): Encrypted DNS resolution

## Prerequisites

```bash
# Install testing tools
brew install curl jq httpie watch
go install github.com/rakyll/hey@latest

# Navigate to project root
cd /Users/rexliu/shroudinger

# Ensure Go dependencies are current
cd backend && go mod tidy
```

## Starting Services

### Start All Services
```bash
# Terminal 1: API Server
cd backend/cmd/api-server && go run main.go

# Terminal 2: Blocklist Service  
cd backend/cmd/blocklist-service && go run main.go

# Terminal 3: DNS Service
cd backend/cmd/dns-service && go run main.go
```

### Quick Health Check
```bash
# Check all services are running
curl http://localhost:8080/health | jq
curl http://localhost:8081/health | jq
curl http://localhost:8082/health | jq
```

## API Server Testing (Port 8080)

### Health and Status
```bash
# Basic health check
curl http://localhost:8080/health | jq

# System metrics
curl http://localhost:8080/metrics | jq

# System statistics
curl http://localhost:8080/api/v1/stats/summary | jq

# Configuration
curl http://localhost:8080/api/v1/config | jq
```

### Blocklist Management
```bash
# Trigger blocklist update
curl -X POST http://localhost:8080/api/v1/blocklist/update | jq

# Get blocklist status
curl http://localhost:8080/api/v1/blocklist/status | jq
```

### DNS Resolution
```bash
# Test DNS resolution (privacy-critical - no domain logging)
curl -X POST http://localhost:8080/api/v1/dns/resolve \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "type": "A"}' | jq
```

### Privacy Testing
```bash
# Test 1: Verify no domain logging in responses
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/dns/resolve \
  -H "Content-Type: application/json" \
  -d '{"domain": "test-privacy.com", "type": "A"}')

if echo "$RESPONSE" | grep -q "test-privacy.com"; then
    echo "❌ PRIVACY VIOLATION: Domain found in response"
else
    echo "✅ Privacy compliant: No domain in response"
fi

# Test 2: Check privacy headers
curl -I http://localhost:8080/health | grep -E "(X-Privacy|X-No-)"
```

## Blocklist Service Testing (Port 8081)

### Health and Performance
```bash
# Service health
curl http://localhost:8081/health | jq

# Performance metrics
curl http://localhost:8081/metrics | jq

# Blocklist sources
curl http://localhost:8081/api/v1/blocklist/sources | jq
```

### High-Performance Domain Checking
```bash
# Single domain check (target: <1ms)
curl -X POST http://localhost:8081/api/v1/blocklist/check \
  -H "Content-Type: application/json" \
  -d '{"domain": "doubleclick.net"}' | jq

# Batch domain checking
curl -X POST http://localhost:8081/api/v1/blocklist/batch \
  -H "Content-Type: application/json" \
  -d '{"domains": ["doubleclick.net", "googlesyndication.com", "facebook.com"]}' | jq
```

### Performance Testing
```bash
# Load test blocklist checking (target: <1ms per lookup)
hey -n 1000 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com"}' \
  http://localhost:8081/api/v1/blocklist/check
```

### Blocklist Management
```bash
# Fetch from sources
curl -X POST http://localhost:8081/api/v1/blocklist/fetch \
  -H "Content-Type: application/json" \
  -d '{"sources": ["StevenBlack", "AdGuard"]}' | jq

# Optimize data structures
curl -X POST http://localhost:8081/api/v1/blocklist/optimize | jq
```

## DNS Service Testing (Port 8082)

### Health and Configuration
```bash
# Service health
curl http://localhost:8082/health | jq

# Performance metrics
curl http://localhost:8082/metrics | jq

# Available DNS servers
curl http://localhost:8082/api/v1/dns/servers | jq
```

### DNS Resolution Testing
```bash
# Test encrypted DNS resolution (target: <5ms)
curl -X POST http://localhost:8082/api/v1/dns/resolve \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "type": "A"}' | jq

# Test server connectivity
curl -X POST http://localhost:8082/api/v1/dns/test \
  -H "Content-Type: application/json" \
  -d '{"server": "1.1.1.1"}' | jq
```

### Performance Testing
```bash
# Load test DNS resolution (target: <5ms per query)
hey -n 1000 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "type": "A"}' \
  http://localhost:8082/api/v1/dns/resolve
```

## Automated Testing Script

```bash
#!/bin/bash
# test_backend.sh - Automated backend testing

echo "🚀 Starting Backend Service Tests"

# Check if services are running
services=("8080" "8081" "8082")
for port in "${services[@]}"; do
    if curl -s "http://localhost:$port/health" > /dev/null; then
        echo "✅ Service on port $port is running"
    else
        echo "❌ Service on port $port is not responding"
        exit 1
    fi
done

echo "📊 Running Performance Tests"

# Test blocklist performance
echo "Testing blocklist performance..."
hey -n 100 -c 5 -m POST \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com"}' \
  http://localhost:8081/api/v1/blocklist/check

# Test DNS performance
echo "Testing DNS performance..."
hey -n 100 -c 5 -m POST \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "type": "A"}' \
  http://localhost:8082/api/v1/dns/resolve

echo "🔒 Running Privacy Tests"

# Test domain privacy
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/dns/resolve \
  -H "Content-Type: application/json" \
  -d '{"domain": "privacy-test.com", "type": "A"}')

if echo "$RESPONSE" | grep -q "privacy-test.com"; then
    echo "❌ PRIVACY VIOLATION: Domain found in response"
    exit 1
else
    echo "✅ Privacy test passed: No domain in response"
fi

echo "✅ All backend tests completed successfully"
```

## Performance Targets

| Service | Target | Endpoint |
|---------|--------|----------|
| API Server | <10ms | All endpoints |
| Blocklist | <1ms | Domain lookup |
| DNS | <5ms | DNS resolution |

## Privacy Compliance

- ✅ No domain names in API responses
- ✅ No DNS query logging
- ✅ No user data persistence
- ✅ Anonymous metrics only
- ✅ Privacy headers present

## Troubleshooting

### Common Issues
1. **Service won't start**: Check port conflicts with `lsof -i :8080`
2. **High response times**: Check system resources with `top`
3. **Privacy violations**: Verify no domain names in logs or responses

### Debug Commands
```bash
# Check service processes
ps aux | grep "go run"

# Monitor service logs
tail -f logs/*.log

# Test service connectivity
curl -v http://localhost:8080/health
```

This comprehensive testing guide ensures all backend services meet privacy and performance requirements.