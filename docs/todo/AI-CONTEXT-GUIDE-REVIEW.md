# AI Context Guide Review - Updates Needed

**Date**: 2025-11-12  
**Status**: 📋 **REVIEW COMPLETE**  
**Purpose**: Document updates needed for AI_CONTEXT_GUIDE.md

---

## 🔍 Review Summary

Reviewed `AI_CONTEXT_GUIDE.md` against current configuration and identified several discrepancies that need to be updated.

---

## 📋 Updates Required

### 1. **fks_main** - Rust Management & Monitoring Service

**Current Description** (Lines 1142-1231):
- **Language**: Python, JavaScript
- **Framework**: Django, Kubernetes
- **Internal Architecture**: Shows Python files (orchestrator/, services/, docs/, api/)
- **Dependencies**: Lists Django as dependency

**Should Be**:
- **Language**: Rust
- **Framework**: Axum/Actix, Kubernetes
- **Internal Architecture**: Should show Rust files (src/main.rs, src/config.rs, src/k8s.rs, src/monitor.rs, src/routes.rs)
- **Dependencies**: Rust dependencies (axum, tokio, kube, etc.)
- **Purpose**: Rust-based orchestration and management service (not Django)

**Changes Needed**:
- Update language from "Python, JavaScript" to "Rust"
- Update framework from "Django, Kubernetes" to "Axum/Actix, Kubernetes"
- Update internal architecture to reflect Rust structure
- Update dependencies to remove Django, add Rust dependencies
- Update description to reflect Rust-based management and monitoring

---

### 2. **fks_ninja** - NinjaTrader8 Bridge Service

**Current Description** (Lines 1293-1345):
- **Port**: N/A (NinjaTrader plugin)
- **Language**: C#, Python
- **Framework**: NinjaTrader 8
- **Docker Hub**: N/A
- **Internal Architecture**: Shows C# files (strategy.cs, routes.cs)
- **Purpose**: "NinjaTrader 8 bridge plugin for fks_execution"
- **API Endpoints**: "NinjaTrader-specific endpoints (via NinjaTrader platform)"

**Should Be**:
- **Port**: 8006
- **Language**: Python/Rust
- **Framework**: FastAPI/Axum
- **Docker Hub**: nuniesmith/fks:ninja-latest
- **Internal Architecture**: Should show Python/Rust API service structure
- **Purpose**: Python/Rust API service that communicates with NinjaTrader8 (runs separately on Windows)
- **API Endpoints**: `/api/v1/signals/send`, `/api/v1/connection/test`, `/health`, `/ready`
- **Communication**: TCP sockets (port 8080) to NinjaTrader8 running on Windows desktop

**Changes Needed**:
- Update port from "N/A" to "8006"
- Update language from "C#, Python" to "Python/Rust"
- Update framework from "NinjaTrader 8" to "FastAPI/Axum"
- Update Docker Hub from "N/A" to "nuniesmith/fks:ninja-latest"
- Update internal architecture to reflect Python/Rust API service
- Update purpose to reflect API service (not plugin)
- Update API endpoints to list actual REST API endpoints
- Update description to clarify that NinjaTrader8 runs separately on Windows

---

### 3. **fks_web** - Web Interface Service

**Current Description** (Lines 201-268):
- **Port**: 8000

**Actual Configuration**:
- **Docker**: Port 8000 (in Dockerfile and docker-compose.yml)
- **Kubernetes**: Port 3001 (in values.yaml)
- **Service Registry**: Port 8000

**Note**: There's a discrepancy between Docker (8000) and Kubernetes (3001) configurations. The guide should reflect the Kubernetes configuration (3001) since that's the current deployment target.

**Changes Needed**:
- Update port to "3001" for Kubernetes deployment (or clarify both ports)
- Update description to note port differences between Docker and Kubernetes

---

### 4. **fks_ai** - AI/ML Service

**Current Description** (Lines 438-537):
- **Status**: ✅ Active
- **GPU**: CUDA 12.2+, 8GB VRAM minimum
- Mentions GPU support but doesn't explicitly state it's enabled

**Actual Configuration**:
- **Enabled**: true (with GPU support)
- **GPU Resources**: 1x nvidia.com/gpu
- **GPU Environment Variables**: CUDA_VISIBLE_DEVICES, NVIDIA_VISIBLE_DEVICES, NVIDIA_DRIVER_CAPABILITIES
- **GPU Tolerations**: Configured for GPU nodes

**Changes Needed**:
- Update description to explicitly state GPU support is enabled
- Add GPU configuration details (resources, environment variables, tolerations)
- Update status to reflect GPU-enabled deployment

---

### 5. **Service Ports Table** (Lines 1385-1407)

**Current Table**:
- fks_ninja: Port N/A, Docker Hub N/A

**Should Be**:
- fks_ninja: Port 8006, Docker Hub nuniesmith/fks:ninja-latest

**Changes Needed**:
- Update fks_ninja port to "8006"
- Update fks_ninja Docker Hub to "nuniesmith/fks:ninja-latest"
- Update fks_ninja language to "Python/Rust"
- Update fks_ninja framework to "FastAPI/Axum"

---

### 6. **Architecture Diagram** (Lines 78-99)

**Current Diagram**:
- Shows `fks_ninja (N/A)` in Execution Layer

**Should Be**:
- Show `fks_ninja (8006)` in Execution Layer
- Update description to "NinjaTrader8 Bridge (API Service)"

**Changes Needed**:
- Update architecture diagram to show fks_ninja on port 8006
- Update description to reflect API service (not plugin)

---

### 7. **Execution Flow Integration** (Lines 1368-1381)

**Current Flow**:
- Shows `fks_execution → fks_ninja (NT8 plugin)`

**Should Be**:
- Show `fks_execution → fks_ninja (API) → NinjaTrader8 (TCP Socket)`
- Clarify that NinjaTrader8 runs separately on Windows

**Changes Needed**:
- Update execution flow to show fks_ninja as API service
- Add note that NinjaTrader8 runs separately on Windows desktop
- Update integration description

---

### 8. **Service Integration Matrix** (Lines 1350-1367)

**Current Matrix**:
- fks_ninja: "NinjaTrader Integration" via "fks_execution (plugin), NinjaTrader 8"

**Should Be**:
- fks_ninja: "NinjaTrader Integration" via "fks_execution (API), NinjaTrader8 (TCP Socket)"
- Clarify that NinjaTrader8 runs separately

**Changes Needed**:
- Update integration matrix to reflect API service architecture
- Update integration points to show TCP socket communication

---

### 9. **Service Dependencies** (Lines 132-178)

**Current Dependencies**:
- fks_ninja: "depends on: fks_execution (8004), NinjaTrader 8"

**Should Be**:
- fks_ninja: "depends on: fks_execution (8004), NinjaTrader8 (runs separately on Windows)"
- Add note about TCP socket communication

**Changes Needed**:
- Update dependencies to clarify NinjaTrader8 runs separately
- Add note about TCP socket communication (port 8080)

---

### 10. **fks_main Description** (Lines 1142-1231)

**Current Description**:
- "Main orchestrator service that encompasses everything"
- "Handles start, stop, build, push, clean operations"
- Shows Python/Django architecture

**Should Be**:
- "Rust-based orchestration and management service"
- "Manages and monitors all services in the platform"
- "Kubernetes orchestration and service management"
- Shows Rust/Axum architecture

**Changes Needed**:
- Update description to reflect Rust-based service
- Update internal architecture to show Rust files
- Update dependencies to remove Django, add Rust dependencies
- Update API endpoints to reflect Rust API structure

---

## 🔧 Recommended Updates

### Priority 1 (Critical)
1. ✅ Update fks_main description (Rust, not Python/Django)
2. ✅ Update fks_ninja description (Python/Rust API service, port 8006)
3. ✅ Update service ports table (fks_ninja port 8006)
4. ✅ Update architecture diagram (fks_ninja port 8006)

### Priority 2 (Important)
5. ✅ Update fks_ai description (GPU support enabled)
6. ✅ Update execution flow integration (fks_ninja API service)
7. ✅ Update service integration matrix (fks_ninja API service)

### Priority 3 (Nice to Have)
8. ✅ Update fks_web port (clarify Docker vs Kubernetes)
9. ✅ Update service dependencies (clarify NinjaTrader8 runs separately)
10. ✅ Update internal architecture diagrams

---

## 📊 Summary of Changes

### Services Updated
- ✅ **fks_main**: Rust-based management & monitoring service
- ✅ **fks_ninja**: Python/Rust API service (port 8006)
- ✅ **fks_ai**: GPU support enabled
- ✅ **fks_web**: Port 3001 (Kubernetes) or 8000 (Docker)

### Port Updates
- ✅ **fks_ninja**: Port 8006 (was N/A)
- ✅ **fks_web**: Port 3001 (Kubernetes) or 8000 (Docker)

### Architecture Updates
- ✅ **fks_main**: Rust/Axum architecture (not Python/Django)
- ✅ **fks_ninja**: Python/Rust API service (not C# plugin)
- ✅ **Execution Flow**: fks_ninja as API service (not plugin)

---

## 🎯 Next Steps

1. **Update AI_CONTEXT_GUIDE.md** with all changes listed above
2. **Verify service ports** in service_registry.json
3. **Update architecture diagrams** to reflect current state
4. **Update integration descriptions** to reflect API service architecture
5. **Add GPU configuration details** for fks_ai
6. **Clarify port differences** between Docker and Kubernetes

---

## 📝 Notes

### fks_web Port Discrepancy
- **Docker**: Port 8000 (docker-compose.yml, Dockerfile)
- **Kubernetes**: Port 3001 (values.yaml)
- **Recommendation**: Update guide to reflect Kubernetes configuration (3001) as primary deployment target, with note about Docker port (8000)

### fks_ninja Architecture
- **Current**: Described as C# plugin
- **Actual**: Python/Rust API service
- **Recommendation**: Update all references to reflect API service architecture

### fks_main Architecture
- **Current**: Described as Python/Django service
- **Actual**: Rust/Axum service
- **Recommendation**: Update all references to reflect Rust architecture

---

**Status**: ✅ **REVIEW COMPLETE**

**Last Updated**: 2025-11-12

**Next Action**: Update AI_CONTEXT_GUIDE.md with all changes listed above!

---

**Happy Documenting!** 🚀

