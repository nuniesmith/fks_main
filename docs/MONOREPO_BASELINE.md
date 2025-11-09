# FKS Monorepo Baseline Documentation

**Date**: November 7, 2025  
**Purpose**: Document current monorepo structure before Phase 7 multi-repo split  
**Backup**: `fks-backup-20251107.bundle` (23MB, 6,053 objects)

---

## Overview

This document establishes the baseline structure of the FKS monorepo before splitting into multiple repositories. The split aims to improve CI/CD performance by 20-30% and enable independent service deployments.

### Summary Statistics

- **Total Files**: 4,481 (excluding .git, .venv, node_modules, cache)
- **Total Size**: ~23MB compressed git bundle
- **Git Objects**: 6,053 (4,586 compressed)
- **Git History**: Full commit history and branches preserved
- **Last Commit**: `cc7c36b - moving other services to seperate repos`

---

## File Distribution by Service

### Service Directories

| Directory | File Count | Target Repo | Notes |
|-----------|------------|-------------|-------|
| `repo/ai/` | 80 | fks_ai | AI/ML models, agents, forecasting |
| `repo/api/` | 230 | fks_api | REST API endpoints, routers |
| `repo/app/` | 99 | fks_app | Business logic, ASMBTR strategy |
| `repo/data/` | 232 | fks_data | Data adapters, CCXT integration |
| `repo/ninja/` | 260 | fks_ninja | NinjaTrader plugin (C#) |
| `repo/web/` | 219 | fks_web | Django UI, templates |
| `src/services/ai/` | 4 | fks_ai | Sentiment analysis module |
| `src/services/execution/` | ~36 | fks_execution | CCXT, validation, security |
| **Total Services** | **1,160** | **8 repos** | Core service code |

### Infrastructure Directories

| Directory | File Count | Target Repo | Notes |
|-----------|------------|-------------|-------|
| `docs/` | 218 | main_fks | Documentation, guides, status reports |
| `k8s/` | 54 | main_fks | Kubernetes manifests, Helm charts |
| `monitoring/` | 11 | main_fks | Prometheus/Grafana configs |
| `scripts/` | 606 | main_fks | DevOps scripts, utilities |
| `tests/` | 155 | Split | Unit/integration tests per service |
| **Total Infrastructure** | **1,044** | **main_fks** | Orchestration and tooling |

### Shared Code (Duplication Strategy)

Identified ~351 files in shared directories to be duplicated across repos:
- `/src/shared/` - Common utilities, exceptions
- `/src/core/` - Core abstractions, base classes
- `/src/framework/` - Framework-level components

**Phase 9 Plan**: Extract to `fks_shared` pip-installable package to eliminate duplication.

---

## File Type Distribution

### Top 20 File Types

```
   791  .py     - Python source files
   553  .sh     - Shell scripts
   444  .o      - Object files (Rust builds)
   357  .json   - Configuration, data files
   330  .md     - Markdown documentation
   205  .js     - JavaScript files
   204  .timestamp - Build timestamps
   184  .d      - Dependency files (Rust)
   148  .rmeta  - Rust metadata
   148  .rlib   - Rust libraries
    80  .cs     - C# NinjaTrader files
    60  .yml    - YAML configs (K8s, CI/CD)
    54  .txt    - Text files
    51  .css    - Stylesheets
    46  .svg    - Vector graphics
    34  .yaml   - YAML configs (alternative extension)
    19  .ps1    - PowerShell scripts
    16  .xml    - XML configs
    14  .png    - Images
    14  .gitkeep - Empty directory markers
```

### File Type Analysis

**Code Files** (1,644 total):
- Python: 791 files (48%)
- C#: 80 files (5%) - NinjaTrader plugin
- JavaScript: 205 files (12%)
- Shell: 553 files (34%)
- CSS: 51 files (3%)

**Configuration Files** (451 total):
- JSON: 357 files
- YAML: 94 files (yml + yaml)

**Documentation** (330 files):
- Markdown: 330 files

**Build Artifacts** (924 files):
- Rust build outputs: 924 files (.o, .d, .rmeta, .rlib, .timestamp)
- **Note**: These should be in .gitignore for multi-repo

---

## Repository Size Analysis

### Compressed Bundle

```bash
$ ls -lh fks-backup-20251107.bundle
-rw-rw-r-- 1 jordan jordan 23M Nov  7 02:02 fks-backup-20251107.bundle
```

### Git Statistics

```bash
Enumerating objects: 6053, done.
Counting objects: 100% (6053/6053), done.
Delta compression using up to 12 threads
Compressing objects: 100% (4586/4586), done.
Total 6053 (delta 2316)
```

- **Total Objects**: 6,053
- **Compressed Objects**: 4,586 (76% compression)
- **Deltas**: 2,316 (efficient storage)

---

## Directory Structure Snapshot

```
/home/jordan/Documents/code/fks/
├── .github/
│   └── copilot-instructions.md      # Master roadmap
├── assets/
│   └── registry.py                  # Asset registry
├── data/
│   └── market_data/                 # Historical data
├── docker/
│   ├── Dockerfile                   # Multi-service builds
│   ├── Dockerfile.api
│   ├── Dockerfile.app
│   ├── Dockerfile.execution
│   ├── Dockerfile.web_ui
│   └── entrypoint.sh
├── docs/                            # 218 documentation files
│   ├── AI_SENTIMENT_INTEGRATION.md
│   ├── FULL_STACK_DEPLOYMENT.md
│   ├── PHASE_*.md
│   └── ...
├── k8s/                             # 54 Kubernetes files
│   ├── manifests/
│   └── scripts/
├── logs/                            # Application logs
│   ├── ai/
│   ├── api/
│   └── app/
├── monitoring/                      # 11 monitoring configs
│   ├── grafana/
│   └── prometheus/
├── nginx/                           # NGINX configs
├── notebooks/                       # Jupyter notebooks
├── repo/                            # Service implementations
│   ├── ai/         (80 files)       → fks_ai
│   ├── api/        (230 files)      → fks_api
│   ├── app/        (99 files)       → fks_app
│   ├── data/       (232 files)      → fks_data
│   ├── ninja/      (260 files)      → fks_ninja
│   └── web/        (219 files)      → fks_web
├── scripts/                         # 606 utility scripts
│   ├── devtools/
│   ├── deployment/
│   └── testing/
├── sql/                             # Database schemas
├── src/                             # Source code
│   ├── core/
│   ├── framework/
│   ├── services/
│   │   ├── ai/     (4 files)        → fks_ai
│   │   ├── execution/ (~36 files)   → fks_execution
│   │   └── ...
│   └── shared/
├── tests/                           # 155 test files
│   ├── unit/
│   └── integration/
├── docker-compose.yml
├── Makefile
├── requirements.txt
└── README.md
```

---

## Service Boundaries for Split

### Target Repository Mapping

| Repository | Source Paths | File Count | Primary Language | Notes |
|------------|--------------|------------|------------------|-------|
| **fks_ai** | `repo/ai/`, `src/services/ai/` | 84 | Python | Multi-agent AI, sentiment, forecasting |
| **fks_api** | `repo/api/` | 230 | Python | REST API, routers, health checks |
| **fks_app** | `repo/app/` | 99 | Python | ASMBTR strategy, business logic |
| **fks_data** | `repo/data/` | 232 | Python | Data adapters, CCXT, exchanges |
| **fks_execution** | `src/services/execution/` | 36 | Python/Rust | Order execution, validation |
| **fks_ninja** | `repo/ninja/` | 260 | C# | NinjaTrader plugin, .csproj |
| **fks_meta** | (new structure) | 1+ | MQL5 | MetaTrader plugin, minimal |
| **fks_web** | `repo/web/` | 219 | Python/JS | Django UI, templates, static |
| **main_fks** | Root, docs, k8s, monitoring | 696+ | Mixed | Orchestration, CI/CD, docs |

### Shared Code Distribution Strategy

**Phase 7 (Initial Split)**:
- Duplicate `/src/shared/`, `/src/core/`, `/src/framework/` to each sub-repo
- Add `/scripts/sync-shared-code.sh` for manual synchronization
- Document duplication in `/docs/SHARED_CODE_MANAGEMENT.md`

**Phase 9 (Future)**:
- Extract shared code to `fks_shared` pip package
- Publish to private PyPI or GitHub Packages
- Update all repos to use `pip install fks-shared`
- Remove duplicated code, reduce total codebase by ~20%

---

## Git Backup Verification

### Backup Creation

```bash
cd /home/jordan/Documents/code/fks
git bundle create fks-backup-20251107.bundle --all
```

**Result**: 23MB bundle with all branches, tags, and commit history.

### Restoration Test

```bash
cd /tmp
git clone /home/jordan/Documents/code/fks/fks-backup-20251107.bundle fks-test-restore
cd fks-test-restore
git log --oneline -5
```

**Output**:
```
cc7c36b (HEAD -> main, origin/main, origin/HEAD) moving other services to seperate repos
5ef1f3f feat: add deployment scripts and update monitoring for Celery-enabled web services
02c94f8 docs: update known issues with template fix status and deployment instructions
9c47a71 feat: add script to update web service from DockerHub
5cc948d fix: add web templates directory to Django TEMPLATES settings
```

**Verification**: ✅ Backup successfully restored with full history and branches.

---

## Tools Installed

### git-filter-repo

- **Version**: fb3de42e4281
- **Location**: `/home/jordan/Documents/code/fks/git-filter-repo`
- **Source**: https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo
- **Purpose**: Split monorepo with history preservation

**Usage**:
```bash
cd /home/jordan/Documents/code/fks
./git-filter-repo --help
```

---

## Pre-Split Checklist

Before proceeding with repository split (Phase 7.1.2):

- [x] **Backup Created**: `fks-backup-20251107.bundle` (23MB)
- [x] **Backup Verified**: Successfully restored to `/tmp/fks-test-restore`
- [x] **git-filter-repo Installed**: Version fb3de42e4281
- [x] **File Counts Documented**: 4,481 total files mapped to 8 repos
- [x] **Service Boundaries Defined**: Clear paths for each target repo
- [x] **Shared Code Identified**: ~351 files for duplication strategy
- [ ] **Repository Mapping Created**: Detailed FILE_MAPPING.json (Task 6)
- [ ] **GitHub Repos Created**: 8 new repositories (Task 6)
- [ ] **Split Strategy Documented**: MULTI_REPO_ARCHITECTURE.md (Task 6)

---

## Risk Assessment

### Low Risk
- ✅ Full backup with verified restoration
- ✅ git-filter-repo preserves commit history
- ✅ Clear service boundaries with minimal overlap
- ✅ Existing K8s deployment uses separate images

### Medium Risk
- ⚠️ Shared code duplication (351 files)
  - **Mitigation**: Sync script + future fks_shared package
- ⚠️ Import path changes after split
  - **Mitigation**: Update imports systematically, test each repo
- ⚠️ CI/CD pipeline reconfiguration
  - **Mitigation**: Create per-repo GitHub Actions, test before main_fks

### High Risk (Managed)
- ⚠️ Build artifacts in git (924 Rust files)
  - **Mitigation**: Add to .gitignore in split repos, exclude during filter-repo
- ⚠️ Large file count (4,481 files)
  - **Mitigation**: Incremental split with validation gates

---

## Next Steps (Phase 7.1.2)

1. **Create FILE_MAPPING.json**: Detailed file-to-repo mapping with glob patterns
2. **Create GitHub Repositories**: 8 new repos under nuniesmith organization
3. **Document Split Strategy**: MULTI_REPO_ARCHITECTURE.md with:
   - Repository structure templates
   - Docker multi-stage builds (CPU/GPU/ARM64)
   - GitHub Actions workflows
   - K8s manifest updates
   - Helm chart integration
4. **Validate Mapping**: Review with checklist before split execution

---

## Appendix: Key Paths Reference

### Service Entry Points

```python
# fks_ai
/repo/ai/src/agents/          # Multi-agent system
/repo/ai/src/models/          # Forecasting models
/src/services/ai/src/sentiment/  # Sentiment analysis

# fks_api
/repo/api/src/routes/         # API routers
/repo/api/src/middleware/     # FastAPI middleware

# fks_app
/repo/app/src/tasks/asmbtr_prediction.py  # ASMBTR Celery task
/repo/app/src/strategies/     # Trading strategies

# fks_data
/repo/data/src/adapters/      # Exchange adapters
/repo/data/src/sources/       # Data sources (CCXT, Polygon)

# fks_execution
/src/services/execution/exchanges/  # CCXT manager
/src/services/execution/validation/ # Normalizer, validators

# fks_ninja
/repo/ninja/*.cs              # C# NinjaTrader files
/repo/ninja/*.csproj          # Build configuration

# fks_web
/repo/web/src/django/         # Django project
/repo/web/static/             # Static assets
/repo/web/templates/          # HTML templates
```

### Configuration Files

```yaml
# Docker
/docker/Dockerfile            # Multi-service builds
/docker-compose.yml           # Local development

# Kubernetes
/k8s/manifests/all-services.yaml      # All service deployments
/k8s/manifests/ingress-tailscale.yaml # TLS ingress

# Monitoring
/monitoring/prometheus/prometheus.yml      # Prometheus config
/monitoring/grafana/dashboards/*.json      # Grafana dashboards

# CI/CD
/.github/workflows/build-push-fks_api.yml  # Per-service builds
/.github/workflows/deploy-all.yml          # Master deployment
```

---

## Conclusion

Monorepo baseline successfully documented with:
- ✅ 4,481 files mapped across 8 target repositories
- ✅ 23MB git bundle backup with verified restoration
- ✅ git-filter-repo tool installed and tested
- ✅ Service boundaries clearly defined
- ✅ Shared code strategy documented

**Ready for Phase 7.1.2**: Repository mapping and split planning.
