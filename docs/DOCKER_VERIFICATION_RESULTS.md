# Docker Service Verification Results

## Summary

**Date**: 2025-11-08  
**Total Services**: 10  
**Passing**: 3  
**Failing**: 7

## ✅ Passing Services

1. **fks_api** (core/api) - Port 8001
   - ✅ Dockerfile found
   - ✅ Build successful
   - ✅ Container starts
   - ✅ Health endpoint working
   - ⚠️  /ready and /live endpoints not available

2. **fks_app** (core/app) - Port 8002
   - ✅ Dockerfile found
   - ✅ Build successful
   - ✅ Container starts
   - ✅ Health endpoint working
   - ⚠️  /ready and /live endpoints not available

3. **fks_ai** (gpu/ai) - Port 8007
   - ✅ Dockerfile found
   - ✅ Build successful
   - ✅ Container starts
   - ✅ Health endpoint working
   - ⚠️  /ready and /live endpoints not available

## ❌ Failing Services

### 1. fks_data (core/data) - Port 8003
**Issue**: `uvicorn` module not found
```
/usr/local/bin/python: No module named uvicorn
```
**Fix Needed**: 
- Check if `uvicorn` is in `requirements.txt`
- Or use `python -m uvicorn` instead of just `uvicorn` in entrypoint.sh

### 2. fks_web (core/web) - Port 8000
**Issue**: Import error
```
ERROR: Error loading ASGI app. Could not import module "src.main".
```
**Fix Needed**: 
- Check import path in entrypoint.sh or Dockerfile
- Verify Python path configuration

### 3. fks_training (gpu/training) - Port 8004
**Issue**: Port mismatch - service running on 8005, but we're testing 8004
```
Starting training service on port 8005
```
**Fix Needed**: 
- Update service to use port 8004, or
- Update test script to use port 8005

### 4. fks_analyze (tools/analyze) - Port 8008
**Issue**: Placeholder entrypoint
```
fks_analyze container started. Replace this with the actual application command.
```
**Fix Needed**: 
- Update entrypoint.sh or Dockerfile CMD to run the actual application

### 5. fks_monitor (tools/monitor) - Port 8009
**Issue**: Circular import
```
ImportError: cannot import name 'get_health_collector' from partially initialized module 'src.main'
```
**Fix Needed**: 
- Fix circular import in `src/api/routes/services.py`
- Refactor to break the circular dependency

### 6. fks_execution (core/execution) - Port 8006 (Rust)
**Issue**: Router state type mismatch
```
error: mismatched types
expected unit type `()`
found struct `Arc<AppState>`
```
**Fix Needed**: 
- Fix router state handling in `src/main.rs`
- Ensure all merged routers have compatible state types

### 7. fks_main (core/main) - Port 8010 (Rust)
**Issue**: Rust edition2024 not supported
```
feature `edition2024` is required
The package requires the Cargo feature called `edition2024`, but that feature is not stabilized
```
**Fix Needed**: 
- Change `Cargo.toml` edition from "2024" to "2021"
- Or update Dockerfile to use newer Rust version

## Next Steps

1. Fix fks_data - Add uvicorn to requirements or fix entrypoint
2. Fix fks_web - Fix import path
3. Fix fks_training - Fix port configuration
4. Fix fks_analyze - Add proper entrypoint
5. Fix fks_monitor - Fix circular import
6. Fix fks_execution - Fix router state types
7. Fix fks_main - Change Rust edition to 2021

---

**Script Location**: `repo/core/main/scripts/verify_single_service.sh`  
**Usage**: `./verify_single_service.sh <path> <name> <port> <type>`

