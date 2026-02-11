#!/bin/bash

# EZ-Assistant Integration Test Script
# This script tests the EZ-Assistant integration functions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATION_SCRIPT="$SCRIPT_DIR/ez-assistant-integration.sh"

echo "🧪 Testing EZ-Assistant Integration"
echo "=================================="

# Check if integration script exists
if [[ ! -f "$INTEGRATION_SCRIPT" ]]; then
    echo "❌ Integration script not found: $INTEGRATION_SCRIPT"
    exit 1
fi

# Source the integration script
echo "📦 Sourcing integration script..."
source "$INTEGRATION_SCRIPT"

# Test function existence
echo "🔍 Checking function definitions..."
declare -f check_ez_assistant_requirements >/dev/null || { echo "❌ check_ez_assistant_requirements function not found"; exit 1; }
declare -f build_ez_assistant_image >/dev/null || { echo "❌ build_ez_assistant_image function not found"; exit 1; }
declare -f setup_ez_assistant_config >/dev/null || { echo "❌ setup_ez_assistant_config function not found"; exit 1; }
declare -f install_ez_assistant >/dev/null || { echo "❌ install_ez_assistant function not found"; exit 1; }

echo "✅ All functions found"

# Test requirements check (dry run)
echo "🔧 Testing requirements check..."
if check_ez_assistant_requirements; then
    echo "✅ Requirements check passed"
else
    echo "❌ Requirements check failed"
    exit 1
fi

# Check if Docker Compose file exists
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
if [[ -f "$COMPOSE_FILE" ]]; then
    echo "✅ Docker Compose file found: $COMPOSE_FILE"
else
    echo "❌ Docker Compose file missing: $COMPOSE_FILE"
    exit 1
fi

# Check if config directory exists
CONFIG_DIR="$SCRIPT_DIR/moltbot/config"
if [[ -d "$CONFIG_DIR" ]]; then
    echo "✅ Config directory found: $CONFIG_DIR"
else
    echo "❌ Config directory missing: $CONFIG_DIR"
    exit 1
fi

# Check if moltbot.json exists
CONFIG_FILE="$CONFIG_DIR/moltbot.json"
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ Config file found: $CONFIG_FILE"
else
    echo "❌ Config file missing: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "🎉 Integration test completed successfully!"
echo ""
echo "Next steps:"
echo "1. Add the source line to your main ez-homelab.sh script"
echo "2. Add menu option 4 for EZ-Assistant"
echo "3. Add the menu handler for option 4"
echo "4. Test the full installation on a fresh system"