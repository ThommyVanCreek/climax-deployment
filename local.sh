#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# ClimaX Local Development - Start All Services
# ═══════════════════════════════════════════════════════════════════════════════
# Runs all services locally without Docker (except PostgreSQL)
# 
# Prerequisites:
#   - Node.js 18+
#   - Python 3.10+
#   - Docker (only for PostgreSQL)
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ClimaX Local Development${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────────

# Load .env.local if exists
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env.local" | xargs)
    echo -e "${GREEN}✓${NC} Loaded .env.local"
fi

# Defaults
export DB_HOST=${DB_HOST:-localhost}
export DB_PORT=${DB_PORT:-5432}
export DB_NAME=${DB_NAME:-climax}
export DB_USER=${DB_USER:-climax}
export DB_PASSWORD=${DB_PASSWORD:-devpassword}
export API_PORT=${API_PORT:-5000}
export CLIENT_PORT=${CLIENT_PORT:-3000}
export API_KEY_WRITE=${API_KEY_WRITE:-dev_write_key}
export API_KEY_READ=${API_KEY_READ:-dev_read_key}
export BRIDGE_IP=${BRIDGE_IP:-192.168.1.100}
export DEBUG=true

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Bridge IP:    $BRIDGE_IP"
echo "  API Port:     $API_PORT"
echo "  Client Port:  $CLIENT_PORT"
echo "  Database:     $DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# Start PostgreSQL (Docker)
# ─────────────────────────────────────────────────────────────────────────────────

echo -e "${BLUE}[1/4]${NC} Starting PostgreSQL..."

if docker ps --format '{{.Names}}' | grep -q '^climax-db-local$'; then
    echo -e "  ${GREEN}✓${NC} PostgreSQL already running"
else
    # Check if container exists but stopped
    if docker ps -a --format '{{.Names}}' | grep -q '^climax-db-local$'; then
        docker start climax-db-local > /dev/null
        echo -e "  ${GREEN}✓${NC} PostgreSQL started"
    else
        # Create new container
        docker run -d --name climax-db-local \
            -p 5432:5432 \
            -e POSTGRES_DB=$DB_NAME \
            -e POSTGRES_USER=$DB_USER \
            -e POSTGRES_PASSWORD=$DB_PASSWORD \
            -v climax-postgres-local:/var/lib/postgresql/data \
            postgres:16-alpine > /dev/null
        echo -e "  ${GREEN}✓${NC} PostgreSQL created and started"
        
        # Wait for PostgreSQL to be ready
        echo -e "  Waiting for PostgreSQL to be ready..."
        sleep 3
        
        # Initialize schema
        if [ -f "$ROOT_DIR/climax-database-server/database_schema.sql" ]; then
            docker exec -i climax-db-local psql -U $DB_USER -d $DB_NAME < "$ROOT_DIR/climax-database-server/database_schema.sql" > /dev/null 2>&1 || true
            echo -e "  ${GREEN}✓${NC} Database schema initialized"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────────
# Start API Server
# ─────────────────────────────────────────────────────────────────────────────────

echo -e "${BLUE}[2/4]${NC} Starting API Server..."

cd "$ROOT_DIR/climax-database-server"

# Create venv if needed
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "  ${GREEN}✓${NC} Virtual environment created"
fi

# Install dependencies
source venv/bin/activate
pip install -q -r requirements.txt

# Export env vars for Flask
export PORT=$API_PORT
export HOST=0.0.0.0

# Start Flask in background
python database_server.py &
API_PID=$!
echo -e "  ${GREEN}✓${NC} API Server starting on http://localhost:$API_PORT (PID: $API_PID)"

# ─────────────────────────────────────────────────────────────────────────────────
# Start Vue Client
# ─────────────────────────────────────────────────────────────────────────────────

echo -e "${BLUE}[3/4]${NC} Starting Vue Client..."

cd "$ROOT_DIR/climax-client"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    npm install
    echo -e "  ${GREEN}✓${NC} Dependencies installed"
fi

# Export env vars for Vite
export VITE_API_URL="http://localhost:$API_PORT"
export VITE_BRIDGE_URL="http://$BRIDGE_IP"
export VITE_API_KEY="$API_KEY_READ"

# Start Vite in background
npm run dev -- --port $CLIENT_PORT &
CLIENT_PID=$!
echo -e "  ${GREEN}✓${NC} Vue Client starting on http://localhost:$CLIENT_PORT (PID: $CLIENT_PID)"

# ─────────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}[4/4]${NC} Checking Bridge connection..."
sleep 2

if curl -s --connect-timeout 3 "http://$BRIDGE_IP/api/health" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Bridge reachable at http://$BRIDGE_IP"
else
    echo -e "  ${YELLOW}⚠${NC} Bridge not reachable at http://$BRIDGE_IP"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  All services started!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}Client:${NC}   http://localhost:$CLIENT_PORT"
echo -e "  ${BLUE}API:${NC}      http://localhost:$API_PORT"
echo -e "  ${BLUE}Bridge:${NC}   http://$BRIDGE_IP"
echo -e "  ${BLUE}Adminer:${NC}  docker run -d -p 8080:8080 adminer"
echo ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop all services"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping services...${NC}"
    kill $API_PID 2>/dev/null || true
    kill $CLIENT_PID 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Services stopped (PostgreSQL still running)"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for processes
wait
