# Service Issues Summary

**Date**: 2025-11-12

---

## Issues Identified

### 1. **fks-ai** ❌
**Error**: `exec: uvicorn: not found`  
**Cause**: Missing uvicorn in Docker image  
**Fix**: Need to rebuild image with uvicorn installed

### 2. **fks-analyze** ❌
**Error**: `No module named uvicorn`  
**Cause**: Missing uvicorn in Docker image  
**Fix**: Need to rebuild image with uvicorn installed

### 3. **fks-training** ❌
**Error**: `ModuleNotFoundError: No module named 'flask'`  
**Cause**: Missing flask dependency  
**Fix**: Need to add flask to requirements.txt and rebuild

### 4. **fks-meta** ❌
**Error**: `Path segments must not start with :` (Rust router error)  
**Cause**: Code issue in Rust router configuration  
**Fix**: Need to fix router path in Rust code

### 5. **fks-monitor** ❌
**Error**: `ImportError: cannot import name 'get_test_collector'` (circular import)  
**Cause**: Circular import in Python code  
**Fix**: Need to fix import structure

### 6. **celery-beat** ❌
**Error**: `relation "django_celery_beat_crontabschedule" does not exist`  
**Cause**: Database migrations not run  
**Fix**: Need to run Django migrations

### 7. **flower** ❌
**Error**: `ValueError: invalid literal for int() with base 10: 'tcp://10.108.117.157:5555'`  
**Cause**: Environment variable format issue (should be just port, not full URL)  
**Fix**: Fix environment variable configuration

### 8. **fks-main** ❌
**Status**: Need to check logs  
**Fix**: TBD

### 9. **fks-execution** ❌
**Status**: Need to check logs  
**Fix**: TBD

### 10. **tailscale-connector** ❌
**Status**: Need to check logs  
**Fix**: TBD

---

## Fix Priority

1. **Quick fixes** (config/env vars):
   - celery-beat (migrations)
   - flower (env var)

2. **Docker image fixes** (need rebuild):
   - fks-ai (uvicorn)
   - fks-analyze (uvicorn)
   - fks-training (flask)

3. **Code fixes** (need code changes):
   - fks-meta (Rust router)
   - fks-monitor (circular import)

4. **Investigation needed**:
   - fks-main
   - fks-execution
   - tailscale-connector

---

Let's start fixing them!

