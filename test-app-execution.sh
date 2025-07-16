#!/bin/bash
# Test script to simulate what the Swift app does

echo "Test script execution"
echo "Current directory: $(pwd)"
echo "Environment variables:"
env | grep SHROUDINGER || echo "No SHROUDINGER variables found"

echo "Testing script path resolution..."
PROJECT_ROOT="/Users/rexliu/shroudinger"
SCRIPT_PATH="$PROJECT_ROOT/scripts/start-services.sh"
echo "Script path: $SCRIPT_PATH"

if [ -f "$SCRIPT_PATH" ]; then
    echo "✅ Script exists"
    ls -la "$SCRIPT_PATH"
else
    echo "❌ Script does not exist"
fi

echo "Testing script execution..."
cd "$PROJECT_ROOT"
export SHROUDINGER_TESTING=true
bash "$SCRIPT_PATH"