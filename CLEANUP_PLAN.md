# FKS Main Cleanup Plan

## Goal
Transform `fks_main` into a Rust-only orchestration service focused on platform and infrastructure control.

## Files to Move

### 1. Django/Python Code → `fks_web`
- `src/authentication/` → `services/web/src/authentication/` (merge with existing)
- `src/shared/framework/` → `services/web/src/shared/framework/`
- `src/shared/core/` → `services/web/src/shared/core/`
- `src/shared/monitor/` → `services/web/src/shared/monitor/`
- `src/manage.py` → `services/web/manage.py` (if not exists)
- `src/__init__.py` → Update to reflect Rust-only

### 2. Signal Service → `fks_portfolio`
- `assets/` → `services/portfolio/assets/`
- `src/services/signal_service.py` → `services/portfolio/src/services/signal_service.py`

### 3. Sentiment Analyzer → `fks_ai`
- `src/services/ai/src/sentiment/` → `services/ai/src/sentiment/`

### 4. Notebooks → `fks_training`
- `notebooks/` → `services/training/notebooks/`

### 5. Tests → `fks_web`
- `tests/` (Python/Django tests) → `services/web/tests/`
- Keep Rust tests (`test_main.rs`, `integration_test.rs`)

## Files to Delete

### Python Dependencies
- `requirements.txt` (keep only Rust)
- `requirements.gpu.txt`
- `requirements.root.txt`
- `pytest.ini` (if Python-only)

### Python Static Files
- `src/staticfiles/` (Django admin static files - not needed for Rust)

### Other
- `src/services/` (Python services - move or delete)
- `src/entrypoint.sh` (if Python-specific)

## Files to Keep

### Rust Code
- `src/main.rs`
- `src/config.rs`
- `src/k8s.rs`
- `src/monitor.rs`
- `src/runsh.rs`
- `src/web_ui.rs` (new)
- `src/static/index.html` (new)
- `src/test_main.rs`
- `Cargo.toml`
- `Cargo.lock`

### Infrastructure
- `docker/` (Dockerfile, entrypoint.sh)
- `docker/k8s/` (K8s manifests - main controls infra)
- `k8s/` (K8s configs)
- `monitoring/` (Prometheus/Grafana configs)

### Scripts
- `run.sh` (if still needed)
- `Makefile` (update for Rust-only)
- Shell scripts for K8s management

### Documentation
- `README.md` (update)
- `docs/` (update or move)

## Execution Order

1. ✅ Create simple web UI for Rust app
2. Move shared framework to fks_web
3. Move signal service to portfolio
4. Move sentiment analyzer to ai
5. Move notebooks to training
6. Move tests to fks_web
7. Delete Python files
8. Update README and docs
9. Update Dockerfile (already Rust-only)
10. Update Makefile
