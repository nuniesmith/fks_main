# FKS Platform Kubernetes Testing Guide

## Overview
This guide covers testing the FKS Platform Kubernetes deployment locally before production.

## Prerequisites

### Local Kubernetes Cluster Options

**Option 1: Minikube** (Recommended for Linux)
```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start with sufficient resources
minikube start --cpus=6 --memory=16384 --disk-size=50g --driver=docker

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
```

**Option 2: Docker Desktop Kubernetes**
```bash
# Enable Kubernetes in Docker Desktop Settings
# Settings → Kubernetes → Enable Kubernetes
# Allocate: 6 CPUs, 16GB RAM
```

**Option 3: k3d** (Lightweight)
```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create cluster
k3d cluster create fks-test --servers 1 --agents 2 --port "8080:80@loadbalancer"
```

### Required Tools
```bash
# Verify installations
kubectl version --client
helm version
docker --version

# Install if missing
# kubectl: https://kubernetes.io/docs/tasks/tools/
# helm: https://helm.sh/docs/intro/install/
```

## Testing Phases

### Phase 1: Basic Deployment Test

#### 1.1 Start Local Cluster
```bash
# Using minikube
minikube start --cpus=6 --memory=16384 --disk-size=50g
minikube status

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

#### 1.2 Deploy FKS Platform (Development)
```bash
cd /home/jordan/Documents/fks/k8s

# Deploy with development values
./scripts/deploy.sh deploy --values charts/fks-platform/values-dev.yaml

# Or manual deployment
helm install fks-platform ./charts/fks-platform \
  -f charts/fks-platform/values-dev.yaml \
  --namespace fks-system \
  --create-namespace \
  --wait
```

#### 1.3 Verify Deployment
```bash
# Check all pods are running
kubectl get pods -n fks-system
kubectl get all -n fks-system

# Watch deployment progress
watch kubectl get pods -n fks-system

# Check pod logs for errors
kubectl logs -n fks-system -l app=fks-main --tail=100
kubectl logs -n fks-system -l app=fks-ai --tail=100
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
fks-main-xxxxxxxxxx-xxxxx         1/1     Running   0          2m
fks-api-xxxxxxxxxx-xxxxx          1/1     Running   0          2m
fks-app-xxxxxxxxxx-xxxxx          1/1     Running   0          2m
fks-ai-xxxxxxxxxx-xxxxx           1/1     Running   0          2m
fks-data-xxxxxxxxxx-xxxxx         1/1     Running   0          2m
fks-execution-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
fks-ninja-xxxxxxxxxx-xxxxx        1/1     Running   0          2m
fks-mt5-xxxxxxxxxx-xxxxx          1/1     Running   0          2m
fks-web-xxxxxxxxxx-xxxxx          1/1     Running   0          2m
postgresql-0                      1/1     Running   0          2m
redis-master-0                    1/1     Running   0          2m
```

### Phase 2: Health & Connectivity Tests

#### 2.1 Port Forwarding
```bash
# Forward main service
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &

# Forward API service
kubectl port-forward -n fks-system svc/fks-api 8001:8001 &

# Forward Web UI
kubectl port-forward -n fks-system svc/fks-web 3001:3001 &

# Forward AI service
kubectl port-forward -n fks-system svc/fks-ai 8007:8007 &

# Forward Grafana
kubectl port-forward -n fks-system svc/grafana 3000:3000 &
```

#### 2.2 Health Check Tests
```bash
# Check fks-main health
curl http://localhost:8000/health/
# Expected: {"status": "healthy", "services": {...}}

# Check fks-api health
curl http://localhost:8001/health/
# Expected: {"status": "ok"}

# Check fks-ai health
curl http://localhost:8007/health/
# Expected: {"status": "healthy", "agents": 7}

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana
open http://localhost:3000  # admin/admin (dev)
```

#### 2.3 Service-to-Service Communication
```bash
# Test from fks-main pod
kubectl exec -n fks-system -it deployment/fks-main -- curl fks-api:8001/health/
kubectl exec -n fks-system -it deployment/fks-main -- curl fks-data:8003/health/

# Test database connectivity
kubectl exec -n fks-system -it deployment/fks-main -- \
  python -c "import psycopg2; conn = psycopg2.connect('postgresql://fks_user:dev_password_change_me@postgresql:5432/fks_db'); print('DB OK')"

# Test Redis connectivity
kubectl exec -n fks-system -it deployment/fks-main -- \
  redis-cli -h redis-master -a dev_redis_password ping
```

### Phase 3: Functional Testing

#### 3.1 Database Migrations
```bash
# Run Django migrations
kubectl exec -n fks-system -it deployment/fks-main -- python manage.py migrate

# Verify migrations
kubectl exec -n fks-system -it deployment/fks-main -- python manage.py showmigrations
```

#### 3.2 AI Agent Testing
```bash
# Test AI agent endpoint
curl -X POST http://localhost:8007/api/v1/analyze/ \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "BTC/USD",
    "timeframe": "1h",
    "data": {"price": 50000, "volume": 1000}
  }'

# Check agent responses
kubectl logs -n fks-system -l app=fks-ai --tail=50 | grep -i "agent"
```

#### 3.3 Trading Signal Test
```bash
# Test signal generation
curl -X POST http://localhost:8000/api/v1/signals/ \
  -H "Content-Type: application/json" \
  -d '{
    "strategy": "test_strategy",
    "symbol": "BTC/USD",
    "timeframe": "1h"
  }'
```

#### 3.4 Run Application Tests
```bash
# Run pytest in container
kubectl exec -n fks-system -it deployment/fks-main -- \
  pytest tests/unit/ -v

# Run AI tests
kubectl exec -n fks-system -it deployment/fks-ai -- \
  pytest tests/unit/ -v
```

### Phase 4: Performance Testing

#### 4.1 Load Testing Setup
```bash
# Install k6 for load testing
sudo apt-get install k6  # or brew install k6

# Create load test script
cat > k8s/tests/load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },  // Ramp up
    { duration: '3m', target: 50 },  // Stay at 50 users
    { duration: '1m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p95<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],  // Less than 1% failures
  },
};

export default function() {
  let res = http.get('http://localhost:8000/health/');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
EOF
```

#### 4.2 Run Load Tests
```bash
# API load test
k6 run k8s/tests/load-test.js

# Monitor pod resources during test
watch kubectl top pods -n fks-system

# Check HPA scaling (if enabled)
watch kubectl get hpa -n fks-system
```

Expected metrics:
- p95 latency: <500ms
- Error rate: <1%
- CPU usage: <70% during sustained load
- Memory usage: Stable (no leaks)

### Phase 5: Resilience Testing

#### 5.1 Pod Failure Recovery
```bash
# Delete a pod and verify auto-recovery
kubectl delete pod -n fks-system -l app=fks-main
kubectl get pods -n fks-system -w  # Watch recovery

# Expected: New pod created within 30s
```

#### 5.2 Database Failover Test (if HA enabled)
```bash
# Delete primary DB pod
kubectl delete pod -n fks-system postgresql-0

# Verify automatic failover
kubectl get pods -n fks-system -l app=postgresql -w

# Test app connectivity during recovery
while true; do curl -s http://localhost:8000/health/ || echo "DOWN"; sleep 1; done
```

#### 5.3 Network Policy Test
```bash
# Try unauthorized access (should fail)
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl postgresql:5432

# Should timeout or be blocked by NetworkPolicy
```

### Phase 6: Monitoring & Alerting Tests

#### 6.1 Prometheus Metrics
```bash
# Port-forward Prometheus
kubectl port-forward -n fks-system svc/prometheus 9090:9090 &

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'

# Check all targets are up
curl 'http://localhost:9090/api/v1/targets' | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

Expected targets:
- fks-main: up
- fks-api: up
- fks-app: up
- fks-ai: up
- fks-data: up
- fks-execution: up
- postgresql: up
- redis: up

#### 6.2 Grafana Dashboards
```bash
# Access Grafana
kubectl port-forward -n fks-system svc/grafana 3000:3000 &
open http://localhost:3000

# Login: admin / admin (dev)
# Verify dashboards:
# - FKS Platform Overview
# - Service Metrics
# - Database Performance
# - AI Agent Performance
```

#### 6.3 Alert Testing
```bash
# Trigger high CPU alert (stress test)
kubectl exec -n fks-system -it deployment/fks-main -- \
  sh -c 'for i in $(seq 1 4); do (yes > /dev/null &); done'

# Check Prometheus alerts
curl 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts'

# Expected: HighCPUUsage alert after 5 min

# Clean up stress
kubectl delete pod -n fks-system -l app=fks-main
```

### Phase 7: Security Testing

#### 7.1 Pod Security
```bash
# Verify non-root execution
kubectl get pod -n fks-system -o json | \
  jq -r '.items[] | select(.spec.securityContext.runAsNonRoot == true) | .metadata.name'

# Verify read-only filesystem
kubectl get pod -n fks-system -o json | \
  jq -r '.items[] | select(.spec.containers[0].securityContext.readOnlyRootFilesystem == true) | .metadata.name'
```

#### 7.2 Network Policy Validation
```bash
# Deploy test pod in different namespace
kubectl create ns test
kubectl run test-pod -n test --image=curlimages/curl -- sleep 3600

# Try to access FKS services (should be blocked)
kubectl exec -n test test-pod -- curl fks-api.fks-system:8001 --max-time 5
# Expected: timeout or connection refused

# Cleanup
kubectl delete ns test
```

#### 7.3 Secret Security
```bash
# Verify secrets are not in plaintext
kubectl get secrets -n fks-system -o yaml | grep -i password
# Should see base64 encoded values only

# Verify secret permissions
kubectl auth can-i get secrets -n fks-system --as=system:serviceaccount:default:default
# Expected: no
```

### Phase 8: Backup & Recovery Tests

#### 8.1 Database Backup Test
```bash
# Trigger manual backup
kubectl create job -n fks-system --from=cronjob/postgresql-backup manual-backup-$(date +%s)

# Wait for completion
kubectl wait -n fks-system --for=condition=complete --timeout=300s job/manual-backup-*

# Verify backup file
kubectl exec -n fks-system -it deployment/fks-main -- \
  ls -lh /backups/postgresql/
```

#### 8.2 Database Restore Test
```bash
# Create test data
kubectl exec -n fks-system -it postgresql-0 -- \
  psql -U fks_user -d fks_db -c "CREATE TABLE test_table (id SERIAL, data TEXT);"

# Perform backup
kubectl create job -n fks-system --from=cronjob/postgresql-backup restore-test-backup

# Delete test data
kubectl exec -n fks-system -it postgresql-0 -- \
  psql -U fks_user -d fks_db -c "DROP TABLE test_table;"

# Restore from backup
BACKUP_FILE=$(kubectl exec -n fks-system -it deployment/fks-main -- ls -t /backups/postgresql/*.sql.gz | head -1)
kubectl exec -n fks-system -it postgresql-0 -- \
  sh -c "gunzip -c $BACKUP_FILE | psql -U fks_user -d fks_db"

# Verify restoration
kubectl exec -n fks-system -it postgresql-0 -- \
  psql -U fks_user -d fks_db -c "\dt test_table"
# Expected: test_table exists
```

## Cleanup

### Remove Test Deployment
```bash
# Uninstall Helm release
helm uninstall fks-platform -n fks-system

# Delete namespace
kubectl delete namespace fks-system

# Or use deploy script
./k8s/scripts/deploy.sh destroy
```

### Stop Local Cluster
```bash
# Minikube
minikube stop
minikube delete

# k3d
k3d cluster delete fks-test

# Docker Desktop
# Disable Kubernetes in Settings
```

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod -n fks-system <pod-name>

# Check logs
kubectl logs -n fks-system <pod-name> --previous

# Common issues:
# - ImagePullBackOff: Image doesn't exist or registry auth needed
# - CrashLoopBackOff: Application error, check logs
# - Pending: Resource constraints or PVC issues
```

### Service Connectivity Issues
```bash
# Check service endpoints
kubectl get endpoints -n fks-system

# Test DNS resolution
kubectl run -n fks-system test-dns --rm -it --image=busybox -- nslookup fks-api

# Check network policies
kubectl get networkpolicies -n fks-system
kubectl describe networkpolicy -n fks-system fks-platform
```

### Database Connection Errors
```bash
# Verify PostgreSQL is ready
kubectl exec -n fks-system postgresql-0 -- pg_isready

# Test connection string
kubectl exec -n fks-system -it deployment/fks-main -- \
  psql postgresql://fks_user:dev_password_change_me@postgresql:5432/fks_db -c '\l'

# Check PostgreSQL logs
kubectl logs -n fks-system postgresql-0 --tail=100
```

### Performance Issues
```bash
# Check resource usage
kubectl top pods -n fks-system
kubectl top nodes

# Describe resource limits
kubectl describe pod -n fks-system <pod-name> | grep -A 5 "Limits:"

# Check HPA status
kubectl describe hpa -n fks-system
```

## Success Criteria

### ✅ Deployment Success
- [ ] All pods running (9 services + 2 databases)
- [ ] No CrashLoopBackOff or ImagePullBackOff
- [ ] All health endpoints return 200 OK
- [ ] Database migrations completed
- [ ] All 282 tests passing in containers

### ✅ Performance Success
- [ ] API p95 latency <500ms
- [ ] Error rate <1% under load
- [ ] Pod auto-recovery <30s
- [ ] HPA scaling working (if enabled)

### ✅ Monitoring Success
- [ ] All Prometheus targets up
- [ ] Grafana dashboards loading
- [ ] Alerts can be triggered
- [ ] ServiceMonitors scraping metrics

### ✅ Security Success
- [ ] Pods running as non-root
- [ ] Network policies blocking unauthorized access
- [ ] Secrets not in plaintext
- [ ] Pod Security Policies enforced

### ✅ Backup Success
- [ ] Backup CronJob created
- [ ] Manual backup completes successfully
- [ ] Restore from backup works
- [ ] 30-day retention enforced

## Next Steps

After successful testing:

1. **Build Docker Images**
   ```bash
   cd /home/jordan/Documents/fks
   make docker-build
   make docker-push
   ```

2. **Update Image Tags**
   ```bash
   # Edit values-prod.yaml with real image tags
   vim k8s/charts/fks-platform/values-prod.yaml
   ```

3. **Deploy to Production**
   ```bash
   ./k8s/scripts/deploy.sh deploy --values charts/fks-platform/values-prod.yaml
   ```

4. **Setup CI/CD**
   - GitHub Actions for automated testing
   - ArgoCD for GitOps deployment

5. **Proceed to Phase 8.2**
   - Auto-scaling optimization
   - Performance tuning
   - Multi-region deployment
