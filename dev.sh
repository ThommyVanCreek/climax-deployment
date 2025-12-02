#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# ClimaX Development Environment - Start Script
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════════════════════"
echo "  ClimaX Development Environment"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# Check for .env.dev file
if [ ! -f ".env.dev" ]; then
    echo "📋 Creating .env.dev from template..."
    cp .env.dev.example .env.dev
    echo "⚠️  Please edit .env.dev with your Bridge IP address!"
    echo "   Then run this script again."
    exit 1
fi

# Load environment
export $(grep -v '^#' .env.dev | xargs)

echo "🔧 Configuration:"
echo "   Bridge IP:    ${BRIDGE_IP:-not set}"
echo "   API Port:     ${API_PORT:-5000}"
echo "   Client Port:  ${CLIENT_PORT:-3000}"
echo "   Adminer Port: ${ADMINER_PORT:-8080}"
echo ""

# Check if Bridge is reachable
if [ -n "$BRIDGE_IP" ]; then
    echo "🔍 Checking Bridge connection..."
    if curl -s --connect-timeout 3 "http://$BRIDGE_IP/api/health" > /dev/null 2>&1; then
        echo "   ✅ Bridge is reachable at $BRIDGE_IP"
    else
        echo "   ⚠️  Bridge not reachable at $BRIDGE_IP (may be offline or wrong IP)"
    fi
    echo ""
fi

# Start services
echo "🚀 Starting development services..."
docker-compose -f docker-compose.dev.yml --env-file .env.dev up --build "$@"
