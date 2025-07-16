#!/bin/bash

# Script to stop all services from the Swift app
# This script is called by the SettingsManager to stop backend services

set -e

echo "🛑 Stopping Shroudinger services..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to stop a service by PID file
stop_service() {
    local service_name=$1
    local pid_file="${PROJECT_ROOT}/logs/${service_name}.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "🔄 Stopping $service_name (PID: $pid)..."
            kill "$pid"
            
            # Wait for process to stop
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                count=$((count + 1))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  Force killing $service_name..."
                kill -9 "$pid"
            fi
            
            echo "✅ $service_name stopped"
        else
            echo "⚠️  $service_name was not running"
        fi
        
        rm -f "$pid_file"
    else
        echo "⚠️  No PID file for $service_name"
    fi
}

# Function to stop services by name pattern
stop_services_by_pattern() {
    local pattern=$1
    local service_name=$2
    
    echo "🔄 Stopping $service_name processes..."
    
    # Find and kill processes matching the pattern
    local pids=$(pgrep -f "$pattern" || true)
    
    if [[ -n "$pids" ]]; then
        for pid in $pids; do
            echo "🔄 Stopping $service_name (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
        done
        
        # Wait for processes to stop
        sleep 2
        
        # Force kill if still running
        local remaining_pids=$(pgrep -f "$pattern" || true)
        if [[ -n "$remaining_pids" ]]; then
            for pid in $remaining_pids; do
                echo "⚠️  Force killing $service_name (PID: $pid)..."
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
        
        echo "✅ $service_name stopped"
    else
        echo "⚠️  No $service_name processes found"
    fi
}

# Stop services using PID files first
stop_service "api-server"
stop_service "dns-service"
stop_service "blocklist-service"
stop_service "middleware"

# Fallback: stop services by process pattern
stop_services_by_pattern "go run.*api-server" "api-server"
stop_services_by_pattern "go run.*dns-service" "dns-service"
stop_services_by_pattern "go run.*blocklist-service" "blocklist-service"
stop_services_by_pattern "go run.*middleware" "middleware"

# Clean up logs directory
rm -rf "${PROJECT_ROOT}/logs"

echo "🎉 All services stopped successfully!"