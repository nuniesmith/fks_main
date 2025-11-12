### 🎯 FKS Trading Platform - Multi-Repo Microservices Architecture

**Last Updated**: November 7, 2025  
**Overall Progress**: Phase 5 Complete + Full K8s Deployment (93% Operational)

## 📋 Organized Documentation

**This file is the legacy overview**. For focused, organized instructions by topic:

### Quick Navigation

**Core Architecture & DevOps**:
- **[Master README](./copilot-docs/00-MASTER-README.md)** - Multi-repo architecture overview
- **[Core Architecture](./copilot-docs/01-core-architecture.md)** - System design & K8s deployment
- **[Docker Strategy](./copilot-docs/02-docker-strategy.md)** - Build/push workflows & tagging
- **[GitHub Actions](./copilot-docs/03-github-actions.md)** - CI/CD automation for all repos

**AI & Trading Systems**:
- **[AI Trading Agents](./copilot-docs/04-ai-trading-agents.md)** - LLM integration, multi-agent systems
- **[Execution Pipeline](./copilot-docs/05-execution-pipeline.md)** - Webhooks, CCXT, security
- **[AI Portfolio Rebalancing](./copilot-docs/06-portfolio-rebalancing.md)** - RL-based optimization research
- **[CVaR Risk Management](./copilot-docs/07-cvar-risk-management.md)** - Safe RL, distributional methods

**Development Practices**:
- **[Solo Dev Workflow](./copilot-docs/09-solo-dev-workflow.md)** - Multi-repo management, automation, task tracking
- **[Fintech Security & Compliance](./copilot-docs/10-fintech-security-compliance.md)** - Encryption, MFA, PCI DSS, NIST CSF
- **[Project Improvement Areas](./copilot-docs/11-project-improvement-areas.md)** - Multi-language optimization, testing, monitoring
- **[Standard Schema Design](./copilot-docs/12-standard-schema-design.md)** - JSON Schema standards, validation, versioning

**Migration & Scaling**:
- **[Monorepo Split Guide](./copilot-docs/08-monorepo-split-guide.md)** - Migration to multi-repo architecture

### Repository-Specific Work

All 9 FKS repositories are now independent GitHub repos:

| Repo | GitHub | DockerHub | Status |
|------|--------|-----------|--------|
| fks_ai | [nuniesmith/fks_ai](https://github.com/nuniesmith/fks_ai) | `nuniesmith/fks_ai:cpu/gpu/arm64` | ⏸️ Needs remote setup |
| fks_api | [nuniesmith/fks_api](https://github.com/nuniesmith/fks_api) | `nuniesmith/fks_api:latest` | ⏸️ Needs remote setup |
| fks_app | [nuniesmith/fks_app](https://github.com/nuniesmith/fks_app) | `nuniesmith/fks_app:latest` | ⏸️ Needs remote setup |
| fks_data | [nuniesmith/fks_data](https://github.com/nuniesmith/fks_data) | `nuniesmith/fks_data:latest` | ⏸️ Needs remote setup |
| fks_execution | [nuniesmith/fks_execution](https://github.com/nuniesmith/fks_execution) | `nuniesmith/fks_execution:latest` | ⏸️ Needs remote setup |
| fks_ninja | [nuniesmith/fks_ninja](https://github.com/nuniesmith/fks_ninja) | `nuniesmith/fks_ninja:latest` | ⏸️ Needs remote setup |
| fks_meta | [nuniesmith/fks_meta](https://github.com/nuniesmith/fks_meta) | `nuniesmith/fks_meta:latest` | ⏸️ Needs remote setup |
| fks_web | [nuniesmith/fks_web](https://github.com/nuniesmith/fks_web) | `nuniesmith/fks_web:latest` | ⏸️ Needs remote setup |
| fks_training | [nuniesmith/fks_training](https://github.com/nuniesmith/fks_training) | `nuniesmith/fks_training:latest` | ⏸️ Needs remote setup |

**Next Actions**: See [copilot-docs/00-MASTER-README.md](./copilot-docs/00-MASTER-README.md) for setup instructions.

---

## 📌 Legacy Overview (Historical Context)

---

## ✅ Completed Phases (Ready for Production)

### Phase 1: Codebase Cleanup ✅ (100%)
- Cleaned monorepo structure
- Removed empty/obsolete files
- Organized documentation in `/docs/`
- Updated README with quick start guide

### Phase 2: AI Enhancements ✅ (100%)
- Integrated TimeCopilot for agentic forecasting
- Fixed Lag-Llama kv_cache issues
- Added probabilistic metrics (CRPS/MASE)
- Enhanced 7-agent LangGraph with confidence thresholds (0.6 min)
- Optimized ChromaDB semantic memory queries

### Phase 3: Integrations & Centralization ✅ (100%)
**Status**: Production-ready, 168/168 tests passing (100% coverage)

**Implemented Components**:
1. **ExecutionPlugin Framework** (Rust)
   - Trait definition for unified plugin interface
   - Python wrappers via pyo3
   - Foundation for ninja/MT5 migration

2. **CCXT Exchange Integration**
   - `ExchangeManager` - Multi-exchange connection pooling
   - `CCXTPlugin` - Unified order interface (market/limit/TP/SL)
   - Support for Binance, Coinbase, Kraken, etc.

3. **TradingView Webhook Handler**
   - HMAC-SHA256 signature verification
   - Payload validation & confidence filtering
   - Timestamp staleness checks (<300s)

4. **Validation & Normalization Layer**
   - `DataNormalizer` - Symbol mapping, NaN handling, precision rounding
   - `PositionSizer` - Fixed %, risk-based, volatility-adjusted sizing
   - Comprehensive data quality checks

5. **Security Middleware**
   - `RateLimiter` - Token bucket (100 req/min default)
   - `CircuitBreaker` - CLOSED→OPEN→HALF_OPEN state machine
   - `IPWhitelist` - CIDR support for IPv4/IPv6
   - `AuditLogger` - Event tracking for compliance

6. **Integration Tests**
   - 18 E2E tests validating complete pipeline
   - Performance validated: <50ms latency, >80 req/s throughput
   - Concurrent request handling (10 simultaneous webhooks)

**Pipeline Architecture**:
```
TradingView Alert → Webhook Handler (signature verification) →
→ Validation (payload, confidence, staleness) →
→ Security Middleware (rate limit, circuit breaker, IP whitelist) →
→ Data Normalization (symbol, NaN, precision) →
→ Position Sizing (risk calculation) →
→ CCXT Plugin → ExchangeManager → Exchange API
```

**Test Coverage**:
- Unit tests: 150/150 ✅
- Integration tests: 18/18 ✅
- **Total: 168/168 (100%)**

**Files Created**:
- `/src/services/execution/validation/normalizer.py` (442 lines, 48 tests)
- `/src/services/execution/security/middleware.py` (545 lines, 33 tests)
- `/tests/integration/test_execution_pipeline.py` (565 lines, 18 tests)
- `/docs/PHASE_3_COMPLETE.md` - Full technical documentation
- `/docs/PHASE_3_SUMMARY.md` - Executive summary

---

## ✅ Phase 4 Complete - Monitoring & Observability (100%)

**Date Completed**: November 5, 2025  
**Status**: All 3 tasks complete (Task 4.1, 4.2, 4.3)

### Summary

Phase 4 successfully implemented comprehensive monitoring and observability for the FKS execution pipeline with Prometheus metrics collection, Grafana visualization, alert rules, integration tests, and validation tools.

**Key Deliverables**:
- 30+ Prometheus metrics across webhooks, orders, security, validation, and exchanges
- 16-panel Grafana dashboard with real-time visualization
- 18 alert rules (critical/warning/info)
- 15 integration tests for metrics validation
- Traffic generator for load testing
- Validation script (8/8 checks passed)

### Completed Tasks

#### ✅ Task 4.1: Metrics Integration (100%)
**File**: `/src/services/execution/metrics.py` (363 lines)

**Instrumented Files** (4):
1. `/src/services/execution/webhooks/tradingview.py` - Webhook metrics
2. `/src/services/execution/exchanges/ccxt_plugin.py` - Order metrics
3. `/src/services/execution/security/middleware.py` - Security metrics
4. `/src/services/execution/validation/normalizer.py` - Validation metrics

**Metrics Categories** (30+ total):
- Webhook metrics (7): requests, latency, validation/signature failures, confidence filtering
- Order metrics (5): execution, failures, size distribution
- Security metrics (7): rate limits, circuit breakers, IP whitelist, audit events
- Validation metrics (4): errors, normalization, NaN handling
- Exchange metrics (3): connections, API calls, errors

**Doc**: `/docs/PHASE_4_1_COMPLETE.md` (15KB)

#### ✅ Task 4.2: Grafana Dashboard (100%)
**File**: `/monitoring/grafana/dashboards/execution_pipeline.json` (20KB)

**16 Panels in 5 Rows**:
- Row 1: Overview (request rate, success rate, active requests, P95 latency)
- Row 2: Webhooks (processing duration, validation/signature failures)
- Row 3: Orders (execution duration, failure rate, size distribution)
- Row 4: Security (rate-limited IPs, circuit breaker state, audit events)
- Row 5: Exchange Health (API latency, error rate, connections)

**Features**: Auto-refresh 30s, Prometheus datasource, variable filters

**Access**: http://localhost:3000/d/execution-pipeline

**Doc**: `/docs/PHASE_4_2_COMPLETE.md` (14KB)

#### ✅ Task 4.3: Testing & Validation (100%)
**Created Files**:
1. `/tests/integration/test_execution_metrics.py` (16KB, 15 tests)
   - TestWebhookMetrics (6 tests)
   - TestOrderMetrics (1 test)
   - TestSecurityMetrics (4 tests)
   - TestValidationMetrics (3 tests)
   - TestEndToEndMetrics (1 test)

2. `/scripts/generate_test_traffic.py` (14KB, executable)
   - Normal traffic generation
   - Load testing (sustained duration)
   - Validation/signature failure testing
   - Rate limiting tests
   - Statistics tracking

3. `/scripts/validate_phase4.py` (7KB, executable)
   - 8 automated validation checks
   - **Result**: 8/8 checks passed ✅

**Validation Results**:
- ✅ Prometheus running (port 9090)
- ✅ Grafana running (port 3000, v12.2.1)
- ✅ Dashboard loaded (16 panels)
- ✅ Metrics module (30+ metrics)
- ✅ Code instrumentation (4 files)
- ✅ Test files exist
- ✅ Documentation complete

**Doc**: `/docs/PHASE_4_3_COMPLETE.md` (17KB)

### Alert Rules

**File**: `/monitoring/prometheus/rules/execution_alerts.yml`

**18 Alerts Configured**:
- Critical (5): Circuit breaker opened, high order failures, security issues
- Warning (8): High latency, validation failures, rate limits, API errors  
- Info (5): Data quality, confidence filtering, high load

### Deployment Status

**Running Services**:
```bash
$ docker-compose ps
fks_prometheus   Up (healthy)   port 9090
fks_grafana      Up (healthy)   port 3000
```

**Health Checks**:
- Prometheus: http://localhost:9090 ✅
- Grafana: http://localhost:3000 ✅

### Usage

```bash
# Generate test traffic
python3 scripts/generate_test_traffic.py --webhooks 100 --concurrent 10

# Load test (60 seconds)
python3 scripts/generate_test_traffic.py --load-test --duration 60

# Validate setup
python3 scripts/validate_phase4.py  # 8/8 checks passed

# Access monitoring
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
# Dashboard: http://localhost:3000/d/execution-pipeline
```

### Documentation

- `/docs/PHASE_4_1_COMPLETE.md` - Metrics integration (15KB)
- `/docs/PHASE_4_2_COMPLETE.md` - Grafana dashboard (14KB)
- `/docs/PHASE_4_3_COMPLETE.md` - Testing & validation (17KB)
- `/docs/PHASE_4_MONITORING_SUMMARY.md` - Quick summary

**Total**: 16 files created/modified, ~2,800 lines of code/config/docs

---

## ✅ Phase 5 Complete - Production Deployment (100%)

**Date Completed**: November 5, 2025  
**Status**: All 7 tasks complete

### Summary

Phase 5 successfully prepared production Kubernetes deployment for the FKS execution pipeline with full monitoring stack, TLS ingress, auto-scaling, and automated deployment scripts.

**Key Deliverables**:
- Execution service K8s manifests (Deployment, Service, ConfigMap, HPA)
- Monitoring stack with persistent storage (Prometheus 50Gi, Grafana 10Gi)
- Alertmanager with Slack integration (3 channels)
- Ingress with TLS via cert-manager (Let's Encrypt)
- Secrets management template
- Automated deployment script with validation
- Comprehensive documentation

### Completed Tasks

#### ✅ Task 5.1: K8s Infrastructure Analysis (100%)
- Reviewed existing K8s setup and helm charts
- Identified requirements for production deployment
- Planned resource allocation and scaling strategy

#### ✅ Task 5.2: Execution Service Manifests (100%)
**File**: `/k8s/manifests/execution-service.yaml` (280 lines)

**Components**:
- ConfigMap: Execution configuration (confidence, rate limits, circuit breaker)
- Service: ClusterIP with metrics annotations
- Deployment: 2 replicas, rolling updates, health probes, security contexts
- ServiceAccount: RBAC permissions
- HorizontalPodAutoscaler: 2-10 replicas (CPU 70%, memory 80%)

**Features**:
- Resource limits: 200m-1000m CPU, 512Mi-1Gi RAM
- Health probes: `/health` (liveness), `/ready` (readiness)
- Pod anti-affinity for HA
- Environment variables from ConfigMap and Secrets

#### ✅ Task 5.3: Monitoring Stack K8s (100%)
**File**: `/k8s/manifests/monitoring-stack.yaml` (450 lines)

**Prometheus**:
- PVC: 50Gi storage (15-day retention)
- ConfigMap: prometheus.yml with K8s service discovery
- Deployment: 2-4Gi RAM, automatic pod discovery
- Service + RBAC: ClusterRole for K8s API access

**Grafana**:
- PVC: 10Gi storage
- ConfigMaps: Datasources, dashboard provisioning
- Deployment: 256-512Mi RAM
- Service: ClusterIP port 3000

#### ✅ Task 5.4: Alertmanager Configuration (100%)
**File**: `/k8s/manifests/alertmanager.yaml` (180 lines)

**Features**:
- Slack integration with 3 channels (critical/warnings/info)
- Severity-based routing
- Inhibition rules (critical inhibits warning)
- Group intervals: Critical (immediate), Warning (5m), Info (10m)
- Repeat intervals: 12h/4h/24h

#### ✅ Task 5.5: Ingress with TLS (100%)
**File**: `/k8s/manifests/ingress.yaml` (150 lines)

**Ingress Resources**:
- `grafana.fks-trading.com` - Grafana access
- `prometheus.fks-trading.com` - Prometheus (basic auth)
- `alertmanager.fks-trading.com` - Alertmanager (basic auth)
- TLS certificates via cert-manager (Let's Encrypt)
- SSL redirect enabled

#### ✅ Task 5.6: Deployment Automation (100%)
**Files**:
1. `/k8s/manifests/secrets.yaml.template` (60 lines) - Secrets template
2. `/k8s/scripts/deploy-phase5.sh` (260 lines, executable) - Deployment script

**Deployment Script Features**:
- Prerequisite checks (kubectl, cluster, secrets)
- Namespace creation
- Secrets application
- Monitoring stack deployment
- Execution service deployment
- Ingress configuration
- Rollout wait with timeout
- Status display (pods, services, PVCs)
- Access information (URLs, port-forward commands)

#### ✅ Task 5.7: Documentation (100%)
**File**: `/docs/PHASE_5_COMPLETE.md` (580 lines)

**Sections**:
- Overview and deliverables
- Architecture diagrams (K8s resources, traffic flow, metrics flow)
- Deployment guide (prerequisites, step-by-step)
- Configuration options (env vars, resource limits, HPA)
- Testing procedures (health checks, metrics, alerts)
- Troubleshooting guide (pods, secrets, PVCs, ingress)
- Production checklist (before/after deployment)
- Maintenance procedures (updates, scaling, backups)

### Files Created

| File | Size | Purpose |
|------|------|---------|
| `/k8s/manifests/execution-service.yaml` | 280 lines | Execution service K8s deployment |
| `/k8s/manifests/monitoring-stack.yaml` | 450 lines | Prometheus + Grafana with PVCs |
| `/k8s/manifests/prometheus-rules.yaml` | 200 lines | Alert rules ConfigMap |
| `/k8s/manifests/alertmanager.yaml` | 180 lines | Alertmanager with Slack |
| `/k8s/manifests/ingress.yaml` | 150 lines | TLS ingress |
| `/k8s/manifests/secrets.yaml.template` | 60 lines | Secrets template |
| `/k8s/scripts/deploy-phase5.sh` | 260 lines | Deployment automation |
| `/docs/PHASE_5_COMPLETE.md` | 580 lines | Phase 5 documentation |

**Total**: 8 files, ~2,160 lines

### Deployment Commands

```bash
# Quick deployment
cd /home/jordan/fks
./k8s/scripts/deploy-phase5.sh

# Access monitoring
# Grafana: https://grafana.fks-trading.com
# Prometheus: https://prometheus.fks-trading.com
# Alertmanager: https://alertmanager.fks-trading.com

# Port forwarding (local access)
kubectl port-forward -n fks-trading svc/grafana 3000:3000
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
kubectl port-forward -n fks-trading svc/alertmanager 9093:9093
```

---

## ✅ Phase 5.5 Complete - Full Stack K8s Deployment (November 6, 2025)

**Status**: 13/14 services operational (93%) - **DEMO READY**  
**Environment**: Minikube v1.37.0, Kubernetes v1.34.0  
**Cluster**: 4 CPUs, 8GB RAM, 50GB disk

### Deployment Summary

Successfully deployed complete FKS trading platform to local Kubernetes cluster with all microservices, databases, monitoring, and TLS ingress configured for Tailscale network (100.116.135.8).

**Key Achievements**:
- ✅ 13/14 pods running (93% operational)
- ✅ 170Gi persistent storage allocated and bound
- ✅ TLS ingress with 8 routes on *.fkstrading.xyz
- ✅ Professional landing page deployed
- ✅ All backend services healthy and tested
- ✅ Monitoring stack fully operational
- ✅ 503 errors resolved with landing page

### Live Services & Access URLs

**Public URLs** (via Tailscale 100.116.135.8):
- 🏠 Landing Page: <https://fkstrading.xyz>
- 📊 API Health: <https://api.fkstrading.xyz/health>
- 📈 Grafana: <https://grafana.fkstrading.xyz> (admin/admin)
- 🔍 Prometheus: <https://prometheus.fkstrading.xyz>
- 🔔 Alertmanager: <https://alertmanager.fkstrading.xyz>

**Running Services** (13/14):
| Service | Replicas | Status | Notes |
|---------|----------|--------|-------|
| **landing-page** | 1/1 | ✅ Running | Professional portal with service links |
| **postgres** | 1/1 | ✅ Running | PostgreSQL 16, 100Gi PVC, trading_db created |
| **redis** | 1/1 | ✅ Running | Redis 7, 10Gi PVC, AOF persistence |
| **fks-api** | 2/2 | ✅ Running | REST API returning JSON health checks |
| **fks-app** | 2/2 | ✅ Running | Application logic microservice |
| **fks-data** | 2/2 | ✅ Running | Data processing microservice |
| **fks-ai** | 1/1 | ✅ Running | Multi-agent AI (2-4Gi RAM) |
| **grafana** | 1/1 | ✅ Running | Dashboards, 10Gi PVC |
| **prometheus** | 1/1 | ✅ Running | Metrics collection, 50Gi PVC |
| **alertmanager** | 1/1 | ✅ Running | Alert routing configured |

**Scaled to Zero** (Awaiting Docker Image Fix):
| Service | Replicas | Status | Issue |
|---------|----------|--------|-------|
| **fks-web** | 0/0 | ⏸️ Scaled Down | ModuleNotFoundError: 'celery' |
| **celery-worker** | 0/0 | ⏸️ Scaled Down | Missing celery in Docker image |
| **celery-beat** | 0/0 | ⏸️ Scaled Down | Missing celery in Docker image |
| **flower** | 0/0 | ⏸️ Scaled Down | Missing celery in Docker image |

**Root Cause**: Docker images from DockerHub (built by GitHub Actions) are missing Celery dependencies. Web image has Django code but not the celery package.

### Files Created/Modified

**K8s Manifests**:
1. `/k8s/manifests/all-services.yaml` (731 lines)
   - PostgreSQL StatefulSet (postgres:16, 100Gi PVC, trading_db)
   - Redis Deployment (redis:7, 10Gi PVC, AOF)
   - Django web + Celery workers (scaled to 0)
   - Microservices: fks-api, fks-app, fks-data, fks-ai (all running)
   - Module paths fixed: `services.web.src.django` → `src.django`

2. `/k8s/manifests/ingress-tailscale.yaml` (150 lines)
   - TLS ingress for *.fkstrading.xyz (self-signed wildcard cert)
   - Routes: Landing page, API, Grafana, Prometheus, Alertmanager, Flower, Execution
   - Updated fkstrading.xyz → landing-page:80 (fixed 503 error)

3. `/k8s/manifests/landing-page.yaml` (195 lines)
   - Professional HTML portal with gradient design
   - Service status overview (13/14 operational)
   - Links to all working services
   - Lightweight nginx:alpine (32Mi-64Mi RAM)

4. `/k8s/manifests/fks-secrets.yaml.template` (80 lines)
   - Template for postgres credentials
   - Django secret key
   - API keys (Yahoo Finance, exchange APIs)

**Scripts**:
5. `/k8s/scripts/deploy-all-services.sh` (executable)
   - Automated deployment with health checks
   - Secrets validation
   - /etc/hosts update with Tailscale IP
   - Status summary and access URLs

**Documentation**:
6. `/docs/FULL_STACK_DEPLOYMENT.md` (579 lines)
   - Complete deployment guide
   - Troubleshooting for PostgreSQL, Django, Celery
   - Service configuration details

7. `/docs/FULL_STACK_QUICKREF.md` (quick commands)
8. `/docs/DEPLOYMENT_STATUS.md` (technical details)
9. `/docs/HEALTH_CHECK_REPORT.md` (479 lines, DEMO_PLAN readiness)
10. `/docs/503_FIX_COMPLETE.md` (resolution documentation)
11. `/HEALTH_STATUS.md` (current status summary)
12. `/QUICK_ACCESS.md` (125 lines, working URLs and quick tests)

### Infrastructure Details

**Storage (170Gi Total)**:
- postgres-data: 100Gi (Bound, trading_db created, no tables yet)
- redis-data: 10Gi (Bound, PING → PONG working)
- grafana-pvc: 10Gi (Bound)
- prometheus-pvc: 50Gi (Bound)

**Networking**:
- NGINX Ingress Controller with self-signed TLS
- Internal DNS: db:5432, redis:6379, fks-api:8001, etc.
- Service discovery working (tested with curl between pods)
- Tailscale IP: 100.116.135.8 configured in /etc/hosts

**Security**:
- fks-secrets created (postgres-user, postgres-password, django-secret-key)
- TLS enabled for all ingress routes (self-signed wildcard *.fkstrading.xyz)
- Pod security contexts configured
- RBAC permissions for service accounts

### Troubleshooting Completed

**PostgreSQL Issues (RESOLVED)**:
1. ❌ TimescaleDB security context → ✅ Switched to postgres:16
2. ❌ "root execution not permitted" → ✅ Removed security context
3. ❌ PGDATA initialization errors → ✅ Used default /var/lib/postgresql/data
4. ✅ Final: postgres-0 pod Running (1/1), trading_db created

**Django/Celery Issues (IDENTIFIED)**:
1. ❌ ModuleNotFoundError: 'services' → ✅ Fixed module paths to `src.django`
2. ❌ ModuleNotFoundError: 'celery' → ⏸️ Scaled to 0 (needs Docker image rebuild)
3. Root cause: GitHub Actions Dockerfile not installing full requirements.txt

**503 Error (RESOLVED)**:
1. Issue: fkstrading.xyz routing to web:8000 with 0 active endpoints
2. Solution: Created landing-page.yaml, updated ingress routing
3. Result: Professional portal now serving at root domain

### Testing Results

**Health Checks Passed**:
```bash
# API - SUCCESS
curl -k https://api.fkstrading.xyz/health
{"status":"healthy","env":"development","ts":"2025-11-06T10:04:01..."}

# Grafana - SUCCESS (redirects to /login)
curl -k -I https://grafana.fkstrading.xyz
HTTP/2 302

# Prometheus - SUCCESS
curl -k https://prometheus.fkstrading.xyz

# PostgreSQL - SUCCESS
kubectl exec postgres-0 -- psql -U trading_user -d trading_db -c "\l"
trading_db | trading_user | UTF8 | ...

# Redis - SUCCESS  
kubectl exec deployment/redis -- redis-cli ping
PONG
```

**Service Discovery**:
```bash
kubectl exec -it deployment/fks-api -- /bin/sh
curl http://fks-data:8003/health  # Works
curl http://fks-ai:8007/health     # Works
curl http://db:5432                # Works
```

### DEMO_PLAN Readiness Assessment

**Phase 1: Stabilization & Security** - ✅ **READY NOW**
- Infrastructure: All databases and services operational
- Security: K8s secrets configured, TLS enabled
- Tests: Can run against API/App/Data/AI services
- Action: Start security hardening, cleanup imports

**Phase 2: Yahoo Finance Integration** - ✅ **INFRASTRUCTURE READY**
- Database: PostgreSQL ready for market_data tables
- API service: 2/2 pods ready to serve endpoints
- Data service: 2/2 pods ready for Yahoo Finance connectors
- Action: Implement in fks-data service NOW

**Phase 3: Signal Generation** - ⚠️ **BACKEND READY, UI BLOCKED**
- Signal logic: fks-app ready for implementation (2/2 pods)
- Database: PostgreSQL ready for signals table
- API endpoints: fks-api ready to expose (2/2 pods)
- Web UI: Blocked until Docker image fixed
- Workaround: Use Grafana dashboards or curl/Postman for visualization

**Phase 4: RAG Intelligence** - ✅ **READY NOW**
- AI service: 1/1 pod running with 2-4Gi RAM
- Vector storage: Can add pgvector extension to PostgreSQL
- LangGraph: Dependencies available in fks-ai service
- ChromaDB: Can deploy or use PostgreSQL with pgvector
- Action: Start RAG implementation NOW

### Next Steps to 100%

**CRITICAL (to reach 100% operational)**:
1. **Fix Docker Images** (1-2 hours)
   ```bash
   # Update requirements.txt to include:
   celery>=5.3.0
   flower>=2.0.0
   django-celery-beat>=2.5.0
   django-celery-results>=2.5.0
   
   # Rebuild and push
   docker build -f docker/Dockerfile -t nuniesmith/fks:web-v2 .
   docker push nuniesmith/fks:web-v2
   ```

2. **Update K8s Deployments** (5 minutes)
   ```bash
   kubectl set image deployment/fks-web web=nuniesmith/fks:web-v2 -n fks-trading
   kubectl set image deployment/celery-worker worker=nuniesmith/fks:web-v2 -n fks-trading
   kubectl set image deployment/celery-beat beat=nuniesmith/fks:web-v2 -n fks-trading
   kubectl set image deployment/flower flower=nuniesmith/fks:web-v2 -n fks-trading
   ```

3. **Run Django Migrations** (10 minutes)
   ```bash
   kubectl exec -it deployment/fks-web -- python manage.py migrate
   kubectl exec -it deployment/fks-web -- python manage.py createsuperuser
   ```

4. **Scale Up Services** (1 minute)
   ```bash
   kubectl scale deployment fks-web --replicas=2 -n fks-trading
   kubectl scale deployment celery-worker --replicas=2 -n fks-trading
   kubectl scale deployment celery-beat --replicas=1 -n fks-trading
   kubectl scale deployment flower --replicas=1 -n fks-trading
   ```

5. **Update Ingress** (1 minute)
   ```bash
   # Change landing-page back to web:8000 in ingress-tailscale.yaml
   kubectl apply -f k8s/manifests/ingress-tailscale.yaml
   ```

**OPTIONAL ENHANCEMENTS**:
- Add TimescaleDB extension to PostgreSQL for time-series optimization
- Add pgvector extension for AI/RAG vector storage
- Configure Let's Encrypt for real TLS certificates (replace self-signed)
- Set up Slack/PagerDuty integration in Alertmanager
- Add distributed tracing with Jaeger
- Implement log aggregation with Loki or ELK Stack

### Quick Commands Reference

```bash
# Check all services
kubectl get pods -n fks-trading

# View service endpoints
kubectl get endpoints -n fks-trading

# Check ingress routes
kubectl get ingress -n fks-trading

# Test API
kubectl port-forward -n fks-trading svc/fks-api 8001:8001
curl http://localhost:8001/health

# Access Grafana (requires minikube tunnel)
minikube tunnel  # (separate terminal, keep running)
# Open: https://grafana.fkstrading.xyz

# Check database
kubectl exec -it postgres-0 -n fks-trading -- psql -U trading_user -d trading_db

# Check Redis
kubectl exec -it deployment/redis -n fks-trading -- redis-cli ping

# View logs
kubectl logs -f deployment/fks-api -n fks-trading
kubectl logs -f deployment/fks-ai -n fks-trading

# Restart service
kubectl rollout restart deployment/fks-api -n fks-trading

# Scale service
kubectl scale deployment fks-data --replicas=3 -n fks-trading
```

### Documentation Reference

- **Quick Access**: `/QUICK_ACCESS.md` - All working URLs and quick tests
- **Health Status**: `/HEALTH_STATUS.md` - Current operational status
- **Full Deployment**: `/docs/FULL_STACK_DEPLOYMENT.md` - Complete guide (579 lines)
- **Quick Reference**: `/docs/FULL_STACK_QUICKREF.md` - Command cheat sheet
- **Health Report**: `/docs/HEALTH_CHECK_REPORT.md` - DEMO_PLAN readiness (479 lines)
- **503 Fix**: `/docs/503_FIX_COMPLETE.md` - Landing page resolution
- **Deployment Status**: `/docs/DEPLOYMENT_STATUS.md` - Technical details

---

## 📋 Future Phases (Not Started)

### Phase 6: LLM-Driven AI Trading Agent Evolution (2-4 Weeks)
Transform FKS from rule-based bot to adaptive AI agent system using LLMs for contextual trading intelligence.

**Motivation**: Research shows LLM-integrated trading systems achieve 20-40% higher returns in volatile crypto markets (FinGPT benchmarks), with multi-agent architectures improving Sharpe ratios by 0.5-1.0. Current FKS relies on fixed ASMBTR strategy without LLM reasoning or multi-agent collaboration.

**Sub-Phases and Tasks**:

#### **6.1: LLM Sentiment Analysis Integration (Week 1)**
Dependencies: Existing data adapters (/repo/data/src/adapters), CCXT integration.

- **Task 6.1.1**: Set Up LLM Infrastructure (Days 1-2)
  - Install transformers, openai SDK to requirements.txt
  - Create `/src/services/ai/src/sentiment/` module structure
  - Configure API keys for Grok/GPT-4 or load FinBERT locally
  - GitHub Action: Add model download to CI/CD pipeline
  - Agent Prompt: "Generate FinBERT sentiment analysis module for crypto news"

- **Task 6.1.2**: Implement News/Social Sentiment Engine (Days 3-4)
  - Create `sentiment_analyzer.py` with FinBERT/Llama integration
  - Add CryptoPanic/NewsAPI adapters for real-time feeds
  - Build sentiment scoring (-1 to 1 scale) for BTC/ETH/major pairs
  - Cache results in Redis (expire 5min) to reduce API costs
  - Validation Gate: Test on historical news, achieve F1 score >0.85
  - Example Code:
    ```python
    # /src/services/ai/src/sentiment/sentiment_analyzer.py
    from transformers import pipeline
    import requests
    import redis
    
    classifier = pipeline("sentiment-analysis", model="ProsusAI/finbert")
    cache = redis.Redis(host='redis', port=6379, decode_responses=True)
    
    def get_sentiment_from_news(symbol: str) -> float:
        cached = cache.get(f"sentiment:{symbol}")
        if cached:
            return float(cached)
        
        api_url = f"https://cryptopanic.com/api/v1/posts/?currencies={symbol}&kind=news"
        response = requests.get(api_url).json()
        headlines = [post['title'] for post in response['results'][:5]]
        
        sentiments = [classifier(h)[0]['label'] for h in headlines]
        score = sum(1 if s == 'POSITIVE' else -1 if s == 'NEGATIVE' else 0 
                   for s in sentiments) / len(sentiments)
        
        cache.setex(f"sentiment:{symbol}", 300, score)  # 5min TTL
        return score  # -1 (bearish) to 1 (bullish)
    ```

- **Task 6.1.3**: Integrate Sentiment into ASMBTR Strategy (Day 5)
  - Modify `/tests/unit/strategies/asmbtr/test_asmbtr_strategy.py`
  - Add sentiment weight parameter (0.2-0.3 multiplier on signals)
  - Backtest hybrid model vs. pure ASMBTR on 2024 crypto data
  - Target: +15-20% return improvement in backtests
  - Agent Prompt: "Add sentiment weighting to ASMBTR buy/sell signals"

**Milestones**: Sentiment-enhanced trading signals operational.  
**Risks**: API rate limits (mitigate with caching), hallucinations (validate with hard price guards).

#### **6.2: Multi-Agent Collaborative System (Week 2)**
Dependencies: Task 6.1 complete, existing agents in `/repo/ai/src/agents/analysts/`.

- **Task 6.2.1**: Define Agent Architecture (Days 1-2)
  - Design 4-agent system: Technical Analyst, Sentiment Analyst, Risk Manager, Strategy Reasoner
  - Create `/src/services/ai/src/agents/coordinator.py` for debate mechanism
  - Define communication protocol (JSON messages via internal API or message queue)
  - Document roles in `/docs/AI_MULTI_AGENT_ARCHITECTURE.md`
  - Agent Prompt: "Design multi-agent trading system with debate consensus"

- **Task 6.2.2**: Implement Technical Analyst Agent (Day 3)
  - Wrap existing ASMBTR logic as agent with LLM reasoning layer
  - Add indicator explanations (why RSI/MACD triggered signal)
  - Output: Confidence score (0-1) + rationale text
  - Test: Validate on 100 historical scenarios

- **Task 6.2.3**: Implement Sentiment Analyst Agent (Day 3)
  - Wrap Task 6.1.2 sentiment engine as agent
  - Add market regime detection (bull/bear/sideways via news volume)
  - Cross-validate sentiment with on-chain metrics (e.g., Glassnode data)

- **Task 6.2.4**: Implement Risk Manager Agent (Day 4)
  - Use Prometheus metrics from `/monitoring/` for portfolio exposure
  - Add LLM risk assessment (e.g., "drawdown >10%, reduce position size")
  - Hard-code circuit breakers (max 5% portfolio per trade)
  - Validation Gate: Simulate risky scenarios, ensure <25% max drawdown

- **Task 6.2.5**: Build Strategy Reasoner Coordinator (Day 5)
  - Implement debate prompt engineering for agent consensus
  - Add voting mechanism (weighted by confidence scores)
  - Log all decisions to `/logs/ai/agent_decisions.jsonl` for auditing
  - Test: 50 multi-agent decisions, compare vs. single-agent baseline
  - Target: Reduce false signals by 30-40%
  - Example Code:
    ```python
    # /src/services/ai/src/agents/coordinator.py
    import openai
    import json
    from datetime import datetime
    
    openai.api_key = "YOUR_KEY"
    
    def multi_agent_decision(technical_signal: float, sentiment_score: float, 
                            risk_level: float) -> dict:
        prompt = f"""
        Technical Analyst: Signal {technical_signal} (1=buy, -1=sell, 0=neutral).
        Sentiment Analyst: Score {sentiment_score} (positive=bullish).
        Risk Manager: Exposure {risk_level} (>0.7=high risk, avoid trades).
        
        Debate and decide: BUY, SELL, or HOLD. Provide confidence (0-1).
        Format: {{"action": "BUY/SELL/HOLD", "confidence": 0.0-1.0, "reason": "..."}}
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[{"role": "user", "content": prompt}]
        )
        
        decision = json.loads(response.choices[0].message.content)
        
        # Log decision
        with open('/logs/ai/agent_decisions.jsonl', 'a') as f:
            json.dump({
                'timestamp': datetime.utcnow().isoformat(),
                'inputs': {'technical': technical_signal, 'sentiment': sentiment_score, 
                          'risk': risk_level},
                'decision': decision
            }, f)
            f.write('\n')
        
        return decision
    ```

**Milestones**: 4-agent system with collaborative decision-making.  
**Risks**: Latency (1-5s per LLM call—acceptable for medium-term trades), cost (~$0.01-0.05 per decision with GPT-4).

#### **6.3: Reflective Learning Mechanism (Week 3)**
Dependencies: Task 6.2 complete, existing `/metrics.json` post-trade data.

- **Task 6.3.1**: Build Trade Performance Database (Days 1-2)
  - Extend PostgreSQL schema for trade history (entry/exit prices, returns, agent decisions)
  - Create `/src/services/ai/src/reflection/trade_store.py` for CRUD operations
  - Migrate existing backtest results to new schema
  - Agent Prompt: "Design SQL schema for trade performance tracking"

- **Task 6.3.2**: Implement Reflection Agent (Days 3-4)
  - Create daily/weekly analysis task in Celery (`/tests/unit/tasks/`)
  - Use LLM to review losing trades: "Why did BTC buy at $65k fail?"
  - Generate adjustment recommendations (e.g., tighten stop-loss, avoid news-driven FUD)
  - Store insights in vector DB (ChromaDB or pgvector) for RAG retrieval
  - Validation Gate: Manually review 20 reflections for quality

- **Task 6.3.3**: Close Feedback Loop (Day 5)
  - Auto-adjust strategy parameters based on reflection insights
  - Add A/B testing framework: Run adaptive vs. fixed strategies in parallel
  - Monitor performance divergence in Grafana dashboard
  - Target: +10-15% performance improvement over 30-day rolling window
  - GitHub Action: Weekly reflection summary report

**Milestones**: Self-improving trading system with reflective learning.  
**Risks**: Over-fitting to recent data (mitigate with rolling validation window).

#### **6.4: Risk Mitigation and Safeguards (Week 4)**
Dependencies: All tasks 6.1-6.3 complete.

- **Task 6.4.1**: Add LLM Output Validation Layer (Days 1-2)
  - Implement schema validation for agent decisions (Pydantic models)
  - Add plausibility checks (e.g., reject "sell" if price dropped 50% in 1min—likely data error)
  - Log rejected decisions to `/logs/ai/invalid_decisions.jsonl`
  - Test: Inject 100 malformed LLM responses, ensure 100% caught

- **Task 6.4.2**: Real-Time Data Quality Monitoring (Day 3)
  - Add data freshness checks (reject stale data >5min old)
  - Implement anomaly detection for price spikes (z-score >3 flags as suspicious)
  - Circuit breaker: Pause trading if >10% of data sources fail
  - Prometheus metrics: `data_quality_score`, `stale_data_count`

- **Task 6.4.3**: Cost Optimization for LLM Calls (Days 4-5)
  - Fine-tune LoRA adapters on FinGPT for sentiment (~$300 one-time cost)
  - Cache common agent debates (e.g., "BTC above 200-day MA" scenarios)
  - Implement tiered LLM usage: GPT-4 for critical decisions, GPT-3.5/Llama for routine
  - Target: Reduce API costs by 60-70% vs. full GPT-4 usage
  - Agent Prompt: "Optimize LLM inference costs for trading agents"

- **Task 6.4.4**: Integration Testing and Dry-Run (Day 5)
  - Run 1000 simulated trades with full agent stack in `/tests/integration/test_ai_agents/`
  - Validate latency <3s per decision, cost <$0.02 per trade
  - Compare vs. baseline ASMBTR: Target +25-35% return, +0.5 Sharpe ratio
  - Validation Gate: Pass all tests before live deployment

**Milestones**: Production-ready AI agent system with risk controls.  
**Risks**: Hallucinations causing bad trades (mitigate with hard price/volatility guards).

---

### Phase 7: Monorepo Split and Multi-Repo Migration (1-2 Weeks)
Transform FKS monorepo into independent service repositories for improved scalability, faster CI/CD, and team autonomy.

**Motivation**: Research shows multi-repo setups achieve 20-30% faster CI/CD pipelines post-split, with 25% better iteration velocity. Current monorepo (1,731 files, avg 1.3MB each) causes long build times and tight coupling. Split enables independent service lifecycles, isolated deployments, and better resource optimization (e.g., GPU-optional fks_ai).

**Sub-Phases and Tasks**:

#### **7.1: Preparation and Planning (Days 1-2)**
Dependencies: Full codebase backup, git-filter-repo tool.

- **Task 7.1.1**: Backup and Tool Setup (Day 1)
  - Create full backup: `git bundle create fks-backup-$(date +%Y%m%d).bundle --all`
  - Install git-filter-repo: `pip install git-filter-repo`
  - Document current monorepo structure in `/docs/MONOREPO_BASELINE.md`
  - Validation Gate: Verify backup can restore successfully
  - Agent Prompt: "Document current monorepo structure with file counts per service"

- **Task 7.1.2**: Define Repository Mapping (Day 2)
  - Map files to target repos (see table below)
  - Identify shared code: `/src/shared/`, `/src/core/`, `/src/framework/` (351 files)
  - Create GitHub repos: fks_ai, fks_api, fks_app, fks_data, fks_execution, fks_ninja, fks_meta, fks_web
  - Document strategy in `/docs/MULTI_REPO_ARCHITECTURE.md`
  - Agent Prompt: "Create GitHub repositories and document split strategy"

**Repository Mapping** (from 1,731 total files):

| Repository | File Count | Key Paths | Docker Image | Notes |
|------------|-----------|-----------|--------------|-------|
| **fks_ai** | 235 | `/repo/ai/*`, `/src/services/ai/*`, `/notebooks/transformer/*` | `nuniesmith/fks_ai:cpu`, `:gpu` | Multi-stage Dockerfile (CPU/GPU variants), ARM64 support for Raspberry Pi |
| **fks_api** | 180 | `/repo/api/*`, `/src/services/api/*`, `/tests/integration/test_api*` | `nuniesmith/fks_api:latest` | REST API routers, duplicate shared code |
| **fks_app** | 66 | `/repo/app/*`, `/src/services/app/*`, `/data/asmbtr_real_data_optimization.json` | `nuniesmith/fks_app:latest` | Trading strategies and business logic |
| **fks_data** | 200 | `/repo/data/*`, `/src/services/data/*`, `/data/market_data/*` | `nuniesmith/fks_data:latest` | Data adapters (Polygon, Binance, CCXT) |
| **fks_execution** | 36 | `/src/services/execution/*`, `/tests/unit/test_execution/*` | `nuniesmith/fks_execution:latest` | CCXT manager, normalizer, validation |
| **fks_ninja** | 159 | `/repo/ninja/*` (C# files) | `nuniesmith/fks_ninja:latest` | NinjaTrader plugin (.csproj build) |
| **fks_meta** | 1+ | `/scripts/devtools/scripts-meta/*` (create new structure) | `nuniesmith/fks_meta:latest` | MetaTrader plugin (minimal, expandable) |
| **fks_web** | 158 | `/repo/web/*`, `/src/services/web/*`, `/tests/unit/test_web_views.py` | `nuniesmith/fks_web:latest` | Django UI, static files |
| **main_fks** | 696 | `/docs/*`, `/k8s/*`, `/monitoring/*`, `/scripts/*`, `/Makefile` | N/A (orchestrator) | Master repo, K8s manifests, Helm charts |

#### **7.2: Shared Code Strategy (Days 3-4)**
Dependencies: Task 7.1.2 complete.

- **Task 7.2.1**: Duplicate Shared Code (Day 3)
  - Copy `/src/shared/`, `/src/core/`, `/src/framework/` to each sub-repo's `/shared/` directory
  - Add sync script: `/scripts/sync-shared-code.sh` (propagates changes across repos)
  - Document duplication strategy in `/docs/SHARED_CODE_MANAGEMENT.md`
  - Validation Gate: Test builds in 2 sub-repos with duplicated code
  - Agent Prompt: "Create script to sync shared code across all sub-repos"

- **Task 7.2.2**: Plan Future fks_shared Package (Day 4)
  - Design Python package structure for future extraction
  - Add to roadmap: Convert duplicated code to pip-installable package
  - Create `/docs/FKS_SHARED_PACKAGE_DESIGN.md`
  - Timeline: Phase 9 (after migration stabilizes)

#### **7.3: Repository Splitting (Days 5-7)**
Dependencies: Tasks 7.1-7.2 complete.

- **Task 7.3.1**: Split fks_ai Repository (Day 5 AM)
  ```bash
  # Clone monorepo to temp directory
  git clone /home/jordan/Documents/code/fks fks_ai_temp
  cd fks_ai_temp
  
  # Filter to keep only AI-related paths
  git filter-repo --path repo/ai/ --path src/services/ai/ \
    --path notebooks/transformer/ --path tests/unit/test_rag/ \
    --path docs/AI_ARCHITECTURE.md --force
  
  # Add remote and push
  git remote add origin https://github.com/nuniesmith/fks_ai.git
  git push -u origin main
  ```
  - Validation Gate: Clone new repo, verify file structure
  - Agent Prompt: "Split fks_ai repository using git-filter-repo"

- **Task 7.3.2**: Split fks_api Repository (Day 5 PM)
  - Repeat process for fks_api paths
  - Validate API tests run independently
  - Agent Prompt: "Split fks_api repository and validate tests"

- **Task 7.3.3**: Split fks_data Repository (Day 6 AM)
  - Extract data service and adapters
  - Validate CCXT integration works standalone
  - Agent Prompt: "Split fks_data repository with CCXT adapters"

- **Task 7.3.4**: Split Remaining Repositories (Day 6 PM - Day 7)
  - Split fks_app, fks_execution, fks_web
  - Create minimal fks_meta with placeholder structure
  - Extract fks_ninja with C# build configuration
  - Validation Gate: All 8 repos created, basic README in each

#### **7.4: Docker and Compose Setup (Days 8-9)**
Dependencies: Task 7.3 complete, DockerHub account configured.

- **Task 7.4.1**: Create Multi-Stage Dockerfile for fks_ai (Day 8 AM)
  ```dockerfile
  # /fks_ai/Dockerfile
  # Stage 1: Base (CPU)
  FROM python:3.12-slim AS base
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  COPY src/ ./src/
  COPY shared/ ./shared/
  ENV PYTHONPATH=/app
  CMD ["python", "src/main.py"]
  
  # Stage 2: GPU
  FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS gpu
  WORKDIR /app
  RUN apt-get update && apt-get install -y python3 python3-pip
  COPY requirements.txt .
  RUN pip3 install --no-cache-dir -r requirements.txt \
      && pip3 install torch --index-url https://download.pytorch.org/whl/cu121
  COPY src/ ./src/
  COPY shared/ ./shared/
  ENV PYTHONPATH=/app
  CMD ["python3", "src/main.py"]
  ```
  - Build commands: `docker build --target base -t nuniesmith/fks_ai:cpu .`
  - ARM64 variant: `docker build --platform linux/arm64 -t nuniesmith/fks_ai:arm64 .`
  - Agent Prompt: "Create multi-stage Dockerfile with CPU/GPU/ARM64 variants"

- **Task 7.4.2**: Create docker-compose.yml for Each Sub-Repo (Day 8 PM)
  ```yaml
  # /fks_ai/docker-compose.yml
    services:
    ai:
      build:
        context: .
        target: base  # or 'gpu' for GPU variant
      image: nuniesmith/fks_ai:cpu
      ports:
        - "8007:8000"
      environment:
        - GPU_ENABLED=false
        - REDIS_HOST=redis
      depends_on:
        - redis
      networks:
        - fks_network
    redis:
      image: redis:7-alpine
      networks:
        - fks_network
  networks:
    fks_network:
      driver: bridge
  ```
  - Repeat for all sub-repos with appropriate ports (8001-8009)
  - Test locally: `docker-compose up` in each repo
  - Validation Gate: Each service starts successfully
  - Agent Prompt: "Create docker-compose.yml for all sub-repos with unique ports"

- **Task 7.4.3**: Create Master Compose in main_fks (Day 9)
  ```yaml
  # /main_fks/docker-compose.yml
    services:
    ai:
      image: nuniesmith/fks_ai:cpu
      ports: ["8007:8000"]
    api:
      image: nuniesmith/fks_api:latest
      ports: ["8001:8000"]
    data:
      image: nuniesmith/fks_data:latest
      ports: ["8003:8000"]
    app:
      image: nuniesmith/fks_app:latest
      ports: ["8002:8000"]
    execution:
      image: nuniesmith/fks_execution:latest
      ports: ["8006:8000"]
    web:
      image: nuniesmith/fks_web:latest
      ports: ["8000:8000"]
    # Add postgres, redis, grafana, prometheus...
  ```
  - Test integrated stack: `docker-compose up` in main_fks
  - Agent Prompt: "Create master docker-compose.yml for all services"

#### **7.5: GitHub Actions CI/CD (Days 10-11)**
Dependencies: Task 7.4 complete, DockerHub secrets configured.

- **Task 7.5.1**: Add Build/Push Workflow to Sub-Repos (Day 10)
  ```yaml
  # /fks_ai/.github/workflows/build-push.yml
  name: Build and Push Docker Images
  on:
    push:
      branches: [main]
    pull_request:
      branches: [main]
  
  jobs:
    build-cpu:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        
        - name: Login to DockerHub
          uses: docker/login-action@v3
          with:
            username: ${{ secrets.DOCKER_USERNAME }}
            password: ${{ secrets.DOCKER_PASSWORD }}
        
        - name: Build and Push CPU
          uses: docker/build-push-action@v6
          with:
            context: .
            target: base
            push: true
            tags: ${{ secrets.DOCKER_USERNAME }}/fks_ai:cpu,nuniesmith/fks_ai:latest
        
        - name: Build and Push GPU
          uses: docker/build-push-action@v6
          with:
            context: .
            target: gpu
            push: true
            tags: ${{ secrets.DOCKER_USERNAME }}/fks_ai:gpu
    
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Run Tests
          run: |
            pip install -r requirements.txt -r requirements.dev.txt
            pytest tests/ -v
  ```
  - Add secrets: DOCKER_USERNAME, DOCKER_PASSWORD to each repo
  - Repeat workflow for all sub-repos (adjust build steps as needed)
  - Validation Gate: Trigger workflow, verify images on DockerHub
  - Agent Prompt: "Create GitHub Actions workflows for all sub-repos"

- **Task 7.5.2**: Add Deployment Workflow to main_fks (Day 11)
  ```yaml
  # /main_fks/.github/workflows/deploy-all.yml
  name: Deploy All Services
  on:
    workflow_dispatch:  # Manual trigger
    push:
      branches: [main]
      paths:
        - 'k8s/**'
        - 'docker-compose.yml'
  
  jobs:
    deploy-compose:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Deploy with Docker Compose
          run: |
            docker-compose pull
            docker-compose up -d
    
    deploy-k8s:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Setup kubectl
          uses: azure/setup-kubectl@v3
        - name: Deploy to K8s
          run: |
            kubectl apply -f k8s/manifests/
            kubectl rollout status deployment --all -n fks-trading
  ```
  - Test deployment trigger
  - Agent Prompt: "Create master deployment workflow for main_fks"

#### **7.6: Kubernetes Integration (Days 12-13)**
Dependencies: Task 7.5 complete, K8s cluster available.

- **Task 7.6.1**: Update K8s Manifests in main_fks (Day 12)
  ```yaml
  # /main_fks/k8s/manifests/fks-ai-deployment.yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: fks-ai
    namespace: fks-trading
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: fks-ai
    template:
      metadata:
        labels:
          app: fks-ai
      spec:
        containers:
          - name: ai
            image: nuniesmith/fks_ai:cpu  # Pull from DockerHub
            ports:
              - containerPort: 8000
            resources:
              requests:
                cpu: "500m"
                memory: "1Gi"
              limits:
                cpu: "2000m"
                memory: "4Gi"
            env:
              - name: GPU_ENABLED
                value: "false"
        # For GPU variant:
        # nodeSelector:
        #   nvidia.com/gpu: "true"
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: fks-ai
    namespace: fks-trading
  spec:
    selector:
      app: fks-ai
    ports:
      - port: 8007
        targetPort: 8000
  ```
  - Update all service manifests (api, data, app, execution, web)
  - Use Kompose for initial conversion: `kompose convert -f docker-compose.yml`
  - Agent Prompt: "Update K8s manifests to use sub-repo images from DockerHub"

- **Task 7.6.2**: Create Helm Chart for Multi-Service Deployment (Day 13)
  ```bash
  # /main_fks/helm/fks-stack/
  helm create fks-stack
  # Customize values.yaml with all service images
  # Add subcharts for each service
  ```
  - Validation Gate: `helm install fks-stack ./helm/fks-stack --dry-run`
  - Test deployment: `helm install fks-stack ./helm/fks-stack -n fks-trading`
  - Agent Prompt: "Create Helm chart for deploying all FKS services"

#### **7.7: Raspberry Pi Testing (Day 14)**
Dependencies: Task 7.6 complete, Raspberry Pi 4/5 with k3s.

- **Task 7.7.1**: Set Up k3s on Raspberry Pi (Day 14 AM)
  ```bash
  # On Raspberry Pi
  curl -sfL https://get.k3s.io | sh -
  sudo k3s kubectl get nodes  # Verify cluster
  
  # Copy kubeconfig to dev machine
  scp pi@raspberrypi:/etc/rancher/k3s/k3s.yaml ~/.kube/config-pi
  export KUBECONFIG=~/.kube/config-pi
  ```
  - Install kubectl on Pi if needed
  - Agent Prompt: "Document k3s installation on Raspberry Pi"

- **Task 7.7.2**: Deploy fks_ai CPU Variant to Pi (Day 14 PM)
  ```bash
  # Build ARM64 image
  docker buildx build --platform linux/arm64 \
    -t nuniesmith/fks_ai:arm64 --push .
  
  # Update K8s manifest
  kubectl apply -f k8s/manifests/fks-ai-deployment-arm.yaml
  kubectl logs -f deployment/fks-ai
  ```
  - Run lightweight tests (inference, sentiment analysis)
  - Monitor resource usage: `kubectl top pods`
  - Validation Gate: AI service responds on Pi, <2GB RAM usage
  - Document results in `/docs/RASPBERRY_PI_TESTING.md`
  - Agent Prompt: "Deploy and test fks_ai on Raspberry Pi k3s cluster"

**Milestones**: Multi-repo architecture operational, 20-30% faster CI/CD, independent service deployments.  
**Risks**: 
- Initial 15% coordination overhead (mitigate with automation)
- Shared code drift (mitigate with sync scripts, future fks_shared package)
- Broken dependencies during split (mitigate with incremental testing)

**Timeline**: 2 weeks total (can parallelize some repo splits to reduce to 10-12 days)

---

### Phase 6.5: Multi-Agent Debate System (2-3 Weeks)
Implement Layered-Memory Trader (LMT) inspired multi-agent system with debate consensus, reducing false signals by 40-60% and targeting Sharpe ratio 2.0+.

**Motivation**: Research (TradingGPT arXiv:2309.03736, LayeredMemoryTrader) shows multi-agent debate with layered memory achieves 15-25% higher returns vs baselines, with <8% drawdowns. FKS's existing agents lack inter-agent voting and horizon-specific memory, leading to potential overtrading and noise.

**Sub-Phases and Tasks**:

#### **6.5.1: Layered Memory Implementation (Week 1)**
Dependencies: Existing data pipelines in `/repo/data/src/processors`.

- **Task 6.5.1.1**: Design Memory Architecture (Days 1-2)
  - Create `/repo/data/src/memory/manager.py` with MemoryManager class
  - Define horizons: short (<60min), mid (days-weeks), long (months)
  - Set buffer size caps: short (60 candles), mid (10K), long (50K)
  - Document in `/docs/LAYERED_MEMORY_ARCHITECTURE.md`
  - Agent Prompt: "Design layered memory system for time-horizon-specific trading"

- **Task 6.5.1.2**: Implement Memory Buffers (Days 3-4)
  - Rolling DataFrame buffers per horizon with auto-purge
  - Integration with CCXT data feeds (`/tests/integration/test_data`)
  - Add Prometheus metrics: `memory_buffer_size`, `memory_update_latency`
  - Example Code:
    ```python
    # /repo/data/src/memory/manager.py
    import pandas as pd
    from typing import Dict
    
    class MemoryManager:
        def __init__(self, horizons: Dict[str, int]):
            # horizons = {'short': 60, 'mid': 1440*7, 'long': 1440*30}
            self.horizons = horizons
            self.buffers = {k: pd.DataFrame() for k in horizons}
        
        def update(self, new_data: pd.DataFrame):
            """Update all buffers with new candle data."""
            for horizon, size in self.horizons.items():
                self.buffers[horizon] = pd.concat(
                    [self.buffers[horizon], new_data]
                ).tail(size)
        
        def get_snapshot(self) -> Dict[str, pd.DataFrame]:
            """Get current state of all memory buffers."""
            return self.buffers.copy()
    ```

- **Task 6.5.1.3**: Backtest with Memory Layers (Day 5)
  - Extend `/tests/integration/test_backtest` to use layered memory
  - Test on 2023-24 AAPL/GOOG/MSFT data (per LMT benchmarks)
  - Target: <8% drawdown, Sharpe >2.0
  - Validation Gate: Memory size stays within caps under load

**Milestones**: Layered memory operational with sub-5ms update latency.  
**Risks**: Memory overflow (mitigate with size caps), stale data (add freshness checks).

#### **6.5.2: Specialized Trading Agents (Week 2)**
Dependencies: Task 6.5.1 complete, existing `/repo/ai/src/agents/analysts`.

- **Task 6.5.2.1**: Implement Short-Term Momentum Agent (Days 1-2)
  - Create `/repo/ai/src/agents/specialists/short_term.py`
  - Focus: <60min data, momentum indicators (RSI, MACD)
  - Output: Vote (BUY/SELL/HOLD) + Confidence (0-1)
  - LLM Prompt Template:
    ```python
    prompt = f"""
    You are a Short-Term Momentum Analyst. Analyze:
    - Last 60 minutes of {symbol} data
    - RSI: {rsi}, MACD: {macd}, Volume: {volume}
    - Recent price action: {price_change}%
    
    Vote: BUY, SELL, or HOLD
    Confidence: 0.0-1.0
    Reason: Brief explanation
    
    Format: {{"vote": "BUY", "confidence": 0.85, "reason": "..."}}
    """
    ```
  - Test: 50 historical scenarios, validate confidence calibration

- **Task 6.5.2.2**: Implement Mid-Term Swing Agent (Day 3)
  - Create `/repo/ai/src/agents/specialists/mid_term.py`
  - Focus: Days-weeks data, trend analysis (EMA crossovers, Bollinger Bands)
  - Cross-validate with short-term for conflict detection
  - Integration with sentiment module from Phase 6.1.2

- **Task 6.5.2.3**: Implement Long-Term Macro Agent (Day 4)
  - Create `/repo/ai/src/agents/specialists/long_term.py`
  - Focus: Months data, fundamental analysis via news
  - Semantic search on `/data/market_data` for macro events
  - Use embeddings from Gemini API (Phase 6.6) or local models

- **Task 6.5.2.4**: Integration Testing (Day 5)
  - Test all 3 agents with layered memory snapshots
  - Validate vote+confidence format consistency
  - Measure latency: Target <2s per agent
  - Document in `/docs/AGENT_SPECIALISTS.md`

**Milestones**: 3 specialized agents operational with distinct time horizons.  
**Risks**: Agent conflicts (mitigate with debate engine), latency (use async calls).

#### **6.5.3: Debate Engine and Consensus (Week 3)**
Dependencies: Tasks 6.5.1-6.5.2 complete.

- **Task 6.5.3.1**: Build Debate Coordinator (Days 1-2)
  - Create `/repo/ai/src/agents/debate_engine.py` with DebateEngine class
  - Confidence-weighted voting: `net_strength = Σ(conf × vote_value)`
  - Threshold-based action: trade only if `|net_strength| / total_conf > 0.6`
  - Example Code:
    ```python
    # /repo/ai/src/agents/debate_engine.py
    from typing import List, Tuple, Dict
    
    class DebateEngine:
        def __init__(self, agents: List, threshold: float = 0.6):
            self.agents = agents  # [ShortTermAgent, MidTermAgent, LongTermAgent]
            self.threshold = threshold
        
        def run_debate(self, memory_snapshot: Dict) -> Dict:
            votes = []
            for agent in self.agents:
                vote, conf, reason = agent.vote(memory_snapshot)
                votes.append({'agent': agent.name, 'vote': vote, 'conf': conf, 'reason': reason})
            
            # Calculate weighted consensus
            buy_strength = sum(v['conf'] for v in votes if v['vote'] == 'BUY')
            sell_strength = sum(v['conf'] for v in votes if v['vote'] == 'SELL')
            total_conf = sum(v['conf'] for v in votes)
            
            net = buy_strength - sell_strength
            decision_conf = abs(net) / total_conf if total_conf > 0 else 0.5
            
            if decision_conf < self.threshold:
                action = 'HOLD'
            else:
                action = 'BUY' if net > 0 else 'SELL'
            
            return {
                'action': action,
                'confidence': decision_conf,
                'votes': votes,
                'consensus_strength': net
            }
    ```

- **Task 6.5.3.2**: Integrate with ASMBTR (Day 3)
  - Modify `/repo/app/src/tasks/asmbtr_prediction.py`
  - Call debate before final prediction
  - Combine ASMBTR technical + debate consensus
  - Hybrid formula: `final = 0.5 * asmbtr + 0.5 * debate`

- **Task 6.5.3.3**: Logging and Auditability (Day 4)
  - Log all debates to `/logs/ai/agent_decisions.jsonl`
  - Include timestamp, votes, consensus, final action
  - Add Prometheus metrics: `debate_duration_seconds`, `vote_distribution`
  - Store in PostgreSQL for post-trade reflection (Phase 6.3.1)

- **Task 6.5.3.4**: Backtesting with Debate (Day 5)
  - Run on 2024 crypto data (BTC/ETH)
  - Compare: ASMBTR only vs ASMBTR+Debate vs Debate only
  - Target: 40-60% reduction in false signals, +25-35% returns
  - Validation Gate: Max drawdown <10%, trade hold ratio 40%+
  - Document in `/docs/DEBATE_BACKTESTING_RESULTS.md`

**Milestones**: Debate engine operational, integrated with ASMBTR, backtested.  
**Risks**: Debate inaction (tune threshold), over-complexity (fallback to technical).

**Timeline**: 3 weeks total, can parallelize agent development (Week 2) to reduce to 2.5 weeks.

---

### Phase 6.6: Gemini API Integration for Cost Optimization (1 Week)
Leverage Google Gemini API's free tier (1,500 requests/day) to offload 50-70% of light AI tasks, reducing GPU load and enabling CPU-only Raspberry Pi deployment.

**Motivation**: Gemini offers generous free tier suitable for baselines (sentiment, simple reasoning). Research shows ~$0.30/1M tokens paid tier (vs OpenAI $5/1M), with multimodal support. FKS can reserve local GPU for heavy tasks (ASMBTR training) while offloading routine queries.

**Sub-Phases and Tasks**:

#### **6.6.1: Setup and Evaluation (Days 1-2)**
Dependencies: None, standalone integration.

- **Task 6.6.1.1**: API Setup (Day 1)
  - Register for free tier at Google AI Studio
  - Generate API key (no billing required for 1,500 req/day)
  - Install SDK: `pip install google-generativeai`
  - Add to `/requirements.txt` and Docker images
  - Store key in K8s secrets: `GEMINI_API_KEY`
  - Agent Prompt: "Set up Gemini API free tier for FKS AI offloading"

- **Task 6.6.1.2**: Baseline Prototyping (Day 2)
  - Create `/repo/ai/src/integrations/gemini_client.py`
  - Test text generation, chat, embeddings on free tier
  - Measure latency (target <3s per call)
  - Compare sentiment analysis: Gemini vs FinBERT (Phase 6.1.2)
  - Example Code:
    ```python
    # /repo/ai/src/integrations/gemini_client.py
    import google.generativeai as genai
    import os
    
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    
    class GeminiClient:
        def __init__(self, model='gemini-1.5-flash'):
            self.model = genai.GenerativeModel(model)
            self.daily_quota = 1500
            self.request_count = 0
        
        def analyze_sentiment(self, text: str) -> dict:
            if self.request_count >= self.daily_quota:
                return {'vote': 'HOLD', 'conf': 0.5, 'source': 'quota_exceeded'}
            
            prompt = f"Analyze trading sentiment: {text}. Return JSON: {{\"vote\": \"BUY/SELL/HOLD\", \"confidence\": 0.0-1.0, \"reason\": \"...\"}}"
            response = self.model.generate_content(prompt)
            self.request_count += 1
            
            # Parse response (regex for JSON)
            import re, json
            match = re.search(r'\{.*\}', response.text, re.DOTALL)
            if match:
                return json.loads(match.group())
            return {'vote': 'HOLD', 'conf': 0.5, 'source': 'parse_error'}
    ```

#### **6.6.2: Offloading Strategy (Days 3-4)**
Dependencies: Task 6.6.1 complete.

- **Task 6.6.2.1**: Define Offload Rules (Day 3)
  - Create config: `/docs/GEMINI_OFFLOAD_RULES.md`
  - Rules:
    * Sentiment analysis on news: Offload if quota <80% used
    * Simple strategy reasoning: Offload for low-complexity queries
    * Embeddings for RAG: Offload if local GPU busy
    * Heavy tasks (ASMBTR training, transformer): Always local
  - Add complexity estimator in `/repo/ai/src/utils/task_classifier.py`

- **Task 6.6.2.2**: Integrate with Agents (Day 4)
  - Modify Phase 6.5 agents to use Gemini for prompts
  - Add fallback: If Gemini fails/quota exceeded, use local models
  - Track usage in Prometheus: `gemini_requests_total`, `gemini_quota_remaining`
  - Example integration in short-term agent:
    ```python
    # In /repo/ai/src/agents/specialists/short_term.py
    from repo.ai.src.integrations.gemini_client import GeminiClient
    
    class ShortTermAgent:
        def __init__(self):
            self.gemini = GeminiClient()
            self.use_gemini = True  # Config flag
        
        def vote(self, memory_snapshot):
            if self.use_gemini and self.gemini.request_count < 1400:
                # Offload to Gemini
                prompt = f"Short-term momentum analysis for {symbol}..."
                result = self.gemini.model.generate_content(prompt)
                return self._parse_vote(result.text)
            else:
                # Local fallback
                return self._local_analysis(memory_snapshot)
    ```

#### **6.6.3: Cost Monitoring and Optimization (Day 5)**
Dependencies: Task 6.6.2 complete.

- **Task 6.6.3.1**: Usage Tracking Dashboard
  - Add Grafana panel for Gemini metrics
  - Track daily quota consumption, latency, error rates
  - Alert if quota >90% used (fallback to local)
  - Document in `/docs/GEMINI_MONITORING.md`

- **Task 6.6.3.2**: A/B Testing (Day 5)
  - Run parallel: Gemini-offloaded vs All-local
  - Compare: Latency, accuracy, cost (free vs GPU power)
  - Target: 50-70% GPU load reduction, <5% accuracy drop
  - Validation Gate: Free tier handles 60-80% of daily queries
  - Document results in `/docs/GEMINI_AB_TEST_RESULTS.md`

**Milestones**: Gemini integrated, 50-70% offload achieved, free tier optimized.  
**Risks**: API rate limits (monitor quota), latency (async calls), privacy (use public data only).

**Timeline**: 1 week total, can start in parallel with Phase 6.5.

---

### Phase 8: NinjaTrader/MT5 Integration (Optional, 1-2 Weeks)
- Migrate fks_ninja to plugin framework
- Migrate fks_mt5 to plugin framework  
- Add C# bindings (csbindgen) and MT5 DLL bindings
- Test bridges with simulated orders

---

### Phase 9: Production Operations (Ongoing)
- Deploy to cloud K8s (GKE/EKS/AKS)
- Configure DNS for ingress hosts
- Set up Slack channels for alerts
- Implement GitOps (Flux/ArgoCD)
- Add distributed tracing (Jaeger)
- Log aggregation (ELK/Loki)
- Chaos engineering (Chaos Mesh)
- Multi-region deployment

---

### Phase 10: Advanced Features (Future)
- Extract fks_shared as pip-installable package
- Distributed rate limiting (Redis)
- Advanced order types (iceberg, trailing stop)
- Multi-exchange arbitrage via CCXT
- Real-time portfolio optimization with LLM agents
- SLO/SLI dashboards for trading performance
- Cost optimization for cloud infrastructure

---

## 🚀 Quick Commands

```bash
# Check K8s cluster status
kubectl get pods -n fks-trading
kubectl get svc,ingress -n fks-trading

# Test live services
curl -k https://api.fkstrading.xyz/health
curl -k https://fkstrading.xyz

# Access Grafana (requires minikube tunnel)
minikube tunnel  # (separate terminal)
# Open: https://grafana.fkstrading.xyz (admin/admin)

# Check database
kubectl exec -it postgres-0 -n fks-trading -- psql -U trading_user -d trading_db

# Check Redis
kubectl exec -it deployment/redis -n fks-trading -- redis-cli ping

# View logs
kubectl logs -f deployment/fks-api -n fks-trading

# Run all tests
make test  # 168/168 should pass

# Run linting
make lint
```

---

## 📊 Project Statistics

- **Total Tests**: 168/168 passing (100%)
- **Code Coverage**: 100% (execution pipeline)
- **Performance**: <50ms latency, >80 req/s throughput
- **K8s Services**: 13/14 healthy (93% operational)
- **Storage**: 170Gi allocated (postgres 100Gi, redis 10Gi, monitoring 60Gi)
- **Monitoring**: Prometheus + Grafana + Alertmanager live

---

## 🎯 Immediate Next Action

**Phase 5.5 Complete - K8s Deployment Live!** ✅ (November 6, 2025, 11:15 PM EST)

### Current Live System Status

**Minikube Cluster**:
- ✅ 13/14 pods Running (93% operational)
- ✅ 170Gi persistent storage allocated and bound
- ✅ TLS ingress with self-signed certs on *.fkstrading.xyz
- ✅ Landing page deployed and serving
- ✅ All backend services (API, App, Data, AI) healthy
- ✅ Monitoring stack (Grafana, Prometheus, Alertmanager) operational
- ⚠️ Django web/Celery services scaled to 0 (Docker image needs Celery dependencies)

**Live Access URLs**:
- 🏠 Landing Page: <https://fkstrading.xyz>
- 📊 API Health: <https://api.fkstrading.xyz/health>
- 📈 Grafana: <https://grafana.fkstrading.xyz> (admin/admin)
- 🔍 Prometheus: <https://prometheus.fkstrading.xyz>
- 🔔 Alertmanager: <https://alertmanager.fkstrading.xyz>

**Quick Reference Docs**:
- `/QUICK_ACCESS.md` - All working URLs and test commands
- `/HEALTH_STATUS.md` - Current operational status
- `/docs/503_FIX_COMPLETE.md` - Landing page resolution
- `/docs/HEALTH_CHECK_REPORT.md` - DEMO_PLAN readiness assessment

### Choose Your Path Forward

**Path A: Start Phase 6 - LLM AI Trading Agent Evolution** (2-4 weeks) ⭐ HIGH IMPACT
```bash
# Transform FKS from rule-based bot to adaptive AI agent system
# Research shows 20-40% return improvements in volatile crypto markets
# 
# Week 1: LLM Sentiment Analysis Integration
# - Install transformers, FinBERT models
# - Build news/social sentiment engine (CryptoPanic, NewsAPI)
# - Integrate sentiment into ASMBTR strategy
# Target: +15-20% backtest improvement
#
# Week 2: Multi-Agent Collaborative System
# - Build 4-agent system: Technical, Sentiment, Risk, Strategy Reasoner
# - Implement debate mechanism for consensus
# Target: 30-40% reduction in false signals, +0.5 Sharpe ratio
#
# Week 3: Reflective Learning Mechanism
# - Daily/weekly trade review with LLM
# - Auto-adjust strategy parameters
# Target: +10-15% performance over 30-day window
#
# Week 4: Risk Mitigation & Production Deployment
# - LLM output validation, data quality monitoring
# - Fine-tune LoRA adapters to reduce API costs 60-70%
# - 1000 simulated trades validation
#
# Agent Delegation: "Start Phase 6.1 - Implement FinBERT sentiment analysis module"
```

**Path B: Fix Docker Images for 100% Operational** (1-2 hours) ✅ QUICK WIN
```bash
# Update requirements.txt to include Celery
# Rebuild: docker build -f docker/Dockerfile -t nuniesmith/fks:web-v2 .
# Push: docker push nuniesmith/fks:web-v2
# Deploy: kubectl set image deployment/fks-web web=nuniesmith/fks:web-v2
# Scale up: kubectl scale deployment fks-web --replicas=2
```

**Path C: Start DEMO_PLAN Phase 1 Work** (Immediate) ✅ READY NOW
```bash
# Backend infrastructure 100% ready for:
# - Phase 1: Stabilization & Security (run tests, cleanup imports)
# - Phase 2: Yahoo Finance Integration (implement in fks-data service)
# - Phase 4: RAG Intelligence (implement in fks-ai service)
# Use docker-compose locally for Django development while K8s provides backend
```

**Path D: Deploy to Cloud Kubernetes** (2-3 hours)
```bash
# Migration from minikube to cloud (GKE/EKS/AKS)
# - Provision managed K8s cluster
# - Configure DNS for real domain (replace *.fkstrading.xyz)
# - Install cert-manager for Let's Encrypt (replace self-signed)
# - Public LoadBalancer for TradingView webhooks
# - Slack/PagerDuty alert integration
```

**Path E: Advanced Monitoring & Observability** (1 hour)
```bash
# Add distributed tracing (Jaeger)
# Add log aggregation (Loki or ELK Stack)
# Create SLO/SLI dashboards
# Custom Prometheus alerting rules
```

**Path F: Start Phase 7 - Monorepo Split** (1-2 weeks) 📦 SCALABILITY
```bash
# Transform monorepo into independent service repositories
# Research shows 20-30% faster CI/CD pipelines post-split
#
# Week 1: Preparation and Splitting
# - Backup monorepo, install git-filter-repo
# - Map 1,731 files to 8 sub-repos + main orchestrator
# - Split repos with history preservation
# Target: Independent fks_ai, fks_api, fks_data, etc.
#
# Week 2: Docker, Compose, and Deployment
# - Multi-stage Dockerfiles (CPU/GPU/ARM64 for fks_ai)
# - GitHub Actions for each sub-repo (build/test/push)
# - Update K8s manifests in main repo
# - Test on Raspberry Pi with k3s
# Target: 25% improvement in deployment velocity
#
# Agent Delegation: "Start Phase 7.1 - Backup monorepo and install git-filter-repo"
```

### Suggested Commands

```bash
# Check current cluster status
kubectl get pods -n fks-trading
kubectl get svc,ingress -n fks-trading

# Test API
curl -k https://api.fkstrading.xyz/health

# Access Grafana (requires minikube tunnel)
minikube tunnel  # (separate terminal, keep running)
# Open: https://grafana.fkstrading.xyz

# View logs
kubectl logs -f deployment/fks-api -n fks-trading
```

### Documentation Reference

- **Quick Access**: `/QUICK_ACCESS.md` - All working URLs and quick tests
- **Health Status**: `/HEALTH_STATUS.md` - Current operational status  
- **Full Deployment**: `/docs/FULL_STACK_DEPLOYMENT.md` - Complete guide (579 lines)
- **Health Report**: `/docs/HEALTH_CHECK_REPORT.md` - DEMO_PLAN readiness (479 lines)
- **503 Fix**: `/docs/503_FIX_COMPLETE.md` - Landing page resolution
- **Phase 5 Complete**: `/docs/PHASE_5_COMPLETE.md`
- **Phase 4 Summary**: `/docs/PHASE_4_MONITORING_SUMMARY.md`
- **Phase 3 Complete**: `/docs/PHASE_3_COMPLETE.md`

**Agent Delegation for Next Work**:
- "Fix Docker images for Django web and Celery services to reach 100% operational"
- "Start DEMO_PLAN Phase 1 - Stabilization & Security hardening"
- "Start DEMO_PLAN Phase 2 - Implement Yahoo Finance integration in fks-data"
- "Start DEMO_PLAN Phase 4 - Implement RAG Intelligence in fks-ai"
- "Deploy to cloud K8s (GKE/EKS/AKS) with real domain"
- "Add distributed tracing with Jaeger"
- "Implement log aggregation with ELK or Loki"
xdg-open http://localhost:9090  # Prometheus
```

### Documentation Reference

- **Phase 5 Summary**: `/docs/PHASE_5_SUMMARY.md`
- **Phase 5 Complete**: `/docs/PHASE_5_COMPLETE.md`
- **Phase 5 Quick Reference**: `/docs/PHASE_5_QUICKREF.md`
- **Phase 4 Summary**: `/docs/PHASE_4_MONITORING_SUMMARY.md`
- **Phase 3 Complete**: `/docs/PHASE_3_COMPLETE.md`
- **Project Roadmap**: `.github/copilot-instructions.md` (this file)

**Agent Delegation for Next Work**:
- "Deploy Phase 5 to local Kubernetes cluster (minikube)"
- "Configure DNS and deploy to cloud K8s (GKE/EKS/AKS)"
- "Start Phase 6 - Migrate fks_ninja to ExecutionPlugin framework"
- "Start Phase 7 - Implement GitOps with Flux or ArgoCD"
- "Add distributed tracing with Jaeger"
- "Implement log aggregation with ELK or Loki"
- "Create SLO/SLI dashboards for trading performance"

---

## 📚 Key Documentation

- `/docs/PHASE_3_COMPLETE.md` - Complete Phase 3 technical documentation
- `/docs/PHASE_3_SUMMARY.md` - Executive summary  
- `/src/services/execution/metrics.py` - Metrics definitions
- `/monitoring/prometheus/rules/execution_alerts.yml` - Alert rules
- `/monitoring/README.md` - Monitoring infrastructure guide

---

## 🤖 AI Trading Agent Research & References

### Key Benefits of LLM Integration
- **Return Improvement**: 20-40% higher returns in volatile crypto markets (FinGPT benchmarks)
- **Risk-Adjusted Performance**: +0.5-1.0 Sharpe ratio improvement with multi-agent systems
- **Signal Quality**: 30-40% reduction in false signals with agent debate consensus
- **Adaptivity**: 60% outperformance vs non-adaptive models with reflective learning (Alpha Arena)
- **Cost Efficiency**: Fine-tuning with FinGPT ~$300 vs $3M for full training

### Research Sources
- **FinGPT**: Open-source financial LLMs with F1 score 0.88 on sentiment analysis
  - GitHub: https://github.com/AI4Finance-Foundation/FinGPT
  - Enables cost-effective fine-tuning for personalized trading
  
- **CryptoTrade**: Reflective LLM agent achieving 2.38% ETH returns in bull markets
  - GitHub: https://github.com/Xtra-Computing/CryptoTrade
  - Paper: https://aclanthology.org/2024.emnlp-main.63.pdf
  - Demonstrates post-trade reflection for continuous improvement
  
- **TradingAgents**: Multi-agent LLM framework for collaborative trading
  - GitHub: https://github.com/TauricResearch/TradingAgents
  - Best practices for agent coordination and debate mechanisms
  
- **Alpha Arena Competition**: Real-world AI trading agent benchmarks
  - DeepSeek agent: +39.9% returns with "patient sniper" tactics
  - Results: https://www.chaincatcher.com/en/article/2213902
  - Validates reflective learning and risk management strategies

### Implementation Models
- **FinBERT**: ProsusAI/finbert for financial sentiment (Hugging Face)
- **Llama/GPT**: GPT-4 for critical decisions, GPT-3.5/Llama for routine tasks
- **LoRA Fine-tuning**: 60-70% API cost reduction with domain-specific adapters

### Risk Mitigation Strategies
- **Hallucination Control**: 10-20% error rate in trading signals mitigated with:
  - Ground truth validation against price/volume data
  - Hard-coded price/volatility guards
  - Schema validation with Pydantic models
- **Latency Management**: 1-5s per LLM call acceptable for medium-term strategies
- **Data Quality**: Real-time freshness checks, anomaly detection (z-score >3)
- **Circuit Breakers**: Pause trading if >10% data sources fail

### Current FKS AI Components
- **ASMBTR Strategy**: `/tests/unit/strategies/asmbtr/` - Technical analysis baseline
- **RAG Integration**: `/tests/integration/test_rag_signal_integration.py` - Semantic memory
- **Agent Framework**: `/repo/ai/src/agents/analysts/` - Macro/risk/sentiment analysts
- **Data Pipeline**: CCXT integration for Binance/Polygon/exchange data

---

## 🔀 Monorepo Split Research & Best Practices

### Key Benefits of Multi-Repo Architecture
- **CI/CD Performance**: 20-30% faster build times (sub-repos <5min vs monorepo 20-30min)
- **Iteration Velocity**: 25% improvement in deployment frequency
- **Team Autonomy**: Independent service ownership reduces coordination overhead
- **Resource Optimization**: Service-specific configurations (GPU-optional AI, lightweight execution)
- **Scalability**: Isolated deployments reduce blast radius of failures

### Migration Strategy Sources
- **git-filter-repo**: Best practice tool for splitting with history preservation
  - Repository: https://github.com/newren/git-filter-repo
  - Maintains commit logs for traceability and compliance
  
- **Kompose**: Kubernetes conversion tool for Docker Compose
  - Docs: https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/
  - Automates K8s manifest generation from Compose files
  
- **Multi-Repo Docker Compose**: Best practices for inter-service communication
  - Reference: Stack Overflow Multi-Repository Docker-Compose patterns
  - Network isolation and service discovery strategies

### Implementation Patterns
- **Shared Code Management**: 
  - Phase 1: Duplicate across repos (351 files) for independence
  - Phase 2: Extract to fks_shared pip package (reduces duplication by 100%)
  - Sync scripts for interim period
  
- **Docker Multi-Stage Builds**:
  - Base stage for CPU workloads
  - Extended stage for GPU (CUDA 12.0+)
  - ARM64 variant for edge devices (Raspberry Pi)
  
- **GitHub Actions Workflow**:
  - Sub-repos: Build → Test → Push to DockerHub
  - Main repo: Pull images → Deploy (Compose/K8s)
  - Webhook-triggered deployments

### Risk Mitigation
- **Dependency Conflicts**: Test builds incrementally, use dependency graphs
- **Shared Code Drift**: Automated sync scripts, version tagging
- **Coordination Overhead**: 15% initial increase (normalize after 2-3 sprints)
- **Broken Imports**: Comprehensive testing suite, rollback procedures

### Raspberry Pi Edge Deployment
- **k3s Lightweight K8s**: 
  - Official docs: https://k3s.io/
  - Optimized for ARM64, <512MB overhead
  
- **ARM64 Docker Images**:
  - Build with `--platform linux/arm64`
  - Test fks_ai CPU variant on Pi 4/5 (4-8GB RAM recommended)
  - Expected performance: <2GB RAM for inference workloads

### Current FKS Monorepo Stats
- **Total Files**: 1,731 (avg 1.3MB each)
- **Services**: 8 (ai, api, app, data, execution, ninja, meta, web)
- **Shared Code**: 351 files (20% of total)
- **Test Coverage**: 415 test files
- **Build Time**: ~20-30min (target: <5min per sub-repo)

---

### Reorganized and Rewritten Full Plan for FKS Trading Platform: A Comprehensive Development Roadmap

As fintech trading platforms like FKS evolve, a well-structured plan is crucial for managing complexity, ensuring scalability, and mitigating risks such as market volatility or integration failures. This rewritten plan reorganizes your original blueprint into seven logical phases, drawing from established best practices in fintech development. Sources emphasize starting with market analysis and regulatory compliance, progressing to MVP prototyping, full implementation, rigorous testing, secure deployment, performance optimization, and ongoing maintenance. For FKS—a Bitcoin-first, AI-driven system supporting crypto/forex/futures—the plan prioritizes cleanup to address codebase bloat (1,629 files, including 100+ small/empty ones), centralizes external communications in fks_execution (with plugins for fks_ninja/mt5 and new CCXT integration), and incorporates 2025 advancements like TimeCopilot for agentic forecasting and probabilistic metrics (e.g., CRPS for accuracy over MAE). All original phases (6-8) and tasks are preserved and expanded with sub-tasks, dependencies, timelines, and GitHub Actions for automation, enabling solo dev efficiency with agent delegation.

The plan assumes your "working K8s" baseline (e.g., 8 healthy services, 282 passing tests) and balances optimism with realism: While Lag-Llama excels in univariate probabilistic forecasting (CRPS ~0.25 on benchmarks), hybrids with TimesFM may reduce errors by 15-20% in multivariate scenarios, though compute costs rise. LLM integrations add value but carry hallucination risks (e.g., 10-20% in trading signals per studies), mitigated by ground truth validation. Phases include validation gates for oversight, with empathetic acknowledgment of solo dev challenges like burnout—build in weekly reviews.

#### Phase 1: Codebase Cleanup and Organization (1 Week)
Focus on streamlining the monorepo to improve navigation and reduce maintenance overhead. From audits, flatten nesting (e.g., /src/services) and eliminate redundancies, ensuring root has only README.md linking to /docs.

**Sub-Phases and Tasks**:
- **1.1: Inventory and Audit (Days 1-2)**  
  Dependencies: analyze_project.py script.  
  - Task 1.1.1: Run enhanced inventory script to list all files (extend /scripts/analyze_src_structure.py with JSON output including last_modified).  
  - Task 1.1.2: Identify and delete empty/small files (e.g., 6 empty like /k8s/tests/load-test-api.js; ~100 <100 bytes like __init__.py stubs)—use script: `find . -size 0 -delete; find . -size -100c -name "*.py" -delete`.  
  - Task 1.1.3: Review MD files (267 total): Keep core (e.g., /docs/DEPLOYMENT.md—edit for CCXT); delete obsolete (e.g., /docs/archive/*_OLD.md); move all non-root to /docs/subdirs (e.g., mv ./CLUSTER_HEALTHY.md /docs/operations/).  
  - GitHub Action: Create .github/workflows/cleanup.yml (run on schedule: find/delete empties, notify on Slack/Issues).  
  Agent Prompt: "Generate script to categorize MD files by relevance."

- **1.2: Restructure Directories (Days 3-4)**  
  Dependencies: Inventory from 1.1.  
  - Task 1.2.1: Flatten /src: Move language-specific code (e.g., Rust to /src/rust/execution, C# to /src/csharp/ninja).  
  - Task 1.2.2: Centralize tests (/tests/) and shared utils (/src/shared/—extract duplicates like framework/exceptions).  
  - Task 1.2.3: Update README.md: Add sections like "## Quick Start" (make up), "## Docs" with links (e.g., [AI Phases](/docs/phase-6-ai.md)).  
  - Validation Gate: Re-run inventory; confirm <1,500 files, root clean.  
  Timeline: Commit daily; PR review via agent.

- **1.3: Code Quality Pass (Day 5)**  
  - Task 1.3.1: Run `make lint` globally; fix Ruff/mypy issues.  
  - Task 1.3.2: Add type hints to key files (e.g., /assets/registry.py).  
  - GitHub Action: Update lint workflow to enforce on PRs.

**Milestones**: Clean monorepo; updated README. Risks: Breaking imports—mitigate with grep checks.

#### Phase 2: AI and Model Enhancements (1 Week)
Build on Phase 6: Integrate 2025 updates for better forecasting accuracy.

**Sub-Phases and Tasks**:
- **2.1: Time-Series Model Upgrades (Days 1-3)**  
  Dependencies: fks_ai service.  
  - Task 2.1.1: Integrate TimeCopilot (agentic wrapper for Lag-Llama/TimesFM)—clone repo, add to /src/services/ai/src/models.  
  - Task 2.1.2: Fix Lag-Llama kv_cache (per 2024 GitHub issues); test univariate/multivariate on sample data (/data/market_data/latest.json).  
  - Task 2.1.3: Add probabilistic metrics (CRPS/MASE) to evaluations (/tests/unit/test_core/test_ml_models.py).  
  - Agent Prompt: "Implement TimeCopilot pipeline for Lag-Llama."

- **2.2: Agent System Refinements (Days 4-5)**  
  - Task 2.2.1: Enhance 7-agent LangGraph (/src/services/ai/src/agents.py): Add confidence thresholds (0.6 min).  
  - Task 2.2.2: Optimize ChromaDB queries for semantic memory.  
  - Validation Gate: Run 88 AI tests; benchmark CRPS (<0.3 target).

**Milestones**: Hybrid forecasting ready. Debates: Hybrids reduce errors but increase compute—monitor via Prometheus.

#### Phase 3: Integrations and Centralization (1-2 Weeks)
Centralize in fks_execution: Plugins (ninja/mt5), CCXT for exchanges, TradingView webhooks.

**Sub-Phases and Tasks**:
- **3.1: Plugin Framework (Days 1-2)**  
  - Task 3.1.1: Define ExecutionPlugin trait in Rust (/src/execution/src/plugins.rs)—methods: init, execute_order, fetch_data.  
  - Task 3.1.2: Python wrappers via pyo3 for hybrid calls.  
  - Agent Prompt: "Generate Rust trait for ExecutionPlugin."

- **3.2: fks_ninja/mt5 Migration (Days 3-5)**  
  - Task 3.2.1: Move code to /src/execution/plugins/; implement bindings (csbindgen for C#, bindgen for MT5 DLLs).  
  - Task 3.2.2: Test bridges: Simulate orders in /tests/unit/test_trading/.

- **3.3: CCXT Integration (Days 6-7)**  
  - Task 3.3.1: Add CCXT to requirements; create ExchangeManager (/src/execution/exchanges/manager.py).  
  - Task 3.3.2: Wrap in plugin methods: fetch_ticker, place_order (market/limit with TP/SL).  
  - Task 3.3.3: Tie to webhooks: Validate payloads against rules before CCXT calls.  
  - Code: As in previous response (async examples).

- **3.4: Validation and Security (Days 8-9)**  
  - Task 3.4.1: Add normalization (NaN handling, type conversion) and risk checks (e.g., quantity <1% capital).  
  - Task 3.4.2: Security: Rate limiting, auth tokens, circuit breakers.  
  - Validation Gate: End-to-end tests; confirm centralized comms.

**Milestones**: Unified execution hub. Risks: API limits—use CCXT's built-in retries.

#### Phase 4: Testing and Quality Assurance (1 Week)
Ensure 100% coverage post-integrations.

**Sub-Phases and Tasks**:
- **4.1: Unit/Integration Tests (Days 1-3)**  
  - Task 4.1.1: Add CCXT mocks to /tests/unit/test_trading/test_ccxt.py.  
  - Task 4.1.2: Expand webhook tests (/tests/integration/test_trading/test_webhooks.py).  
  - Agent Prompt: "Generate pytest for CCXT order placement."

- **4.2: Performance and Load (Days 4-5)**  
  - Task 4.2.1: Run /k8s/tests/load-test.js on fks_execution.  
  - Validation Gate: 282+ tests passing; coverage >85%.

**Milestones**: Robust testing suite.

#### Phase 5: Deployment and Monitoring (1 Week)
Leverage "working K8s" for prod readiness.

**Sub-Phases and Tasks**:
- **5.1: K8s Enhancements (Days 1-3)**  
  - Task 5.1.1: Update Helm charts for CCXT env vars.  
  - Task 5.1.2: Add HPA/VPA for auto-scaling.

- **5.2: Monitoring Setup (Days 4-5)**  
  - Task 5.2.1: Extend Prometheus rules for CCXT metrics (/monitoring/prometheus/rules/quality_alerts.yml).  
  - GitHub Action: Weekly report YAML (commits, coverage, alerts).

**Milestones**: Prod deploy; first weekly report.

#### Phase 6: Optimization and Iteration (Ongoing, 1 Week Initial)
Post-launch refinements.

**Sub-Phases and Tasks**:
- **6.1: Performance Tuning (Days 1-3)**  
  - Task 6.1.1: Profile CCXT calls; add caching (Redis).  
  - Task 6.1.2: Optimize Docker (multi-stage builds).

- **6.2: Future Roadmap (Days 4-5)**  
  - Task 6.2.1: Plan Phase 8.2-8.5 (multi-region, advanced AI).  
  - Agent Prompt: "Suggest optimizations for Lag-Llama in trading."

**Milestones**: Optimized baseline; roadmap MD.

#### Phase 7: Maintenance and Expansion (Ongoing)
- Weekly reviews: Use Actions for reports.
- Expansions: Multi-exchange via CCXT; advanced AI (e.g., debate agents).
- Risks: Market changes—monitor via signals.

This plan positions FKS for sustainable growth, blending your vision with fintech best practices.

#### Key Citations
- [ASIFMA Best Practices for Fintech Development](https://www.asifma.org/wp-content/uploads/2018/05/asifma-best-practices-for-effective-development-of-fintech-june-2017.pdf)
- [Techvify Guide to Building Trading Platforms](https://techvify.com/building-a-trading-platform/)
- [Euvic Fintech App Development Guide](https://www.euvic.com/us/post/fintech-app-development-guide)
- [Somco Software Trading Development Guide](https://somcosoftware.com/en/blog/trading-software-development-a-comprehensive-guide)
- [Rndpoint Trading Platform Trends](https://rndpoint.com/blog/build-a-trading-platform/)