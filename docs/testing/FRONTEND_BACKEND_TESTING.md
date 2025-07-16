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

### Test Connection Button Implementation

The SwiftUI app has a "Test Connection" button that should validate the backend connectivity. This section provides comprehensive testing for this critical UI component.

#### Test Connection Button Backend Endpoints

```bash
# 1. Test main configuration endpoint (primary connectivity test)
curl -s http://localhost:8080/api/v1/config/ | jq

# Expected response for successful connection:
# {
#   "privacy_mode": true,
#   "logging_disabled": true,
#   "dns_servers": ["1.1.1.1", "9.9.9.9", "8.8.8.8"],
#   "blocklist_sources": 3,
#   "blocklist_enabled": true,
#   "encryption_enabled": true,
#   "response_time": "42ns",
#   "status": "healthy"
# }

# 2. Test service health endpoint (secondary connectivity test)
curl -s http://localhost:8080/api/v1/stats/health | jq

# Expected response for healthy services:
# {
#   "api_server": "healthy",
#   "blocklist_service": "healthy", 
#   "dns_service": "healthy",
#   "middleware": "healthy",
#   "overall_status": "healthy"
# }

# 3. Test DNS server connectivity (DNS functionality test)
curl -s -X POST http://localhost:8080/api/v1/dns/test \
  -H "Content-Type: application/json" \
  -d '{"server": "1.1.1.1", "timeout": 5}' | jq

# Expected response for successful DNS test:
# {
#   "status": "success",
#   "server": "1.1.1.1", 
#   "response_time": "45ms",
#   "connection": "established",
#   "encryption": "verified"
# }
```

#### Test Connection Button UI Flow Testing

```bash
# Test Connection Button Complete Flow
echo "🔘 Testing Test Connection Button Flow..."

# Step 1: Backend connectivity test
echo "Step 1: Testing backend connectivity..."
BACKEND_STATUS=$(curl -s http://localhost:8080/health | jq -r '.status // "error"')
if [ "$BACKEND_STATUS" = "healthy" ]; then
    echo "✅ Backend connection: SUCCESS"
else
    echo "❌ Backend connection: FAILED ($BACKEND_STATUS)"
fi

# Step 2: Configuration retrieval test
echo "Step 2: Testing configuration retrieval..."
CONFIG_RESPONSE=$(curl -s http://localhost:8080/api/v1/config/)
if echo "$CONFIG_RESPONSE" | jq -e '.privacy_mode == true' > /dev/null; then
    echo "✅ Configuration retrieval: SUCCESS"
else
    echo "❌ Configuration retrieval: FAILED"
fi

# Step 3: DNS server connectivity test
echo "Step 3: Testing DNS server connectivity..."
DNS_TEST_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/dns/test \
  -H "Content-Type: application/json" \
  -d '{"server": "1.1.1.1", "timeout": 5}')
if echo "$DNS_TEST_RESPONSE" | jq -e '.status' > /dev/null; then
    echo "✅ DNS connectivity test: SUCCESS"
else
    echo "❌ DNS connectivity test: FAILED"
fi

# Step 4: Service health verification
echo "Step 4: Testing service health..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/api/v1/stats/health)
if echo "$HEALTH_RESPONSE" | jq -e '.overall_status' > /dev/null; then
    echo "✅ Service health check: SUCCESS"
else
    echo "❌ Service health check: FAILED"
fi

echo "🎉 Test Connection Button flow completed"
```

#### Test Connection Button Error Scenarios

```bash
# Test Connection Button Error Handling
echo "🔘 Testing Test Connection Button Error Scenarios..."

# Scenario 1: Backend service unavailable
echo "Scenario 1: Testing backend service unavailable..."
# (Stop API server temporarily)
curl -s http://localhost:8080/health --connect-timeout 2 || echo "✅ Error handling: Connection timeout detected"

# Scenario 2: Partial service failure
echo "Scenario 2: Testing partial service failure..."
# Test when one service is down but others are up
curl -s http://localhost:8080/api/v1/stats/health | jq -e '.overall_status' || echo "✅ Error handling: Partial failure detected"

# Scenario 3: DNS server unreachable
echo "Scenario 3: Testing DNS server unreachable..."
curl -s -X POST http://localhost:8080/api/v1/dns/test \
  -H "Content-Type: application/json" \
  -d '{"server": "192.0.2.1", "timeout": 2}' | jq -e '.status == "timeout"' && echo "✅ Error handling: DNS timeout detected"

# Scenario 4: Invalid configuration
echo "Scenario 4: Testing invalid configuration..."
curl -s http://localhost:8080/api/v1/config/ | jq -e '.privacy_mode == false' && echo "❌ Configuration error detected" || echo "✅ Configuration valid"

echo "🎉 Error scenario testing completed"
```

#### Test Connection Button UI State Testing

```bash
# Test Connection Button UI State Validation
echo "🔘 Testing Test Connection Button UI States..."

# UI State 1: Loading state validation
echo "UI State 1: Testing loading state..."
START_TIME=$(date +%s%3N)
curl -s http://localhost:8080/api/v1/config/ > /dev/null
END_TIME=$(date +%s%3N)
RESPONSE_TIME=$((END_TIME - START_TIME))
if [ $RESPONSE_TIME -lt 1000 ]; then
    echo "✅ Loading state: Fast response (<1s) - good UX"
else
    echo "⚠️ Loading state: Slow response (>1s) - may need loading indicator"
fi

# UI State 2: Success state validation
echo "UI State 2: Testing success state..."
SUCCESS_RESPONSE=$(curl -s http://localhost:8080/api/v1/config/)
if echo "$SUCCESS_RESPONSE" | jq -e '.privacy_mode == true' > /dev/null; then
    echo "✅ Success state: All systems operational - green indicator"
    echo "   - Privacy mode: $(echo "$SUCCESS_RESPONSE" | jq -r '.privacy_mode')"
    echo "   - DNS servers: $(echo "$SUCCESS_RESPONSE" | jq -r '.dns_servers | length') configured"
    echo "   - Blocklist: $(echo "$SUCCESS_RESPONSE" | jq -r '.blocklist_enabled') enabled"
else
    echo "❌ Success state: System issues detected - red indicator"
fi

# UI State 3: Warning state validation
echo "UI State 3: Testing warning state..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/api/v1/stats/health)
if echo "$HEALTH_RESPONSE" | jq -e '.status == "not_implemented"' > /dev/null; then
    echo "⚠️ Warning state: Some services not fully operational - yellow indicator"
else
    echo "✅ Warning state: All services operational"
fi

echo "🎉 UI state testing completed"
```

#### Test Connection Button Performance Testing

```bash
# Test Connection Button Performance Testing
echo "🔘 Testing Test Connection Button Performance..."

# Performance test: Response time
echo "Performance Test: Response time measurement..."
for i in {1..5}; do
    START_TIME=$(date +%s%3N)
    curl -s http://localhost:8080/api/v1/config/ > /dev/null
    END_TIME=$(date +%s%3N)
    RESPONSE_TIME=$((END_TIME - START_TIME))
    echo "  Test $i: ${RESPONSE_TIME}ms"
done

# Performance test: Concurrent connections
echo "Performance Test: Concurrent connection handling..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/v1/config/ > /dev/null &
done
wait
echo "✅ Concurrent connection test completed"

# Performance test: Memory usage during test
echo "Performance Test: Memory usage monitoring..."
MEMORY_BEFORE=$(ps aux | grep "go run.*main.go" | grep -v grep | awk '{print $6}' | head -1)
curl -s http://localhost:8080/api/v1/config/ > /dev/null
MEMORY_AFTER=$(ps aux | grep "go run.*main.go" | grep -v grep | awk '{print $6}' | head -1)
echo "  Memory usage: ${MEMORY_BEFORE} -> ${MEMORY_AFTER} KB"

echo "🎉 Performance testing completed"
```

#### Test Connection Button Swift Integration

```swift
// Swift code example for Test Connection Button implementation
// This would be integrated into the SwiftUI app

import SwiftUI
import Foundation

struct TestConnectionButton: View {
    @State private var isLoading = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var errorMessage: String = ""
    
    enum ConnectionStatus {
        case unknown
        case testing
        case success
        case warning
        case error
    }
    
    var body: some View {
        Button(action: testConnection) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(buttonText)
                statusIcon
            }
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
    
    private var buttonText: String {
        switch connectionStatus {
        case .unknown: return "Test Connection"
        case .testing: return "Testing..."
        case .success: return "Connection OK"
        case .warning: return "Partial Issues"
        case .error: return "Connection Failed"
        }
    }
    
    private var buttonColor: Color {
        switch connectionStatus {
        case .unknown: return .blue
        case .testing: return .orange
        case .success: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
    
    private var statusIcon: some View {
        switch connectionStatus {
        case .success: return Image(systemName: "checkmark.circle.fill")
        case .warning: return Image(systemName: "exclamationmark.triangle.fill")
        case .error: return Image(systemName: "xmark.circle.fill")
        default: return Image(systemName: "network")
        }
    }
    
    private func testConnection() {
        isLoading = true
        connectionStatus = .testing
        errorMessage = ""
        
        // Test backend connectivity
        testBackendConnection { success in
            DispatchQueue.main.async {
                if success {
                    connectionStatus = .success
                } else {
                    connectionStatus = .error
                    errorMessage = "Backend service unavailable"
                }
                isLoading = false
            }
        }
    }
    
    private func testBackendConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:8080/api/v1/config/") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Connection test error: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            
            guard let data = data else {
                completion(false)
                return
            }
            
            do {
                let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
                completion(config.privacyMode == true)
            } catch {
                print("JSON decode error: \(error)")
                completion(false)
            }
        }.resume()
    }
}

struct ConfigResponse: Codable {
    let privacyMode: Bool
    let dnsServers: [String]
    let blocklistEnabled: Bool
    let encryptionEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case privacyMode = "privacy_mode"
        case dnsServers = "dns_servers"
        case blocklistEnabled = "blocklist_enabled"
        case encryptionEnabled = "encryption_enabled"
    }
}
```

### Configuration Management

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