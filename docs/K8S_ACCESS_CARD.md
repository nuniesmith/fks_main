# 🚀 FKS Platform - Quick Access Card

**Updated**: November 3, 2025, 12:49 PM

---

## 🌐 Access URLs (Port-Forward Active)

| Service | URL | Credentials |
|---------|-----|-------------|
| **Kubernetes Dashboard** | <http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/kubernetes-dashboard:/proxy/> | Token (see below) |
| **FKS Main API** | <http://localhost:8000/health/> | N/A |
| **Grafana** | <http://localhost:3000> | admin / a4VCcjlhLI3iAMBie83UqNmk1JxuzpSfeucrfBHY |
| **Prometheus** | <http://localhost:9090> | N/A |

---

## 🔑 Dashboard Login Token

```text
eyJhbGciOiJSUzI1NiIsImtpZCI6InQ0QXJPVDVqa28zZVBaV3RxMXcydExRRDkzUHFfSzEtTFhpX0VjaWtsSWcifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJlODc2ODdmNS05OGZjLTQ4YzYtOTg2OS00ZTI1NzBkYWJlOTAiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.zLUrYuDqPLsn3kcjS1bWYwfg6mYvn6L5LSfeyaNr4pSuMSKxIlG93xym5J9iitGAe3cnE_PhEaSpQDyXnyvm1w1AfrXf95hreHY1dhahwkM72NF_prmutNU21daYpXyfU2GXTy6ueF4BrvhFMs2ztbYjMgeMVVo67KW-eilAw86sfHk-UNRlQTiYuwbBrIFVlkM2T3iDmXrryod8JqvIv56aKsMIBOMVFjFj_BiRyOHI4EV8_m9cLiUmYehBy_otp9-iNzUgGVPVlrSp-avcnXsionUA4vUPVtpTZIhzimvauDF2v7egyfFzcAdCvF-8oB6bYMfCRixqrHBTxL4KAw
```

---

## ⚡ Quick Commands

### View All Pods

```bash
kubectl get pods -n fks-trading
```

### Watch Pod Status

```bash
watch kubectl get pods -n fks-trading
```

### Tail Logs

```bash
# Main service
kubectl logs -n fks-trading -l app=fks-main --tail=50 -f

# Specific pod
kubectl logs -n fks-trading <pod-name> -f
```

### Restart Services

```bash
# Restart all
kubectl rollout restart deployment -n fks-trading

# Restart specific
kubectl rollout restart deployment/fks-main -n fks-trading
```

### Stop Port Forwards

```bash
# Stop all
pkill -f "port-forward"

# Stop dashboard proxy
pkill -f "kubectl proxy"
```

### Restart Port Forwards

```bash
# Main API
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &

# Grafana
kubectl port-forward -n fks-trading svc/fks-platform-grafana 3000:80 &

# Prometheus
kubectl port-forward -n fks-trading svc/fks-platform-prometheus-server 9090:80 &

# Dashboard
kubectl proxy &
```

---

## 📊 Service Status

**Healthy** (24/29 pods):

- ✅ fks-main (10 replicas)
- ✅ fks-api (2 replicas)
- ✅ fks-app (2 replicas)
- ✅ fks-data (2 replicas)
- ✅ PostgreSQL + Redis
- ✅ Grafana + Prometheus

**Issues**:

- ❌ fks-execution (CrashLoopBackOff)
- ❌ fks-ai, fks-ninja, fks-mt5, fks-web (not deployed)

---

## 🔧 Troubleshooting

### Check Pod Issues

```bash
# Describe pod
kubectl describe pod -n fks-trading <pod-name>

# View events
kubectl get events -n fks-trading --sort-by=.lastTimestamp

# Check HPA status
kubectl get hpa -n fks-trading
```

### Database Access

```bash
# PostgreSQL
kubectl exec -it -n fks-trading fks-platform-postgresql-0 -- \
  psql -U fks_user -d fks_db

# Redis
kubectl exec -it -n fks-trading fks-platform-redis-master-0 -- redis-cli
```

---

## 📚 Documentation

- **Full Status Report**: `K8S_STATUS_REPORT.md`
- **Quick Start**: `k8s/QUICKSTART.md`
- **Deployment Guide**: `docs/K8S_DEPLOYMENT_GUIDE.md`
- **Testing Guide**: `k8s/TESTING.md`

---

**Active Port Forwards**: 4 (kubectl proxy + 3 services)  
**Cluster**: Minikube (local)  
**Namespace**: fks-trading  
**Status**: ✅ Core Services Operational

---

*Keep this card handy for quick reference!*
