# Testing Logs Documentation

## Overview

The testing logs feature provides visibility into backend middleware activities for development and testing purposes only. This feature is completely disabled in production builds and only logs non-sensitive operational data.

## Privacy and Security

⚠️ **Important**: This feature is designed with privacy-first principles:

- **No sensitive data**: Domain names, IP addresses, or user information are NEVER logged
- **Testing only**: Completely disabled in production builds
- **In-memory only**: Logs are stored in memory and cleared on restart
- **Limited retention**: Maximum 100 log entries in circular buffer
- **Non-persistent**: No logs are ever written to disk

## What is Logged

The testing logs capture only operational metadata:

### Logged Information
- ✅ Timestamp of events
- ✅ Log level (INFO, ERROR, WARN)
- ✅ Service name (middleware, dns, extension)
- ✅ Event type (query_processed, extension_registered, etc.)
- ✅ HTTP status codes
- ✅ Response times
- ✅ Error messages (without sensitive data)

### NOT Logged
- ❌ Domain names
- ❌ IP addresses
- ❌ User identifiers
- ❌ Query content
- ❌ Personal information
- ❌ Browsing history

## Enabling Testing Mode

### Environment Variable
```bash
export SHROUDINGER_TESTING=true
```

### Starting Services with Testing
```bash
# Method 1: Using make with environment variable
export SHROUDINGER_TESTING=true
make dev

# Method 2: Using Swift app
# 1. Enable "Testing Logs" in Overview -> Development Tools
# 2. Toggle "DNS Protection" ON

# Method 3: Direct script execution
SHROUDINGER_TESTING=true ./scripts/start-services.sh
```

### Verifying Testing Mode
Check the middleware startup logs for:
```
🧪 Testing mode enabled - logging endpoints available
```

## API Endpoints

When testing mode is enabled, the following endpoints are available:

### Get Logs
```
GET /testing/logs
```

Returns all current log entries with metadata.

### Clear Logs
```
DELETE /testing/logs
```

Clears all log entries from memory.

### Stream Logs (Basic)
```
GET /testing/logs/stream
```

Server-sent events stream for real-time log updates.

## Using the Swift UI

### Enabling Testing Logs

1. Open the Shroudinger app
2. Go to the "Overview" section
3. Find "Development Tools" card
4. Enable "Testing Logs" toggle
5. Optionally enable "Show in Overview" to see logs in main view
6. Toggle "DNS Protection" ON to start services with testing mode

### Accessing the Logs

**Main Interface (if "Show in Overview" is enabled):**
- Recent logs appear in the Overview section
- Shows last 5 log entries
- Click "View All" to see full logs

**Dedicated Logs Window:**
- Navigate to "Testing Logs" in the sidebar (appears when enabled)
- Full-featured logging interface with:
  - Testing mode warning
  - Privacy notices
  - Real-time log entries
  - Auto-refresh controls
  - Manual refresh and clear buttons

### Features

- **Auto-refresh**: Logs update every 2 seconds
- **Manual refresh**: Click refresh button to update immediately
- **Clear logs**: Remove all log entries
- **Color coding**: Different levels have different colors
- **Timestamps**: All entries show precise timing
- **Error highlighting**: Error entries are highlighted in red

## Example Log Entry

```json
{
  "timestamp": "2025-07-16T10:30:45Z",
  "level": "INFO",
  "service": "dns",
  "event": "query_processed",
  "status_code": 200,
  "response_time": "2.3ms"
}
```

## Testing Script

Run the included test script to verify logging functionality:

```bash
./scripts/test-logging.sh
```

This script:
1. Checks if testing mode is enabled
2. Verifies middleware is running
3. Tests various logging scenarios
4. Demonstrates API endpoints
5. Validates log clearing

## Development Workflow

### 1. Enable Testing Mode
```bash
export SHROUDINGER_TESTING=true
```

### 2. Start Services
```bash
# Start middleware with testing
cd middleware && go run ./cmd/middleware

# Start other services (in separate terminals)
cd backend && go run ./cmd/api-server
cd backend && go run ./cmd/dns-service
cd backend && go run ./cmd/blocklist-service
```

### 3. Build and Run Swift App
```bash
cd frontend
xcodebuild -project Shroudinger.xcodeproj -scheme Shroudinger
```

### 4. Use Testing Logs
- Open app and navigate to "Testing Logs"
- Perform actions to generate log entries
- Monitor middleware activity in real-time
- Clear logs when needed

## Production Builds

In production builds:
- `SHROUDINGER_TESTING` is ignored
- All logging endpoints return 403 Forbidden
- No log entries are created or stored
- Testing logs UI section is hidden
- Zero performance impact

## Troubleshooting

### Logs Not Appearing
1. Verify `SHROUDINGER_TESTING=true` is set
2. Check middleware startup logs for testing mode confirmation
3. Ensure middleware is running on port 8083
4. Test endpoints manually with curl

### Connection Errors
1. Verify middleware is running: `curl http://localhost:8083/health`
2. Check firewall/network settings
3. Ensure correct port (8083) is used

### Swift UI Issues
1. Verify app is built with testing configuration
2. Check console for Swift networking errors
3. Ensure proper JSON parsing of log entries

## Security Considerations

- Never deploy with `SHROUDINGER_TESTING=true` in production
- Logs are automatically cleared on service restart
- No sensitive data is ever logged
- All logged data is safe for development sharing
- Testing endpoints are protected by environment flag

## Performance Impact

- Minimal CPU overhead for log entry creation
- Memory usage: ~10KB for 100 log entries
- No disk I/O for logging
- Circular buffer prevents memory leaks
- Auto-refresh network requests every 2 seconds when UI is active