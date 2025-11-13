# Nginx Ingress Controller - Current Setup ✅

**Decision:** Using Option 1 - Nginx Ingress Controller (Kubernetes-native)

**Date:** 2025-11-12  
**Status:** ✅ Active and Running

---

## Current Configuration

### Ingress Controller
- **Namespace:** `ingress-nginx`
- **Service:** `ingress-nginx-controller`
- **Type:** LoadBalancer (or NodePort in minikube)
- **Status:** ✅ Running

### Ingress Resources
- **Primary Ingress:** `fks-platform-ingress`
  - Domain: `fkstrading.xyz`
  - Routes all services under single domain with path-based routing
  
- **Multi-Domain Ingress:** `fks-platform-ingress-multi`
  - Subdomain routing (api.fkstrading.xyz, web.fkstrading.xyz, etc.)
  - Alternative routing option

---

## Service Routes (Primary Ingress)

| Path | Service | Port | Description |
|------|---------|------|-------------|
| `/` | `web` | 8000 | Django Web Interface (main) |
| `/api/` | `fks-api` | 8001 | API Service |
| `/app/` | `fks-app` | 8002 | App Service (strategies/signals) |
| `/data/` | `fks-data` | 8003 | Data Service |
| `/execution/` | `fks-execution` | 8004 | Execution Service |
| `/meta/` | `fks-meta` | 8005 | Meta Service (MT5) |
| `/ninja/` | `fks-ninja` | 8006 | NinjaTrader8 Bridge |
| `/ai/` | `fks-ai` | 8007 | AI Service |
| `/analyze/` | `fks-analyze` | 8008 | Analyze Service |
| `/auth/` | `fks-auth` | 8009 | Auth Service |
| `/main/` | `fks-main` | 8010 | Main Service (Rust) |
| `/training/` | `fks-training` | 8011 | Training Service |
| `/portfolio/` | `fks-portfolio` | 8012 | Portfolio Service |
| `/monitor/` | `fks-monitor` | 8013 | Monitor Service |
| `/grafana/` | `fks-platform-grafana` | 80 | Grafana Dashboard |
| `/prometheus/` | `fks-platform-prometheus-server` | 80 | Prometheus Metrics |

---

## SSL/TLS Configuration

- **Certificate Manager:** cert-manager
- **Issuer:** `letsencrypt-prod`
- **Secret:** `fkstrading-tls`
- **Domains:**
  - `fkstrading.xyz`
  - `*.fkstrading.xyz` (wildcard)

---

## Benefits of Current Setup

✅ **Kubernetes-native** - Managed by Kubernetes  
✅ **Automatic SSL** - cert-manager handles Let's Encrypt certificates  
✅ **Easy management** - Configure via Ingress resources  
✅ **Built-in load balancing** - Automatic across service replicas  
✅ **Health checks** - Automatic backend health checking  
✅ **Path-based routing** - All services under one domain  
✅ **Subdomain routing** - Alternative multi-domain setup available  

---

## Management Commands

### Check Ingress Status
```bash
kubectl get ingress -n fks-trading
kubectl describe ingress fks-platform-ingress -n fks-trading
```

### Check Ingress Controller
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### View Ingress Logs
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100
```

### Test Routes
```bash
# Test main route
curl -H "Host: fkstrading.xyz" http://$(minikube ip)/

# Test API route
curl -H "Host: fkstrading.xyz" http://$(minikube ip)/api/health

# Test portfolio route
curl -H "Host: fkstrading.xyz" http://$(minikube ip)/portfolio/health
```

---

## Configuration Files

- **Primary Ingress:** `repo/k8s/ingress.yaml`
- **Ingress Controller:** Managed by Kubernetes (installed via Helm or kubectl)

---

## Future Options

If you need more control over nginx configuration in the future:
- Standalone nginx service files are available in `repo/nginx/`
- Kubernetes manifests ready in `repo/k8s/manifests/nginx-service.yaml`
- Can be deployed alongside or instead of ingress controller

---

## Troubleshooting

### 503 Service Unavailable
```bash
# Check if backend services are running
kubectl get pods -n fks-trading

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### SSL Certificate Issues
```bash
# Check cert-manager
kubectl get certificates -n fks-trading
kubectl describe certificate fkstrading-tls -n fks-trading

# Check certificate secret
kubectl get secret fkstrading-tls -n fks-trading
```

### Route Not Working
```bash
# Verify ingress rules
kubectl describe ingress fks-platform-ingress -n fks-trading

# Check backend service
kubectl get svc -n fks-trading web
kubectl get endpoints -n fks-trading web
```

---

**✅ Current setup is optimal for Kubernetes deployment!**

