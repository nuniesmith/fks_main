# FKS Trading Platform - Multi-Repo Architecture

**Last Updated**: November 7, 2025  
**Purpose**: Master orchestration guide for all FKS microservices

## 📁 Repository Structure

This workspace coordinates **9 independent GitHub repositories** + 1 main orchestrator:

```
fks_main/          → Main orchestrator (K8s, monitoring, docs) - THIS REPO (not tracked)
├── fks_ai/        → AI/ML services (LangGraph, TimeCopilot, RAG)
├── fks_api/       → REST API gateway
├── fks_app/       → Trading strategies & business logic
├── fks_data/      → Data adapters (CCXT, Polygon, Binance)
├── fks_execution/ → Execution engine (webhooks, CCXT, security)
├── fks_ninja/     → NinjaTrader C# plugin
├── fks_meta/      → MetaTrader plugin
├── fks_web/       → Django web UI
└── fks_training/  → Model training & backtesting
```

## 🎯 Navigation Guide

### By Priority (High → Low)

**🔥 CRITICAL (Demo-Ready)**
- [Core Architecture](./01-core-architecture.md) - System design & K8s deployment
- [Docker Strategy](./02-docker-strategy.md) - Build/push workflows
- [GitHub Actions](./03-github-actions.md) - CI/CD automation

**⭐ HIGH VALUE (Production-Ready)**
- [AI Trading Agents](./04-ai-trading-agents.md) - LLM integration, multi-agent systems
- [Execution Pipeline](./05-execution-pipeline.md) - Webhooks, CCXT, security

**🚀 ADVANCED (Future)**
- [Portfolio Rebalancing](./06-portfolio-rebalancing.md) - RL-based optimization
- [CVaR Risk Management](./07-cvar-risk-management.md) - Safe RL, distributional methods
- [Monorepo Split Guide](./08-monorepo-split-guide.md) - Migration documentation

### By Repository

| Repo | DockerHub Image | GitHub Repo | Key Features |
|------|----------------|-------------|--------------|
| **fks_ai** | `nuniesmith/fks_ai:cpu`, `:gpu`, `:arm64` | [nuniesmith/fks_ai](https://github.com/nuniesmith/fks_ai) | Multi-agent AI, LangGraph, TimeCopilot |
| **fks_api** | `nuniesmith/fks_api:latest` | [nuniesmith/fks_api](https://github.com/nuniesmith/fks_api) | REST API routers, health endpoints |
| **fks_app** | `nuniesmith/fks_app:latest` | [nuniesmith/fks_app](https://github.com/nuniesmith/fks_app) | ASMBTR strategy, business logic |
| **fks_data** | `nuniesmith/fks_data:latest` | [nuniesmith/fks_data](https://github.com/nuniesmith/fks_data) | CCXT, Polygon, Binance adapters |
| **fks_execution** | `nuniesmith/fks_execution:latest` | [nuniesmith/fks_execution](https://github.com/nuniesmith/fks_execution) | Webhooks, order execution, security |
| **fks_ninja** | `nuniesmith/fks_ninja:latest` | [nuniesmith/fks_ninja](https://github.com/nuniesmith/fks_ninja) | NinjaTrader C# integration |
| **fks_meta** | `nuniesmith/fks_meta:latest` | [nuniesmith/fks_meta](https://github.com/nuniesmith/fks_meta) | MetaTrader plugin |
| **fks_web** | `nuniesmith/fks_web:latest` | [nuniesmith/fks_web](https://github.com/nuniesmith/fks_web) | Django UI, Celery workers |
| **fks_training** | `nuniesmith/fks_training:latest` | [nuniesmith/fks_training](https://github.com/nuniesmith/fks_training) | Model training, backtesting |

## 🔧 Quick Commands

### Repository Setup
```bash
# Add remotes for all repos (run from each repo directory)
cd fks_ai && git remote add origin https://github.com/nuniesmith/fks_ai.git
cd ../fks_api && git remote add origin https://github.com/nuniesmith/fks_api.git
# ... repeat for all repos

# Push to GitHub (first time)
git push -u origin main
```

### Docker Operations
```bash
# Build and push (from each repo)
docker build -t nuniesmith/fks_ai:latest .
docker push nuniesmith/fks_ai:latest

# Pull all images (from fks_main)
docker-compose pull
```

### Kubernetes Deployment
```bash
# Deploy all services (from fks_main)
cd fks_main
kubectl apply -f k8s/manifests/

# Check status
kubectl get pods -n fks-trading
kubectl get svc,ingress -n fks-trading
```

## 📊 Current Status

**Deployment**: 13/14 services running (93% operational)  
**Tests**: 168/168 passing (100%)  
**Storage**: 170Gi allocated (Postgres 100Gi, Redis 10Gi)  
**Live URLs**: 
- Landing: https://fkstrading.xyz
- API: https://api.fkstrading.xyz/health
- Grafana: https://grafana.fkstrading.xyz

## 🔑 Secrets Management

**Critical**: All repos need DockerHub secrets for GitHub Actions:
```yaml
# Add to each repo's GitHub Settings → Secrets
DOCKER_USERNAME: nuniesmith
DOCKER_PASSWORD: <your-dockerhub-token>
```

See [GitHub Actions Guide](./03-github-actions.md) for automation setup.

## 🎯 Next Steps

1. **Setup Remotes**: Add GitHub origins to all repos
2. **Configure Secrets**: Add DockerHub credentials to each repo
3. **Enable Actions**: Push GitHub workflows to each repo
4. **Test Pipeline**: Trigger builds and verify DockerHub pushes
5. **Deploy to K8s**: Pull images from DockerHub in fks_main

---

**Note**: The `fks_main/` directory is NOT tracked in GitHub (local only). It contains:
- Kubernetes manifests (K8s deployments, services, ingress)
- Monitoring configs (Prometheus, Grafana)
- Documentation (this file, roadmaps)
- Secrets (`.env` files, API keys)
