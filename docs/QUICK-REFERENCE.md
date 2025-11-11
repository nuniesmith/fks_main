# FKS Platform - Quick Reference

**Date**: 2025-01-XX  
**Purpose**: Quick reference guide for common tasks  
**Status**: Ready for Use

---

## 🚀 Quick Start

### Start Services
```bash
# Docker Compose
docker-compose up -d

# Individual services
cd repo/ai && python -m uvicorn src.main:app --port 8001
cd repo/analyze && python -m uvicorn src.main:app --port 8004
```

### Test Endpoints
```bash
# Health checks
curl http://localhost:8001/ai/bots/health
curl http://localhost:8004/api/v1/rag/health

# Bot consensus
curl -X POST http://localhost:8001/ai/bots/consensus \
  -H "Content-Type: application/json" \
  -d '{"symbol": "BTC-USD", "market_data": {...}}'

# RAG query
curl -X POST http://localhost:8004/api/v1/rag/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is FKS?"}'
```

---

## 📚 Documentation Quick Links

### Getting Started
- [First Steps](FIRST-STEPS.md) - Start here
- [Quick Start Guide](QUICK-START-GUIDE.md) - Quick reference
- [Project Overview](PROJECT-OVERVIEW.md) - Architecture overview

### Implementation
- [Multi-Agent Bots](../todo/14-MULTI-AGENT-TRADING-BOTS-IMPLEMENTATION.md)
- [PPO Meta-Learning](../todo/18-PPO-META-LEARNING-IMPLEMENTATION.md)
- [RAG Implementation](../todo/16-RAG-IMPLEMENTATION-GUIDE.md)

### Operations
- [Security Audit](SECURITY-AUDIT.md)
- [Staging Deployment](STAGING-DEPLOYMENT.md)
- [Load Testing](LOAD-TESTING-GUIDE.md)
- [Deployment Guide](DEPLOYMENT-GUIDE.md)

### Reference
- [API Reference](API-REFERENCE.md)
- [Development Guide](DEVELOPMENT-GUIDE.md)
- [Troubleshooting](TROUBLESHOOTING-GUIDE.md)

---

## 🧪 Testing

### Run Tests
```bash
# All tests
./repo/main/scripts/run_all_tests.sh all

# Specific service
cd repo/ai && pytest tests/ -v
cd repo/training && pytest tests/ -v
cd repo/analyze && pytest tests/ -v
```

### Load Testing
```bash
python repo/main/scripts/load_test.py \
  --service ai \
  --endpoint /ai/bots/consensus \
  --concurrent 10 \
  --requests 100
```

---

## 🔒 Security

### Security Checklist
- [ ] Review [Security Audit](SECURITY-AUDIT.md)
- [ ] Implement authentication
- [ ] Add rate limiting
- [ ] Configure HTTPS
- [ ] Set up secrets management

### Security Commands
```bash
# Check for vulnerabilities
pip install pip-audit
pip-audit

# Or use safety
pip install safety
safety check
```

---

## 🚀 Deployment

### Staging
```bash
# Deploy to staging
docker-compose -f docker-compose.staging.yml up -d

# Check status
docker-compose -f docker-compose.staging.yml ps

# View logs
docker-compose -f docker-compose.staging.yml logs -f
```

### Kubernetes
```bash
# Deploy
kubectl apply -f k8s/staging/ -n fks-staging

# Check status
kubectl get pods -n fks-staging
```

---

## 📊 Monitoring

### Health Checks
```bash
# Service health
curl http://localhost:8001/ai/bots/health
curl http://localhost:8004/api/v1/rag/health

# System health
docker stats
kubectl top pods -n fks-staging
```

### Logs
```bash
# Docker
docker-compose logs -f [service]

# Kubernetes
kubectl logs -f deployment/[service] -n fks-staging
```

---

## 🛠️ Common Tasks

### Add New Bot
1. Create bot class in `repo/ai/src/agents/`
2. Add bot node in `repo/ai/src/graph/bot_nodes.py`
3. Add API endpoint in `repo/ai/src/api/routes/bots.py`
4. Add tests in `repo/ai/tests/`

### Add New RAG Feature
1. Implement feature in `repo/analyze/src/rag/`
2. Add tests in `repo/analyze/tests/`
3. Update API in `repo/analyze/src/api/routes/rag.py`
4. Update documentation

### Train PPO Model
```bash
cd repo/training
python src/ppo/train_trading_ppo.py \
  --symbol BTC-USD \
  --epochs 100 \
  --save-path ./models/ppo
```

---

## 📝 File Locations

### Code
- **Bots**: `repo/ai/src/agents/`
- **PPO**: `repo/training/src/ppo/`
- **RAG**: `repo/analyze/src/rag/`
- **API**: `repo/*/src/api/routes/`

### Tests
- **Bots**: `repo/ai/tests/`
- **PPO**: `repo/training/tests/`
- **RAG**: `repo/analyze/tests/`

### Documentation
- **Docs**: `repo/main/docs/`
- **Guides**: `repo/main/docs/` and `todo/`

### Scripts
- **Load Test**: `repo/main/scripts/load_test.py`
- **Test Runner**: `repo/main/scripts/run_all_tests.sh`

---

## 🎯 Performance Targets

| Endpoint | Target | Acceptable |
|----------|--------|------------|
| Bot Health | <50ms | <100ms |
| Bot Consensus | <200ms | <500ms |
| RAG Query | <2s | <5s |
| RAG Health | <50ms | <100ms |

---

## 🔗 Important Links

- **Main Documentation**: [README.md](README.md)
- **Table of Contents**: [TABLE-OF-CONTENTS.md](TABLE-OF-CONTENTS.md)
- **API Reference**: [API-REFERENCE.md](API-REFERENCE.md)
- **Security Audit**: [SECURITY-AUDIT.md](SECURITY-AUDIT.md)
- **Project Status**: [COMPLETE-PROJECT-STATUS.md](COMPLETE-PROJECT-STATUS.md)

---

**Last Updated**: 2025-01-XX  
**Status**: ✅ Ready for Use

