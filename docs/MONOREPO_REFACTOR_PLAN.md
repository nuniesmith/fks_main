# FKS Monorepo Refactor Plan 🏗️

**Date**: November 7, 2025  
**Status**: Planning Phase  
**Goal**: Prepare for service extraction while fixing duplication issues

---

## 🔍 Current Issues Identified

### 1. **Critical Duplication Problem** ⚠️

#### `/src/` Root Level (Legacy Django Structure)
```
/src/
├── core/           # Django app - 4,540 LOC
├── framework/      # Shared utilities - 25,488 LOC
├── monitor/        # Monitoring - 761 LOC
├── shared/         # NEW centralization attempt
│   ├── core/       # Duplicate of above core/
│   │   └── core/   # ❌ NESTED DUPLICATE (core/core/)
│   ├── framework/  # ✅ Identical to root framework/
│   └── monitor/    # ✅ Identical to root monitor/
└── authentication/ # Django app
```

**Problem**: We have **triple duplication** of core modules:
- `/src/core/` (original)
- `/src/shared/core/` (copy)
- `/src/shared/core/core/` (nested mistake)

**Framework and monitor are duplicated twice**:
- `/src/framework/` vs `/src/shared/framework/` (identical)
- `/src/monitor/` vs `/src/shared/monitor/` (identical)

#### `/repo/` Directory (Future Service Repos)
```
/repo/
├── ai/         # Will become fks-ai repo
├── api/        # Will become fks-api repo
├── app/        # Will become fks-app repo
├── data/       # Will become fks-data repo
├── execution/  # Will become fks-execution repo
├── ninja/      # Will become fks-ninja repo
└── web/        # Will become fks-web repo
```

**Each service currently duplicates shared code**:
```
/repo/*/src/framework/  # Duplicate of shared framework
/repo/*/src/core/       # Duplicate of shared core
```

### 2. **Import Pattern Confusion**

Multiple import patterns exist:
```python
# Pattern 1: Root imports (breaks in services)
from core.database import DatabaseManager

# Pattern 2: Shared imports (intended path)
from src.shared.framework.middleware import RateLimiter

# Pattern 3: Service-local imports (duplicates)
from framework.config import Config

# Pattern 4: Legacy imports (deprecated)
from config import SYMBOLS  # Old pattern
from shared_python import Trade  # Microservice artifact
```

---

## 🎯 Proposed Solution: Three-Tier Architecture

### Tier 1: **Main FKS Repo** (Platform Orchestrator)
```
/home/jordan/Documents/code/fks/  (THIS REPO)
├── README.md                      # Main platform docs
├── docker-compose.yml             # Full stack orchestration
├── k8s/                          # Kubernetes manifests for all services
├── monitoring/                   # Prometheus, Grafana, Alertmanager
├── docs/                         # Platform-wide documentation
├── scripts/                      # Deployment automation
├── shared/                       # ⭐ SHARED LIBRARY PACKAGE
│   ├── pyproject.toml           # shared-fks package
│   ├── src/
│   │   └── fks_shared/          # Import as: from fks_shared.xxx
│   │       ├── framework/       # Common utilities
│   │       ├── core/            # Core business logic
│   │       ├── monitor/         # Observability
│   │       └── models/          # Shared data models
│   └── tests/
└── services/                     # Git submodules pointing to service repos
    ├── fks-ai/                  # Submodule → github.com/nuniesmith/fks-ai
    ├── fks-api/                 # Submodule → github.com/nuniesmith/fks-api
    ├── fks-app/                 # Submodule → github.com/nuniesmith/fks-app
    ├── fks-data/                # Submodule → github.com/nuniesmith/fks-data
    ├── fks-execution/           # Submodule → github.com/nuniesmith/fks-execution
    ├── fks-ninja/               # Submodule → github.com/nuniesmith/fks-ninja
    └── fks-web/                 # Submodule → github.com/nuniesmith/fks-web
```

### Tier 2: **Shared Library** (Distributed as Package)
```
/home/jordan/Documents/code/fks/shared/
├── pyproject.toml               # Package: fks-shared
├── README.md
├── src/
│   └── fks_shared/
│       ├── __init__.py
│       ├── framework/          # From current /src/framework
│       │   ├── cache/
│       │   ├── config/
│       │   ├── middleware/
│       │   └── logging/
│       ├── core/               # From current /src/core (consolidated)
│       │   ├── database/
│       │   ├── models/
│       │   └── utils/
│       ├── monitor/            # From current /src/monitor
│       │   ├── health/
│       │   └── metrics/
│       └── exceptions/         # Common exception types
└── tests/
    ├── test_framework/
    ├── test_core/
    └── test_monitor/
```

**Installation in services**:
```toml
# In service's pyproject.toml
[tool.poetry.dependencies]
fks-shared = {path = "../../shared", develop = true}
# OR for production:
fks-shared = {git = "https://github.com/nuniesmith/fks-shared.git", tag = "v1.0.0"}
```

**Import pattern**:
```python
# All services use consistent imports
from fks_shared.framework.middleware import RateLimiter, CircuitBreaker
from fks_shared.core.database import DatabaseManager
from fks_shared.monitor.metrics import PrometheusMetrics
from fks_shared.models import Trade, Position, Signal
```

### Tier 3: **Individual Service Repos** (Microservices)
```
github.com/nuniesmith/fks-api/
├── README.md
├── pyproject.toml              # Depends on fks-shared
├── Dockerfile
├── k8s/                        # Service-specific K8s manifests
├── src/
│   └── fks_api/               # Service code only
│       ├── routes/
│       ├── handlers/
│       └── __init__.py
├── tests/
└── docs/
```

**Each service**:
- ✅ Single responsibility (API, Data, Execution, etc.)
- ✅ Independent versioning and deployment
- ✅ Depends on `fks-shared` package (no duplication)
- ✅ Can be developed/tested independently
- ✅ Can have its own CI/CD pipeline

---

## 📋 Migration Plan (7 Phases)

### Phase 1: Clean Up Current Duplication (1 day) 🔴 URGENT

**Objective**: Remove duplicate code in `/src/` and consolidate into single location

#### Step 1.1: Analyze Current State
```bash
# Compare directories to confirm they're duplicates
diff -r src/framework src/shared/framework
diff -r src/core src/shared/core
diff -r src/monitor src/shared/monitor

# Check for the nested core/core issue
ls -la src/shared/core/core/
```

#### Step 1.2: Decision - Which to Keep?

**Option A: Keep `/src/shared/` as transition location**
- Delete `/src/core`, `/src/framework`, `/src/monitor`
- Keep `/src/shared/core`, `/src/shared/framework`, `/src/shared/monitor`
- Fix the nested `/src/shared/core/core/` issue
- Update all imports in `/src/` to use `src.shared.xxx`

**Option B: Keep root level temporarily (safer)**
- Delete `/src/shared/` entirely
- Keep `/src/core`, `/src/framework`, `/src/monitor`
- Then move to proper `shared/` package structure in Phase 2

**Recommendation**: **Option A** - Keep `/src/shared/` since it's the intended direction

#### Step 1.3: Execute Cleanup
```bash
# Backup first!
tar -czf ~/fks-src-backup-$(date +%Y%m%d).tar.gz src/

# Remove nested duplicate
rm -rf src/shared/core/core/

# Remove root duplicates
rm -rf src/core/
rm -rf src/framework/
rm -rf src/monitor/

# Update imports in remaining /src/ files
find src/ -name "*.py" -type f -exec sed -i 's/from core\./from src.shared.core./g' {} \;
find src/ -name "*.py" -type f -exec sed -i 's/from framework\./from src.shared.framework./g' {} \;
find src/ -name "*.py" -type f -exec sed -i 's/from monitor\./from src.shared.monitor./g' {} \;

# Run tests to verify nothing broke
make test
```

### Phase 2: Create Proper Shared Package (1 day)

**Objective**: Convert `/src/shared/` into installable `fks-shared` package

#### Step 2.1: Create Package Structure
```bash
# Create new shared package directory
mkdir -p shared/src/fks_shared
mkdir -p shared/tests

# Move consolidated code
mv src/shared/core shared/src/fks_shared/core
mv src/shared/framework shared/src/fks_shared/framework
mv src/shared/monitor shared/src/fks_shared/monitor
```

#### Step 2.2: Create pyproject.toml
```toml
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "fks-shared"
version = "1.0.0"
description = "Shared utilities and models for FKS Trading Platform"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.13"
django = "^5.1.3"
redis = "^5.0.0"
prometheus-client = "^0.21.0"
pydantic = "^2.0.0"
loguru = "^0.7.0"

[tool.poetry.group.dev.dependencies]
pytest = "^8.3.4"
pytest-asyncio = "^0.24.0"
mypy = "^1.13.0"
ruff = "^0.7.4"
```

#### Step 2.3: Add __init__.py Files
```python
# shared/src/fks_shared/__init__.py
"""FKS Trading Platform - Shared Utilities and Models."""
__version__ = "1.0.0"

from fks_shared.framework import *
from fks_shared.core import *
from fks_shared.monitor import *

__all__ = [
    # Framework exports
    "RateLimiter",
    "CircuitBreaker",
    "Config",
    "get_logger",
    # Core exports
    "DatabaseManager",
    "CacheManager",
    # Monitor exports
    "PrometheusMetrics",
    "HealthCheck",
]
```

#### Step 2.4: Install in Development Mode
```bash
cd shared
poetry install

# Or with pip
pip install -e .
```

### Phase 3: Extract First Service (fks-api) (2 days)

**Objective**: Create template for service extraction

#### Step 3.1: Create New Repo
```bash
# On GitHub: Create new repo "fks-api"
mkdir -p ~/repos/fks-api
cd ~/repos/fks-api
git init
git remote add origin git@github.com:nuniesmith/fks-api.git
```

#### Step 3.2: Copy Service Code
```bash
# Copy from /repo/api
cp -r ~/Documents/code/fks/repo/api/* ~/repos/fks-api/

# Remove duplicate shared code
rm -rf ~/repos/fks-api/src/framework/
rm -rf ~/repos/fks-api/src/core/

# Rename to proper package
mv ~/repos/fks-api/src ~/repos/fks-api/src_old
mkdir -p ~/repos/fks-api/src/fks_api
mv ~/repos/fks-api/src_old/* ~/repos/fks-api/src/fks_api/
```

#### Step 3.3: Update pyproject.toml
```toml
[tool.poetry]
name = "fks-api"
version = "1.0.0"
description = "FKS Trading Platform - REST API Service"

[tool.poetry.dependencies]
python = "^3.13"
fastapi = "^0.115.0"
fks-shared = {path = "../../fks/shared", develop = true}

# OR for production:
# fks-shared = {git = "https://github.com/nuniesmith/fks-shared.git", tag = "v1.0.0"}
```

#### Step 3.4: Update Imports
```bash
# Update all imports to use fks_shared
find src/ -name "*.py" -exec sed -i 's/from framework\./from fks_shared.framework./g' {} \;
find src/ -name "*.py" -exec sed -i 's/from core\./from fks_shared.core./g' {} \;
```

#### Step 3.5: Test and Push
```bash
poetry install
poetry run pytest
git add .
git commit -m "Initial extraction of fks-api service"
git push origin main
```

### Phase 4: Add as Submodule to Main Repo (30 min)

#### Step 4.1: Add Submodule
```bash
cd ~/Documents/code/fks
mkdir -p services
git submodule add git@github.com:nuniesmith/fks-api.git services/fks-api
git submodule update --init --recursive
```

#### Step 4.2: Update docker-compose.yml
```yaml
services:
  fks-api:
    build:
      context: ./services/fks-api
      dockerfile: Dockerfile
    volumes:
      - ./shared:/app/shared:ro  # Mount shared code
    environment:
      - PYTHONPATH=/app/shared/src:/app/src
```

### Phase 5: Extract Remaining Services (1-2 weeks)

Repeat Phase 3 for each service:
- [ ] fks-data
- [ ] fks-app
- [ ] fks-execution
- [ ] fks-ai
- [ ] fks-web
- [ ] fks-ninja

**Priority Order**:
1. **fks-api** (template, low dependencies)
2. **fks-data** (needed by others)
3. **fks-execution** (core trading logic)
4. **fks-app** (business logic)
5. **fks-ai** (ML/AI features)
6. **fks-web** (Django UI)
7. **fks-ninja** (NinjaTrader integration)

### Phase 6: Update Main Repo Structure (1 day)

#### Step 6.1: Clean Up Old Structure
```bash
# Remove old /repo directory
rm -rf repo/

# Remove old /src directory (except Django manage.py if needed)
# Keep only authentication app if it's main-repo specific
```

#### Step 6.2: Create Platform-Level Files
```
/home/jordan/Documents/code/fks/
├── README.md                    # Platform overview
├── ARCHITECTURE.md              # Full system architecture
├── docker-compose.yml           # Orchestration
├── docker-compose.dev.yml       # Development environment
├── k8s/                        # All K8s manifests
│   ├── base/                   # Base configurations
│   ├── services/               # Per-service manifests
│   │   ├── api/
│   │   ├── data/
│   │   └── ...
│   └── monitoring/             # Monitoring stack
├── shared/                     # Shared package
│   ├── pyproject.toml
│   └── src/fks_shared/
├── services/                   # Git submodules
│   ├── fks-api/
│   ├── fks-data/
│   └── ...
├── monitoring/                 # Monitoring configs
├── scripts/                    # Platform automation
│   ├── setup.sh
│   ├── deploy.sh
│   └── update-services.sh
└── docs/                       # Platform docs
    ├── GETTING_STARTED.md
    ├── SERVICE_DEVELOPMENT.md
    └── DEPLOYMENT.md
```

### Phase 7: CI/CD Setup (1 day)

#### Step 7.1: Shared Package CI
```yaml
# shared/.github/workflows/test.yml
name: Test Shared Package
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.13'
      - run: poetry install
      - run: poetry run pytest
      - run: poetry run mypy src/
```

#### Step 7.2: Service CI (Template)
```yaml
# services/fks-api/.github/workflows/test.yml
name: Test API Service
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: false  # Don't need fks-shared submodule for testing
      - run: poetry install
      - run: poetry run pytest
      - name: Build Docker Image
        run: docker build -t fks-api:test .
```

#### Step 7.3: Main Repo CI (Integration)
```yaml
# .github/workflows/integration.yml
name: Integration Tests
on: [push, pull_request]
jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true  # Fetch all service repos
      - name: Start Stack
        run: docker-compose up -d
      - name: Run Integration Tests
        run: pytest tests/integration/
      - name: Cleanup
        run: docker-compose down
```

---

## 🎯 Benefits of This Approach

### For Development
- ✅ **Clear Separation**: Platform orchestration vs service code
- ✅ **No Duplication**: Single source of truth in `fks-shared`
- ✅ **Independent Development**: Work on services without affecting others
- ✅ **Easy Testing**: Each service has its own test suite
- ✅ **Version Control**: Tag and release services independently

### For Deployment
- ✅ **Selective Deployment**: Deploy only changed services
- ✅ **Rollback**: Revert individual services without full redeploy
- ✅ **Scaling**: Scale services independently based on load
- ✅ **Resource Efficiency**: Build only what changed

### For Collaboration
- ✅ **Clear Ownership**: Each repo has clear purpose
- ✅ **Easier PRs**: Smaller, focused changes
- ✅ **Better CI/CD**: Faster pipelines per service
- ✅ **Documentation**: Service-specific docs in service repos

---

## 📊 Current vs Future Structure

### Current (Problematic)
```
/fks/
├── src/
│   ├── core/              ❌ Duplicate 1
│   ├── framework/         ❌ Duplicate 1
│   ├── shared/
│   │   ├── core/          ❌ Duplicate 2
│   │   │   └── core/      ❌ Duplicate 3 (nested!)
│   │   └── framework/     ❌ Duplicate 2
└── repo/
    ├── api/
    │   └── src/framework/ ❌ Duplicate 3
    ├── data/
    │   └── src/framework/ ❌ Duplicate 4
    └── ...
```

### Future (Clean)
```
/fks/ (Main Platform Repo)
├── shared/                     ✅ Single source
│   └── src/fks_shared/
│       ├── framework/
│       ├── core/
│       └── monitor/
└── services/                   ✅ Git submodules
    ├── fks-api/               → github.com/nuniesmith/fks-api
    ├── fks-data/              → github.com/nuniesmith/fks-data
    └── ...

Each service just imports:
from fks_shared.framework import ...
```

---

## 🚨 Risks and Mitigations

### Risk 1: Breaking Changes During Migration
**Mitigation**:
- Work in feature branch `refactor/monorepo-split`
- Keep backups of current state
- Test thoroughly before merging
- Use git tags for rollback points

### Risk 2: Import Hell During Transition
**Mitigation**:
- Use automated find/replace for import updates
- Add temporary compatibility shims
- Document import patterns clearly
- Phase migration service by service

### Risk 3: Shared Package Version Conflicts
**Mitigation**:
- Pin `fks-shared` versions in services
- Use semantic versioning
- Test backward compatibility
- Document breaking changes in CHANGELOG

### Risk 4: Submodule Complexity
**Mitigation**:
- Document submodule workflow
- Create helper scripts (`update-services.sh`)
- Consider alternatives (pip packages, manual clones)
- Keep main repo simple

---

## 📝 Next Steps (Immediate Actions)

### Day 1: Assessment and Cleanup
```bash
# 1. Back up current state
tar -czf ~/fks-backup-$(date +%Y%m%d).tar.gz ~/Documents/code/fks/

# 2. Create analysis script
python scripts/analyze_duplication.py > docs/DUPLICATION_REPORT.md

# 3. Review and confirm approach
# (Review this plan with team/yourself)
```

### Day 2-3: Execute Phase 1 (Clean Duplicates)
```bash
# Follow Phase 1 steps above
# Commit frequently
# Test after each change
```

### Day 4-5: Execute Phase 2 (Create Shared Package)
```bash
# Follow Phase 2 steps above
# Test shared package independently
# Document usage patterns
```

### Week 2: Extract Services (Phase 3-5)
```bash
# One service per day
# Start with fks-api (simplest)
# Test each extraction thoroughly
```

---

## 🔗 Related Documentation

- `/docs/MONOREPO_ARCHITECTURE.md` - Current architecture
- `/docs/PHASE_1_PROGRESS.md` - Previous cleanup work
- `/docs/CLEANUP_COMPLETE.md` - Code cleanup results
- `.github/copilot-instructions.md` - Project roadmap

---

## ✅ Success Criteria

**Phase 1 Complete When**:
- [ ] No duplicate directories in `/src/`
- [ ] All imports work correctly
- [ ] All tests pass
- [ ] No nested `core/core/` directory

**Phase 2 Complete When**:
- [ ] `fks-shared` package installable
- [ ] All exports documented
- [ ] Tests pass independently
- [ ] Version tagged (v1.0.0)

**Full Migration Complete When**:
- [ ] All 7 services extracted to separate repos
- [ ] All services added as submodules
- [ ] Main repo only contains orchestration code
- [ ] All service tests pass independently
- [ ] Integration tests pass in main repo
- [ ] Documentation updated
- [ ] CI/CD pipelines working

---

**Created**: November 7, 2025  
**Author**: GitHub Copilot + Jordan  
**Status**: 📝 Planning - Ready for Review
