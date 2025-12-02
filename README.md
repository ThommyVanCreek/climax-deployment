# ClimaX Deployment

Production and development deployment configuration for the ClimaX security system.

## Quick Start (Production)

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Edit with your values

# 2. Start all services
docker-compose up -d

# 3. Verify
curl http://localhost:5000/api/health
```

## Quick Start (Development)

```bash
# 1. Configure development environment
cp .env.dev.example .env.dev
nano .env.dev  # Set your Bridge IP address!

# 2. Start development services with hot-reload
./dev.sh

# Or manually:
docker-compose -f docker-compose.dev.yml --env-file .env.dev up --build
```

### Development Features

- **Hot-reload** for Vue client (changes apply instantly)
- **Direct Bridge connection** to your real ESP32 hardware
- **Database admin** (Adminer) always enabled
- **Debug logging** enabled by default

## Services

| Service | Port | Description |
|---------|------|-------------|
| **postgres** | 5432 | PostgreSQL database |
| **api** | 5000 | Flask REST API server |
| **client** | 3000 | Vue web dashboard |
| **adminer** | 8080 | Database admin UI (optional in prod, always in dev) |

## Configuration

Edit `.env` with your settings:

```env
# Docker Registry (your GitLab registry)
REGISTRY=registry.gitlab.com/thommyvancreek/climax
IMAGE_TAG=latest

# Database
POSTGRES_PASSWORD=your_secure_password

# API Keys
API_KEY_WRITE=your_write_key  # For ESP32 Bridge
API_KEY_READ=your_read_key    # For web client

# Ports
API_PORT=5000
CLIENT_PORT=3000
```

## Commands

```bash
# Start all services
docker-compose up -d

# Start with database admin (Adminer)
docker-compose --profile admin up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api

# Stop all services
docker-compose down

# Stop and delete data (WARNING!)
docker-compose down -v

# Pull latest images
docker-compose pull

# Restart with new images
docker-compose pull && docker-compose up -d
```

## Bridge Configuration

After deployment, update `climax-bridge/src/config/database.h`:

```cpp
#define DB_LOGGING_ENABLED    true
#define DB_API_HOST           "your-server-ip"
#define DB_API_PORT           5000
#define DB_API_KEY            "your_API_KEY_WRITE"
```

## Files

| File | Description |
|------|-------------|
| `.env` | Production environment variables |
| `.env.example` | Template for environment variables |
| `docker-compose.yml` | Main Docker Compose configuration |
| `init-db.sql` | Database initialization schema |

## GitLab CI/CD

Images are built automatically by GitLab CI pipeline:
- `climax-server:latest` - API server image
- `climax-client:latest` - Vue client image

Images are pushed to:
```
registry.gitlab.com/thommyvancreek/climax/climax-server:latest
registry.gitlab.com/thommyvancreek/climax/climax-client:latest
```

## Updating

```bash
# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d
```

## Backup

```bash
# Backup database
docker exec climax-db pg_dump -U climax climax > backup_$(date +%Y%m%d).sql

# Restore database
cat backup.sql | docker exec -i climax-db psql -U climax climax
```
