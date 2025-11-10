# FKS Platform - Deployment Guide

**Date**: 2025-01-XX  
**Status**: Ready for Deployment  
**Purpose**: Guide for deploying FKS Platform services

---

## 🚀 Deployment Overview

This guide covers deploying all FKS Platform services, including:
- Multi-Agent Trading Bots (`fks_ai`)
- PPO Training Service (`fks_training`)
- RAG Analysis Service (`fks_analyze`)

---

## 📋 Prerequisites

### System Requirements
- Python 3.9+
- Docker and Docker Compose (optional)
- PostgreSQL (for vector store, optional)
- Redis (for caching, optional)
- MLflow server (for PPO training tracking)

### Environment Variables
```bash
# RAG Configuration
export GOOGLE_AI_API_KEY="your_gemini_key"
export OLLAMA_HOST="http://fks_ai:11434"
export RAG_USE_HYDE="true"
export RAG_USE_RAPTOR="true"
export RAG_USE_SELF_RAG="true"

# PPO Configuration
export MLFLOW_TRACKING_URI="http://localhost:5000"

# Service URLs
export FKS_DATA_URL="http://fks_data:8003"
export FKS_PORTFOLIO_URL="http://fks_portfolio:8005"
```

---

## 🐳 Docker Deployment

### Docker Compose Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  fks_ai:
    build: ./repo/ai
    ports:
      - "8001:8001"
    environment:
      - OLLAMA_HOST=http://ollama:11434
    depends_on:
      - ollama
    volumes:
      - ./repo/ai:/app
    command: uvicorn src.main:app --host 0.0.0.0 --port 8001

  fks_training:
    build: ./repo/training
    ports:
      - "8002:8002"
    environment:
      - MLFLOW_TRACKING_URI=http://mlflow:5000
    depends_on:
      - mlflow
    volumes:
      - ./repo/training:/app
      - ./models:/app/models
    command: uvicorn src.main:app --host 0.0.0.0 --port 8002

  fks_analyze:
    build: ./repo/analyze
    ports:
      - "8004:8004"
    environment:
      - GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY}
      - OLLAMA_HOST=http://ollama:11434
      - RAG_USE_HYDE=true
      - RAG_USE_RAPTOR=true
    depends_on:
      - ollama
      - chromadb
    volumes:
      - ./repo/analyze:/app
      - ./chroma_db:/app/chroma_db
    command: uvicorn src.main:app --host 0.0.0.0 --port 8004

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama

  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.8.1
    ports:
      - "5000:5000"
    environment:
      - BACKEND_STORE_URI=sqlite:///mlflow.db
    volumes:
      - mlflow_data:/mlflow

  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chroma_data:/chroma/chroma

volumes:
  ollama_data:
  mlflow_data:
  chroma_data:
```

### Deploy with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

---

## 🖥️ Local Deployment

### 1. Install Dependencies

```bash
# fks_ai
cd repo/ai
pip install -r requirements.txt

# fks_training
cd repo/training
pip install -r requirements.txt

# fks_analyze
cd repo/analyze
pip install -r requirements.txt
```

### 2. Start Services

#### Start fks_ai
```bash
cd repo/ai
uvicorn src.main:app --host 0.0.0.0 --port 8001 --reload
```

#### Start fks_training
```bash
cd repo/training
uvicorn src.main:app --host 0.0.0.0 --port 8002 --reload
```

#### Start fks_analyze
```bash
cd repo/analyze
uvicorn src.main:app --host 0.0.0.0 --port 8004 --reload
```

### 3. Start Supporting Services

#### Start Ollama
```bash
# Install Ollama (if not installed)
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama
ollama serve

# Pull required model
ollama pull qwen2.5
```

#### Start MLflow
```bash
mlflow ui --port 5000
```

#### Start ChromaDB (if using)
```bash
docker run -d -p 8000:8000 chromadb/chroma:latest
```

---

## ☁️ Cloud Deployment

### AWS Deployment

#### Using ECS/Fargate

1. **Build Docker Images**:
```bash
# Build and push to ECR
aws ecr create-repository --repository-name fks-ai
docker build -t fks-ai ./repo/ai
docker tag fks-ai:latest <account>.dkr.ecr.<region>.amazonaws.com/fks-ai:latest
docker push <account>.dkr.ecr.<region>.amazonaws.com/fks-ai:latest
```

2. **Create ECS Task Definition**:
```json
{
  "family": "fks-ai",
  "containerDefinitions": [{
    "name": "fks-ai",
    "image": "<account>.dkr.ecr.<region>.amazonaws.com/fks-ai:latest",
    "portMappings": [{
      "containerPort": 8001,
      "protocol": "tcp"
    }],
    "environment": [
      {"name": "OLLAMA_HOST", "value": "http://ollama:11434"}
    ]
  }]
}
```

3. **Deploy Service**:
```bash
aws ecs create-service \
  --cluster fks-cluster \
  --service-name fks-ai \
  --task-definition fks-ai \
  --desired-count 2
```

### Kubernetes Deployment

#### Create Deployments

```yaml
# fks-ai-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fks-ai
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fks-ai
  template:
    metadata:
      labels:
        app: fks-ai
    spec:
      containers:
      - name: fks-ai
        image: fks-ai:latest
        ports:
        - containerPort: 8001
        env:
        - name: OLLAMA_HOST
          value: "http://ollama-service:11434"
---
apiVersion: v1
kind: Service
metadata:
  name: fks-ai-service
spec:
  selector:
    app: fks-ai
  ports:
  - port: 8001
    targetPort: 8001
  type: LoadBalancer
```

#### Deploy to Kubernetes

```bash
kubectl apply -f fks-ai-deployment.yaml
kubectl apply -f fks-training-deployment.yaml
kubectl apply -f fks-analyze-deployment.yaml
```

---

## 🔧 Configuration

### Service Configuration

#### fks_ai Configuration
```python
# repo/ai/.env
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=qwen2.5
LOG_LEVEL=INFO
```

#### fks_training Configuration
```python
# repo/training/.env
MLFLOW_TRACKING_URI=http://mlflow:5000
MODEL_SAVE_PATH=./models/ppo
LOG_LEVEL=INFO
```

#### fks_analyze Configuration
```python
# repo/analyze/.env
GOOGLE_AI_API_KEY=your_key
OLLAMA_HOST=http://ollama:11434
RAG_USE_HYDE=true
RAG_USE_RAPTOR=true
RAG_USE_SELF_RAG=true
RAG_CHROMA_DIR=./chroma_db
```

---

## 🔍 Health Checks

### Service Health Endpoints

```bash
# fks_ai
curl http://localhost:8001/ai/bots/health

# fks_analyze
curl http://localhost:8004/api/v1/rag/health

# fks_training
curl http://localhost:8002/health
```

### Monitoring

#### Prometheus Metrics
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'fks-ai'
    static_configs:
      - targets: ['fks-ai:8001']
  - job_name: 'fks-analyze'
    static_configs:
      - targets: ['fks-analyze:8004']
```

---

## 🔒 Security

### API Authentication

```python
# Add JWT authentication
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer

security = HTTPBearer()

async def verify_token(token: str = Depends(security)):
    # Verify JWT token
    if not verify_jwt(token.credentials):
        raise HTTPException(status_code=401)
    return token.credentials
```

### Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/api/v1/rag/query")
@limiter.limit("10/minute")
async def query_rag(request: Request, ...):
    ...
```

---

## 📊 Monitoring and Logging

### Logging Configuration

```python
# Configure structured logging
from loguru import logger

logger.add(
    "logs/fks_{time}.log",
    rotation="1 day",
    retention="30 days",
    level="INFO"
)
```

### Metrics Collection

```python
# Prometheus metrics
from prometheus_client import Counter, Histogram

request_count = Counter('requests_total', 'Total requests')
request_duration = Histogram('request_duration_seconds', 'Request duration')
```

---

## 🐛 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check logs
docker-compose logs fks-ai

# Check port availability
netstat -tulpn | grep 8001

# Check dependencies
pip list | grep fastapi
```

#### Import Errors
```bash
# Verify Python path
python -c "import sys; print(sys.path)"

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

#### Connection Errors
```bash
# Test service connectivity
curl http://localhost:8001/health

# Check network
docker network ls
docker network inspect fks_default
```

---

## 📈 Scaling

### Horizontal Scaling

```bash
# Scale services
docker-compose up -d --scale fks-ai=3
docker-compose up -d --scale fks-analyze=2
```

### Load Balancing

```nginx
# nginx.conf
upstream fks_ai {
    server fks-ai-1:8001;
    server fks-ai-2:8001;
    server fks-ai-3:8001;
}

server {
    listen 80;
    location / {
        proxy_pass http://fks_ai;
    }
}
```

---

## 🔄 Updates and Rollbacks

### Rolling Updates

```bash
# Update service
docker-compose pull fks-ai
docker-compose up -d --no-deps fks-ai

# Rollback
docker-compose up -d --no-deps fks-ai:previous-version
```

### Blue-Green Deployment

```bash
# Deploy new version
docker-compose -f docker-compose.blue.yml up -d

# Switch traffic
# Update load balancer to point to blue

# Keep green for rollback
docker-compose -f docker-compose.green.yml up -d
```

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Environment variables configured
- [ ] Dependencies installed
- [ ] Database migrations run (if applicable)
- [ ] Secrets configured securely

### Deployment
- [ ] Services started
- [ ] Health checks passing
- [ ] Logs monitored
- [ ] Metrics collected

### Post-Deployment
- [ ] Smoke tests pass
- [ ] Performance verified
- [ ] Monitoring active
- [ ] Documentation updated

---

## 🎯 Next Steps

1. **Deploy to Staging**: Test in staging environment
2. **Load Testing**: Verify performance under load
3. **Security Audit**: Review security configurations
4. **Production Deployment**: Deploy to production
5. **Monitoring Setup**: Configure monitoring and alerts

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for Deployment

