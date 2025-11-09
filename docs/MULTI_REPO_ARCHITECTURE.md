# FKS Multi-Repository Architecture

**Date**: 2025-11-07  
**Status**: Planning Complete - Ready for Execution  
**Strategy**: git-filter-repo with history preservation

---

## Table of Contents
1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Docker Strategy](#docker-strategy)
4. [GitHub Actions CI/CD](#github-actions-cicd)
5. [Kubernetes Integration](#kubernetes-integration)
6. [Shared Code Management](#shared-code-management)
7. [Inter-Repository Dependencies](#inter-repository-dependencies)
8. [Versioning Strategy](#versioning-strategy)
9. [Split Execution Plan](#split-execution-plan)
10. [Migration Timeline](#migration-timeline)

---

## Overview

### Motivation
Transform FKS monorepo (4,481 files) into 9 independent service repositories to achieve:
- **20-30% faster CI/CD** (sub-repos <5min vs monorepo 20-30min)
- **25% improvement** in deployment frequency
- **Independent service ownership** and scaling
- **Resource optimization** (GPU-optional AI, lightweight execution)

### Source Repository
- **GitHub**: `nuniesmith/fks`
- **Total Files**: 4,481
- **Backup**: `fks-backup-20251107.bundle` (23MB, 6,053 objects)

### Target Repositories (All created under `nuniesmith`)
1. **fks_ai** - AI/ML services (84 files)
2. **fks_api** - REST API (230 files)
3. **fks_app** - Trading logic (99 files)
4. **fks_data** - Data adapters (232 files)
5. **fks_execution** - Execution engine (36 files)
6. **fks_ninja** - NinjaTrader plugin (260 files, C#)
7. **fks_meta** - MetaTrader plugin (5 files, MQL5)
8. **fks_web** - Django UI (219 files)
9. **fks_main** - Orchestration (696 files, K8s/monitoring)

---

## Repository Structure

### fks_ai
**Purpose**: AI/ML services (multi-agent debate, RAG, sentiment analysis)

**Directory Structure**:
```
fks_ai/
├── src/
│   ├── agents/           # Multi-agent debate system
│   │   ├── specialists/  # Short/mid/long-term agents
│   │   ├── debate_engine.py
│   │   └── coordinator.py
│   ├── models/           # Lag-Llama, TimeCopilot
│   ├── integrations/     # Gemini API client
│   ├── sentiment/        # FinBERT sentiment
│   └── memory/           # Layered memory buffers
├── shared/               # Duplicated from main (351 files)
├── tests/
│   ├── unit/test_rag/
│   ├── unit/test_sentiment/
│   └── integration/
├── notebooks/transformer/
├── requirements.txt
├── Dockerfile            # Multi-stage (CPU/GPU/ARM64)
├── docker-compose.yml
└── README.md
```

**Key Files**:
- `src/agents/debate_engine.py` - Confidence-weighted voting
- `src/memory/manager.py` - Layered memory (short/mid/long horizons)
- `src/integrations/gemini_client.py` - Gemini API offloading

---

### fks_api
**Purpose**: REST API for trading operations

**Directory Structure**:
```
fks_api/
├── src/
│   ├── routes/          # FastAPI routers
│   ├── models/          # Pydantic schemas
│   └── middleware/      # Auth, rate limiting
├── shared/
├── tests/integration/test_api*.py
├── requirements.txt
├── Dockerfile
└── README.md
```

---

### fks_app
**Purpose**: Trading strategies and business logic

**Directory Structure**:
```
fks_app/
├── src/
│   ├── strategies/
│   │   └── asmbtr/      # ASMBTR with sentiment
│   ├── tasks/           # Celery tasks
│   └── integrations/    # Hybrid AI signals
├── shared/
├── tests/unit/test_asmbtr*.py
├── data/asmbtr_real_data_optimization.json
├── requirements.txt
└── Dockerfile
```

---

### fks_data
**Purpose**: Data adapters (CCXT, Polygon, Binance)

**Directory Structure**:
```
fks_data/
├── src/
│   ├── adapters/        # CCXT, exchange adapters
│   ├── processors/      # Data normalization
│   └── storage/         # PostgreSQL interfaces
├── shared/
├── data/market_data/
├── tests/
├── requirements.txt
└── Dockerfile
```

---

### fks_execution
**Purpose**: Execution engine (CCXT, webhooks, validation)

**Directory Structure**:
```
fks_execution/
├── src/
│   ├── exchanges/       # CCXT plugin, ExchangeManager
│   ├── webhooks/        # TradingView handler
│   ├── validation/      # Normalizer, PositionSizer
│   ├── security/        # RateLimiter, CircuitBreaker
│   └── metrics.py       # Prometheus metrics
├── shared/
├── tests/
├── requirements.txt
└── Dockerfile
```

---

### fks_ninja
**Purpose**: NinjaTrader plugin (C#)

**Directory Structure**:
```
fks_ninja/
├── src/
│   ├── Indicators/
│   ├── Strategies/
│   └── FKS.NinjaTrader.csproj
├── shared/              # C# utilities
├── tests/
├── Dockerfile           # Multi-stage (.NET SDK)
└── README.md
```

---

### fks_meta
**Purpose**: MetaTrader plugin (MQL5)

**Directory Structure**:
```
fks_meta/
├── src/
│   ├── Experts/
│   ├── Indicators/
│   └── Include/
├── tests/
├── Dockerfile
└── README.md
```

**Note**: Minimal structure, to be expanded.

---

### fks_web
**Purpose**: Django web UI

**Directory Structure**:
```
fks_web/
├── src/
│   ├── dashboard/
│   ├── accounts/
│   ├── static/
│   └── templates/
├── shared/
├── tests/unit/test_web*.py
├── requirements.txt
└── Dockerfile
```

---

### fks_main
**Purpose**: Orchestration (K8s, monitoring, docs)

**Directory Structure**:
```
fks_main/
├── docs/                # All documentation
├── k8s/
│   ├── manifests/       # Deployment YAMLs
│   ├── helm/            # Helm charts
│   └── scripts/         # Deployment automation
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── alertmanager/
├── scripts/             # DevOps utilities
├── .github/workflows/   # Master deployment workflow
├── docker-compose.yml   # Multi-service orchestration
├── Makefile
├── README.md
└── requirements.txt     # Common dependencies
```

**Key Files**:
- `docker-compose.yml` - References all sub-repo images
- `k8s/manifests/all-services.yaml` - Pulls from DockerHub
- `.github/workflows/deploy-all.yml` - Workflow dispatch for full deployment

---

## Docker Strategy

### Multi-Stage Builds (fks_ai Example)

**File**: `fks_ai/Dockerfile`

```dockerfile
# Stage 1: Base (CPU)
FROM python:3.12-slim AS base
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY shared/ ./shared/

# Environment
ENV PYTHONPATH=/app
ENV GPU_ENABLED=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=5)"

CMD ["python", "src/main.py"]

# Stage 2: GPU
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS gpu
WORKDIR /app

# Install Python
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*

# Install dependencies + PyTorch GPU
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt \
    && pip3 install torch --index-url https://download.pytorch.org/whl/cu121

COPY src/ ./src/
COPY shared/ ./shared/

ENV PYTHONPATH=/app
ENV GPU_ENABLED=true
ENV CUDA_VISIBLE_DEVICES=0

CMD ["python3", "src/main.py"]

# Stage 3: ARM64 (Raspberry Pi)
FROM python:3.12-slim AS arm64
WORKDIR /app

# Install ARM64-optimized dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY shared/ ./shared/

ENV PYTHONPATH=/app
ENV GPU_ENABLED=false
ENV PLATFORM=arm64

CMD ["python", "src/main.py"]
```

**Build Commands**:
```bash
# CPU variant
docker build --target base -t nuniesmith/fks_ai:cpu .

# GPU variant
docker build --target gpu -t nuniesmith/fks_ai:gpu .

# ARM64 variant (for Raspberry Pi)
docker buildx build --platform linux/arm64 --target arm64 -t nuniesmith/fks_ai:arm64 --push .

# Latest (alias for CPU)
docker tag nuniesmith/fks_ai:cpu nuniesmith/fks_ai:latest
```

---

### Docker Compose (Per Sub-Repo)

**File**: `fks_ai/docker-compose.yml`

```yaml

services:
  ai:
    build:
      context: .
      target: base  # or 'gpu' for GPU variant
    image: nuniesmith/fks_ai:cpu
    container_name: fks_ai
    ports:
      - "8007:8000"
    environment:
      - GPU_ENABLED=false
      - REDIS_HOST=redis
      - PROMETHEUS_ENABLED=true
    depends_on:
      - redis
    networks:
      - fks_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  redis:
    image: redis:7-alpine
    container_name: fks_redis
    networks:
      - fks_network
    restart: unless-stopped

networks:
  fks_network:
    driver: bridge
```

**Usage**:
```bash
# Run locally
docker-compose up -d

# View logs
docker-compose logs -f ai

# Stop
docker-compose down
```

---

### Master Compose (fks_main)

**File**: `fks_main/docker-compose.yml`

```yaml

services:
  # AI Service
  ai:
    image: nuniesmith/fks_ai:cpu  # or :gpu for GPU variant
    ports:
      - "8007:8000"
    environment:
      - GPU_ENABLED=false
      - REDIS_HOST=redis
    depends_on:
      - redis
    networks:
      - fks_network

  # API Service
  api:
    image: nuniesmith/fks_api:latest
    ports:
      - "8001:8000"
    environment:
      - POSTGRES_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    networks:
      - fks_network

  # App Service
  app:
    image: nuniesmith/fks_app:latest
    ports:
      - "8002:8000"
    environment:
      - AI_SERVICE_URL=http://ai:8000
      - DATA_SERVICE_URL=http://data:8000
    depends_on:
      - ai
      - data
    networks:
      - fks_network

  # Data Service
  data:
    image: nuniesmith/fks_data:latest
    ports:
      - "8003:8000"
    environment:
      - POSTGRES_HOST=postgres
    depends_on:
      - postgres
    networks:
      - fks_network

  # Execution Service
  execution:
    image: nuniesmith/fks_execution:latest
    ports:
      - "8006:8000"
    environment:
      - CCXT_ENABLED=true
      - WEBHOOK_SECRET=${WEBHOOK_SECRET}
    networks:
      - fks_network

  # Web UI
  web:
    image: nuniesmith/fks_web:latest
    ports:
      - "8000:8000"
    environment:
      - POSTGRES_HOST=postgres
      - API_URL=http://api:8000
    depends_on:
      - postgres
      - api
    networks:
      - fks_network

  # PostgreSQL
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: trading_db
      POSTGRES_USER: trading_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - fks_network

  # Redis
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - fks_network

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - fks_network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - fks_network

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:

networks:
  fks_network:
    driver: bridge
```

**Usage**:
```bash
# Deploy all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all
docker-compose down
```

---

## GitHub Actions CI/CD

### Sub-Repository Workflow (Build & Push)

**File**: `fks_ai/.github/workflows/build-push.yml`

```yaml
name: Build and Push Docker Images

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt -r requirements.dev.txt
      
      - name: Run tests
        run: |
          pytest tests/ -v --cov=src --cov-report=term-missing
      
      - name: Run linting
        run: |
          ruff check src/

  build-cpu:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and Push CPU Image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: base
          push: ${{ github.event_name == 'push' }}
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/fks_ai:cpu
            ${{ secrets.DOCKER_USERNAME }}/fks_ai:latest
  
  build-gpu:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and Push GPU Image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: gpu
          push: ${{ github.event_name == 'push' }}
          tags: ${{ secrets.DOCKER_USERNAME }}/fks_ai:gpu
  
  build-arm64:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and Push ARM64 Image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: arm64
          platforms: linux/arm64
          push: ${{ github.event_name == 'push' }}
          tags: ${{ secrets.DOCKER_USERNAME }}/fks_ai:arm64
```

**Required Secrets** (per repo):
- `DOCKER_USERNAME` - DockerHub username (`nuniesmith`)
- `DOCKER_PASSWORD` - DockerHub password/token

---

### Master Deployment Workflow (fks_main)

**File**: `fks_main/.github/workflows/deploy-all.yml`

```yaml
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
    name: Deploy with Docker Compose
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Pull latest images
        run: |
          docker-compose pull
      
      - name: Deploy services
        run: |
          docker-compose up -d
      
      - name: Wait for health checks
        run: |
          sleep 30
          docker-compose ps
  
  deploy-k8s:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'latest'
      
      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBECONFIG }}" > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
      
      - name: Apply K8s manifests
        run: |
          kubectl apply -f k8s/manifests/
      
      - name: Wait for rollout
        run: |
          kubectl rollout status deployment --all -n fks-trading --timeout=5m
      
      - name: Verify deployment
        run: |
          kubectl get pods -n fks-trading
          kubectl get svc -n fks-trading
```

**Required Secrets** (fks_main):
- `KUBECONFIG` - Kubernetes config (base64 encoded)

---

## Kubernetes Integration

### Service Deployment Updates

**Before (Monorepo)**:
```yaml
# k8s/manifests/fks-ai-deployment.yaml
spec:
  containers:
    - name: ai
      image: nuniesmith/fks:ai-latest  # Built from monorepo
      imagePullPolicy: Always
```

**After (Multi-Repo)**:
```yaml
# fks_main/k8s/manifests/fks-ai-deployment.yaml
spec:
  containers:
    - name: ai
      image: nuniesmith/fks_ai:cpu  # Pulled from sub-repo image
      imagePullPolicy: IfNotPresent  # Or Always for latest
```

---

### Master Compose to K8s Conversion

**Use Kompose** for initial conversion:
```bash
cd fks_main
kompose convert -f docker-compose.yml -o k8s/manifests/generated/
```

**Manually adjust**:
- Resource limits (CPU/RAM)
- HPA/VPA for auto-scaling
- PersistentVolumeClaims
- Ingress routes

---

### Updated Deployment Script

**File**: `fks_main/k8s/scripts/deploy-all-services.sh`

```bash
#!/bin/bash
set -e

echo "🚀 Deploying FKS Multi-Repo Stack to Kubernetes..."

# Pull latest images from DockerHub
echo "📦 Pulling latest Docker images..."
kubectl set image deployment/fks-ai ai=nuniesmith/fks_ai:cpu -n fks-trading
kubectl set image deployment/fks-api api=nuniesmith/fks_api:latest -n fks-trading
kubectl set image deployment/fks-app app=nuniesmith/fks_app:latest -n fks-trading
kubectl set image deployment/fks-data data=nuniesmith/fks_data:latest -n fks-trading
kubectl set image deployment/fks-execution execution=nuniesmith/fks_execution:latest -n fks-trading
kubectl set image deployment/fks-web web=nuniesmith/fks_web:latest -n fks-trading

# Wait for rollouts
echo "⏳ Waiting for rollouts..."
kubectl rollout status deployment --all -n fks-trading --timeout=5m

# Verify
echo "✅ Deployment complete!"
kubectl get pods -n fks-trading
```

---

## Shared Code Management

### Phase 1: Duplication Strategy

**351 shared files** in:
- `src/shared/` - Common utilities
- `src/core/` - Core logic
- `src/framework/` - Base classes

**Approach**: Copy to each service repo's `/shared/` directory.

**Sync Script**: `fks_main/scripts/sync-shared-code.sh`

```bash
#!/bin/bash
# Sync shared code across all service repos

SHARED_DIRS=("src/shared" "src/core" "src/framework")
SERVICE_REPOS=("fks_ai" "fks_api" "fks_app" "fks_data" "fks_execution" "fks_web")

for repo in "${SERVICE_REPOS[@]}"; do
  echo "Syncing shared code to $repo..."
  
  for dir in "${SHARED_DIRS[@]}"; do
    rsync -av --delete "$dir/" "../$repo/shared/$(basename $dir)/"
  done
  
  echo "✅ Synced to $repo"
done
```

**Usage**:
```bash
# After updating shared code
cd fks_main
./scripts/sync-shared-code.sh

# Commit in each service repo
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_web; do
  cd ../$repo
  git add shared/
  git commit -m "Sync shared code from main"
  git push
done
```

---

### Phase 2: fks_shared Package (Future)

**Goal**: Extract to pip-installable package.

**Structure**:
```
fks_shared/
├── setup.py
├── pyproject.toml
├── src/fks_shared/
│   ├── utils.py
│   ├── exceptions.py
│   └── models.py
└── tests/
```

**Install**:
```bash
pip install git+https://github.com/nuniesmith/fks_shared.git
```

**Timeline**: Phase 9 (after migration stabilizes).

---

## Inter-Repository Dependencies

### Service Communication

**Pattern**: REST API calls via internal DNS.

**Example** (fks_app calling fks_ai):
```python
# fks_app/src/integrations/ai_client.py
import os
import requests

AI_SERVICE_URL = os.getenv("AI_SERVICE_URL", "http://ai:8000")

def get_sentiment(symbol: str) -> dict:
    response = requests.get(f"{AI_SERVICE_URL}/sentiment/{symbol}")
    response.raise_for_status()
    return response.json()
```

**Environment Variable** (K8s):
```yaml
# fks_main/k8s/manifests/fks-app-deployment.yaml
env:
  - name: AI_SERVICE_URL
    value: "http://fks-ai:8007"
```

---

### Dependency Graph

```
fks_web → fks_api → fks_app → fks_ai
                  ↓           ↓
                fks_data    fks_execution
```

**Notes**:
- `fks_ai`, `fks_data`, `fks_execution` - No dependencies (leaf services)
- `fks_app` - Depends on `fks_ai`, `fks_data`
- `fks_api` - Depends on `fks_app`, `fks_data`
- `fks_web` - Depends on `fks_api`

---

## Versioning Strategy

### Semantic Versioning

**Format**: `MAJOR.MINOR.PATCH`

**Rules**:
- **MAJOR**: Breaking API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes

**Example**:
- `fks_ai:1.0.0` - Initial release
- `fks_ai:1.1.0` - Added Gemini integration
- `fks_ai:1.1.1` - Fixed sentiment bug

---

### Git Tags

**Per Sub-Repo**:
```bash
cd fks_ai
git tag -a v1.0.0 -m "Release 1.0.0 - Multi-agent debate system"
git push origin v1.0.0
```

**Docker Tags**:
```bash
docker tag nuniesmith/fks_ai:cpu nuniesmith/fks_ai:v1.0.0
docker push nuniesmith/fks_ai:v1.0.0
```

---

### Version Pinning (fks_main)

**File**: `fks_main/docker-compose.yml`

```yaml
services:
  ai:
    image: nuniesmith/fks_ai:v1.0.0  # Pinned version
  api:
    image: nuniesmith/fks_api:latest  # Rolling
```

**K8s**:
```yaml
# fks_main/k8s/manifests/fks-ai-deployment.yaml
spec:
  containers:
    - name: ai
      image: nuniesmith/fks_ai:v1.0.0  # Pinned for stability
```

---

## Split Execution Plan

### Prerequisites

1. ✅ Backup created: `fks-backup-20251107.bundle`
2. ✅ git-filter-repo installed: `/home/jordan/Documents/code/fks/git-filter-repo`
3. ✅ GitHub repos created: All 9 repos under `nuniesmith`
4. ✅ FILE_MAPPING.json documented
5. ✅ MULTI_REPO_ARCHITECTURE.md complete

---

### Step-by-Step Execution

**Task 7.3.1: Split fks_ai** (30 minutes)

```bash
# Clone monorepo to temp directory
cd /tmp
git clone /home/jordan/Documents/code/fks fks_ai_temp
cd fks_ai_temp

# Filter to keep only AI-related paths
/home/jordan/Documents/code/fks/git-filter-repo \
  --path repo/ai/ \
  --path src/services/ai/ \
  --path notebooks/transformer/ \
  --path tests/unit/test_rag/ \
  --path tests/unit/test_sentiment/ \
  --force

# Copy shared code
mkdir -p shared
rsync -av /home/jordan/Documents/code/fks/src/shared/ shared/shared/
rsync -av /home/jordan/Documents/code/fks/src/core/ shared/core/
rsync -av /home/jordan/Documents/code/fks/src/framework/ shared/framework/

# Add remote and push
git remote add origin https://github.com/nuniesmith/fks_ai.git
git push -u origin main --force

# Verify
git log --oneline | head -10
ls -R repo/ai/ src/services/ai/
```

**Validation**:
- ✅ Clone new repo: `git clone https://github.com/nuniesmith/fks_ai.git`
- ✅ Verify file structure: `tree -L 3`
- ✅ Check commit history: `git log --oneline`

---

**Task 7.3.2-7.3.8: Repeat for all services**

**Use script**: `fks_main/scripts/split-all-repos.sh`

```bash
#!/bin/bash
set -e

REPOS=(
  "fks_ai:repo/ai/,src/services/ai/,notebooks/transformer/"
  "fks_api:repo/api/"
  "fks_app:repo/app/,data/asmbtr_real_data_optimization.json"
  "fks_data:repo/data/,data/market_data/"
  "fks_execution:src/services/execution/"
  "fks_ninja:repo/ninja/"
  "fks_meta:scripts/devtools/scripts-meta/"
  "fks_web:repo/web/"
)

for entry in "${REPOS[@]}"; do
  IFS=':' read -r repo paths <<< "$entry"
  
  echo "🔀 Splitting $repo..."
  cd /tmp
  git clone /home/jordan/Documents/code/fks "${repo}_temp"
  cd "${repo}_temp"
  
  # Build filter-repo command
  filter_cmd="/home/jordan/Documents/code/fks/git-filter-repo --force"
  IFS=',' read -ra PATH_ARRAY <<< "$paths"
  for path in "${PATH_ARRAY[@]}"; do
    filter_cmd="$filter_cmd --path $path"
  done
  
  # Execute filter
  eval "$filter_cmd"
  
  # Copy shared code
  mkdir -p shared
  rsync -av /home/jordan/Documents/code/fks/src/shared/ shared/shared/
  rsync -av /home/jordan/Documents/code/fks/src/core/ shared/core/
  rsync -av /home/jordan/Documents/code/fks/src/framework/ shared/framework/
  
  # Push to GitHub
  git remote add origin "https://github.com/nuniesmith/$repo.git"
  git push -u origin main --force
  
  echo "✅ $repo split complete"
done
```

**Run**:
```bash
cd fks_main
./scripts/split-all-repos.sh
```

---

### Post-Split Tasks

1. **Create READMEs** in each sub-repo
2. **Add .gitignore**, **requirements.txt**
3. **Copy Dockerfiles** from main repo
4. **Add GitHub Actions workflows**
5. **Build and push initial Docker images**

---

## Migration Timeline

### Week 1: Repository Split (Days 1-5)
- **Day 1-2**: Backup, mapping, documentation (✅ COMPLETE)
- **Day 3**: Split fks_ai, fks_api, fks_app
- **Day 4**: Split fks_data, fks_execution, fks_web
- **Day 5**: Split fks_ninja, fks_meta; verify all repos

### Week 2: Docker & CI/CD (Days 6-10)
- **Day 6**: Create Dockerfiles for all sub-repos
- **Day 7**: Set up docker-compose.yml in each repo
- **Day 8**: Create GitHub Actions workflows
- **Day 9**: Build and push initial images to DockerHub
- **Day 10**: Test local deployment with docker-compose

### Week 3: Kubernetes Integration (Days 11-14)
- **Day 11**: Update K8s manifests in fks_main
- **Day 12**: Create Helm charts
- **Day 13**: Deploy to local K8s (minikube/k3s)
- **Day 14**: Raspberry Pi testing (fks_ai ARM64)

**Total**: 2 weeks (can be compressed to 10-12 days with parallelization)

---

## Success Criteria

✅ **All 9 repos** split with full commit history  
✅ **Docker images** built and pushed to DockerHub  
✅ **CI/CD pipelines** operational in all sub-repos  
✅ **Local deployment** successful with docker-compose  
✅ **K8s deployment** operational in fks_main  
✅ **Tests passing** (168/168 maintained)  
✅ **Documentation** complete in each repo  

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Broken imports | High | Comprehensive testing, import path updates |
| Shared code drift | Medium | Sync script, future fks_shared package |
| CI/CD failures | Medium | Incremental testing, rollback procedures |
| Lost commit history | High | Backup verification, git-filter-repo validation |
| Coordination overhead | Low | Automation scripts, clear ownership |

---

## Next Steps

1. ✅ **Task 6 Complete**: File mapping and architecture documented
2. **Task 7**: Execute repository split
   - Run `split-all-repos.sh`
   - Verify all repos on GitHub
   - Create READMEs
3. **Task 8**: Docker and CI/CD setup
   - Create Dockerfiles
   - Set up GitHub Actions
   - Push initial images
4. **Task 9**: K8s integration
   - Update manifests
   - Deploy to local cluster
   - Raspberry Pi testing

---

**Last Updated**: 2025-11-07  
**Status**: Planning Complete - Ready for Execution  
**Next**: Run `fks_main/scripts/split-all-repos.sh`
