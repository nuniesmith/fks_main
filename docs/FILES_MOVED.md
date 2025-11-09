# Files Moved to repo/core/main

## Overview

All files created in the untracked `fks/` directory have been moved to `repo/core/main/` where they are properly tracked by git.

## File Organization

### Configuration Files
**Location**: `config/`

- `slos.json` - SLO definitions
- `service_registry.json` - Service registry
- `circuit_breakers.json` - Circuit breaker config
- `caching.json` - Caching configuration
- `performance_benchmarks.json` - Performance targets
- `oncall.json` - On-call rotation
- `toil_tracking.json` - Toil tracking
- `incident_management.json` - Incident management
- `tracing.yaml` - Distributed tracing config

### Documentation
**Location**: `docs/`

**Phase Documentation**:
- `ALL_PHASES_SUMMARY.md`
- `ALL_PHASES_COMPLETE.md`
- `PHASE3_CORE_IMPROVEMENTS.md`
- `PHASE4_SRE_INTEGRATION.md`
- `PHASE5_CHAOS_ENGINEERING.md`
- `PHASE1_GUIDE.md`

**Guides**:
- `AUTOMATION.md`
- `INCIDENT_RESPONSE.md`
- `PERFORMANCE_OPTIMIZATION.md`
- `SERVICE_DISCOVERY.md`
- `SLO_DEFINITIONS.md`
- `STANDARDIZATION_GUIDE.md`
- `STANDARDIZATION_COMPLETE.md`
- `VERIFICATION_FIXES.md`
- `SETUP_COMPLETE.md`
- `FKS_MAIN_SETUP.md`
- `FKS_MONITOR_SETUP.md`

**Templates**:
- `docs/templates/postmortem_template.md`
- `docs/runbooks/template.md`

**Phase 1 Assessment**:
- `docs/phase1_assessment/` (all files)

### Scripts
**Location**: `scripts/`

**Organized by phase**:
- `scripts/phase1/` - Phase 1 scripts
- `scripts/phase3/` - Phase 3 scripts
- `scripts/phase4/` - Phase 4 scripts

**Organized by purpose**:
- `scripts/standardization/` - Standardization scripts
- `scripts/fixes/` - Fix scripts
- `scripts/setup/` - Setup scripts
- `scripts/verification/` - Verification scripts
- `scripts/deployment/` - Deployment automation
- `scripts/migrations/` - Migration scripts
- `scripts/backup/` - Backup scripts

### Kubernetes Configurations
**Location**: `k8s/`

- `k8s/monitoring/` - SLO rules and dashboards
- `k8s/api-gateway/` - API gateway config

## Path Updates

All scripts have been updated to use paths relative to `repo/core/main`:
- `BASE_PATH` now points to `repo/` directory
- Scripts use `Path(__file__).parent.parent.parent` for relative paths

## Next Steps

1. **Review moved files**:
   ```bash
   cd repo/core/main
   git status
   ```

2. **Commit to git**:
   ```bash
   git add .
   git commit -m "Add microservices improvement plan files (Phases 1-5)"
   ```

3. **Update any remaining hardcoded paths** if needed

## Notes

- All files are now in the git-tracked `repo/core/main/` directory
- Scripts have been updated to use relative paths
- Configuration files are in `config/` directory
- Documentation is in `docs/` directory
- Scripts are organized by phase and purpose

---

**Moved**: 2025-11-08  
**Status**: ✅ Complete

