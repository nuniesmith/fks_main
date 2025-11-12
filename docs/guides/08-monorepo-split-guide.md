# Monorepo Split Guide - Migration from FKS Monorepo to Multi-Repo

**Status**: Planning Phase  
**Timeline**: 14 days (2 weeks) for full migration  
**Risk Level**: Medium (mitigated with careful planning)

## 🎯 Overview

Complete guide for splitting FKS monorepo (1,731 files) into 9 independent GitHub repositories with preserved git history. This migration enables faster CI/CD (20-30% improvement), better team autonomy, and service-specific configurations.

### Target Architecture

```
BEFORE (Monorepo):
/home/jordan/Documents/code/fks/
├── fks_ai/
├── fks_api/
├── fks_app/
├── fks_data/
├── fks_execution/
├── fks_ninja/
├── fks_meta/
├── fks_web/
├── fks_training/
└── fks_main/ (orchestrator)

AFTER (Multi-Repo):
GitHub: nuniesmith/
├── fks_ai          → https://github.com/nuniesmith/fks_ai
├── fks_api         → https://github.com/nuniesmith/fks_api
├── fks_app         → https://github.com/nuniesmith/fks_app
├── fks_data        → https://github.com/nuniesmith/fks_data
├── fks_execution   → https://github.com/nuniesmith/fks_execution
├── fks_ninja       → https://github.com/nuniesmith/fks_ninja
├── fks_meta        → https://github.com/nuniesmith/fks_meta
├── fks_web         → https://github.com/nuniesmith/fks_web
└── fks_training    → https://github.com/nuniesmith/fks_training

Local: /home/jordan/Documents/code/
├── fks_main/       (local only, NOT on GitHub)
└── fks-backup/     (full monorepo backup)
```

## 📋 Repository Mapping

| Repository | File Count | Key Paths | Size | Notes |
|------------|-----------|-----------|------|-------|
| **fks_ai** | 235 | `/repo/ai/*`, `/src/services/ai/*`, `/notebooks/transformer/*` | ~85MB | Multi-stage Dockerfile (CPU/GPU/ARM64) |
| **fks_api** | 180 | `/repo/api/*`, `/src/services/api/*`, `/tests/integration/test_api*` | ~50MB | REST API routers |
| **fks_app** | 66 | `/repo/app/*`, `/src/services/app/*`, `/data/asmbtr_real_data_optimization.json` | ~30MB | Trading strategies, ASMBTR |
| **fks_data** | 200 | `/repo/data/*`, `/src/services/data/*`, `/data/market_data/*` | ~120MB | CCXT, Polygon adapters |
| **fks_execution** | 36 | `/src/services/execution/*`, `/tests/unit/test_execution/*` | ~15MB | CCXT manager, webhooks |
| **fks_ninja** | 159 | `/repo/ninja/*` (C# files) | ~40MB | NinjaTrader plugin (.csproj) |
| **fks_meta** | 1+ | `/scripts/devtools/scripts-meta/*` | <5MB | MetaTrader plugin (minimal, expandable) |
| **fks_web** | 158 | `/repo/web/*`, `/src/services/web/*`, `/tests/unit/test_web_views.py` | ~60MB | Django UI, static files |
| **fks_training** | ~100 | `/notebooks/*`, `/tests/unit/test_core/test_ml_models.py` | ~70MB | Model training, backtesting |
| **fks_main** | 696 | `/docs/*`, `/k8s/*`, `/monitoring/*`, `/scripts/*` | ~200MB | Orchestrator (local only) |

**Total**: 1,731 files → 1,135 files in sub-repos + 696 in fks_main

## 🛠️ Tools Required

### git-filter-repo

**Installation**:
```bash
# Python package
pip install git-filter-repo

# Or download single file
wget https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo
chmod +x git-filter-repo
sudo mv git-filter-repo /usr/local/bin/
```

**Why git-filter-repo?**
- ✅ Preserves commit history with correct timestamps
- ✅ Faster than git-filter-branch (10-100x)
- ✅ Handles large repos efficiently
- ✅ Rewrites commit messages automatically
- ❌ Destructive (requires backup first)

### Kompose (Optional)

**For K8s manifest generation from docker-compose.yml**:
```bash
# Download binary
curl -L https://github.com/kubernetes/kompose/releases/download/v1.31.2/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv kompose /usr/local/bin/
```

## 📝 14-Day Migration Plan

### Week 1: Preparation and Splitting (Days 1-7)

#### Day 1: Backup and Tooling

**Tasks**:
1. Create full monorepo backup
2. Install git-filter-repo
3. Document current structure
4. Create GitHub repositories

**Commands**:
```bash
# 1. Backup monorepo
cd /home/jordan/Documents/code/fks
git bundle create ~/fks-backup-$(date +%Y%m%d).bundle --all
cp -r . ~/fks-backup-$(date +%Y%m%d)

# 2. Verify backup
mkdir /tmp/fks-verify
cd /tmp/fks-verify
git clone ~/fks-backup-$(date +%Y%m%d).bundle .
git log --oneline | head -10  # Should show recent commits
cd -
rm -rf /tmp/fks-verify

# 3. Install git-filter-repo
pip install git-filter-repo
git-filter-repo --version  # Should output version

# 4. Document structure
find . -type f | wc -l  # Count files (should be ~1,731)
du -sh .  # Total size
```

**Create GitHub Repositories**:
```bash
# Using GitHub CLI (gh)
gh repo create nuniesmith/fks_ai --public --description "AI/ML services for FKS trading platform"
gh repo create nuniesmith/fks_api --public --description "REST API gateway"
gh repo create nuniesmith/fks_app --public --description "Trading strategies and business logic"
gh repo create nuniesmith/fks_data --public --description "Data adapters (CCXT, Polygon, Binance)"
gh repo create nuniesmith/fks_execution --public --description "Execution engine (webhooks, CCXT, security)"
gh repo create nuniesmith/fks_ninja --public --description "NinjaTrader C# plugin"
gh repo create nuniesmith/fks_meta --public --description "MetaTrader plugin"
gh repo create nuniesmith/fks_web --public --description "Django web UI"
gh repo create nuniesmith/fks_training --public --description "Model training and backtesting"
```

#### Day 2-3: Shared Code Analysis

**Identify shared code**:
```bash
# Find duplicated code across services
fdupes -r src/services/ | grep -v ".pyc" > shared_code_candidates.txt

# Analyze imports
grep -r "from src.shared" src/services/ > shared_imports.txt
grep -r "from src.core" src/services/ >> shared_imports.txt
grep -r "from src.framework" src/services/ >> shared_imports.txt
```

**Key shared directories**:
- `/src/shared/` - 120 files (utils, constants, types)
- `/src/core/` - 150 files (database, caching, messaging)
- `/src/framework/` - 81 files (exceptions, logging, config)

**Total shared code**: ~351 files (20% of codebase)

**Decision: Duplication Strategy**
```
Phase 1 (Immediate): Duplicate shared code in each sub-repo
  - Copy /src/shared/, /src/core/, /src/framework/ to each repo's /shared/
  - Quick migration, independent repos
  - Cost: ~351 files × 9 repos = 3,159 files (manageable)

Phase 2 (Future): Extract to fks_shared package
  - Create separate pip-installable package
  - Publish to PyPI or private package index
  - Update sub-repos: pip install fks-shared
  - Cost: Coordination overhead, version management
  - Timeline: 3-4 weeks after migration stabilizes
```

#### Day 4-5: Split fks_ai and fks_api

**fks_ai Split**:
```bash
# Clone monorepo to temp directory
cd /home/jordan/Documents/code/
git clone fks fks_ai_temp
cd fks_ai_temp

# Filter to keep only AI-related paths
git filter-repo --path repo/ai/ \
                --path src/services/ai/ \
                --path notebooks/transformer/ \
                --path tests/unit/test_rag/ \
                --path tests/integration/test_ai/ \
                --path docs/AI_ARCHITECTURE.md \
                --force

# Copy shared code
mkdir -p shared/
cp -r ../fks/src/shared/ shared/
cp -r ../fks/src/core/ shared/
cp -r ../fks/src/framework/ shared/

# Update imports (automated script)
find . -name "*.py" -exec sed -i 's|from src.shared|from shared.shared|g' {} +
find . -name "*.py" -exec sed -i 's|from src.core|from shared.core|g' {} +
find . -name "*.py" -exec sed -i 's|from src.framework|from shared.framework|g' {} +

# Create README
cat > README.md << 'EOF'
# FKS AI - Machine Learning & AI Services

AI/ML services for FKS trading platform, including:
- Multi-agent trading agents (LangGraph)
- Time-series forecasting (Lag-Llama, TimeCopilot)
- RAG intelligence (ChromaDB, semantic memory)
- Sentiment analysis (FinBERT)

## Quick Start

```bash
docker build -t nuniesmith/fks_ai:cpu .
docker run -p 8007:8000 nuniesmith/fks_ai:cpu
```

See [docs/](docs/) for full documentation.
EOF

# Add remote and push
git remote add origin https://github.com/nuniesmith/fks_ai.git
git branch -M main
git push -u origin main

# Cleanup
cd ..
rm -rf fks_ai_temp
```

**fks_api Split** (similar process):
```bash
cd /home/jordan/Documents/code/
git clone fks fks_api_temp
cd fks_api_temp

git filter-repo --path repo/api/ \
                --path src/services/api/ \
                --path tests/integration/test_api/ \
                --force

# Copy shared code (same as above)
mkdir -p shared/
cp -r ../fks/src/shared/ shared/
# ... update imports, create README, push to GitHub
```

**Validation**:
```bash
# For each split repo
cd fks_ai  # or fks_api
git log --oneline  # Should show relevant commits only
git log --follow src/services/ai/src/agents.py  # Check history preserved
find . -name "*.py" | wc -l  # Count files
```

#### Day 6: Split fks_data, fks_app, fks_execution

**Parallel splitting** (same process as Day 4-5):
```bash
# fks_data
git filter-repo --path repo/data/ --path src/services/data/ --force

# fks_app
git filter-repo --path repo/app/ --path src/services/app/ --force

# fks_execution
git filter-repo --path src/services/execution/ --force
```

**Time-saving script**:
```bash
#!/bin/bash
# scripts/split_repo.sh

REPO_NAME=$1
PATHS=$2  # Space-separated paths

cd /home/jordan/Documents/code/
git clone fks ${REPO_NAME}_temp
cd ${REPO_NAME}_temp

# Filter paths
for path in $PATHS; do
    git filter-repo --path $path --force
done

# Copy shared code
mkdir -p shared/
cp -r ../fks/src/shared/ shared/
cp -r ../fks/src/core/ shared/
cp -r ../fks/src/framework/ shared/

# Update imports
find . -name "*.py" -exec sed -i 's|from src.shared|from shared.shared|g' {} +

# Push to GitHub
git remote add origin https://github.com/nuniesmith/${REPO_NAME}.git
git branch -M main
git push -u origin main

cd ..
rm -rf ${REPO_NAME}_temp
```

**Usage**:
```bash
bash scripts/split_repo.sh fks_data "repo/data/ src/services/data/"
bash scripts/split_repo.sh fks_app "repo/app/ src/services/app/"
bash scripts/split_repo.sh fks_execution "src/services/execution/"
```

#### Day 7: Split fks_web, fks_ninja, fks_meta, fks_training

**Complete remaining splits**:
```bash
bash scripts/split_repo.sh fks_web "repo/web/ src/services/web/"
bash scripts/split_repo.sh fks_ninja "repo/ninja/"
bash scripts/split_repo.sh fks_training "notebooks/ tests/unit/test_core/test_ml_models.py"

# fks_meta (create minimal structure)
cd /home/jordan/Documents/code/
mkdir fks_meta
cd fks_meta
git init
mkdir -p src/
echo "# FKS Meta - MetaTrader Plugin" > README.md
git add .
git commit -m "Initial commit: MetaTrader plugin structure"
git remote add origin https://github.com/nuniesmith/fks_meta.git
git branch -M main
git push -u origin main
```

**End of Week 1 Validation**:
```bash
# Check all 9 repos created
gh repo list nuniesmith | grep fks_

# Clone each and verify structure
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_meta fks_web fks_training; do
    git clone https://github.com/nuniesmith/$repo /tmp/$repo
    cd /tmp/$repo
    echo "=== $repo ==="
    git log --oneline | head -5
    find . -name "*.py" | wc -l
    cd -
    rm -rf /tmp/$repo
done
```

### Week 2: Docker, CI/CD, and Testing (Days 8-14)

#### Day 8: Dockerfiles and .dockerignore

**Add to each repo**:

**Standard Dockerfile** (fks_api, fks_app, fks_data, fks_execution):
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
COPY shared/ ./shared/
ENV PYTHONPATH=/app
HEALTHCHECK CMD curl --fail http://localhost:8000/health || exit 1
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Multi-stage Dockerfile** (fks_ai):
```dockerfile
FROM python:3.12-slim AS base
# ... CPU build (see 02-docker-strategy.md)

FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS gpu
# ... GPU build
```

**Django Dockerfile** (fks_web):
```dockerfile
FROM python:3.12-slim
# ... Django-specific (see 02-docker-strategy.md)
```

**Add .dockerignore**:
```gitignore
.git/
.github/
.vscode/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.mypy_cache/
.coverage
.env
*.log
docs/
tests/
```

**Automation**:
```bash
#!/bin/bash
# scripts/add_docker_configs.sh

REPOS="fks_api fks_app fks_data fks_execution fks_web fks_ai fks_ninja fks_meta fks_training"

for repo in $REPOS; do
    cd /home/jordan/Documents/code/$repo
    
    # Copy Dockerfile template
    if [ "$repo" == "fks_ai" ]; then
        cp ../templates/Dockerfile.multistage Dockerfile
    elif [ "$repo" == "fks_web" ]; then
        cp ../templates/Dockerfile.django Dockerfile
    else
        cp ../templates/Dockerfile.standard Dockerfile
    fi
    
    # Copy .dockerignore
    cp ../templates/.dockerignore .
    
    # Commit
    git add Dockerfile .dockerignore
    git commit -m "Add Dockerfile and .dockerignore"
    git push origin main
done
```

#### Day 9-10: GitHub Actions Workflows

**Add workflows to each repo**:
```bash
#!/bin/bash
# scripts/add_github_actions.sh

REPOS="fks_api fks_app fks_data fks_execution fks_web fks_ai fks_ninja fks_meta fks_training"

for repo in $REPOS; do
    cd /home/jordan/Documents/code/$repo
    
    # Create workflow directory
    mkdir -p .github/workflows
    
    # Copy workflow template
    if [ "$repo" == "fks_ai" ]; then
        cp ../templates/workflow-multistage.yml .github/workflows/docker-build-push.yml
    elif [ "$repo" == "fks_web" ]; then
        cp ../templates/workflow-django.yml .github/workflows/docker-build-push.yml
    else
        cp ../templates/workflow-standard.yml .github/workflows/docker-build-push.yml
    fi
    
    # Update SERVICE_NAME in workflow
    sed -i "s/SERVICE_NAME: fks_api/SERVICE_NAME: $repo/g" .github/workflows/docker-build-push.yml
    
    # Commit
    git add .github/
    git commit -m "Add GitHub Actions workflow for Docker build/push"
    git push origin main
done
```

**Add DockerHub secrets** (manual step):
```bash
# For each repo, go to GitHub web UI:
# Settings → Secrets and variables → Actions → New repository secret
# Add: DOCKER_USERNAME = nuniesmith
# Add: DOCKER_PASSWORD = <your-dockerhub-token>

# Or use GitHub CLI (if available):
gh secret set DOCKER_USERNAME --body "nuniesmith" --repo nuniesmith/fks_ai
gh secret set DOCKER_PASSWORD --body "$(cat ~/.dockerhub_token)" --repo nuniesmith/fks_ai
# Repeat for all repos
```

#### Day 11: docker-compose.yml for Each Sub-Repo

**Example for fks_ai**:
```yaml
# fks_ai/docker-compose.yml
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

**Add to all repos**:
```bash
bash scripts/add_compose_files.sh
```

#### Day 12: Master docker-compose.yml in fks_main

**fks_main/docker-compose.yml** (pulls from DockerHub):
```yaml
services:
  ai:
    image: nuniesmith/fks_ai:cpu
    ports: ["8007:8000"]
    networks: [fks_network]
  
  api:
    image: nuniesmith/fks_api:latest
    ports: ["8001:8000"]
    networks: [fks_network]
  
  data:
    image: nuniesmith/fks_data:latest
    ports: ["8003:8000"]
    networks: [fks_network]
  
  app:
    image: nuniesmith/fks_app:latest
    ports: ["8002:8000"]
    networks: [fks_network]
  
  execution:
    image: nuniesmith/fks_execution:latest
    ports: ["8006:8000"]
    networks: [fks_network]
  
  web:
    image: nuniesmith/fks_web:latest
    ports: ["8000:8000"]
    networks: [fks_network]
  
  postgres:
    image: postgres:16
    ports: ["5432:5432"]
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: trading_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: trading_db
    networks: [fks_network]
  
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes:
      - redis-data:/data
    networks: [fks_network]
  
  grafana:
    image: grafana/grafana:latest
    ports: ["3000:3000"]
    volumes:
      - grafana-data:/var/lib/grafana
    networks: [fks_network]
  
  prometheus:
    image: prom/prometheus:latest
    ports: ["9090:9090"]
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    networks: [fks_network]

volumes:
  postgres-data:
  redis-data:
  grafana-data:
  prometheus-data:

networks:
  fks_network:
    driver: bridge
```

#### Day 13: Update K8s Manifests in fks_main

**Update image references**:
```bash
# fks_main/k8s/manifests/all-services.yaml
# Change:
# image: fks-api:latest
# To:
# image: nuniesmith/fks_api:latest

# Automated update
cd /home/jordan/Documents/code/fks_main/k8s/manifests
for file in *.yaml; do
    sed -i 's|image: fks-|image: nuniesmith/fks_|g' $file
    sed -i 's|image: fks_|image: nuniesmith/fks_|g' $file
done

# Commit changes
git add .
git commit -m "Update K8s manifests to use DockerHub images"
```

**Test deployment**:
```bash
kubectl delete namespace fks-trading  # Clean slate
kubectl apply -f k8s/manifests/
kubectl get pods -n fks-trading --watch
```

#### Day 14: Validation and Documentation

**End-to-end test**:
```bash
# 1. Make code change in sub-repo
cd /home/jordan/Documents/code/fks_api
echo "# Test change" >> README.md
git add README.md
git commit -m "Test: Trigger GitHub Actions"
git push origin main

# 2. Check GitHub Actions
gh run list --repo nuniesmith/fks_api

# 3. Verify DockerHub
docker pull nuniesmith/fks_api:latest
docker images | grep fks_api

# 4. Update K8s deployment
cd /home/jordan/Documents/code/fks_main
kubectl set image deployment/fks-api fks-api=nuniesmith/fks_api:latest -n fks-trading
kubectl rollout status deployment/fks-api -n fks-trading

# 5. Test health endpoint
curl -k https://api.fkstrading.xyz/health
```

**Update documentation**:
```bash
# Update README files
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_meta fks_web fks_training; do
    cd /home/jordan/Documents/code/$repo
    cat >> README.md << 'EOF'

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/ -v

# Build Docker image
docker build -t nuniesmith/$REPO_NAME:latest .

# Run locally
docker run -p 8000:8000 nuniesmith/$REPO_NAME:latest
```
EOF
    git add README.md
    git commit -m "Update README with development instructions"
    git push origin main
done
```

## 🔄 Shared Code Synchronization

### Immediate Solution: Sync Script

```bash
#!/bin/bash
# fks_main/scripts/sync-shared-code.sh
# Propagate changes to shared code across all sub-repos

REPOS="fks_ai fks_api fks_app fks_data fks_execution fks_web fks_training"
SHARED_DIRS="shared/shared shared/core shared/framework"

for repo in $REPOS; do
    cd /home/jordan/Documents/code/$repo
    
    for dir in $SHARED_DIRS; do
        # Copy from fks_main source of truth
        rsync -av --delete ../../fks_main/src/${dir##*/}/ $dir/
    done
    
    # Commit if changes
    if [ -n "$(git status --porcelain)" ]; then
        git add shared/
        git commit -m "Sync shared code from fks_main"
        git push origin main
    fi
done
```

**Run weekly**:
```bash
# Add to cron
crontab -e
# 0 2 * * 1 /home/jordan/Documents/code/fks_main/scripts/sync-shared-code.sh
```

### Future Solution: fks_shared Package (Phase 2)

**Structure**:
```
fks_shared/
├── setup.py
├── pyproject.toml
├── README.md
├── fks_shared/
│   ├── __init__.py
│   ├── shared/
│   ├── core/
│   └── framework/
└── tests/
```

**setup.py**:
```python
from setuptools import setup, find_packages

setup(
    name='fks-shared',
    version='0.1.0',
    packages=find_packages(),
    install_requires=[
        'pydantic>=2.0',
        'redis>=5.0',
        'sqlalchemy>=2.0',
    ],
    author='FKS Trading Team',
    description='Shared utilities for FKS trading platform',
    url='https://github.com/nuniesmith/fks_shared',
)
```

**Publishing**:
```bash
# Build package
python setup.py sdist bdist_wheel

# Publish to PyPI (or private index)
twine upload dist/*

# Install in sub-repos
pip install fks-shared==0.1.0
```

**Update sub-repos**:
```python
# Change imports from:
from shared.shared.utils import format_ticker

# To:
from fks_shared.shared.utils import format_ticker
```

## 📊 Expected Benefits

### CI/CD Performance

| Metric | Monorepo | Multi-Repo | Improvement |
|--------|----------|------------|-------------|
| Build Time (avg) | 20-30 min | <5 min/repo | 20-30% faster |
| Test Time | 15-20 min | <3 min/repo | 25-30% faster |
| Deploy Time | 10 min | 2-3 min/service | 70% faster |
| Iteration Velocity | Baseline | +25% | More deploys/day |

### Team Autonomy

- ✅ Independent service ownership
- ✅ Service-specific CI/CD pipelines
- ✅ Isolated deployments (reduce blast radius)
- ✅ Easier onboarding (smaller codebases)

### Challenges

| Challenge | Mitigation |
|-----------|-----------|
| Shared code drift | Sync script (immediate), fks_shared package (future) |
| Coordination overhead | 15% initial increase (normalizes after 2-3 sprints) |
| Broken dependencies | Comprehensive testing, rollback procedures |
| Import path changes | Automated sed replacements, CI validation |

## 🔗 References

- [Docker Strategy](./02-docker-strategy.md) - Build/push workflows
- [GitHub Actions](./03-github-actions.md) - CI/CD automation
- [Core Architecture](./01-core-architecture.md) - K8s deployment
- [git-filter-repo Documentation](https://github.com/newren/git-filter-repo)
- [Kompose Conversion Guide](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)

## 🎯 Success Criteria

- ✅ All 9 repos created with preserved history
- ✅ GitHub Actions workflows operational
- ✅ Docker images on DockerHub (nuniesmith/*)
- ✅ K8s deployment updated to pull from DockerHub
- ✅ End-to-end test: Code change → CI/CD → Deployment
- ✅ Build time <5 min per repo
- ✅ Documentation updated in all repos

**Timeline**: 14 days for full migration, can parallelize to reduce to 10-12 days.
