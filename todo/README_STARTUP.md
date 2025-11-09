# FKS Services Startup Guide

Quick guide for starting and managing all FKS microservices.

## Quick Start

### Start All Services

```bash
./start.sh
```

This will:
1. Create the `fks-network` Docker network (if it doesn't exist)
2. Build and start all services in the correct order
3. Show status of all services

### Stop All Services

```bash
./stop.sh
```

## Usage Examples

### Start Specific Services

```bash
# Start only data and api services
./start.sh data api

# Start execution and meta services
./start.sh execution meta
```

### Start Without Rebuilding

```bash
# Start all services without rebuilding images
./start.sh --no-build

# Start specific services without rebuilding
./start.sh --no-build data api
```

### Force Recreate Containers

```bash
# Force recreate all containers
./start.sh --force

# Force recreate specific services
./start.sh --force data api
```

### Show Service Status

```bash
# Check status of all services
./start.sh --status
```

### Start and View Logs

```bash
# Start all services and show logs
./start.sh --logs

# Start specific services and show logs
./start.sh --logs data api
```

### Stop with Options

```bash
# Stop all services and remove volumes
./stop.sh --volumes

# Stop all services, remove volumes, and remove network
./stop.sh --all
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| fks_web | 8000 | Web interface |
| fks_api | 8001 | API service |
| fks_ai | 8002 | AI service |
| fks_data | 8003 | Data service |
| fks_execution | 8004 | Execution service |
| fks_meta | 8005 | MetaTrader 5 plugin |
| fks_monitor | 8006 | Monitor service |
| fks_analyze | 8007 | Analyze service |
| fks_app | 8008 | App service |
| fks_auth | 8009 | Auth service |
| fks_training | 8009 | Training service |

## Individual Service Management

You can also manage services individually:

```bash
# Start a single service
cd repo/data
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop a service
docker-compose down

# Restart a service
docker-compose restart
```

## Health Checks

All services have health check endpoints:

```bash
# Check service health
curl http://localhost:8000/health  # fks_web
curl http://localhost:8001/health  # fks_api
curl http://localhost:8003/health  # fks_data
# ... etc
```

## Troubleshooting

### Service Won't Start

1. Check if port is already in use:
   ```bash
   sudo lsof -i :8000  # Check port 8000
   ```

2. Check Docker logs:
   ```bash
   docker logs <container_name>
   ```

3. Check service-specific logs:
   ```bash
   cd repo/<service>
   docker-compose logs
   ```

### Network Issues

If services can't communicate:

1. Check if network exists:
   ```bash
   docker network ls | grep fks-network
   ```

2. Recreate network:
   ```bash
   docker network rm fks-network
   ./start.sh --network-only
   ```

### Rebuild Everything

```bash
# Stop all services
./stop.sh --all

# Remove all images (optional)
docker images | grep fks | awk '{print $3}' | xargs docker rmi

# Start fresh
./start.sh
```

## Environment Variables

Some services require environment variables. Create `.env` files in service directories:

```bash
# Example: repo/meta/.env
MT5_ACCOUNT_NUMBER=12345678
MT5_PASSWORD=your_password
MT5_SERVER=your_broker_server
```

## Service Dependencies

Services are started in this order to handle dependencies:

1. `data` - Data service (no dependencies)
2. `api` - API service
3. `web` - Web service
4. `ai` - AI service
5. `execution` - Execution service
6. `meta` - MetaTrader 5 plugin
7. `monitor` - Monitor service
8. `analyze` - Analyze service
9. `app` - App service
10. `auth` - Auth service
11. `training` - Training service
12. `main` - Main service

## Tips

- Use `docker-compose ps` in any service directory to see container status
- Use `docker stats` to monitor resource usage
- Use `./start.sh --status` to quickly check all services
- Services automatically restart on failure (restart: unless-stopped)

