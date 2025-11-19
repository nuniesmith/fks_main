# Service Health Fix Plan

**Date**: 2025-11-12  
**Goal**: Get all Kubernetes services healthy

---

## Current Status

### ✅ Healthy Services
- fks-web
- fks-api
- fks-app
- fks-data
- fks-portfolio
- fks-ninja
- fks-auth
- PostgreSQL
- Redis

### ❌ Failing Services (Need Fix)
1. **fks-training** - CrashLoopBackOff
2. **fks-meta** - CrashLoopBackOff
3. **fks-monitor** - CrashLoopBackOff
4. **fks-main** - CrashLoopBackOff
5. **fks-ai** - CrashLoopBackOff
6. **fks-analyze** - CrashLoopBackOff
7. **fks-execution** - CrashLoopBackOff
8. **celery-beat** - CrashLoopBackOff
9. **flower** - CrashLoopBackOff
10. **tailscale-connector** - CrashLoopBackOff

---

## Fix Strategy

For each service, we'll:
1. Check pod logs to identify the error
2. Check deployment configuration
3. Fix the issue (missing dependencies, config errors, etc.)
4. Verify the service starts successfully
5. Move to next service

---

## Progress Tracker

- [ ] fks-training
- [ ] fks-meta
- [ ] fks-monitor
- [ ] fks-main
- [ ] fks-ai
- [ ] fks-analyze
- [ ] fks-execution
- [ ] celery-beat
- [ ] flower
- [ ] tailscale-connector

---

## Common Issues to Check

1. **Missing dependencies** (Python packages, etc.)
2. **Configuration errors** (env vars, secrets)
3. **Port conflicts**
4. **Volume mount issues**
5. **Resource limits**
6. **Health check failures**
7. **Database connection issues**

---

Let's start fixing them one by one!

