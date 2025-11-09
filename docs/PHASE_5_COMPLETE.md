# Phase 5 Complete - Production Deployment

**Date**: November 5, 2025  
**Status**: ✅ Complete (100%)  
**Deployment Target**: Kubernetes

---

## Overview

Phase 5 successfully prepares the FKS Trading Platform for production deployment on Kubernetes. This phase creates all necessary manifests, configurations, and deployment scripts to run the execution pipeline with full monitoring stack in a production-ready Kubernetes environment.

---

## What Was Built

###  1. Execution Service Deployment ✅

**File**: `/k8s/manifests/execution-service.yaml` (280 lines)

**Components**:
- **ConfigMap**: Execution pipeline configuration (confidence thresholds, rate limits, circuit breaker settings)
- **Service**: ClusterIP service exposing ports 8000 (HTTP) and 9090 (metrics)
- **Deployment**: 2 replicas with rolling updates, health probes, security context
- **ServiceAccount**: RBAC for execution service
- **HorizontalPodAutoscaler**: Auto-scaling 2-10 pods based on CPU (70%) and memory (80%)

**Key Features**:
- Prometheus scrape annotations
- Environment variables from ConfigMaps and Secrets
- Resource requests/limits (200m CPU, 512Mi RAM → 1000m CPU, 1Gi RAM)
- Liveness probe: `/health` endpoint
- Readiness probe: `/ready` endpoint
- Security: runAsNonRoot, readOnlyRootFilesystem, no privilege escalation
- Pod anti-affinity for high availability

### 2. Monitoring Stack ✅

**File**: `/k8s/manifests/monitoring-stack.yaml` (450 lines)

**Prometheus**:
- PersistentVolumeClaim: 50Gi for metrics storage (15-day retention)
- ConfigMap: Full prometheus.yml with Kubernetes service discovery
- Deployment: 1 replica with 2Gi-4Gi RAM
- Service: ClusterIP on port 9090
- ServiceAccount + ClusterRole + ClusterRoleBinding for K8s API access
- Automatic pod discovery via annotations

**Grafana**:
- PersistentVolumeClaim: 10Gi for dashboards/config
- ConfigMap: Datasource configuration (Prometheus)
- ConfigMap: Dashboard provisioning configuration
- Deployment: 1 replica with 256Mi-512Mi RAM
- Service: ClusterIP on port 3000
- Admin credentials from secrets
- Dashboard auto-loading from ConfigMap

**Features**:
- Persistent storage for metrics and dashboards
- Kubernetes service discovery for automatic scraping
- Health probes for both services
- Resource limits to prevent overconsumption

### 3. Alert Rules ✅

**File**: `/k8s/manifests/prometheus-rules.yaml` (200 lines)

**Alert Rules Configured** (10+ critical alerts):
- `HighWebhookLatency` - P95 >100ms for 5 minutes
- `WebhookValidationFailureRate` - >10% failures for 3 minutes
- `WebhookSignatureFailures` - Any signature failures for 1 minute
- `HighOrderFailureRate` - >10% order failures for 5 minutes
- `CircuitBreakerOpened` - Circuit breaker in OPEN state
- `HighRateLimitRejections` - >100 rejections/sec for 5 minutes
- `IPWhitelistRejections` - >50 rejections/sec for 5 minutes
- `HighNaNReplacementRate` - >10 NaN/sec for 5 minutes
- `HighExchangeAPILatency` - Average >1s for 5 minutes
- `ExchangeConnectionLoss` - Zero connections for 2 minutes

**Alert Metadata**:
- Severity levels: critical, warning, info
- Category labels: performance, security, data_quality, trading, availability
- Detailed descriptions with recommended actions
- Structured for Alertmanager routing

### 4. Alertmanager ✅

**File**: `/k8s/manifests/alertmanager.yaml` (180 lines)

**Configuration**:
- Slack integration with 3 channels:
  - `#fks-alerts-critical` - Critical alerts (immediate)
  - `#fks-alerts-warnings` - Warning alerts (grouped every 5m)
  - `#fks-alerts-info` - Info alerts (grouped every 10m)
- Routing tree with severity-based routing
- Inhibition rules (critical inhibits warning for same alert)
- Group by: alertname, cluster, service
- Repeat intervals: 12h (critical), 4h (warning), 24h (info)

**Deployment**:
- Service: ClusterIP on port 9093
- Deployment: 1 replica with 128Mi-256Mi RAM
- Slack webhook URL from secrets
- Template support for custom notification formatting

### 5. Ingress with TLS ✅

**File**: `/k8s/manifests/ingress.yaml` (150 lines)

**Ingress Resources**:
1. **Grafana Ingress**:
   - Host: `grafana.fks-trading.com`
   - TLS certificate via cert-manager (Let's Encrypt)
   - SSL redirect enabled
   - Proxy timeouts: 600s

2. **Prometheus Ingress**:
   - Host: `prometheus.fks-trading.com`
   - TLS certificate via cert-manager
   - Basic authentication (htpasswd)
   - Access restricted for security

3. **Alertmanager Ingress**:
   - Host: `alertmanager.fks-trading.com`
   - TLS certificate via cert-manager
   - Basic authentication (htpasswd)
   - Access restricted for security

**ClusterIssuers**:
- `letsencrypt-prod` - Production Let's Encrypt certificates
- `letsencrypt-staging` - Staging for testing (higher rate limits)

**Features**:
- Automatic TLS certificate provisioning
- HTTP to HTTPS redirect
- Basic auth for Prometheus/Alertmanager
- ACME HTTP-01 challenge solver

### 6. Secrets Management ✅

**File**: `/k8s/manifests/secrets.yaml.template` (60 lines)

**Secrets Template**:
```yaml
stringData:
  # Database
  postgres-password: "..."
  
  # Redis
  redis-password: "..."
  
  # Grafana
  grafana-admin-user: "admin"
  grafana-admin-password: "..."
  
  # TradingView webhook
  webhook-secret: "..."
  
  # Exchange API keys
  binance-api-key: "..."
  binance-api-secret: "..."
  coinbase-api-key: "..."
  coinbase-api-secret: "..."
  
  # Slack
  slack-webhook-url: "https://hooks.slack.com/..."
```

**Security**:
- Template file for documentation (not containing real secrets)
- Real `secrets.yaml` in `.gitignore`
- Secrets referenced via `secretKeyRef` in deployments
- Optional secrets (exchange API keys) can be empty

### 7. Deployment Script ✅

**File**: `/k8s/scripts/deploy-phase5.sh` (260 lines, executable)

**Features**:
- Prerequisite checks (kubectl, cluster connection, secrets file)
- Namespace creation with labels
- Secrets application
- Monitoring stack deployment (Prometheus, Grafana, Alertmanager)
- Execution service deployment
- Ingress configuration
- Deployment rollout wait (with timeouts)
- Status display (pods, services, ingress, PVCs)
- Access information (URLs, port-forward commands)

**Usage**:
```bash
cd /home/jordan/fks
./k8s/scripts/deploy-phase5.sh
```

**Output**:
- Colored console output (blue headers, green success, yellow warnings, red errors)
- Progress indicators for each step
- Final access information with URLs and commands
- Rollout status tracking

---

## Architecture

### Kubernetes Resources

```
fks-trading namespace
├── Execution Service
│   ├── Deployment (2-10 replicas, HPA)
│   ├── Service (ClusterIP :8000)
│   ├── ConfigMap (execution config)
│   └── ServiceAccount
│
├── Monitoring Stack
│   ├── Prometheus
│   │   ├── Deployment (1 replica)
│   │   ├── Service (ClusterIP :9090)
│   │   ├── PVC (50Gi)
│   │   ├── ConfigMap (prometheus.yml)
│   │   ├── ConfigMap (alert rules)
│   │   └── ServiceAccount + RBAC
│   │
│   ├── Grafana
│   │   ├── Deployment (1 replica)
│   │   ├── Service (ClusterIP :3000)
│   │   ├── PVC (10Gi)
│   │   └── ConfigMaps (datasources, dashboards)
│   │
│   └── Alertmanager
│       ├── Deployment (1 replica)
│       ├── Service (ClusterIP :9093)
│       └── ConfigMap (alertmanager.yml)
│
├── Ingress
│   ├── grafana.fks-trading.com (TLS)
│   ├── prometheus.fks-trading.com (TLS + BasicAuth)
│   └── alertmanager.fks-trading.com (TLS + BasicAuth)
│
├── Secrets
│   ├── fks-secrets (passwords, API keys, webhooks)
│   └── prometheus-basic-auth (htpasswd)
│
└── ClusterIssuers
    ├── letsencrypt-prod
    └── letsencrypt-staging
```

### Traffic Flow

```
External Request
    ↓
NGINX Ingress Controller
    ↓ (TLS termination)
    ├─→ grafana.fks-trading.com → Grafana Service → Grafana Pod
    ├─→ prometheus.fks-trading.com → Prometheus Service → Prometheus Pod
    └─→ alertmanager.fks-trading.com → Alertmanager Service → Alertmanager Pod

TradingView Webhook
    ↓
Execution Service (ClusterIP)
    ↓
Execution Pod (with metrics)
    ↓
Prometheus (scrape :8000/metrics)
    ↓
Grafana (query Prometheus)
```

### Metrics Flow

```
Execution Pod
    ↓ (expose /metrics endpoint)
Prometheus Scraper
    ↓ (15s interval)
Prometheus TSDB (50Gi PVC)
    ↓ (PromQL queries)
Grafana Dashboards
    ↓ (visualize)
User Browser
```

### Alert Flow

```
Prometheus Alert Rules
    ↓ (evaluate every 30s)
Alert Firing
    ↓
Alertmanager
    ↓ (route by severity)
    ├─→ Slack (#fks-alerts-critical)
    ├─→ Slack (#fks-alerts-warnings)
    └─→ Slack (#fks-alerts-info)
```

---

## Deployment Guide

### Prerequisites

1. **Kubernetes Cluster**:
   - minikube (local development)
   - kind (local development)
   - GKE/EKS/AKS (cloud production)
   - Minimum: 4 CPUs, 8GB RAM, 100GB storage

2. **Kubernetes Tools**:
   ```bash
   # kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   
   # helm (optional)
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

3. **NGINX Ingress Controller**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```

4. **cert-manager** (for TLS):
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

### Step-by-Step Deployment

#### 1. Prepare Secrets

```bash
cd /home/jordan/fks/k8s/manifests

# Copy template
cp secrets.yaml.template secrets.yaml

# Edit with your values
nano secrets.yaml

# Generate htpasswd for Prometheus basic auth
htpasswd -c auth admin
# Enter password when prompted

# Create basic auth secret
kubectl create namespace fks-trading
kubectl create secret generic prometheus-basic-auth \
  --from-file=auth \
  -n fks-trading
```

#### 2. Run Deployment Script

```bash
cd /home/jordan/fks
./k8s/scripts/deploy-phase5.sh
```

**Expected Output**:
```
╔══════════════════════════════════════════════════════════════════════════╗
║          FKS Trading Platform - Phase 5 Deployment                      ║
╚══════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking Prerequisites
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ kubectl found
✓ Connected to Kubernetes cluster
✓ secrets.yaml found

[... deployment progress ...]

╔══════════════════════════════════════════════════════════════════════════╗
║              ✅ Phase 5 Deployment Complete!                             ║
╚══════════════════════════════════════════════════════════════════════════╝
```

#### 3. Verify Deployment

```bash
# Check all resources
kubectl get all -n fks-trading

# Check PVCs
kubectl get pvc -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# View logs
kubectl logs -n fks-trading -l app=fks-execution --tail=100
```

#### 4. Access Monitoring

**Using Ingress (with DNS configured)**:
- Grafana: https://grafana.fks-trading.com
- Prometheus: https://prometheus.fks-trading.com (admin/password)
- Alertmanager: https://alertmanager.fks-trading.com (admin/password)

**Using Port Forwarding (local access)**:
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
```

---

## Configuration

### Environment Variables

**Execution Service**:
- `MIN_CONFIDENCE`: "0.6" - Minimum confidence threshold for webhooks
- `MAX_ORDER_SIZE_USD`: "100000" - Maximum order size in USD
- `RATE_LIMIT_REQUESTS`: "100" - Requests per window
- `RATE_LIMIT_WINDOW`: "60" - Window in seconds
- `CIRCUIT_BREAKER_THRESHOLD`: "5" - Failures before opening
- `CIRCUIT_BREAKER_TIMEOUT`: "60" - Timeout before half-open (seconds)

**Prometheus**:
- Scrape interval: 15s
- Evaluation interval: 15s
- Retention: 15 days
- Storage: 50Gi PVC

**Grafana**:
- Admin user: From secrets
- Root URL: https://grafana.fks-trading.com
- Anonymous auth: Disabled
- Storage: 10Gi PVC

### Resource Limits

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Execution | 200m | 1000m | 512Mi | 1Gi |
| Prometheus | 500m | 2000m | 2Gi | 4Gi |
| Grafana | 100m | 500m | 256Mi | 512Mi |
| Alertmanager | 100m | 200m | 128Mi | 256Mi |

### Auto-Scaling

**Execution Service HPA**:
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%
- Target Memory: 80%
- Scale-up: 100% every 30s (max 2 pods)
- Scale-down: 50% every 60s (stabilization: 300s)

---

## Testing

### 1. Health Checks

```bash
# Execution service health
kubectl exec -n fks-trading deployment/fks-execution -- curl http://localhost:8000/health

# Prometheus health
kubectl exec -n fks-trading deployment/prometheus -- wget -qO- http://localhost:9090/-/healthy

# Grafana health
kubectl exec -n fks-trading deployment/grafana -- wget -qO- http://localhost:3000/api/health
```

### 2. Metrics Collection

```bash
# Port forward execution service
kubectl port-forward -n fks-trading svc/fks-execution 8000:8000

# Check metrics endpoint
curl http://localhost:8000/metrics | grep execution_

# Expected output:
# execution_webhook_requests_total{...} 0
# execution_orders_total{...} 0
# execution_active_requests 0
```

### 3. Test Traffic Generation

```bash
# From local machine (requires webhook endpoint accessible)
cd /home/jordan/fks
python3 scripts/generate_test_traffic.py \
  --url http://localhost:8000/webhook/tradingview \
  --webhooks 100 \
  --concurrent 10
```

### 4. Alert Testing

```bash
# Port forward Prometheus
kubectl port-forward -n fks-trading svc/prometheus 9090:9090

# Open Prometheus UI
xdg-open http://localhost:9090

# Check alerts
# Navigate to: Status → Rules
# Navigate to: Alerts
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n fks-trading

# Describe problem pod
kubectl describe pod -n fks-trading <pod-name>

# Check events
kubectl get events -n fks-trading --sort-by='.lastTimestamp'

# Common issues:
# - Image pull errors: Check image tag and registry
# - CrashLoopBackOff: Check logs
# - Pending: Check resource availability, PVC binding
```

### Secrets Issues

```bash
# Verify secrets exist
kubectl get secrets -n fks-trading

# Check secret contents (base64 encoded)
kubectl get secret fks-secrets -n fks-trading -o yaml

# Recreate if needed
kubectl delete secret fks-secrets -n fks-trading
kubectl apply -f k8s/manifests/secrets.yaml -n fks-trading
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n fks-trading

# Describe PVC
kubectl describe pvc prometheus-data -n fks-trading

# Check available PVs
kubectl get pv

# Common issues:
# - No storage class available
# - Insufficient storage
# - Access mode mismatch
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

# Common issues:
# - DNS not configured
# - Certificate not ready (check cert-manager logs)
# - Ingress controller not installed
```

### Metrics Not Appearing

```bash
# Check Prometheus targets
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
# Open: http://localhost:9090/targets

# Check service discovery
# Prometheus UI → Status → Service Discovery

# Verify pod annotations
kubectl get pod -n fks-trading -l app=fks-execution -o jsonpath='{.items[0].metadata.annotations}'

# Common issues:
# - Missing prometheus.io/scrape annotation
# - Wrong port in annotation
# - Service selector mismatch
```

---

## Production Checklist

### Before Deployment

- [ ] Secrets configured with strong passwords
- [ ] Exchange API keys added (if needed)
- [ ] Slack webhook URL configured
- [ ] DNS records configured for ingress hosts
- [ ] Storage class available and configured
- [ ] NGINX Ingress Controller installed
- [ ] cert-manager installed
- [ ] Resource quotas reviewed
- [ ] Network policies reviewed

### After Deployment

- [ ] All pods running and healthy
- [ ] PVCs bound and mounted
- [ ] Ingress accessible via HTTPS
- [ ] TLS certificates issued
- [ ] Grafana accessible and dashboards loaded
- [ ] Prometheus scraping targets
- [ ] Alertmanager receiving alerts
- [ ] Slack notifications working
- [ ] Metrics appearing in Grafana
- [ ] HPA scaling tested
- [ ] Backup strategy configured

### Monitoring

- [ ] Grafana dashboard configured
- [ ] Alert rules loaded
- [ ] Alertmanager routing configured
- [ ] Slack channels created
- [ ] On-call rotation established
- [ ] Runbook created
- [ ] SLO/SLI defined

### Security

- [ ] Secrets encrypted at rest
- [ ] RBAC configured
- [ ] Network policies applied
- [ ] Pod security policies/standards applied
- [ ] Ingress with TLS
- [ ] Basic auth on Prometheus/Alertmanager
- [ ] Audit logging enabled
- [ ] Vulnerability scanning configured

---

## Maintenance

### Updating Deployments

```bash
# Update image
kubectl set image deployment/fks-execution \
  execution=nuniesmith/fks:execution-v2 \
  -n fks-trading

# Rollout status
kubectl rollout status deployment/fks-execution -n fks-trading

# Rollback if needed
kubectl rollout undo deployment/fks-execution -n fks-trading
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment/fks-execution --replicas=5 -n fks-trading

# Update HPA
kubectl edit hpa/fks-execution -n fks-trading
```

### Backup

```bash
# Backup Prometheus data
kubectl exec -n fks-trading deployment/prometheus -- \
  tar czf /tmp/prometheus-backup.tar.gz /prometheus

kubectl cp fks-trading/prometheus-pod:/tmp/prometheus-backup.tar.gz \
  ./prometheus-backup-$(date +%Y%m%d).tar.gz

# Backup Grafana dashboards
kubectl exec -n fks-trading deployment/grafana -- \
  tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana

kubectl cp fks-trading/grafana-pod:/tmp/grafana-backup.tar.gz \
  ./grafana-backup-$(date +%Y%m%d).tar.gz
```

---

## Next Steps

### Immediate

1. **Test deployment on minikube**:
   ```bash
   minikube start --cpus=4 --memory=8192
   ./k8s/scripts/deploy-phase5.sh
   ```

2. **Configure DNS for ingress hosts**
3. **Set up Slack channels for alerts**
4. **Load test the execution service**

### Short-Term

1. **Add distributed tracing** (Jaeger)
2. **Implement log aggregation** (ELK/Loki)
3. **Create SLO/SLI dashboards**
4. **Set up automated backups**
5. **Configure multi-region deployment**

### Long-Term

1. **Implement GitOps** (Flux/ArgoCD)
2. **Add chaos engineering** (Chaos Mesh)
3. **Implement cost optimization**
4. **Create disaster recovery plan**
5. **Set up multi-cluster federation**

---

## Files Created

| File | Size | Purpose |
|------|------|---------|
| `/k8s/manifests/execution-service.yaml` | 280 lines | Execution service deployment |
| `/k8s/manifests/monitoring-stack.yaml` | 450 lines | Prometheus + Grafana |
| `/k8s/manifests/prometheus-rules.yaml` | 200 lines | Alert rules ConfigMap |
| `/k8s/manifests/alertmanager.yaml` | 180 lines | Alertmanager deployment |
| `/k8s/manifests/ingress.yaml` | 150 lines | Ingress with TLS |
| `/k8s/manifests/secrets.yaml.template` | 60 lines | Secrets template |
| `/k8s/scripts/deploy-phase5.sh` | 260 lines | Deployment script |
| `/docs/PHASE_5_COMPLETE.md` | This file | Phase 5 documentation |

**Total**: 8 files, ~1,580 lines

---

## Acceptance Criteria

All criteria met:

- [x] Execution service K8s manifests created
- [x] Monitoring stack (Prometheus + Grafana) with PVCs
- [x] Alertmanager with Slack integration
- [x] Ingress with TLS (cert-manager)
- [x] Secrets template and management
- [x] Deployment script with validation
- [x] HPA for auto-scaling
- [x] Health probes for all services
- [x] RBAC configured
- [x] Comprehensive documentation

---

## Conclusion

Phase 5 successfully prepares the FKS Trading Platform for production deployment on Kubernetes. All manifests, configurations, and scripts are ready to deploy the execution pipeline with full monitoring stack to any Kubernetes cluster.

**Phase 5 Status**: 100% Complete ✅

**Ready For**: Production deployment on Kubernetes (minikube, GKE, EKS, AKS)

---

**Documentation Links**:
- [Phase 4 Complete - Monitoring](/docs/PHASE_4_COMPLETE.md)
- [Phase 5 Complete - Production Deployment](/docs/PHASE_5_COMPLETE.md) (this file)
- [K8s Deployment Guide](/docs/K8S_DEPLOYMENT_GUIDE.md)
- [Copilot Instructions](/.github/copilot-instructions.md)
