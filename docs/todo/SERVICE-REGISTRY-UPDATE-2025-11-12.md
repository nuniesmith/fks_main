# Service Registry Update - 2025-11-12

**Date**: 2025-11-12  
**Status**: ✅ **UPDATE COMPLETE**  
**Version**: 1.2

---

## 🎯 Summary

Updated `service_registry.json` to match the current Kubernetes configuration and reflect the latest service architecture changes.

---

## 📋 Updates Applied

### 1. Service Names
- **Updated**: All service names to use hyphens (Kubernetes format)
  - `fks_web` → `fks-web`
  - `fks_api` → `fks-api`
  - `fks_app` → `fks-app`
  - `fks_data` → `fks-data`
  - `fks_execution` → `fks-execution`
  - `fks_meta` → `fks-meta`
  - `fks_ninja` → `fks-ninja` (new service)
  - `fks_ai` → `fks-ai`
  - `fks_analyze` → `fks-analyze`
  - `fks_auth` → `fks-auth`
  - `fks_main` → `fks-main`
  - `fks_training` → `fks-training`
  - `fks_portfolio` → `fks-portfolio`
  - `fks_monitor` → `fks-monitor`

### 2. Service Ports

#### fks_web
- **Port**: 3001 (Kubernetes) / 8000 (Docker)
- **Added**: `port_docker` field for Docker compatibility
- **Added**: Note about port differences
- **Updated**: Dependencies to include `fks_auth`

#### fks_api
- **Port**: 8001 (verified)
- **Updated**: Service name to `fks-api`

#### fks_app
- **Port**: 8002 (verified)
- **Added**: `fks_ai` dependency
- **Updated**: Service name to `fks-app`

#### fks_data
- **Port**: 8003 (verified)
- **Updated**: Service name to `fks-data`

#### fks_execution
- **Port**: 8004 (verified)
- **Added**: `plugins` field with `fks_meta` and `fks_ninja`
- **Updated**: Service name to `fks-execution`

#### fks_meta
- **Port**: 8005 (verified)
- **Updated**: Service name to `fks-meta`

#### fks_ninja (NEW)
- **Port**: 8006
- **Added**: New service entry
- **Added**: Note about Python/Rust API service
- **Added**: Note about NinjaTrader8 communication (TCP sockets, port 8080)
- **Added**: Note about NinjaTrader8 running separately on Windows desktop (100.80.141.117:8080)
- **Updated**: Service name to `fks-ninja`

#### fks_ai
- **Port**: 8007 (verified)
- **Added**: `gpu_enabled: true` field
- **Added**: Note about GPU support (1x nvidia.com/gpu)
- **Updated**: Service name to `fks-ai`

#### fks_analyze
- **Port**: 8008 (verified)
- **Updated**: Service name to `fks-analyze`

#### fks_auth
- **Port**: 8009 (verified)
- **Updated**: Service name to `fks-auth`

#### fks_main
- **Port**: 8010 (verified)
- **Added**: `language: "Rust"` field
- **Added**: `framework: "Axum"` field
- **Added**: Note about Rust-based orchestration and management service
- **Updated**: Service name to `fks-main`

#### fks_training
- **Port**: 8011 (verified)
- **Updated**: Service name to `fks-training`

#### fks_portfolio
- **Port**: 8012 (verified)
- **Updated**: Service name to `fks-portfolio`

#### fks_monitor
- **Port**: 8013 (updated from 8009)
- **Added**: Note about monitoring all FKS services and providing unified API for fks_main orchestration
- **Updated**: Service name to `fks-monitor`

### 3. Version Update
- **Version**: 1.1 → 1.2
- **Updated**: Timestamp to 2025-11-12T00:00:00.000000

---

## 📊 Current Service Configuration

### Service Ports (All Services)

| Service | Port | Language | Framework | GPU | Status |
|---------|------|----------|-----------|-----|--------|
| fks_web | 3001 (K8s) / 8000 (Docker) | Python/JS | Django | ❌ | ✅ Active |
| fks_api | 8001 | Python | FastAPI | ❌ | ✅ Active |
| fks_app | 8002 | Python | FastAPI | ❌ | ✅ Active |
| fks_data | 8003 | Python | FastAPI | ❌ | ✅ Active |
| fks_execution | 8004 | Rust/Python | Actix/Axum | ❌ | ✅ Active |
| fks_meta | 8005 | Rust/MQL5 | Actix/Axum | ❌ | ✅ Active |
| fks_ninja | 8006 | Python/Rust | FastAPI/Axum | ❌ | ✅ Active |
| fks_ai | 8007 | Python | FastAPI | ✅ | ✅ Active |
| fks_analyze | 8008 | Python | FastAPI | ❌ | ✅ Active |
| fks_auth | 8009 | Rust | Axum | ❌ | ✅ Active |
| fks_main | 8010 | Rust | Axum | ❌ | ✅ Active |
| fks_training | 8011 | Python | FastAPI | ❌ | ✅ Active |
| fks_portfolio | 8012 | Python | FastAPI | ❌ | ✅ Active |
| fks_monitor | 8013 | Python | FastAPI | ❌ | ✅ Active |

---

## 🔧 Key Changes

### Service Name Standardization
- **All services**: Updated to use hyphens (Kubernetes format)
- **Reason**: Kubernetes service names use hyphens, not underscores
- **Impact**: Service discovery and DNS resolution in Kubernetes

### Port Updates
- **fks_web**: Port 3001 (Kubernetes) / 8000 (Docker)
- **fks_monitor**: Port 8013 (updated from 8009)
- **fks_ninja**: Port 8006 (new service)

### New Service
- **fks_ninja**: Added new service entry with full configuration
  - Port: 8006
  - Language: Python/Rust
  - Framework: FastAPI/Axum
  - Communication: TCP sockets (port 8080) with NinjaTrader8
  - Note: NinjaTrader8 runs separately on Windows desktop (100.80.141.117:8080)

### Service Dependencies
- **fks_web**: Added `fks_auth` dependency
- **fks_app**: Added `fks_ai` dependency
- **fks_execution**: Added `plugins` field with `fks_meta` and `fks_ninja`

### Service Metadata
- **fks_main**: Added `language: "Rust"` and `framework: "Axum"` fields
- **fks_ai**: Added `gpu_enabled: true` field
- **fks_ninja**: Added comprehensive notes about architecture and communication
- **fks_monitor**: Added note about monitoring and orchestration

---

## 📝 Notes

### Port Discrepancies
1. **fks_web**: Port 3001 in Kubernetes, port 8000 in Docker
   - **Reason**: Kubernetes configuration uses port 3001 to avoid conflicts
   - **Solution**: Added `port_docker` field for Docker compatibility
   - **Impact**: Service registry now supports both Kubernetes and Docker deployments

2. **fks_monitor**: Port 8013 in Kubernetes (was 8009)
   - **Reason**: Port conflict resolution in Kubernetes
   - **Impact**: All service references to fks_monitor must use port 8013

### Service Name Format
- **Kubernetes**: Uses hyphens (e.g., `fks-web`, `fks-api`)
- **Docker**: May use underscores (e.g., `fks_web`, `fks_api`)
- **Solution**: Service registry uses Kubernetes format (hyphens) for consistency

### New Service: fks_ninja
- **Purpose**: Python/Rust API service communicating with NinjaTrader8
- **Architecture**: API service (not plugin) that communicates via TCP sockets
- **Communication**: TCP sockets (port 8080) with NinjaTrader8 running on Windows desktop
- **Note**: NinjaTrader8 runs separately on Windows desktop (100.80.141.117:8080)

---

## ✅ Verification Checklist

- [x] fks_web: Port 3001 (K8s) / 8000 (Docker), service name updated
- [x] fks_api: Port 8001, service name updated
- [x] fks_app: Port 8002, dependencies updated, service name updated
- [x] fks_data: Port 8003, service name updated
- [x] fks_execution: Port 8004, plugins added, service name updated
- [x] fks_meta: Port 8005, service name updated
- [x] fks_ninja: Port 8006, new service added, service name updated
- [x] fks_ai: Port 8007, GPU enabled, service name updated
- [x] fks_analyze: Port 8008, service name updated
- [x] fks_auth: Port 8009, service name updated
- [x] fks_main: Port 8010, Rust/Axum added, service name updated
- [x] fks_training: Port 8011, service name updated
- [x] fks_portfolio: Port 8012, service name updated
- [x] fks_monitor: Port 8013, note added, service name updated
- [x] Version: Updated to 1.2
- [x] Timestamp: Updated to 2025-11-12

---

## 🎯 Next Steps

1. ✅ **Update service_registry.json** - **COMPLETE**
2. ⏳ **Update service code** - Update service code to use new service names (hyphens)
3. ⏳ **Update Docker configurations** - Ensure Docker configurations use correct service names
4. ⏳ **Update Kubernetes deployments** - Verify Kubernetes deployments use correct service names
5. ⏳ **Update documentation** - Update service documentation to reflect new service names
6. ⏳ **Test service connectivity** - Verify all services can communicate using new service names

---

## 📚 Related Documentation

- `AI_CONTEXT_GUIDE.md` (version 2.1) - Updated service descriptions
- `FKS-SERVICES-CONFIGURATION.md` - Service configuration details
- `FKS-NINJA-SERVICE-CONFIGURATION.md` - Ninja service configuration
- `AI-CONTEXT-GUIDE-REVIEW.md` - Context guide review
- `AI-CONTEXT-GUIDE-UPDATES-COMPLETE.md` - Context guide updates

---

**Status**: ✅ **UPDATE COMPLETE**

**Last Updated**: 2025-11-12

**Next Action**: Update service code and Docker configurations to use new service names!

---

**Happy Documenting!** 🚀

