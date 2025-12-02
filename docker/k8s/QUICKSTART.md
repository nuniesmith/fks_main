# FKS Platform Kubernetes - Quick Start

**Get your FKS Platform running on Kubernetes in 10 minutes.**

---

## 🚀 Quick Deploy (Development)

### Prerequisites

```bash
# Verify tools installed
kubectl version --client
helm version
docker --version
```

### Step 1: Start Local Kubernetes

```bash
# Option A: Minikube (Recommended)
minikube start --cpus=6 --memory=16384 --disk-size=50g
minikube addons enable ingress
minikube addons enable metrics-server

# Option B: Docker Desktop
# Enable Kubernetes in Settings → Kubernetes
# Allocate 6 CPUs, 16GB RAM

# Verify cluster
kubectl cluster-info
```

### Step 2: Deploy FKS Platform

```bash
cd /home/jordan/Documents/fks

# One-command deploy
make k8s-dev

# Or manual
./k8s/scripts/deploy.sh deploy --values charts/fks-platform/values-dev.yaml
```

### Step 3: Verify & Access

```bash
# Check all pods running
kubectl get pods -n fks-system

# Port-forward services
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &
kubectl port-forward -n fks-system svc/fks-web 3001:3001 &
kubectl port-forward -n fks-system svc/grafana 3000:3000 &

# Access services
open http://localhost:8000/health/  # Main API
open http://localhost:3001          # Web UI
open http://localhost:3000          # Grafana (admin/admin)
```

---

## 🎯 Quick Commands

### Deployment

```bash
make k8s-dev      # Deploy development environment
make k8s-prod     # Deploy production environment
make k8s-destroy  # Remove deployment
make k8s-test     # Run health checks
```

### Docker Images

```bash
# Set registry
export DOCKER_REGISTRY=ghcr.io/yourusername

# Build and push
make docker-build-all
make docker-push-all
```

### Monitoring

```bash
# View all resources
kubectl get all -n fks-system

# Watch pods
watch kubectl get pods -n fks-system

# View logs
kubectl logs -n fks-system -l app=fks-main --tail=50 -f

# Check HPA status
kubectl get hpa -n fks-system

# Prometheus metrics
kubectl port-forward -n fks-system svc/prometheus 9090:9090
open http://localhost:9090
```

### Troubleshooting

```bash
# Describe pod issues
kubectl describe pod -n fks-system <pod-name>

# Check events
kubectl get events -n fks-system --sort-by=.lastTimestamp

# Shell into pod
kubectl exec -n fks-system -it deployment/fks-main -- bash

# Database access
kubectl exec -n fks-system -it postgresql-0 -- psql -U fks_user -d fks_db
```

---

## 📋 Service URLs (Port-Forward)

| Service | Port | URL | Notes |
|---------|------|-----|-------|
| fks-main | 8000 | http://localhost:8000/health/ | Main API |
| fks-api | 8001 | http://localhost:8001/health/ | Gateway |
| fks-web | 3001 | http://localhost:3001 | Web UI |
| fks-ai | 8007 | http://localhost:8007/health/ | AI Service |
| Grafana | 3000 | http://localhost:3000 | admin/admin |
| Prometheus | 9090 | http://localhost:9090 | Metrics |

---

## 🧪 Quick Health Check

```bash
# Run automated tests
./k8s/scripts/deploy.sh test

# Or manual
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &
curl http://localhost:8000/health/

# Expected response:
# {"status": "healthy", "services": {...}}
```

---

## 🔧 Configuration

### Environment Values

```bash
# Development (minimal resources)
./k8s/scripts/deploy.sh deploy --values charts/fks-platform/values-dev.yaml

# Production (full resources)
./k8s/scripts/deploy.sh deploy --values charts/fks-platform/values-prod.yaml

# Custom values
./k8s/scripts/deploy.sh deploy --values my-custom-values.yaml
```

### Customize Resources

Edit `k8s/charts/fks-platform/values-dev.yaml`:

```yaml
fks_ai:
  replicaCount: 1
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
```

---

## 🧹 Cleanup

```bash
# Uninstall deployment
make k8s-destroy

# Or manual
./k8s/scripts/deploy.sh destroy

# Stop cluster
minikube stop
minikube delete
```

---

## 📖 Documentation

- **Full Guide**: `docs/K8S_DEPLOYMENT_GUIDE.md`
- **Testing Guide**: `k8s/TESTING.md`
- **Phase 8 Roadmap**: `docs/PHASE_8_PRODUCTION_SCALING.md`

---

## ⚡ Pro Tips

1. **Faster Deployment**: Use `--wait=false` to skip health checks
   ```bash
   ./k8s/scripts/deploy.sh deploy --wait=false
   ```

2. **Watch Deployment Progress**:
   ```bash
   watch kubectl get pods -n fks-system
   ```

3. **Tail All Logs**:
   ```bash
   kubectl logs -n fks-system -l app.kubernetes.io/instance=fks-platform --tail=100 -f
   ```

4. **Quick Restart**:
   ```bash
   kubectl rollout restart -n fks-system deployment
   ```

5. **Scale Manually**:
   ```bash
   kubectl scale -n fks-system deployment/fks-ai --replicas=3
   ```

---

## 🆘 Common Issues

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n fks-system <pod-name>

# Common fixes:
# - Insufficient resources: Increase minikube memory
# - Image pull errors: Check image exists, build with make docker-build-all
# - CrashLoopBackOff: Check logs with kubectl logs
```

### Can't Access Services

```bash
# Verify port-forward is running
ps aux | grep port-forward

# Restart port-forward
pkill -f port-forward
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &
```

### Database Connection Errors

```bash
# Check PostgreSQL is ready
kubectl exec -n fks-system postgresql-0 -- pg_isready

# Verify credentials in secrets
kubectl get secret -n fks-system fks-secrets -o yaml
```

---

## 📞 Support

- **Issues**: See `k8s/TESTING.md` troubleshooting section
- **Logs**: `kubectl logs -n fks-system <pod-name>`
- **Status**: `kubectl get all -n fks-system`

---

**Ready to deploy?** Run `make k8s-dev` now! 🚀
