# FKS Project - Quick Start Guide

**Last Updated**: 2025-01-15  
**Status**: Phase 1 Stabilization Complete

---

## 🎯 Current Status

### ✅ Completed
- **Port Conflicts Resolved**: All 14 services now have unique ports (8000-8013)
- **Service Registry Updated**: All services registered with correct ports
- **Docker Compose Files**: Updated to match service registry

### ⏳ In Progress
- Health endpoint verification
- Codebase cleanup
- Dependency audit

---

## 🚀 Quick Start

### 1. Verify Port Configuration

```bash
# Check service registry
cat repo/main/config/service_registry.json

# Verify ports are unique
./repo/main/scripts/verify_ports.sh
```

### 2. Start Services

```bash
# Start all services (if you have a master docker-compose)
docker-compose up -d

# Or start individual services
cd repo/data && docker-compose up -d
cd repo/api && docker-compose up -d
# ... etc
```

### 3. Verify Health

```bash
# Run health check script
./repo/main/scripts/verify_ports.sh

# Or manually check
curl http://localhost:8000/health  # fks_web
curl http://localhost:8001/health  # fks_api
curl http://localhost:8003/health  # fks_data
# ... etc
```

---

## 📊 Service Port Reference

| Service | Port | Health URL | Status |
|---------|------|------------|--------|
| fks_web | 8000 | http://localhost:8000/health | ✅ |
| fks_api | 8001 | http://localhost:8001/health | ✅ |
| fks_app | 8002 | http://localhost:8002/health | ✅ |
| fks_data | 8003 | http://localhost:8003/health | ✅ |
| fks_execution | 8004 | http://localhost:8004/health | ✅ |
| fks_meta | 8005 | http://localhost:8005/health | ✅ |
| fks_ai | 8007 | http://localhost:8007/health | ✅ |
| fks_analyze | 8008 | http://localhost:8008/health | ✅ |
| fks_auth | 8009 | http://localhost:8009/health | ✅ |
| fks_main | 8010 | http://localhost:8010/health | ✅ |
| fks_training | 8011 | http://localhost:8011/health | ✅ |
| fks_portfolio | 8012 | http://localhost:8012/health | ✅ |
| fks_monitor | 8013 | http://localhost:8013/health | ✅ |

---

## 🔧 Recent Changes

### Port Fixes (2025-01-15)
- **fks_execution**: Changed from 8006 → 8004 (to match docker-compose)
- **fks_training**: Changed from 8009 → 8011 (resolved conflict)
- **fks_monitor**: Changed from 8009 → 8013 (resolved conflict)
- **Added to registry**: fks_auth, fks_training, fks_meta

### Files Updated
- `repo/main/config/service_registry.json`
- `repo/training/docker-compose.yml`
- `repo/monitor/docker-compose.yml`
- `repo/monitor/config/services.yaml`
- `repo/monitor/entrypoint.sh`

---

## 📋 Next Steps

1. **Test Service Startup**: Verify all services start without conflicts
2. **Codebase Cleanup**: Remove empty/redundant files (Task 1.2)
3. **Dependency Audit**: Lock versions and check conflicts (Task 1.3)
4. **Phase 2**: Begin demo build (data flow, signal generation, dashboard)

---

## 📚 Related Documents

- [Phase 1 Action Plan](./PHASE-1-ACTION-PLAN.md)
- [Port Fixes Summary](./PHASE-1-PORT-FIXES-SUMMARY.md)
- [FKS Project Review](./FKS_PROJECT_REVIEW.md)
- [Master Plan](./00-PORTFOLIO-PLATFORM-MASTER-PLAN.md)

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Check what's using a port
lsof -i :8000
netstat -an | grep 8000

# Kill process if needed
kill -9 <PID>
```

### Service Won't Start
```bash
# Check logs
docker-compose logs <service_name>

# Check service registry
cat repo/main/config/service_registry.json | jq '.services.<service_name>'
```

### Health Check Fails
```bash
# Verify service is running
docker ps | grep <service_name>

# Check container logs
docker logs <container_name>
```

---

**For detailed implementation guides, see**: [Implementation Guides Index](./17-IMPLEMENTATION-GUIDES-INDEX.md)

