# FKS Duplication Fix - Quick Reference Card 🎯

**Date**: November 7, 2025

---

## 🚨 The Problem (In 30 Seconds)

You have **TRIPLE DUPLICATION** of shared code:

```
/src/core            (20 files)  ← Original
/src/shared/core     (40 files)  ← Copy 1
/src/shared/core/core (21 files) ← Copy 2 (NESTED MISTAKE!)

/src/framework       (64 files)  ← Original  
/src/shared/framework (64 files) ← Exact copy

/src/monitor         (8 files)   ← Original
/src/shared/monitor  (8 files)   ← Exact copy
```

**Impact**: Bug fixes need 3 locations, imports are confusing, wasted space

---

## ✅ The Solution (3 Steps)

### Step 1: Back Up & Analyze (2 minutes)
```bash
cd /home/jordan/Documents/code/fks
python3 scripts/analyze_duplication.py
```

### Step 2: Run Cleanup Script (5 minutes)
```bash
./scripts/cleanup_phase1.sh
# Choose Option A (recommended)
```

**What it does**:
- ✅ Creates backup in `~/fks-backups/`
- ✅ Removes nested `src/shared/core/core/`
- ✅ Deletes `src/core`, `src/framework`, `src/monitor`
- ✅ Updates imports to use `src.shared.*`
- ✅ Runs tests automatically

### Step 3: Verify & Commit (3 minutes)
```bash
git status
git diff
git add .
git commit -m "refactor: Remove duplicate directories (Phase 1)"
```

---

## 🎯 Immediate Actions

| Priority | Action | Time | Command |
|----------|--------|------|---------|
| 🔴 HIGH | Back up | 1 min | `tar -czf ~/fks-backup.tar.gz src/` |
| 🔴 HIGH | Fix nested core | 1 min | `rm -rf src/shared/core/core/` |
| 🟡 MEDIUM | Remove duplicates | 5 min | `./scripts/cleanup_phase1.sh` |
| 🟢 LOW | Create shared pkg | 1 hour | See Phase 2 in refactor plan |

---

## 📁 Files Created for You

| File | Purpose | Use When |
|------|---------|----------|
| `/docs/MONOREPO_REFACTOR_PLAN.md` | Complete 7-phase plan | Planning full refactor |
| `/docs/MONOREPO_REVIEW_SUMMARY.md` | Detailed analysis | Understanding the problem |
| `/scripts/analyze_duplication.py` | Check for duplicates | Anytime you're unsure |
| `/scripts/cleanup_phase1.sh` | Automated cleanup | Ready to fix duplicates |
| `/docs/DUPLICATION_ANALYSIS.json` | Metrics & stats | Reporting/documentation |

---

## 🔄 Future Service Extraction (Later)

Current structure:
```
/repo/ai, /repo/api, etc.  ← Will become separate repos
```

Future structure:
```
github.com/nuniesmith/fks              ← Main orchestrator
github.com/nuniesmith/fks-shared       ← Shared library  
github.com/nuniesmith/fks-api          ← Service repo
github.com/nuniesmith/fks-data         ← Service repo
... (etc)
```

Main repo will use **git submodules** to include service repos:
```
/home/jordan/Documents/code/fks/
└── services/
    ├── fks-api/      (submodule)
    ├── fks-data/     (submodule)
    └── ...
```

**When to do this**: After fixing duplicates (Phase 1-2), then follow Phase 3-5

---

## ⚡ Emergency Commands

### Restore from Backup
```bash
cd /home/jordan/Documents/code/fks
tar -xzf ~/fks-backups/fks-src-backup-*.tar.gz
```

### Check What Changed
```bash
git status
git diff src/
```

### Rollback Cleanup
```bash
git restore src/
# Or restore from backup (above)
```

---

## 📞 Help & Resources

- **Full Plan**: `/docs/MONOREPO_REFACTOR_PLAN.md`
- **Analysis**: Run `python3 scripts/analyze_duplication.py`
- **Backup Location**: `~/fks-backups/`
- **K8s Status**: Run `kubectl get pods -n fks-trading`

---

## ✅ Success Checklist

After running cleanup:

- [ ] Backup created in `~/fks-backups/`
- [ ] No more nested `src/shared/core/core/`
- [ ] Only `src/shared/` exists (no root duplicates)
- [ ] Tests still pass
- [ ] Git diff looks reasonable
- [ ] Committed changes

---

**Ready?** Run: `./scripts/cleanup_phase1.sh`

**Questions?** Read: `/docs/MONOREPO_REVIEW_SUMMARY.md`
