# Visual Guide: FKS Code Duplication Problem 🎨

**Date**: November 7, 2025

---

## 🔴 Current State (PROBLEMATIC)

```
/home/jordan/Documents/code/fks/
│
├── src/
│   ├── core/                    ← Duplicate 1 (20 files)
│   │   ├── admin.py
│   │   ├── cache/
│   │   ├── database/
│   │   └── ...
│   │
│   ├── framework/               ← Duplicate 1 (64 files, 794 KB)
│   │   ├── cache/
│   │   ├── config/
│   │   ├── middleware/
│   │   └── ...
│   │
│   ├── monitor/                 ← Duplicate 1 (8 files)
│   │   ├── health/
│   │   └── metrics/
│   │
│   └── shared/                  ⚠️ DUPLICATION STARTS HERE
│       ├── core/                ← Duplicate 2 (40 files)
│       │   ├── admin.py        (same as above)
│       │   ├── cache/          (same as above)
│       │   ├── database/       (same as above)
│       │   └── core/           ← 🚨 NESTED DUPLICATE 3! (21 files)
│       │       ├── admin.py    (AGAIN!)
│       │       ├── cache/      (AGAIN!)
│       │       └── ...         (AGAIN!)
│       │
│       ├── framework/           ← Duplicate 2 (64 files, 794 KB)
│       │   (100% identical to src/framework)
│       │
│       └── monitor/             ← Duplicate 2 (8 files)
│           (100% identical to src/monitor)
│
└── repo/                        ⚠️ MORE DUPLICATION IN SERVICES
    ├── api/
    │   └── src/framework/       ← Duplicate 3 (64 files, 794 KB)
    │
    └── data/
        └── src/framework/       ← Duplicate 4 (64 files, 794 KB)
```

### Problem Summary
| Module | Locations | Total Waste |
|--------|-----------|-------------|
| `core` | 3x (src/, shared/, shared/core/) | ~300 KB |
| `framework` | 4x (src/, shared/, api/, data/) | ~2.4 MB |
| `monitor` | 2x (src/, shared/) | ~50 KB |
| **TOTAL** | **9 duplicate locations** | **~2.75 MB** |

---

## 🟢 Future State (CLEAN)

### After Phase 1 Cleanup
```
/home/jordan/Documents/code/fks/
│
├── src/
│   ├── shared/                  ✅ ONLY LOCATION
│   │   ├── core/               (No nested core/!)
│   │   ├── framework/
│   │   └── monitor/
│   │
│   └── authentication/          (Django app, stays here)
│
└── repo/                        (Still has duplicates - fix in Phase 3)
    ├── api/
    └── data/
```

### After Phase 2 (Shared Package)
```
/home/jordan/Documents/code/fks/
│
├── shared/                      ✅ INSTALLABLE PACKAGE
│   ├── pyproject.toml
│   ├── README.md
│   ├── src/
│   │   └── fks_shared/         ← Import: from fks_shared.xxx
│   │       ├── framework/
│   │       ├── core/
│   │       └── monitor/
│   └── tests/
│
└── repo/                        (Still temporary)
```

### After Phase 3-5 (Service Extraction)
```
Main Platform Repo (github.com/nuniesmith/fks)
/home/jordan/Documents/code/fks/
│
├── README.md
├── docker-compose.yml           ← Orchestrates all services
├── k8s/                        ← K8s manifests for platform
├── monitoring/                 ← Prometheus, Grafana
├── scripts/                    ← Deployment automation
├── docs/                       ← Platform documentation
│
├── shared/                     ✅ Shared library (versioned)
│   ├── pyproject.toml
│   └── src/fks_shared/
│
└── services/                   ✅ Git submodules
    ├── fks-ai/                 → Submodule (separate repo)
    ├── fks-api/                → Submodule (separate repo)
    ├── fks-app/                → Submodule (separate repo)
    ├── fks-data/               → Submodule (separate repo)
    ├── fks-execution/          → Submodule (separate repo)
    ├── fks-ninja/              → Submodule (separate repo)
    └── fks-web/                → Submodule (separate repo)


Separate Service Repos (Independent)
────────────────────────────────────
github.com/nuniesmith/fks-api/
├── pyproject.toml              (Depends on fks-shared)
├── Dockerfile
├── src/fks_api/                ← Service-specific code only
├── tests/
└── docs/

github.com/nuniesmith/fks-data/
├── pyproject.toml              (Depends on fks-shared)
├── Dockerfile
├── src/fks_data/               ← Service-specific code only
├── tests/
└── docs/

... (same pattern for other services)
```

---

## 📊 Side-by-Side Comparison

### Import Patterns

| Current (Confusing) | After Phase 1 | After Phase 2 |
|---------------------|---------------|---------------|
| `from core.database import ...` | `from src.shared.core.database import ...` | `from fks_shared.core.database import ...` |
| `from framework.middleware import ...` | `from src.shared.framework.middleware import ...` | `from fks_shared.framework.middleware import ...` |
| `from monitor.health import ...` | `from src.shared.monitor.health import ...` | `from fks_shared.monitor.health import ...` |

### Deployment Flow

**Current (Monolith)**:
```
1. Build entire fks repo
2. Deploy everything together
3. Any change = full rebuild
```

**Future (Microservices)**:
```
1. Build only changed service
2. Deploy only that service
3. Other services unaffected
4. Rollback per service
```

---

## 🎯 The Migration Path

```
┌─────────────────┐
│  Current State  │  ← You are here
│  (Duplicates)   │
└────────┬────────┘
         │
         │ Phase 1: Clean Duplicates (30 min)
         ↓
┌─────────────────┐
│  src/shared/    │  ← Duplicates removed
│  (Clean)        │     Nested core/ fixed
└────────┬────────┘
         │
         │ Phase 2: Create Package (1 day)
         ↓
┌─────────────────┐
│  /shared/       │  ← Installable package
│  fks-shared     │     Can pip install
└────────┬────────┘
         │
         │ Phase 3-5: Extract Services (2 weeks)
         ↓
┌─────────────────┐
│  Microservices  │  ← Separate repos
│  + Main Repo    │     Git submodules
└─────────────────┘     Independent CI/CD
```

---

## 🔍 Visualization: How Duplication Happened

```
Initial State (Good)
════════════════════
/src/core/
/src/framework/
/src/monitor/


Phase 1.2.2 Cleanup (October 2025)
═══════════════════════════════════
Goal: Centralize shared code
Action: Copy to /src/shared/

/src/core/              ← Original
/src/framework/         ← Original
/src/monitor/           ← Original
/src/shared/            ← NEW
    ├── core/           ← Copy
    ├── framework/      ← Copy
    └── monitor/        ← Copy

Problem: Forgot to delete originals!


Nested Core Bug
════════════════
During copy operation:
$ cp -r src/core src/shared/core
$ cd src/shared/core
$ cp -r ../../../src/core ./core  ← OOPS! Created core/core/

Result:
/src/shared/core/       ← Correct location
/src/shared/core/core/  ← Accidental nesting


Service Extraction Attempts
════════════════════════════
Each service copied shared code:
/repo/api/src/framework/    ← Another copy
/repo/data/src/framework/   ← Another copy

Result: 4 copies of framework!
```

---

## 💡 Key Insights

### Why This Matters

1. **Maintenance Nightmare**
   - Fix bug in framework → Must fix in 4 places
   - Update config → Must update in 3 places
   - Add feature → Must add to multiple locations

2. **Import Confusion**
   - Which path is correct?
   - `from core.` vs `from src.shared.core.` vs `from framework.`
   - IDEs show duplicate symbols

3. **Testing Issues**
   - Are we testing the right version?
   - Coverage reports confusing
   - Integration tests unpredictable

4. **Deployment Risk**
   - Docker images may use different versions
   - Kubernetes deployments inconsistent
   - Hard to track which code is running

### The Fix

**Short-term (Phase 1)**:
- Delete duplicates
- Keep one canonical location (`src/shared/`)
- Update imports

**Long-term (Phase 2-5)**:
- Create installable package (`fks-shared`)
- Extract services to separate repos
- Use git submodules for composition

---

## ✅ Success Metrics

| Metric | Before | After Phase 1 | After Phase 5 |
|--------|--------|---------------|---------------|
| Duplicate locations | 9 | 2 | 0 |
| Framework copies | 4 | 2 | 0 |
| Wasted space | 2.75 MB | 1.6 MB | 0 |
| Import patterns | 3+ variants | 1 variant | 1 variant |
| Services in monolith | 7 | 7 | 0 |
| Independent repos | 1 | 1 | 8 |

---

## 🚀 Quick Actions

```bash
# 1. See the problem yourself
ls -la src/core src/shared/core src/shared/core/core
ls -la src/framework src/shared/framework

# 2. Run analysis
python3 scripts/analyze_duplication.py

# 3. Fix it
./scripts/cleanup_phase1.sh
```

---

**Visual Guide Complete!** 📊

Next: Read `/docs/MONOREPO_REVIEW_SUMMARY.md` for detailed analysis.
