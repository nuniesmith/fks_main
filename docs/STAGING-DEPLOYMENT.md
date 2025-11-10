# FKS Platform - Staging Deployment Guide

**Date**: 2025-01-XX  
**Purpose**: Guide for deploying FKS Platform to staging environment  
**Status**: Ready for Deployment

---

## 🎯 Staging Deployment Overview

This guide covers deploying the FKS Platform to a staging environment for testing and validation before production deployment.

---

## 📋 Prerequisites

### Infrastructure
- [ ] Staging server/VM available
- [ ] Docker and Docker Compose installed
- [ ] Kubernetes cluster (if using K8s)
- [ ] Database/vector store available
- [ ] Network access configured

### Configuration
- [ ] Environment variables configured
- [ ] Secrets management set up
- [ ] SSL certificates obtained
- [ ] Domain names configured
- [ ] Monitoring tools ready

---

## 🐳 Docker Deployment (Recommended)

### 1. Create Staging Docker Compose

Create `docker-compose.staging.yml`:

```yaml
version: '3.8'

services:
  fks_ai:
    build:
      context: ./repo/ai
      dockerfile: Dockerfile
    image: fks-ai:staging
    ports:
      - "8001:8001"
    environment:
      - ENV=staging
      - OLLAMA_HOST=http://ollama:11434
      - LOG_LEVEL=INFO
    depends_on:
      - ollama
    networks:
      - fks-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/ai/bots/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  fks_training:
    build:
      context: ./repo/training
      dockerfile: Dockerfile
    image: fks-training:staging
    ports:
      - "8002:8002"
    environment:
      - ENV=staging
      - MLFLOW_TRACKING_URI=http://mlflow:5000
      - MODEL_SAVE_PATH=/app/models/ppo
    depends_on:
      - mlflow
    volumes:
      - ./models:/app/models
    networks:
      - fks-network
    restart: unless-stopped

  fks_analyze:
    build:
      context: ./repo/analyze
      dockerfile: Dockerfile
    image: fks-analyze:staging
    ports:
      - "8004:8004"
    environment:
      - ENV=staging
      - GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY}
      - OLLAMA_HOST=http://ollama:11434
      - RAG_USE_HYDE=true
      - RAG_USE_RAPTOR=true
      - RAG_CHROMA_DIR=/app/chroma_db
    depends_on:
      - ollama
      - chromadb
    volumes:
      - ./chroma_db:/app/chroma_db
    networks:
      - fks-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8004/api/v1/rag/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - fks-network
    restart: unless-stopped

  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.8.1
    ports:
      - "5000:5000"
    environment:
      - BACKEND_STORE_URI=sqlite:///mlflow.db
    volumes:
      - mlflow_data:/mlflow
    networks:
      - fks-network
    restart: unless-stopped

  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chroma_data:/chroma/chroma
    networks:
      - fks-network
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/staging.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - fks_ai
      - fks_analyze
    networks:
      - fks-network
    restart: unless-stopped

volumes:
  ollama_data:
  mlflow_data:
  chroma_data:

networks:
  fks-network:
    driver: bridge
```

### 2. Create NGINX Configuration

Create `nginx/staging.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream fks_ai {
        server fks_ai:8001;
    }

    upstream fks_analyze {
        server fks_analyze:8004;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    server {
        listen 80;
        server_name staging.fks-platform.com;

        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name staging.fks-platform.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # API endpoints
        location /ai/ {
            limit_req zone=api_limit burst=20 nodelay;
            proxy_pass http://fks_ai;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /api/v1/rag/ {
            limit_req zone=api_limit burst=20 nodelay;
            proxy_pass http://fks_analyze;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health checks
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### 3. Deploy to Staging

```bash
# Build and start services
docker-compose -f docker-compose.staging.yml up -d --build

# Check status
docker-compose -f docker-compose.staging.yml ps

# View logs
docker-compose -f docker-compose.staging.yml logs -f

# Stop services
docker-compose -f docker-compose.staging.yml down
```

---

## ☸️ Kubernetes Deployment

### 1. Create Namespace

```bash
kubectl create namespace fks-staging
```

### 2. Create ConfigMap

```yaml
# configmap-staging.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fks-config
  namespace: fks-staging
data:
  ENV: "staging"
  OLLAMA_HOST: "http://ollama-service:11434"
  MLFLOW_TRACKING_URI: "http://mlflow-service:5000"
  RAG_USE_HYDE: "true"
  RAG_USE_RAPTOR: "true"
```

### 3. Create Secrets

```bash
# Create secret for API keys
kubectl create secret generic fks-secrets \
  --from-literal=google-ai-api-key=$GOOGLE_AI_API_KEY \
  --namespace=fks-staging
```

### 4. Deploy Services

```bash
# Apply deployments
kubectl apply -f k8s/staging/ -n fks-staging

# Check status
kubectl get pods -n fks-staging

# Check services
kubectl get svc -n fks-staging
```

---

## ✅ Staging Verification

### 1. Health Checks

```bash
# Check all services
curl https://staging.fks-platform.com/health
curl https://staging.fks-platform.com/ai/bots/health
curl https://staging.fks-platform.com/api/v1/rag/health
```

### 2. Smoke Tests

```bash
# Test bot endpoint
curl -X POST https://staging.fks-platform.com/ai/bots/consensus \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "BTC-USD",
    "market_data": {
      "close": 50000.0,
      "data": [{"open": 49000, "high": 51000, "low": 48000, "close": 50000, "volume": 100000000}]
    }
  }'

# Test RAG endpoint
curl -X POST https://staging.fks-platform.com/api/v1/rag/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is FKS?"}'
```

### 3. Performance Checks

```bash
# Check response times
time curl https://staging.fks-platform.com/ai/bots/health

# Check resource usage
docker stats
# or
kubectl top pods -n fks-staging
```

---

## 📊 Monitoring Setup

### 1. Prometheus Configuration

```yaml
# prometheus-staging.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'fks-ai'
    static_configs:
      - targets: ['fks_ai:8001']
  
  - job_name: 'fks-analyze'
    static_configs:
      - targets: ['fks_analyze:8004']
```

### 2. Grafana Dashboards

- Service health dashboard
- API performance dashboard
- Error rate dashboard
- Resource usage dashboard

---

## 🔧 Configuration Management

### Environment Variables

```bash
# .env.staging
ENV=staging
LOG_LEVEL=INFO
GOOGLE_AI_API_KEY=staging_key
OLLAMA_HOST=http://ollama:11434
MLFLOW_TRACKING_URI=http://mlflow:5000
RAG_USE_HYDE=true
RAG_USE_RAPTOR=true
```

### Secrets Management

```bash
# Use environment-specific secrets
# Staging secrets should be separate from production
# Use secret management service (Vault, AWS Secrets Manager, etc.)
```

---

## 🧪 Staging Test Plan

### 1. Functional Tests
- [ ] All API endpoints respond
- [ ] Bot signals generate correctly
- [ ] RAG queries work
- [ ] PPO training can start
- [ ] Health checks pass

### 2. Integration Tests
- [ ] Services communicate correctly
- [ ] Data flows between services
- [ ] Error handling works
- [ ] Fallback mechanisms work

### 3. Performance Tests
- [ ] Response times acceptable
- [ ] Resource usage within limits
- [ ] No memory leaks
- [ ] Handles concurrent requests

### 4. Security Tests
- [ ] HTTPS configured
- [ ] Rate limiting works
- [ ] No exposed secrets
- [ ] Input validation works

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Configuration verified
- [ ] Secrets configured
- [ ] SSL certificates ready

### Deployment
- [ ] Services deployed
- [ ] Health checks passing
- [ ] Smoke tests passing
- [ ] Monitoring configured
- [ ] Logs accessible

### Post-Deployment
- [ ] Functional tests pass
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Documentation updated
- [ ] Team notified

---

## 🔄 Rollback Procedure

### Docker Compose
```bash
# Rollback to previous version
docker-compose -f docker-compose.staging.yml down
docker-compose -f docker-compose.staging.yml.previous up -d
```

### Kubernetes
```bash
# Rollback deployment
kubectl rollout undo deployment/fks-ai -n fks-staging
kubectl rollout undo deployment/fks-analyze -n fks-staging
```

---

## 📝 Staging Environment Details

### URLs
- **API Base**: `https://staging.fks-platform.com`
- **fks_ai**: `https://staging.fks-platform.com/ai/`
- **fks_analyze**: `https://staging.fks-platform.com/api/v1/rag/`
- **MLflow**: `http://mlflow-staging:5000` (internal)

### Credentials
- Staging API keys (separate from production)
- Test user accounts
- Staging database credentials

---

## 🎯 Success Criteria

### Deployment Success
- ✅ All services running
- ✅ Health checks passing
- ✅ Smoke tests passing
- ✅ No critical errors

### Ready for Production
- ✅ Performance acceptable
- ✅ Security verified
- ✅ Monitoring working
- ✅ Documentation updated

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for Staging Deployment

