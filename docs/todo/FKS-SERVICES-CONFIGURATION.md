# FKS Services Configuration - Updated

**Date**: 2025-11-12  
**Status**: ✅ **UPDATED**  
**Purpose**: Document the updated configuration for fks_main, fks_web, and fks_ai

---

## 🎯 Service Roles

### fks_main - Rust Management & Monitoring Service

**Purpose**: Rust-based orchestration service that fully manages and monitors everything in the platform.

**Configuration**:
- **Type**: Rust application
- **Port**: 8010
- **Role**: Platform management, monitoring, and orchestration
- **Features**:
  - K8s orchestration (control deployments, scaling, restarts)
  - Service management (unified API for all FKS services)
  - Monitor integration (consumes fks_monitor for health/metrics)
  - Infrastructure control (full K8s environment control)

**Environment Variables**:
- `SERVICE_NAME=fks_main`
- `SERVICE_PORT=8010`
- `MONITOR_URL=http://fks-monitor:8013`
- `K8S_NAMESPACE=fks-trading`
- `DOMAIN=fkstrading.xyz`
- `RUST_LOG=info`
- `RUST_BACKTRACE=1`

**Health Checks**:
- Liveness: `/health`
- Readiness: `/ready`

---

### fks_web - Web Interface

**Purpose**: Hosts the web interface for the FKS platform.

**Configuration**:
- **Type**: Django/Gunicorn application
- **Port**: 3001
- **Role**: Web UI for platform access
- **Features**:
  - Web interface for platform management
  - User dashboard
  - Trading interface
  - Platform monitoring UI

**Environment Variables**:
- `DJANGO_SETTINGS_MODULE=src.django.settings`
- `ALLOWED_HOSTS=fkstrading.xyz,*.fkstrading.xyz,localhost,127.0.0.1,100.80.141.117`
- `DEBUG=False`
- `DATABASE_URL=postgresql://...`
- `REDIS_HOST=fks-platform-redis-master`
- `CELERY_BROKER_URL=redis://...`
- `API_SERVICE_URL=http://fks-api:8001`
- `APP_SERVICE_URL=http://fks-app:8002`
- `DATA_SERVICE_URL=http://fks-data:8003`
- `MAIN_SERVICE_URL=http://fks-main:8010`

**Health Checks**:
- Liveness: `/health`
- Readiness: `/health`

---

### fks_ai - AI Optimization Service

**Purpose**: AI service to optimize and improve the baseline trading strategies.

**Configuration**:
- **Type**: AI/ML service with GPU support
- **Port**: 8007
- **Role**: AI optimization, strategy improvement, baseline enhancement
- **Features**:
  - GPU-accelerated AI/ML workloads
  - Strategy optimization
  - Baseline improvement
  - Model training and inference

**GPU Configuration**:
- **GPU**: 1x NVIDIA GPU with CUDA support
- **Resources**:
  - CPU: 4000m limit, 1000m request
  - Memory: 8Gi limit, 4Gi request
  - GPU: 1x nvidia.com/gpu

**Environment Variables**:
- `CUDA_VISIBLE_DEVICES=0`
- `NVIDIA_VISIBLE_DEVICES=all`
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility`
- `POSTGRES_HOST=fks-platform-postgresql`
- `DATA_SERVICE_URL=http://fks-data:8003`
- `REDIS_HOST=fks-platform-redis-master`

**GPU Requirements**:
- NVIDIA GPU with CUDA support
- NVIDIA GPU device plugin installed in Kubernetes
- GPU drivers installed on nodes

**Health Checks**:
- Liveness: `/health`
- Readiness: `/health`

---

## 🔧 Deployment Configuration

### Updated Services

All three services are now **enabled** in `values.yaml`:

```yaml
fks_main:
  enabled: true  # Rust management & monitoring service

fks_web:
  enabled: true  # Web interface

fks_ai:
  enabled: true  # AI optimization with GPU support
```

### GPU Setup

For GPU support, ensure:

1. **NVIDIA GPU Device Plugin** is installed:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
   ```

2. **GPU Node Labels** (optional):
   ```bash
   kubectl label nodes <node-name> accelerator=nvidia-tesla-k80
   ```

3. **Verify GPU Availability**:
   ```bash
   kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'
   ```

---

## 📊 Service Dependencies

### fks_main Dependencies

- **fks_monitor**: For health/metrics data
- **PostgreSQL**: For monitoring data storage
- **Redis**: For caching and coordination
- **Kubernetes API**: For managing K8s resources

### fks_web Dependencies

- **PostgreSQL**: Database
- **Redis**: Cache and Celery broker
- **fks_api**: API service
- **fks_app**: Application service
- **fks_data**: Data service
- **fks_main**: Main orchestration service

### fks_ai Dependencies

- **PostgreSQL**: Database
- **fks_data**: Data service for training data
- **Redis**: Cache and coordination
- **GPU**: NVIDIA GPU with CUDA support

---

## 🚀 Deployment

### Deploy All Services

```bash
cd repo/main
./run.sh
# Choose option 8 (Kubernetes Start)
# Choose 'p' to pull images from Docker Hub
```

Or use the deployment script:

```bash
cd repo/main
bash scripts/deploy-all-services.sh
```

### Verify GPU Support

```bash
# Check if GPU is available
kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'

# Check fks_ai pod
kubectl get pods -n fks-trading -l app=fks-ai

# Check GPU allocation
kubectl describe pod <fks-ai-pod-name> -n fks-trading | grep -i gpu
```

---

## 🔍 Monitoring

### fks_main Monitoring

```bash
# Check fks_main logs
kubectl logs -n fks-trading -l app=fks-main -f

# Check fks_main health
kubectl exec -n fks-trading deployment/fks-main -- curl http://localhost:8010/health

# Check fks_main readiness
kubectl exec -n fks-trading deployment/fks-main -- curl http://localhost:8010/ready
```

### fks_web Monitoring

```bash
# Check fks_web logs
kubectl logs -n fks-trading -l app=fks-web -f

# Check fks_web health
kubectl exec -n fks-trading deployment/fks-web -- curl http://localhost:3001/health
```

### fks_ai Monitoring

```bash
# Check fks_ai logs
kubectl logs -n fks-trading -l app=fks-ai -f

# Check fks_ai GPU usage
kubectl exec -n fks-trading deployment/fks-ai -- nvidia-smi

# Check fks_ai health
kubectl exec -n fks-trading deployment/fks-ai -- curl http://localhost:8007/health
```

---

## 🎉 Summary

### Service Configuration

- ✅ **fks_main**: Rust management & monitoring service (enabled)
- ✅ **fks_web**: Web interface (enabled)
- ✅ **fks_ai**: AI optimization with GPU support (enabled)

### Key Changes

1. **fks_main**: Updated to Rust configuration (removed Django env vars)
2. **fks_web**: Enabled and configured for web interface
3. **fks_ai**: Enabled with GPU/CUDA support

### Next Steps

1. Deploy all services: `./run.sh` → option 8
2. Verify GPU support: Check GPU availability in cluster
3. Access web interface: `http://fkstrading.xyz` or port-forward
4. Monitor services: Use fks_main API for platform management

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Deploy all services using `./run.sh` or `bash scripts/deploy-all-services.sh`!

---

**Happy Deploying!** 🚀

