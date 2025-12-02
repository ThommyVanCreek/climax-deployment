#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# ClimaX Local Development - Stop All Services
# ═══════════════════════════════════════════════════════════════════════════════

echo "Stopping ClimaX services..."

# Kill Flask server
pkill -f "python.*database_server.py" 2>/dev/null && echo "✓ API server stopped" || echo "  API server not running"

# Kill Vite
pkill -f "vite.*--port" 2>/dev/null && echo "✓ Vue client stopped" || echo "  Vue client not running"

# Optionally stop PostgreSQL
if [ "$1" == "--all" ]; then
    docker stop climax-db-local 2>/dev/null && echo "✓ PostgreSQL stopped" || echo "  PostgreSQL not running"
else
    echo "  PostgreSQL still running (use --all to stop)"
fi

echo "Done!"
