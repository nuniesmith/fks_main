# Service Fixes Needed - Summary

**Date**: 2025-11-12  
**Status**: In Progress

---

## Quick Fixes (Config/Env Vars) - Can Fix Now

### ✅ 1. celery-beat - Database Migrations
**Issue**: `relation "django_celery_beat_crontabschedule" does not exist`  
**Fix**: Add init container to run migrations before starting celery-beat  
**Status**: ⏳ Need to add init container

### ⏳ 2. flower - Environment Variable Issue
**Issue**: `ValueError: invalid literal for int() with base 10: 'tcp://10.108.117.157:5555'`  
**Fix**: Flower is reading service discovery env vars. Need to explicitly set broker URL  
**Status**: ⏳ Tried adding `--broker` flag, still failing. Need to check env vars

---

## Docker Image Fixes (Need Rebuild)

### 3. fks-ai - Missing uvicorn
**Issue**: `exec: uvicorn: not found`  
**Fix**: Add uvicorn to requirements.txt and rebuild image  
**Action**: Update `repo/ai/requirements.txt`, commit, push, wait for GitHub Actions build

### 4. fks-analyze - Missing uvicorn
**Issue**: `No module named uvicorn`  
**Fix**: Add uvicorn to requirements.txt and rebuild image  
**Action**: Update `repo/analyze/requirements.txt`, commit, push, wait for GitHub Actions build

### 5. fks-training - Missing flask
**Issue**: `ModuleNotFoundError: No module named 'flask'`  
**Fix**: Add flask to requirements.txt and rebuild image  
**Action**: Update `repo/training/requirements.txt`, commit, push, wait for GitHub Actions build

---

## Code Fixes (Need Code Changes)

### 6. fks-meta - Rust Router Error
**Issue**: `Path segments must not start with :`  
**Fix**: Fix router path configuration in Rust code  
**Location**: `repo/meta/src/main.rs` line 55  
**Action**: Fix router path syntax

### 7. fks-monitor - Circular Import
**Issue**: `ImportError: cannot import name 'get_test_collector'`  
**Fix**: Fix circular import in Python code  
**Location**: `repo/monitor/src/api/routes/tests.py` line 8  
**Action**: Refactor import structure

---

## Investigation Needed

### 8. fks-main
**Status**: Logs are empty, need to check deployment config

### 9. fks-execution
**Status**: Logs are empty, need to check deployment config

### 10. tailscale-connector
**Status**: Need to check logs and config

---

## Recommended Fix Order

1. **Quick fixes first** (celery-beat, flower) - Can fix immediately
2. **Docker image fixes** (fks-ai, fks-analyze, fks-training) - Need rebuilds
3. **Code fixes** (fks-meta, fks-monitor) - Need code changes
4. **Investigation** (fks-main, fks-execution, tailscale-connector)

---

## Next Steps

1. Fix celery-beat init container
2. Fix flower environment variable issue
3. Update requirements.txt files for Docker image fixes
4. Fix code issues in fks-meta and fks-monitor
5. Investigate remaining services

