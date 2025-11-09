# FKS Full Stack Deployment - Quick Reference

## 🚀 Deploy Everything (One Command)

```bash
cd /home/jordan/Documents/code/fks

# Build images + Deploy to K8s
./scripts/build-docker-images.sh && ./k8s/scripts/deploy-all-services.sh

# In separate terminal: Enable external access
minikube tunnel  # (keep running, requires sudo password)
```

## 📊 Access URLs (via Tailscale 100.116.135.8)

| Service | URL | Purpose |
|---------|-----|---------|
| **Web UI** | <https://fkstrading.xyz> | Main trading interface |
| **API** | <https://api.fkstrading.xyz> | REST API |
| **Grafana** | <https://grafana.fkstrading.xyz> | Monitoring dashboards |
| **Prometheus** | <https://prometheus.fkstrading.xyz> | Metrics |
| **Alertmanager** | <https://alertmanager.fkstrading.xyz> | Alerts |
| **Flower** | <https://flower.fkstrading.xyz> | Celery tasks |
| **Execution** | <https://execution.fkstrading.xyz> | Order webhooks |

**Note**: Accept self-signed cert warnings (or install `/tmp/fks-certs/tls.crt`)

## 🔑 Default Credentials

| Service | User | Password |
|---------|------|----------|
| Grafana | admin | admin (change on first login) |
| PostgreSQL | trading_user | (from secrets) |
| Django Admin | (create with manage.py) | - |

## 🛠️ Common Commands

### Check Status

```bash
# All pods
kubectl get pods -n fks-trading

# Services
kubectl get svc -n fks-trading

# Ingress
kubectl get ingress -n fks-trading

# Storage
kubectl get pvc -n fks-trading

# Watch logs
kubectl logs -f deployment/fks-web -n fks-trading
```

### Port Forwarding (Alternative to Ingress)

```bash
# Use helper
/tmp/fks-port-forward.sh

# Or manual
kubectl port-forward -n fks-trading svc/web 8000:8000
kubectl port-forward -n fks-trading svc/grafana 3000:3000
# Access: http://localhost:8000, http://localhost:3000
```

### Restart Services

```bash
# Restart deployment
kubectl rollout restart deployment/fks-web -n fks-trading

# Restart all
kubectl rollout restart deployment -n fks-trading
```

### Scale Services

```bash
# Scale up
kubectl scale deployment fks-web --replicas=4 -n fks-trading

# Scale down
kubectl scale deployment fks-api --replicas=1 -n fks-trading
```

### Database Access

```bash
# PostgreSQL shell
kubectl exec -it -n fks-trading postgres-0 -- psql -U trading_user -d trading_db

# Redis CLI
kubectl exec -it -n fks-trading deployment/redis -- redis-cli

# Backup database
kubectl exec -n fks-trading postgres-0 -- pg_dump -U trading_user trading_db > backup.sql
```

### Update Service

```bash
# Build new image
docker build -f docker/Dockerfile -t nuniesmith/fks:web-v2 .
minikube image load nuniesmith/fks:web-v2

# Update deployment
kubectl set image deployment/fks-web web=nuniesmith/fks:web-v2 -n fks-trading

# Watch rollout
kubectl rollout status deployment/fks-web -n fks-trading
```

## 🐛 Troubleshooting

### Pods Not Running

```bash
# Describe pod
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading

# Check init container (migrations)
kubectl logs <pod-name> -c migrate -n fks-trading

# Delete and recreate
kubectl delete pod <pod-name> -n fks-trading
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify tunnel is running
minikube tunnel  # (must stay running)

# Test DNS
ping fkstrading.xyz  # Should resolve to 100.116.135.8

# Check /etc/hosts
grep fkstrading /etc/hosts
```

### Image Not Found

```bash
# Check minikube images
minikube image ls | grep fks

# Load image
docker build -t nuniesmith/fks:web-latest .
minikube image load nuniesmith/fks:web-latest

# Restart deployment
kubectl rollout restart deployment/fks-web -n fks-trading
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
kubectl get pods -n fks-trading -l app=postgres

# Check secrets exist
kubectl get secret fks-secrets -n fks-trading

# Test connection
kubectl run -it --rm psql-test --image=postgres:16 -n fks-trading -- \
  psql -h db -U trading_user -d trading_db
```

## 📦 Services Architecture

```text
14 services deployed in fks-trading namespace:

Stateful:
- postgres (StatefulSet, 100Gi PVC)
- redis (Deployment, 10Gi PVC)

Web/API:
- fks-web (2 replicas, Gunicorn 4 workers)
- fks-api (2 replicas)
- fks-app (2 replicas)
- fks-data (2 replicas)
- fks-ai (1 replica, 2-4Gi RAM)
- fks-execution (1 replica)

Background:
- celery-worker (2 replicas)
- celery-beat (1 replica)
- flower (1 replica, Celery UI)

Monitoring:
- prometheus (1 replica, 50Gi PVC)
- grafana (1 replica, 10Gi PVC)
- alertmanager (1 replica)
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `/k8s/manifests/all-services.yaml` | All service definitions |
| `/k8s/manifests/fks-secrets.yaml.template` | Secrets template |
| `/k8s/manifests/ingress-tailscale.yaml` | Tailscale ingress config |
| `/k8s/scripts/deploy-all-services.sh` | Deployment automation |
| `/scripts/build-docker-images.sh` | Docker build automation |
| `/docs/FULL_STACK_DEPLOYMENT.md` | Complete documentation |

## ⚡ Performance Tuning

### Resource Limits

```bash
# Edit deployment
kubectl edit deployment fks-ai -n fks-trading

# Update resources section:
resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"
```

### Database Tuning

```bash
# Edit postgres StatefulSet
kubectl edit statefulset postgres -n fks-trading

# Add to postgres args:
- -c
- shared_buffers=2GB
- -c
- effective_cache_size=6GB
- -c
- max_connections=200
```

## 🔐 Production Security

```bash
# Generate strong Django secret
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Generate strong DB password
openssl rand -base64 32

# Update secrets
kubectl create secret generic fks-secrets \
  --from-literal=postgres-user=trading_user \
  --from-literal=postgres-password="<strong-password>" \
  --from-literal=django-secret-key="<django-key>" \
  -n fks-trading \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart all to pick up new secrets
kubectl rollout restart deployment -n fks-trading
kubectl rollout restart statefulset -n fks-trading
```

## 📊 Monitoring Quick Access

```bash
# Prometheus queries
https://prometheus.fkstrading.xyz/graph
# Example: rate(http_requests_total[5m])

# Grafana dashboards
https://grafana.fkstrading.xyz/dashboards
# Import: /monitoring/grafana/dashboards/execution_pipeline.json

# Flower tasks
https://flower.fkstrading.xyz/tasks
# View: Running, Scheduled, Completed tasks

# Alertmanager alerts
https://alertmanager.fkstrading.xyz/#/alerts
# View: Active, Silenced alerts
```

## 🔄 Backup & Restore

### PostgreSQL Backup

```bash
# Full backup
kubectl exec -n fks-trading postgres-0 -- \
  pg_dump -U trading_user -Fc trading_db > fks-backup-$(date +%Y%m%d).dump

# Restore
cat fks-backup-20251106.dump | \
  kubectl exec -i -n fks-trading postgres-0 -- \
  pg_restore -U trading_user -d trading_db --clean
```

### Redis Backup

```bash
# Trigger save
kubectl exec -n fks-trading deployment/redis -- redis-cli SAVE

# Copy dump
kubectl cp fks-trading/redis-xxx:/data/dump.rdb ./redis-backup.rdb
```

## 🚨 Emergency Procedures

### Full Cluster Restart

```bash
# Stop all
kubectl scale deployment --all --replicas=0 -n fks-trading

# Start database first
kubectl scale statefulset postgres --replicas=1 -n fks-trading
# Wait 30s

# Start services
kubectl scale deployment --all --replicas=1 -n fks-trading

# Scale up replicas
kubectl scale deployment fks-web --replicas=2 -n fks-trading
kubectl scale deployment fks-api --replicas=2 -n fks-trading
# etc.
```

### Clean Slate

```bash
# Delete everything (DESTRUCTIVE!)
kubectl delete namespace fks-trading

# Re-deploy
./k8s/scripts/deploy-all-services.sh
```

---

**Last Updated**: November 6, 2025  
**Doc**: `/home/jordan/Documents/code/fks/docs/FULL_STACK_DEPLOYMENT.md`  
**Quick Ref**: `/home/jordan/Documents/code/fks/docs/FULL_STACK_QUICKREF.md`
