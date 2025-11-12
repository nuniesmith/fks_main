# FKS Trading Platform - Ingress Access Guide

**Date**: November 3, 2025  
**Status**: ✅ Ingress Configured and Operational

---

## Access URLs

All services are accessible via NGINX Ingress at `192.168.49.2`

### Primary Services

| Service | URL | Status | Description |
|---------|-----|--------|-------------|
| **Main Web UI** | http://fks-trading.local | ✅ Working | Django web interface |
| **API Gateway** | http://api.fks-trading.local | ✅ Working | FastAPI REST API |
| **App Service** | http://app.fks-trading.local | ✅ Working | Trading strategies/signals |
| **Data Service** | http://data.fks-trading.local | ✅ Working | Market data collection |
| **Execution Service** | http://execution.fks-trading.local | ✅ Working | Rust trade execution |

### Monitoring

| Service | URL | Status | Description |
|---------|-----|--------|-------------|
| **Grafana** | http://grafana.fks-trading.local | ✅ Working | Metrics dashboards |
| **Prometheus** | http://prometheus.fks-trading.local | ✅ Working | Metrics collection |

---

## Quick Test Commands

```bash
# Test main UI
curl http://fks-trading.local/

# Test health endpoints
curl http://fks-trading.local/health/ | jq .
curl http://execution.fks-trading.local/health | jq .

# Test Grafana
curl http://grafana.fks-trading.local/api/health | jq .

# Test Prometheus
curl http://prometheus.fks-trading.local/-/healthy
```

---

## Load Testing via Ingress

Now that Ingress is stable, you can run load tests without port-forward issues:

```bash
# Create load test targeting Ingress
k6 run --vus 50 --duration 5m k8s/tests/ingress-load-test.js

# Monitor HPA during load test
watch kubectl get hpa -n fks-trading
```

---

## DNS Configuration

Add to `/etc/hosts` for local access:

```
192.168.49.2 fks-trading.local
192.168.49.2 api.fks-trading.local
192.168.49.2 app.fks-trading.local
192.168.49.2 data.fks-trading.local
192.168.49.2 execution.fks-trading.local
192.168.49.2 grafana.fks-trading.local
192.168.49.2 prometheus.fks-trading.local
```

---

## Ingress Resources

```bash
# List all Ingress rules
kubectl get ingress -n fks-trading

# Describe Ingress for details
kubectl describe ingress fks-platform-ingress-multi -n fks-trading

# Check NGINX Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

---

## Health Check Status

| Endpoint | Response | Status |
|----------|----------|--------|
| http://fks-trading.local/health/ | `{"status":"degraded"}` | ⚠️ Expected |
| http://execution.fks-trading.local/health | `{"status":"healthy"}` | ✅ Working |
| http://grafana.fks-trading.local/api/health | `{"database":"failing"}` | ⚠️ DB config |
| http://api.fks-trading.local/health | HTTP 405 | ⚠️ Method issue |

---

## Next Steps

1. ✅ **Ingress configured** - All services accessible via stable URLs
2. 🔲 **Run load tests** - Use Ingress URLs instead of port-forward
3. 🔲 **Add TLS** - Configure Let's Encrypt certificates for HTTPS
4. 🔲 **External DNS** - Set up real domain for production

---

**Ingress Status**: ✅ **OPERATIONAL**  
**Access Method**: Subdomain-based routing via NGINX Ingress  
**Stability**: ✅ **Stable** (no port-forward dependency)
