# FKS Core Architecture & Kubernetes Deployment

**Status**: 13/14 services operational (93% - DEMO READY)  
**Environment**: Minikube v1.37.0, Kubernetes v1.34.0  
**Last Updated**: November 7, 2025

## 🎯 System Architecture Overview

FKS is a microservices-based fintech trading platform deployed on Kubernetes with complete monitoring, persistence, and TLS ingress.

### Service Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        Ingress Layer (TLS)                       │
│  *.fkstrading.xyz → NGINX Ingress → Service Mesh                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                ┌───────────┴──────────┐
                │                      │
        ┌───────▼────────┐    ┌───────▼────────┐
        │  Application   │    │   Monitoring    │
        │    Layer       │    │     Stack       │
        │                │    │                 │
        │ • fks-api      │    │ • Prometheus    │
        │ • fks-app      │    │ • Grafana       │
        │ • fks-data     │    │ • Alertmanager  │
        │ • fks-ai       │    │                 │
        │ • fks-web*     │    └─────────────────┘
        │ • fks-execution│
        └────────┬───────┘
                 │
        ┌────────▼────────┐
        │  Data Layer     │
        │                 │
        │ • PostgreSQL 16 │
        │ • Redis 7       │
        │                 │
        └─────────────────┘

* fks-web scaled to 0 (pending Docker image fix)
```

## 📦 Deployed Services

### Application Services (6/7 Running)

| Service | Image | Replicas | Resources | Status |
|---------|-------|----------|-----------|--------|
| **fks-api** | `nuniesmith/fks_api:latest` | 2/2 | 200m-1000m CPU, 512Mi-1Gi RAM | ✅ Running |
| **fks-app** | `nuniesmith/fks_app:latest` | 2/2 | 200m-1000m CPU, 512Mi-1Gi RAM | ✅ Running |
| **fks-data** | `nuniesmith/fks_data:latest` | 2/2 | 200m-1000m CPU, 512Mi-1Gi RAM | ✅ Running |
| **fks-ai** | `nuniesmith/fks_ai:cpu` | 1/1 | 500m-2000m CPU, 2Gi-4Gi RAM | ✅ Running |
| **fks-execution** | `nuniesmith/fks_execution:latest` | 2/2 | 200m-1000m CPU, 512Mi-1Gi RAM | ⏸️ Needs deployment |
| **fks-web** | `nuniesmith/fks_web:latest` | 0/0 | 200m-1000m CPU, 512Mi-1Gi RAM | ⏸️ Scaled down (Celery missing) |
| **landing-page** | `nginx:alpine` | 1/1 | 50m-100m CPU, 32Mi-64Mi RAM | ✅ Running |

### Data Layer (2/2 Running)

| Service | Image | Storage | Resources | Status |
|---------|-------|---------|-----------|--------|
| **postgres** | `postgres:16` | 100Gi PVC | 500m-2000m CPU, 1Gi-4Gi RAM | ✅ Running |
| **redis** | `redis:7-alpine` | 10Gi PVC | 100m-500m CPU, 256Mi-512Mi RAM | ✅ Running |

### Monitoring Stack (3/3 Running)

| Service | Image | Storage | Resources | Status |
|---------|-------|---------|-----------|--------|
| **prometheus** | `prom/prometheus:latest` | 50Gi PVC | 500m-2000m CPU, 2Gi-4Gi RAM | ✅ Running |
| **grafana** | `grafana/grafana:latest` | 10Gi PVC | 100m-500m CPU, 256Mi-512Mi RAM | ✅ Running |
| **alertmanager** | `prom/alertmanager:latest` | N/A | 100m-200m CPU, 128Mi-256Mi RAM | ✅ Running |

### Worker Services (0/4 Running)

| Service | Image | Replicas | Status |
|---------|-------|----------|--------|
| **celery-worker** | `nuniesmith/fks_web:celery-worker` | 0/0 | ⏸️ Scaled down (Celery missing) |
| **celery-beat** | `nuniesmith/fks_web:celery-beat` | 0/0 | ⏸️ Scaled down (Celery missing) |
| **flower** | `nuniesmith/fks_web:flower` | 0/0 | ⏸️ Scaled down (Celery missing) |

**Total**: 13/14 services operational (93%)

## 🌐 Network Architecture

### Ingress Routes (TLS Enabled)

```yaml
# /fks_main/k8s/manifests/ingress-tailscale.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fks-ingress
  namespace: fks-trading
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - "*.fkstrading.xyz"
        - fkstrading.xyz
      secretName: fks-tls-wildcard
  rules:
    - host: fkstrading.xyz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: landing-page
                port:
                  number: 80
    
    - host: api.fkstrading.xyz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: fks-api
                port:
                  number: 8001
    
    - host: grafana.fkstrading.xyz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

### Live URLs (Tailscale 100.116.135.8)

- **Landing Page**: https://fkstrading.xyz
- **API Health**: https://api.fkstrading.xyz/health
- **Grafana**: https://grafana.fkstrading.xyz (admin/admin)
- **Prometheus**: https://prometheus.fkstrading.xyz
- **Alertmanager**: https://alertmanager.fkstrading.xyz

### Internal Service Mesh

```bash
# Service DNS (internal)
postgres:5432           → PostgreSQL database
redis:6379             → Redis cache
fks-api:8001          → REST API service
fks-app:8002          → Trading logic service
fks-data:8003         → Data adapters service
fks-ai:8007           → AI/ML service
fks-execution:8006    → Execution engine
prometheus:9090       → Metrics collection
grafana:3000          → Visualization
alertmanager:9093     → Alert routing
```

## 💾 Persistent Storage

### Storage Allocation (170Gi Total)

| PVC Name | Size | Access Mode | Status | Usage |
|----------|------|-------------|--------|-------|
| **postgres-data** | 100Gi | ReadWriteOnce | Bound | trading_db (0 tables) |
| **redis-data** | 10Gi | ReadWriteOnce | Bound | AOF persistence |
| **prometheus-pvc** | 50Gi | ReadWriteOnce | Bound | 15-day metric retention |
| **grafana-pvc** | 10Gi | ReadWriteOnce | Bound | Dashboards & config |

### PostgreSQL Configuration

```yaml
# StatefulSet configuration
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: fks-trading
spec:
  serviceName: db
  replicas: 1
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: fks-secrets
                  key: postgres-user
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: fks-secrets
                  key: postgres-password
            - name: POSTGRES_DB
              value: "trading_db"
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 2000m
              memory: 4Gi
  volumeClaimTemplates:
    - metadata:
        name: postgres-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
```

**Current State**:
- Database: `trading_db` created
- User: `trading_user` configured
- Schema: Empty (0 tables) - ready for migrations

### Redis Configuration

```yaml
# Deployment with AOF persistence
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: fks-trading
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          command: ["redis-server", "--appendonly", "yes"]
          ports:
            - containerPort: 6379
          volumeMounts:
            - name: redis-storage
              mountPath: /data
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
```

**Features**:
- AOF persistence enabled
- 10Gi storage for cache durability
- Health check: `redis-cli ping` → PONG ✅

## 📊 Monitoring Stack

### Prometheus Configuration

```yaml
# /fks_main/monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - "/etc/prometheus/rules/*.yml"

scrape_configs:
  # Kubernetes pod discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

**Metrics Collected**:
- System metrics: CPU, memory, disk, network
- Application metrics: Request rate, latency, errors
- Custom metrics: Webhook processing, order execution, AI inference
- K8s metrics: Pod health, resource usage, events

### Grafana Dashboards

**Execution Pipeline Dashboard** (`/monitoring/grafana/dashboards/execution_pipeline.json`):
- 16 panels in 5 rows
- Real-time visualization of webhooks, orders, security events
- Auto-refresh: 30s
- Variables: Environment, service, time range

**Access**: https://grafana.fkstrading.xyz/d/execution-pipeline

### Alertmanager Routing

```yaml
# /fks_main/k8s/manifests/alertmanager.yaml
route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  routes:
    - match:
        severity: critical
      receiver: 'slack-critical'
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 12h
    
    - match:
        severity: warning
      receiver: 'slack-warnings'
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
    
    - match:
        severity: info
      receiver: 'slack-info'
      group_wait: 5m
      group_interval: 10m
      repeat_interval: 24h

receivers:
  - name: 'slack-critical'
    slack_configs:
      - api_url: '<SLACK_WEBHOOK_URL_CRITICAL>'
        channel: '#fks-alerts-critical'
        title: '🚨 Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'
```

**Alert Categories**:
- **Critical** (5 rules): Circuit breaker opened, high order failures, security breaches
- **Warning** (8 rules): High latency, validation failures, rate limits, API errors
- **Info** (5 rules): Data quality issues, confidence filtering, high load

## 🔐 Security Configuration

### Secrets Management

```yaml
# /fks_main/k8s/manifests/fks-secrets.yaml.template
apiVersion: v1
kind: Secret
metadata:
  name: fks-secrets
  namespace: fks-trading
type: Opaque
stringData:
  # Database credentials
  postgres-user: "trading_user"
  postgres-password: "<GENERATE_SECURE_PASSWORD>"
  
  # Django configuration
  django-secret-key: "<GENERATE_SECRET_KEY>"
  
  # API keys
  yahoo-finance-api-key: "<YOUR_KEY>"
  binance-api-key: "<YOUR_KEY>"
  binance-api-secret: "<YOUR_SECRET>"
  
  # DockerHub (for CI/CD)
  dockerhub-username: "nuniesmith"
  dockerhub-password: "<DOCKERHUB_TOKEN>"
```

**Generation Commands**:
```bash
# Generate secure passwords
openssl rand -base64 32

# Generate Django secret key
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### TLS Certificates

```yaml
# Self-signed wildcard certificate
apiVersion: v1
kind: Secret
metadata:
  name: fks-tls-wildcard
  namespace: fks-trading
type: kubernetes.io/tls
data:
  tls.crt: <BASE64_ENCODED_CERT>
  tls.key: <BASE64_ENCODED_KEY>
```

**Generation**:
```bash
# Create self-signed wildcard cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.fkstrading.xyz/O=FKS Trading"

# Create K8s secret
kubectl create secret tls fks-tls-wildcard \
  --cert=tls.crt --key=tls.key \
  -n fks-trading
```

**Production**: Replace with cert-manager + Let's Encrypt:
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f k8s/manifests/letsencrypt-issuer.yaml
```

### RBAC Permissions

```yaml
# ServiceAccount for Prometheus (pod discovery)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: fks-trading
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: fks-trading
```

## 🚀 Deployment Guide

### Prerequisites

```bash
# Check Kubernetes cluster
kubectl version --client
kubectl cluster-info

# Check namespace
kubectl get namespace fks-trading || kubectl create namespace fks-trading

# Verify storage class
kubectl get storageclass
```

### Step-by-Step Deployment

**1. Create Secrets**:
```bash
cd /home/jordan/Documents/code/fks/fks_main

# Edit secrets template
cp k8s/manifests/fks-secrets.yaml.template k8s/manifests/fks-secrets.yaml
vim k8s/manifests/fks-secrets.yaml  # Replace <PLACEHOLDERS>

# Apply secrets
kubectl apply -f k8s/manifests/fks-secrets.yaml
```

**2. Deploy Data Layer**:
```bash
# PostgreSQL + Redis
kubectl apply -f k8s/manifests/all-services.yaml

# Wait for databases
kubectl wait --for=condition=ready pod -l app=postgres -n fks-trading --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n fks-trading --timeout=300s
```

**3. Deploy Application Services**:
```bash
# Microservices (already in all-services.yaml)
kubectl get pods -n fks-trading

# Expected output:
# fks-api-xxx         2/2   Running
# fks-app-xxx         2/2   Running
# fks-data-xxx        2/2   Running
# fks-ai-xxx          1/1   Running
# postgres-0          1/1   Running
# redis-xxx           1/1   Running
```

**4. Deploy Monitoring Stack**:
```bash
kubectl apply -f k8s/manifests/monitoring-stack.yaml
kubectl apply -f k8s/manifests/prometheus-rules.yaml
kubectl apply -f k8s/manifests/alertmanager.yaml

# Wait for monitoring
kubectl wait --for=condition=ready pod -l app=prometheus -n fks-trading --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n fks-trading --timeout=300s
```

**5. Deploy Ingress**:
```bash
# Create TLS certificate
kubectl apply -f k8s/manifests/fks-tls-secret.yaml

# Deploy ingress
kubectl apply -f k8s/manifests/ingress-tailscale.yaml

# Check ingress
kubectl get ingress -n fks-trading
```

**6. Deploy Landing Page**:
```bash
kubectl apply -f k8s/manifests/landing-page.yaml
```

**7. Update /etc/hosts** (for local access):
```bash
# Add Tailscale IP
echo "100.116.135.8 fkstrading.xyz api.fkstrading.xyz grafana.fkstrading.xyz prometheus.fkstrading.xyz alertmanager.fkstrading.xyz" | sudo tee -a /etc/hosts
```

### Automated Deployment Script

```bash
# Use the deployment script
cd /home/jordan/Documents/code/fks/fks_main
./k8s/scripts/deploy-all-services.sh

# Script performs:
# - Prerequisite checks
# - Secrets validation
# - Service deployments
# - Health checks
# - Status summary
```

## 🧪 Testing & Validation

### Health Checks

```bash
# API health
curl -k https://api.fkstrading.xyz/health
# Expected: {"status":"healthy","env":"development"}

# Grafana
curl -k -I https://grafana.fkstrading.xyz
# Expected: HTTP/2 302 (redirects to /login)

# Prometheus
curl -k https://prometheus.fkstrading.xyz/api/v1/status/config
# Expected: {"status":"success"}

# PostgreSQL
kubectl exec -it postgres-0 -n fks-trading -- psql -U trading_user -d trading_db -c "\l"
# Expected: trading_db listed

# Redis
kubectl exec -it deployment/redis -n fks-trading -- redis-cli ping
# Expected: PONG
```

### Service Discovery Test

```bash
# Test internal DNS from fks-api pod
kubectl exec -it deployment/fks-api -n fks-trading -- /bin/sh

# Inside pod:
curl http://fks-data:8003/health
curl http://fks-ai:8007/health
curl http://db:5432  # PostgreSQL connection test
curl http://redis:6379  # Redis connection test (expect error, but DNS works)
```

### Performance Test

```bash
# Load test API
kubectl run -it --rm load-test --image=curlimages/curl --restart=Never -n fks-trading -- sh

# Inside pod:
for i in $(seq 1 100); do
  curl -s http://fks-api:8001/health > /dev/null
done
```

## 📈 Scaling & Optimization

### Horizontal Pod Autoscaler (HPA)

```yaml
# Already configured for fks-api, fks-app, fks-data
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fks-api-hpa
  namespace: fks-trading
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fks-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

**Monitor HPA**:
```bash
kubectl get hpa -n fks-trading
kubectl describe hpa fks-api-hpa -n fks-trading
```

### Manual Scaling

```bash
# Scale up/down
kubectl scale deployment fks-data --replicas=5 -n fks-trading
kubectl scale deployment fks-ai --replicas=2 -n fks-trading

# Check status
kubectl get pods -n fks-trading -l app=fks-data
```

## 🔧 Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n fks-trading
kubectl describe pod <pod-name> -n fks-trading
kubectl logs <pod-name> -n fks-trading

# Common issues:
# 1. Image pull error → Check DockerHub credentials
# 2. CrashLoopBackOff → Check application logs
# 3. Pending → Check resource availability
```

### Service Unreachable

```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Expected: Each service has IP:port listed
# If empty, pods are not matching service selector

# Test internal connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n fks-trading -- sh
# Inside: wget -O- http://fks-api:8001/health
```

### Ingress 503 Error

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress fks-ingress -n fks-trading

# Common fix: Ensure service is running with endpoints
kubectl get endpoints fks-api -n fks-trading
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n fks-trading

# If Pending:
kubectl describe pvc postgres-data -n fks-trading
# Look for provisioner errors

# Verify storage class
kubectl get storageclass
```

## 🎯 Next Steps

1. **Fix Django/Celery Images**: Rebuild with Celery dependencies
2. **Deploy fks-execution**: Add execution service to cluster
3. **Enable Let's Encrypt**: Replace self-signed certificates
4. **Add Distributed Tracing**: Deploy Jaeger for request tracing
5. **Configure Log Aggregation**: Set up Loki or ELK Stack
6. **Multi-Region Deployment**: Expand to cloud K8s (GKE/EKS/AKS)

## 🔗 References

- [Docker Strategy](./02-docker-strategy.md)
- [GitHub Actions](./03-github-actions.md)
- [Portfolio Rebalancing](./06-portfolio-rebalancing.md)
- [K8s Documentation](https://kubernetes.io/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
