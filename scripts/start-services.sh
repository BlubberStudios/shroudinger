#!/bin/bash

# Script to start all services from the Swift app
# This script is called by the SettingsManager to start backend services

set -e

echo "🚀 Starting Shroudinger services..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Check if testing mode is enabled
if [[ "$SHROUDINGER_TESTING" == "true" ]]; then
    echo "🧪 Testing mode enabled - logs will be available"
else
    echo "🔒 Production mode - no testing logs"
fi

# Function to check if a service is running
check_service() {
    local port=$1
    local service_name=$2
    
    if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ $service_name already running on port $port"
        return 0
    else
        echo "⏳ Starting $service_name on port $port..."
        return 1
    fi
}

# Function to start a service in the background
start_service() {
    local service_dir=$1
    local service_cmd=$2
    local service_name=$3
    local port=$4
    
    if ! check_service "$port" "$service_name"; then
        cd "$PROJECT_ROOT/$service_dir"
        
        # Export environment variables for the service
        export SHROUDINGER_TESTING="${SHROUDINGER_TESTING:-false}"
        
        # Start the service in the background
        nohup $service_cmd > "${PROJECT_ROOT}/logs/${service_name}.log" 2>&1 &
        
        # Store PID for later cleanup
        echo $! > "${PROJECT_ROOT}/logs/${service_name}.pid"
        
        echo "🔄 $service_name starting (PID: $!)"
        
        # Wait a moment for the service to start
        sleep 2
        
        # Verify the service started
        if check_service "$port" "$service_name"; then
            echo "✅ $service_name started successfully"
        else
            echo "❌ $service_name failed to start"
            return 1
        fi
    fi
}

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/logs"

# Start all services
start_service "backend" "go run ./cmd/api-server" "api-server" "8080"
start_service "backend" "go run ./cmd/dns-service" "dns-service" "8082"
start_service "backend" "go run ./cmd/blocklist-service" "blocklist-service" "8081"
start_service "middleware" "go run ./cmd/middleware" "middleware" "8083"

echo "🎉 All services started successfully!"
echo ""
echo "Service status:"
echo "- API Server: http://localhost:8080/health"
echo "- DNS Service: http://localhost:8082/health"
echo "- Blocklist Service: http://localhost:8081/health"
echo "- Middleware: http://localhost:8083/health"

if [[ "$SHROUDINGER_TESTING" == "true" ]]; then
    echo ""
    echo "🧪 Testing endpoints:"
    echo "- Testing logs: http://localhost:8083/testing/logs"
    echo "- Clear logs: curl -X DELETE http://localhost:8083/testing/logs"
fi