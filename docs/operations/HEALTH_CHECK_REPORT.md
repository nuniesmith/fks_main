# FKS Trading Platform - Health Check Report
**Date**: November 3, 2025 @ 22:08 PST  
**Status**: ⚠️ DEGRADED - Memory overcommit

---

## 🚨 Critical Issues

### 1. Memory Overcommitment ❌
- **Allocated**: 38,314 Mi limits / 32,000 Mi capacity
- **Overcommit**: **119%** (19% over capacity)
- **Impact**: Pods being OOM killed (SIGKILL)

### 2. Docker Hub Rate Limiting ⚠️
- **13 pods** in ErrImagePull status
- **Cause**: Pull QPS exceeded (Docker Hub anonymous limit)

### 3. Service Degradation ⚠️
- Only **1 replica** running for most services (need 4-5)
- fks-execution: **0/1** ready (CrashLoopBackOff)

---

## 📊 Pod Status Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ **Running** | 18 | 50% |
| ⚠️ **ErrImagePull** | 13 | 36% |
| ❌ **CrashLoopBackOff** | 4 | 11% |
| ⏳ **ContainerCreating** | 1 | 3% |
| **Total** | **36** | **100%** |

---

## 🎯 Service Health Matrix

| Service | Desired | Ready | Status | Health |
|---------|---------|-------|--------|--------|
| **fks-main** | 5 | 3 | Running | ⚠️ OOM kills, 60% ready |
| **fks-api** | 5 | 1 | Running | ⚠️ 20% ready |
| **fks-app** | 5 | 1 | Running | ⚠️ 20% ready |
| **fks-data** | 4 | 1 | Running | ⚠️ 25% ready |
| **fks-execution** | 1 | 0 | Failed | ❌ Not ready |
| **celery-worker** | 2 | 0 | Failed | ❌ CrashLoopBackOff |

### ✅ Healthy Services

| Service | Status | Health |
|---------|--------|--------|
| **Grafana** | 1/1 | ✅ Healthy (v10.1.5) |
| **Prometheus** | 1/1 | ✅ Healthy |
| **PostgreSQL** | 1/1 | ✅ Running |
| **Redis** | 1/1 | ✅ Running |
| **AlertManager** | 1/1 | ✅ Running |

---

## 🔍 Root Cause Analysis

### Memory Pressure
```
Worker (pid:13) was sent SIGKILL! Perhaps out of memory?
Worker (pid:18) was sent SIGKILL! Perhaps out of memory?
```

**Cause**: 
- fks-main pods being OOM killed by kernel
- Memory limits: 38,314 Mi requested, only 32,000 Mi available
- HPA scaled up services but hit memory ceiling

**Solution**:
1. Reduce replica counts
2. Increase memory limits per pod
3. Or increase minikube memory allocation

### Image Pull Failures
```
Failed to pull image "docker.io/nuniesmith/fks:api-latest": pull QPS exceeded
```

**Cause**: Docker Hub anonymous rate limit (100 pulls/6 hours)

**Solution**:
1. Use `imagePullPolicy: IfNotPresent` 
2. Or configure Docker Hub credentials
3. Or use local registry

---

## 🚀 Immediate Actions Needed

### 1. Reduce Replica Counts (Critical)

```bash
# Scale down to minimum
kubectl scale deployment fks-api -n fks-trading --replicas=1
kubectl scale deployment fks-app -n fks-trading --replicas=1
kubectl scale deployment fks-data -n fks-trading --replicas=1
kubectl scale deployment fks-main -n fks-trading --replicas=2
```

### 2. Update Image Pull Policy

```bash
# Edit deployments to use IfNotPresent
kubectl set image deployment/fks-api -n fks-trading \
  fks-api=docker.io/nuniesmith/fks:api-latest \
  --image-pull-policy=IfNotPresent
```

### 3. Increase Minikube Memory (Optional)

```bash
# Stop and resize
minikube stop
minikube delete
minikube start --memory=24576 --cpus=8
```

---

## ✅ Working Components

### Monitoring Stack
- ✅ **Grafana**: http://grafana.fkstrading.xyz (v10.1.5, DB: ok)
- ✅ **Prometheus**: http://prometheus.fkstrading.xyz (Healthy)
- ✅ **AlertManager**: Running
- ✅ **Kube-State-Metrics**: Running

### Infrastructure
- ✅ **PostgreSQL**: Running (1/1)
- ✅ **Redis**: Running (1/1 + headless)
- ✅ **Ingress**: 3 rules configured
- ✅ **DNS**: 7 domains in /etc/hosts

### Core Services (Minimal)
- ✅ **fks-api**: 1 pod ready (needs 4 more)
- ✅ **fks-app**: 1 pod ready (needs 4 more)
- ✅ **fks-data**: 1 pod ready (needs 3 more)
- ✅ **fks-main**: 3 pods ready (needs 2 more)

---

## 📋 Health Checks

### Monitoring
```bash
# Grafana ✅
curl http://grafana.fkstrading.xyz/api/health
# {"commit":"849c612fcb","database":"ok","version":"10.1.5"}

# Prometheus ✅
curl http://prometheus.fkstrading.xyz/-/healthy
# Prometheus Server is Healthy.
```

### Services (After scaling)
```bash
# Test via Ingress
curl http://api.fkstrading.xyz/health/
curl http://app.fkstrading.xyz/health/
curl http://data.fkstrading.xyz/health/
```

---

## 🎯 Resource Allocation

### Current (Overcommitted)
```
Resource    Requests      Limits         Capacity      Status
CPU         5,950m (49%)  25,250m (210%) 12,000m       ⚠️ Overcommit
Memory      17,228Mi (53%) 38,314Mi (119%) 32,000Mi     ❌ Overcommit
```

### After Scaling Down (Target)
```
Resource    Requests      Limits         Capacity      Status
CPU         ~3,000m (25%) ~10,000m (83%)  12,000m       ✅ OK
Memory      ~10,000Mi (31%) ~18,000Mi (56%) 32,000Mi     ✅ OK
```

---

## 🔧 Recommended Configuration

### Helm Values Update

```yaml
# k8s/charts/fks-platform/values-dev.yaml
fks-main:
  replicaCount: 2  # Down from 15
  resources:
    limits:
      memory: 1Gi   # Down from 1.5Gi
      cpu: 1000m
    requests:
      memory: 512Mi
      cpu: 500m

fks-api:
  replicaCount: 1  # Down from 5
  autoscaling:
    enabled: false  # Disable HPA temporarily

fks-app:
  replicaCount: 1
  autoscaling:
    enabled: false

fks-data:
  replicaCount: 1
  autoscaling:
    enabled: false
```

---

## 🎉 Summary

**Overall Status**: ⚠️ **DEGRADED** (functional but overloaded)

### What's Working ✅
- Monitoring stack fully operational
- Database and cache services healthy
- Ingress and DNS configured correctly
- Minimal core services running (1 pod each)

### What's Broken ❌
- Memory overcommitment causing OOM kills
- Most replicas failing to start (image pull limits)
- fks-execution service not running
- Auto-scaling hitting resource limits

### Next Steps
1. **Immediate**: Scale down deployments to fit memory
2. **Short-term**: Configure image pull policy
3. **Long-term**: Increase cluster resources or optimize pod memory usage

---

**Action Required**: Run scaling commands above to stabilize cluster.
