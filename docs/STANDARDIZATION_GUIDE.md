# FKS Repository Standardization Guide

**Purpose**: Ensure all FKS repositories follow consistent standards for README, Docker, tests, and structure.

## 🎯 Overview

This guide explains how to standardize all FKS repositories to ensure:
- ✅ Consistent README structure
- ✅ Standard Dockerfiles and docker-compose
- ✅ Test coverage across all repos
- ✅ Health endpoints in all services
- ✅ Static analysis configuration
- ✅ Proper dependency management

## 🚀 Quick Start

### Run Complete Standardization

```bash
# Standardize all repos
python3 scripts/standardize_all_repos.py

# Verify all services build
./scripts/verify_all_services.sh

# Or run both
./scripts/standardize_and_verify.sh
```

## 📋 Standard Requirements

### Required Files

Every FKS service must have:

1. **README.md**
   - Service description
   - Quick start guide
   - API endpoints
   - Configuration
   - Testing instructions

2. **Dockerfile**
   - Multi-stage build (if Rust)
   - Health checks
   - Non-root user
   - Proper port exposure

3. **requirements.txt** (Python) or **Cargo.toml** (Rust)
   - All dependencies listed
   - Version pinned

4. **.dockerignore**
   - Excludes unnecessary files
   - Optimizes build context

### Optional but Recommended

- `docker-compose.yml` - For local development
- `pytest.ini` or test configuration
- `ruff.toml` or linter config
- `.env.example` - Example environment variables

### Required Directories

- `src/` - Source code
- `tests/` - Test files

### Required Endpoints

All web services must have:
- `GET /health` - Health check
- `GET /ready` - Readiness probe
- `GET /live` - Liveness probe

## 🔧 Standardization Process

### Step 1: Run Standardization Script

```bash
python3 scripts/standardize_all_repos.py
```

This will:
- Check all repos for required files
- Create missing READMEs, Dockerfiles, etc.
- Add test structures
- Create static analysis configs

### Step 2: Review Generated Report

```bash
cat standardization_report.md
```

Review what was created and what still needs manual fixes.

### Step 3: Verify Services Build

```bash
./scripts/verify_all_services.sh
```

This verifies:
- Dockerfiles build successfully
- docker-compose.yml is valid
- Tests exist and can run

### Step 4: Manual Fixes

Some things require manual attention:
- Custom service-specific configuration
- Complex test setups
- Service-specific documentation

## 📊 Standard Structure

### Python Service

```
service_name/
├── README.md
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── .dockerignore
├── ruff.toml
├── pytest.ini
├── .env.example
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── core/
│   │   └── config.py
│   └── api/
│       └── routes/
└── tests/
    ├── __init__.py
    └── test_health.py
```

### Rust Service

```
service_name/
├── README.md
├── Dockerfile
├── docker-compose.yml
├── Cargo.toml
├── Cargo.lock
├── .dockerignore
├── src/
│   ├── main.rs
│   ├── config.rs
│   └── routes.rs
└── tests/
    └── integration_test.rs
```

## 🎯 Standard README Template

Every README should include:

1. **Service Name & Description**
2. **Quick Start** (Development & Docker)
3. **API Endpoints** (if applicable)
4. **Configuration** (Environment variables)
5. **Testing** (How to run tests)
6. **Documentation** (Links to docs)

## 🐳 Standard Dockerfile

### Python Service

- Base: `python:3.12-slim`
- Health check: Python-based
- Non-root user
- Proper port exposure

### Rust Service

- Multi-stage build
- Base: `rust:1.75-slim` (builder), `debian:bookworm-slim` (runtime)
- Health check: curl-based
- Non-root user

## 🧪 Standard Test Structure

### Python

- `tests/` directory
- `test_health.py` with basic health endpoint tests
- `pytest.ini` configuration

### Rust

- `tests/` directory
- Integration tests in `tests/`
- Unit tests in `src/` modules

## ✅ Verification Checklist

After standardization, verify:

- [ ] All repos have README.md
- [ ] All repos have Dockerfile
- [ ] All repos have requirements.txt or Cargo.toml
- [ ] All repos have .dockerignore
- [ ] All services have health endpoints
- [ ] All services have test files
- [ ] All Dockerfiles build successfully
- [ ] All services start with docker-compose

## 🔄 Continuous Standardization

Run standardization regularly:

```bash
# Weekly check
python3 scripts/standardize_all_repos.py

# Before major releases
./scripts/standardize_and_verify.sh
```

## 📚 Related Documents

- [FKS Monitor Setup](FKS_MONITOR_SETUP.md)
- [FKS Main Setup](FKS_MAIN_SETUP.md)
- [Phase 1 Assessment](../docs/phase1_assessment/KEY_FINDINGS.md)

---

**Questions?** Check the standardization report or run the script to see what needs fixing.

