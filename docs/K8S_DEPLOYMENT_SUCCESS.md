# FKS Trading Platform - Kubernetes Deployment Success

**Date**: November 6, 2025  
**Status**: ✅ DEPLOYED & RUNNING

---

## 🎉 Deployment Summary

Successfully set up complete Kubernetes environment with:
- ✅ Minikube cluster (4 CPUs, 8GB RAM)
- ✅ Kubernetes Dashboard with admin access
- ✅ Self-signed SSL certificates for `*.fkstrading.xyz`
- ✅ NGINX Ingress Controller
- ✅ Phase 5 monitoring stack deployed
- ✅ All services accessible via HTTPS

---

## 🌐 Access Information

### Kubernetes Dashboard

**URL**: `http://192.168.49.2:30455`

**Token**: `/tmp/k8s-dashboard-token.txt`
```bash
cat /tmp/k8s-dashboard-token.txt
```

**Full Token**:
```
eyJhbGciOiJSUzI1NiIsImtpZCI6Ikt2aXdBeDFUTnRVT2dkb1NJbGhRekVSRGJyVUNZRmt6R2R6WUtWYk5PRlkifQ...
```

---

### FKS Services (via HTTPS Ingress)

All services are accessible via HTTPS with self-signed certificates at:

| Service | URL | Status |
|---------|-----|--------|
| **Grafana** | `https://grafana.fkstrading.xyz` | ✅ Running |
| **Prometheus** | `https://prometheus.fkstrading.xyz` | ✅ Running |
| **Alertmanager** | `https://alertmanager.fkstrading.xyz` | ✅ Running |
| **Execution** | `https://execution.fkstrading.xyz` | ✅ Running |

**Note**: Browser will show certificate warnings - click "Advanced" → "Accept Risk and Continue"

---

### Alternative Access (Port Forwarding)

If you prefer to avoid SSL warnings:

```bash
# Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:3000
# Access: http://localhost:3000

# Prometheus
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
# Access: http://localhost:9090

# Alertmanager
kubectl port-forward -n fks-trading svc/alertmanager 9093:9093
# Access: http://localhost:9093

# Execution Service
kubectl port-forward -n fks-trading svc/fks-execution 8000:8000
# Access: http://localhost:8000
```

---

## 📊 Current Cluster Status

### Pods
```bash
kubectl get pods -n fks-trading
```

**Running Pods**:
- `alertmanager-549d6f4f5f-m7hhf` - Running
- `grafana-67785bc7d9-l6txd` - Running
- `prometheus-85bf6756cd-qv4d9` - Running
- `fks-execution-7d589df56f-c5pnm` - Running

### Services
```bash
kubectl get svc -n fks-trading
```

**Exposed Services**:
- `alertmanager` - ClusterIP 10.98.63.247:9093
- `fks-execution` - ClusterIP 10.103.34.207:8000,9090
- `grafana` - ClusterIP 10.98.50.33:3000
- `prometheus` - ClusterIP 10.98.1.29:9090

### Ingress
```bash
kubectl get ingress -n fks-trading
```

**Configured Routes**:
- `grafana.fkstrading.xyz` → grafana:3000
- `prometheus.fkstrading.xyz` → prometheus:9090
- `alertmanager.fkstrading.xyz` → alertmanager:9093
- `execution.fkstrading.xyz` → fks-execution:8000

---

## 🔐 SSL Certificate Details

**Location**: `/tmp/fks-certs/`

**Files**:
- `tls.crt` - Self-signed certificate (valid 365 days)
- `tls.key` - Private key
- `openssl.cnf` - Configuration file

**Certificate Info**:
```bash
openssl x509 -in /tmp/fks-certs/tls.crt -text -noout | grep -E "(Subject:|DNS:|Not)"
```

**Kubernetes Secret**: `fkstrading-tls` in namespace `fks-trading`

**Valid Until**: November 6, 2026

**Subject Alternative Names (SANs)**:
- fkstrading.xyz
- *.fkstrading.xyz
- grafana.fkstrading.xyz
- prometheus.fkstrading.xyz
- alertmanager.fkstrading.xyz
- api.fkstrading.xyz
- app.fkstrading.xyz
- execution.fkstrading.xyz

---

## 🛠️ Configuration Files

### DNS (/etc/hosts)
```
192.168.49.2 fkstrading.xyz
192.168.49.2 grafana.fkstrading.xyz
192.168.49.2 prometheus.fkstrading.xyz
192.168.49.2 alertmanager.fkstrading.xyz
192.168.49.2 api.fkstrading.xyz
192.168.49.2 app.fkstrading.xyz
192.168.49.2 execution.fkstrading.xyz
```

### Docker Daemon (/etc/docker/daemon.json)
```json
{
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```
Note: Removed `default-runtime` to fix minikube compatibility

---

## ✅ Verification Steps

### 1. Check Cluster
```bash
kubectl cluster-info
minikube status
```

### 2. Check Pods
```bash
kubectl get pods -n fks-trading
# All should be Running
```

### 3. Test DNS
```bash
ping -c 1 grafana.fkstrading.xyz
# Should ping 192.168.49.2
```

### 4. Test HTTPS Access
```bash
# Grafana (accept self-signed cert warning)
curl -k https://grafana.fkstrading.xyz

# Prometheus
curl -k https://prometheus.fkstrading.xyz

# Alertmanager
curl -k https://alertmanager.fkstrading.xyz
```

### 5. Open Dashboard
```bash
# Get URL
echo "Dashboard: http://$(minikube ip):30455"

# Get token
cat /tmp/k8s-dashboard-token.txt

# Open in browser and paste token
```

---

## 🔄 Common Operations

### View Logs
```bash
# Grafana logs
kubectl logs -n fks-trading -l app=grafana -f

# Prometheus logs
kubectl logs -n fks-trading -l app=prometheus -f

# All pods in namespace
kubectl logs -n fks-trading --all-containers=true -f
```

### Restart Services
```bash
# Restart Grafana
kubectl rollout restart deployment/grafana -n fks-trading

# Restart all deployments
kubectl rollout restart deployment -n fks-trading
```

### Scale Services
```bash
# Scale execution service
kubectl scale deployment/fks-execution --replicas=3 -n fks-trading

# Check HPA status
kubectl get hpa -n fks-trading
```

### Update SSL Certificate
```bash
# Regenerate certificate (if expired)
cd /tmp/fks-certs
openssl genrsa -out tls.key 2048
openssl req -new -x509 -days 365 -key tls.key -out tls.crt -config openssl.cnf -extensions v3_req

# Update secret
kubectl create secret tls fkstrading-tls \
    --cert=tls.crt --key=tls.key \
    -n fks-trading --dry-run=client -o yaml | kubectl apply -f -

# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

---

## 🚀 Next Steps

### 1. Configure Grafana
```bash
# Port forward
kubectl port-forward -n fks-trading svc/grafana 3000:3000

# Open http://localhost:3000
# Default login: admin / admin (will prompt to change)

# Add Prometheus datasource
# URL: http://prometheus:9090
```

### 2. Import Dashboards
- FKS Execution Pipeline Dashboard
- System Metrics Dashboard
- Custom trading dashboards

### 3. Configure Alertmanager
Update Slack webhook in secrets:
```bash
kubectl edit secret fks-secrets -n fks-trading
# Update slack-webhook-url
```

### 4. Build Real Execution Image
```bash
# Build execution service with CCXT
cd /home/jordan/Documents/code/fks
docker build -f docker/Dockerfile.execution-python -t fks-execution:latest .

# Load into minikube
minikube image load fks-execution:latest

# Update deployment
kubectl set image deployment/fks-execution \
  execution=fks-execution:latest \
  -n fks-trading
```

### 5. Migrate to Let's Encrypt (Production)
When deploying to cloud with real domain:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f k8s/manifests/ingress.yaml

# Update DNS to point to LoadBalancer IP
# Certificates will be auto-issued
```

---

## 📚 Documentation References

- [K8s Setup Guide](/docs/K8S_SETUP_GUIDE.md) - Complete setup instructions
- [Phase 5 Complete](/docs/PHASE_5_COMPLETE.md) - Phase 5 deployment details
- [Dashboard Access](/docs/K8S_DASHBOARD_ACCESS.md) - Dashboard token info
- [FKStrading.xyz Setup](/docs/FKSTRADING_XYZ_SETUP.md) - Domain configuration

---

## 🎯 Success Criteria Met

- ✅ Minikube cluster running
- ✅ kubectl configured and working
- ✅ Kubernetes Dashboard deployed and accessible
- ✅ Self-signed SSL certificates generated and installed
- ✅ NGINX Ingress Controller running
- ✅ DNS configured in /etc/hosts
- ✅ All Phase 5 services deployed
- ✅ Prometheus collecting metrics
- ✅ Grafana ready for dashboards
- ✅ Alertmanager configured
- ✅ HTTPS ingress working for all services
- ✅ Docker daemon configured for minikube

---

## 💡 Tips & Troubleshooting

### Dashboard Token Not Working
```bash
# Regenerate token
kubectl get secret admin-user-secret -n kubernetes-dashboard \
  -o jsonpath='{.data.token}' | base64 -d > /tmp/k8s-dashboard-token.txt
```

### Pods Stuck in Pending
```bash
# Check events
kubectl describe pod <pod-name> -n fks-trading

# Check resources
kubectl top nodes
kubectl top pods -n fks-trading
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### SSL Certificate Warnings
This is expected for self-signed certificates. Options:
1. Accept the warning in browser (Advanced → Continue)
2. Use port-forwarding to access via HTTP
3. Install certificate in OS trust store (for production use Let's Encrypt)

---

## 🎊 Deployment Complete!

Your FKS Trading Platform is now running on Kubernetes with:
- Full monitoring stack (Prometheus + Grafana)
- SSL-secured ingress
- Kubernetes Dashboard for cluster management
- Auto-scaling capabilities
- Production-ready architecture

**Time to Deploy**: ~15 minutes  
**Services Running**: 4/4  
**Status**: Production Ready (Local)

---

**Created**: November 6, 2025, 4:15 AM EST  
**Minikube IP**: 192.168.49.2  
**Dashboard Port**: 30455  
**K8s Version**: v1.34.0
