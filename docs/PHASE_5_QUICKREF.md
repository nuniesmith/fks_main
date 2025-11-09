# Phase 5 - Quick Reference Card

**Production Kubernetes Deployment**

---

## 🚀 Quick Deploy

```bash
cd /home/jordan/fks

# 1. Configure secrets
cp k8s/manifests/secrets.yaml.template k8s/manifests/secrets.yaml
nano k8s/manifests/secrets.yaml

# 2. Deploy everything
./k8s/scripts/deploy-phase5.sh

# 3. Check status
kubectl get all -n fks-trading
```

---

## 📁 Files Created

| File | Purpose |
|------|---------|
| `/k8s/manifests/execution-service.yaml` | Execution deployment + HPA |
| `/k8s/manifests/monitoring-stack.yaml` | Prometheus + Grafana |
| `/k8s/manifests/prometheus-rules.yaml` | Alert rules |
| `/k8s/manifests/alertmanager.yaml` | Alertmanager + Slack |
| `/k8s/manifests/ingress.yaml` | TLS ingress |
| `/k8s/manifests/secrets.yaml.template` | Secrets template |
| `/k8s/scripts/deploy-phase5.sh` | Deployment script |
| `/docs/PHASE_5_COMPLETE.md` | Full documentation |

---

## 🔑 Secrets Required

```yaml
# Database
postgres-password: "..."

# Redis
redis-password: "..."

# Grafana
grafana-admin-user: "admin"
grafana-admin-password: "..."

# TradingView
webhook-secret: "..." (32+ chars)

# Exchanges (optional)
binance-api-key: "..."
binance-api-secret: "..."
coinbase-api-key: "..."
coinbase-api-secret: "..."

# Slack
slack-webhook-url: "https://hooks.slack.com/..."
```

---

## 📊 Services Deployed

| Service | Replicas | Resources | Storage |
|---------|----------|-----------|---------|
| Execution | 2-10 (HPA) | 200m-1000m CPU, 512Mi-1Gi RAM | - |
| Prometheus | 1 | 500m-2000m CPU, 2-4Gi RAM | 50Gi PVC |
| Grafana | 1 | 100-500m CPU, 256-512Mi RAM | 10Gi PVC |
| Alertmanager | 1 | 100-200m CPU, 128-256Mi RAM | - |

---

## 🌐 Access URLs

### Production (with DNS)
- Grafana: https://grafana.fks-trading.com
- Prometheus: https://prometheus.fks-trading.com (basic auth)
- Alertmanager: https://alertmanager.fks-trading.com (basic auth)

### Local (port-forward)
```bash
kubectl port-forward -n fks-trading svc/grafana 3000:3000
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
kubectl port-forward -n fks-trading svc/alertmanager 9093:9093
```

---

## ✅ Validation Commands

```bash
# Check all resources
kubectl get all -n fks-trading

# Check pods
kubectl get pods -n fks-trading

# Check PVCs
kubectl get pvc -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# Check certificates
kubectl get certificates -n fks-trading

# View logs
kubectl logs -n fks-trading -l app=fks-execution --tail=100
kubectl logs -n fks-trading -l app=prometheus --tail=100
kubectl logs -n fks-trading -l app=grafana --tail=100

# Execution service health
kubectl exec -n fks-trading deployment/fks-execution -- curl http://localhost:8000/health

# Prometheus health
kubectl exec -n fks-trading deployment/prometheus -- wget -qO- http://localhost:9090/-/healthy

# Grafana health
kubectl exec -n fks-trading deployment/grafana -- wget -qO- http://localhost:3000/api/health
```

---

## 🔧 Common Operations

### Scale Execution Service
```bash
# Manual scaling
kubectl scale deployment/fks-execution --replicas=5 -n fks-trading

# Check HPA status
kubectl get hpa -n fks-trading
```

### Update Image
```bash
kubectl set image deployment/fks-execution \
  execution=nuniesmith/fks:execution-v2 \
  -n fks-trading

# Check rollout
kubectl rollout status deployment/fks-execution -n fks-trading
```

### Rollback Deployment
```bash
# Rollback to previous version
kubectl rollout undo deployment/fks-execution -n fks-trading

# Rollback to specific revision
kubectl rollout undo deployment/fks-execution --to-revision=2 -n fks-trading
```

### Restart Services
```bash
kubectl rollout restart deployment/fks-execution -n fks-trading
kubectl rollout restart deployment/prometheus -n fks-trading
kubectl rollout restart deployment/grafana -n fks-trading
```

---

## 🐛 Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -n fks-trading

# Describe problem pod
kubectl describe pod -n fks-trading <pod-name>

# Check events
kubectl get events -n fks-trading --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n fks-trading <pod-name>
```

### PVC Not Binding
```bash
# Check PVC status
kubectl get pvc -n fks-trading

# Describe PVC
kubectl describe pvc prometheus-data -n fks-trading

# Check available PVs
kubectl get pv
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress -n fks-trading grafana-ingress

# Check cert-manager
kubectl get certificaterequests -n fks-trading
kubectl get certificates -n fks-trading
kubectl describe certificate -n fks-trading <cert-name>

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Metrics Not Appearing
```bash
# Check Prometheus targets
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
# Open: http://localhost:9090/targets

# Check service discovery
# Prometheus UI → Status → Service Discovery

# Verify pod annotations
kubectl get pod -n fks-trading -l app=fks-execution \
  -o jsonpath='{.items[0].metadata.annotations}'
```

---

## 📦 Backup & Restore

### Backup Prometheus Data
```bash
kubectl exec -n fks-trading deployment/prometheus -- \
  tar czf /tmp/prometheus-backup.tar.gz /prometheus

kubectl cp fks-trading/prometheus-pod:/tmp/prometheus-backup.tar.gz \
  ./prometheus-backup-$(date +%Y%m%d).tar.gz
```

### Backup Grafana Dashboards
```bash
kubectl exec -n fks-trading deployment/grafana -- \
  tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana

kubectl cp fks-trading/grafana-pod:/tmp/grafana-backup.tar.gz \
  ./grafana-backup-$(date +%Y%m%d).tar.gz
```

---

## 📈 Monitoring Stack URLs

### Prometheus
- Targets: http://localhost:9090/targets
- Rules: http://localhost:9090/rules
- Alerts: http://localhost:9090/alerts
- Config: http://localhost:9090/config

### Grafana
- Dashboard: http://localhost:3000/d/execution-pipeline
- Datasources: http://localhost:3000/datasources
- Explore: http://localhost:3000/explore

### Alertmanager
- Status: http://localhost:9093/#/status
- Alerts: http://localhost:9093/#/alerts
- Silences: http://localhost:9093/#/silences

---

## 🚨 Alert Channels

| Severity | Channel | Group Interval | Repeat Interval |
|----------|---------|----------------|-----------------|
| Critical | #fks-alerts-critical | Immediate | 12h |
| Warning | #fks-alerts-warnings | 5m | 4h |
| Info | #fks-alerts-info | 10m | 24h |

---

## 📚 Documentation

- Full Guide: `/docs/PHASE_5_COMPLETE.md`
- Phase 4 Monitoring: `/docs/PHASE_4_COMPLETE.md`
- Phase 3 Execution: `/docs/PHASE_3_COMPLETE.md`
- Copilot Instructions: `/.github/copilot-instructions.md`

---

## 🎯 Next Steps

1. **Deploy to minikube/kind** (local testing)
2. **Deploy to cloud K8s** (GKE/EKS/AKS)
3. **Configure DNS** for ingress hosts
4. **Set up Slack channels** for alerts
5. **Implement GitOps** (Flux/ArgoCD)
6. **Add distributed tracing** (Jaeger)
7. **Log aggregation** (ELK/Loki)

---

**Phase 5 Status**: ✅ Complete (100%)
