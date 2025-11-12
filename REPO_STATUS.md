# FKS Repositories Status

## Repository Overview

### Service Repos (14)
These are repos that run as actual services:

1. **ai** - AI/ML Service (port 8007)
2. **analyze** - Codebase Analysis Service (port 8008)
3. **api** - API Gateway Service (port 8001)
4. **app** - Business Logic Service (port 8002)
5. **auth** - Authentication Service (port 8009)
6. **data** - Data Service (port 8003)
7. **execution** - Execution Engine Service (port 8004)
8. **main** - Main Orchestrator Service (port 8010)
9. **meta** - MetaTrader Bridge Service (port 8005)
10. **monitor** - Monitoring Service (port 8013)
11. **ninja** - NinjaTrader Bridge Service (port 8006)
12. **portfolio** - Portfolio Management Service (port 8012)
13. **training** - Training Service (port 8011)
14. **web** - Web Interface Service (port 3001/8000)

### Infrastructure Repos (1)
1. **docker** - Docker base images and build configurations

### Extracted Repos (4)
These were extracted from the main repo:

1. **docs** - Documentation (fks_docs on GitHub)
2. **scripts** - Scripts and automation (fks_scripts on GitHub)
3. **nginx** - Nginx configuration (fks_nginx on GitHub)
4. **config** - Configuration files (fks_config on GitHub)

## Total: 19 Repos

## Repository Naming

- **Local directories**: Use short names (e.g., `docs`, `scripts`, `nginx`, `config`)
- **GitHub repos**: Use prefixed names (e.g., `fks_docs`, `fks_scripts`, `fks_nginx`, `fks_config`)
- **Service repos**: Match GitHub names (e.g., `fks_ai` → local `ai`)

## run.sh Configuration

The `run.sh` script uses:
- **SERVICES array**: 14 service repos (for service-specific operations)
- **REPOS array**: 19 total repos (for git operations on all repos)

## Git Operations

When committing/pushing:
- **Option 5** in run.sh menu allows:
  - **Services only (s)**: Commit/push only the 14 service repos
  - **All repos (r)**: Commit/push all 19 repos (services + infrastructure + extracted)

## Notes

- Not all repos have Dockerfiles (docs, scripts, nginx, config don't)
- Not all repos have docker-compose.yml
- Only service repos trigger GitHub Actions for Docker builds
- Infrastructure and extracted repos are for organization and documentation

