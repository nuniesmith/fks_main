# FKS Service Standardization Guide

This document defines the standard structure, testing, and CI/CD patterns for all FKS microservices.

## 📁 Standard Directory Structure

All services should follow this structure:

```
repo/{service_name}/
├── src/                    # Source code
│   ├── main.rs or main.py  # Service entry point
│   ├── lib.rs or __init__.py
│   ├── api/                # HTTP endpoints (if applicable)
│   ├── models/             # Data models
│   ├── config/             # Configuration
│   └── {domain}/           # Domain-specific modules
├── tests/                   # Test files
│   ├── unit/               # Unit tests
│   └── integration/        # Integration tests
├── .github/
│   └── workflows/          # GitHub Actions
│       ├── tests.yml
│       └── docker-build-push.yml
├── Dockerfile              # Docker build file
├── docker-compose.yml      # Local development
├── entrypoint.sh           # Container entrypoint
├── requirements.txt        # Python dependencies (if Python)
├── Cargo.toml              # Rust dependencies (if Rust)
├── pytest.ini              # Pytest configuration (if Python)
├── ruff.toml               # Ruff linting config (if Python)
├── .dockerignore           # Docker ignore patterns
├── .gitignore              # Git ignore patterns
├── README.md               # Service documentation
└── LICENSE                 # License file
```

## 🧪 Testing Standards

### Python Services

**pytest.ini** (standard template):
```ini
[pytest]
addopts = -q -v
testpaths = tests
norecursedirs = .git .venv venv __pycache__ .pytest_cache
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

**conftest.py** (if needed):
```python
"""Pytest configuration and fixtures."""
import pytest
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
```

### Rust Services

**Cargo.toml** should include:
```toml
[dev-dependencies]
tokio-test = "0.4"
mockall = "0.13"
```

**Test organization**:
- Unit tests: In same file as code with `#[cfg(test)]`
- Integration tests: In `tests/` directory

## 🔄 GitHub Actions Workflows

### Standard Workflow Template

All services should have:

1. **tests.yml** - Runs tests, linting, type checking
2. **docker-build-push.yml** - Builds and pushes Docker images

### Python Service Workflow

```yaml
name: {Service Name} CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov ruff mypy
      - name: Lint
        run: ruff check src/
        continue-on-error: true
      - name: Type check
        run: mypy src/
        continue-on-error: true
      - name: Run tests
        run: pytest tests/ -v --cov=src --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          flags: {service_name}
```

### Rust Service Workflow

```yaml
name: {Service Name} CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Cache cargo
        uses: actions/cache@v4
        with:
          path: |
            ~/.cargo/bin/
            ~/.cargo/registry/
            target/
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
      - name: Format check
        run: cargo fmt --check
        continue-on-error: true
      - name: Clippy
        run: cargo clippy -- -D warnings
        continue-on-error: true
      - name: Run tests
        run: cargo test --verbose
      - name: Build
        run: cargo build --release
```

## 🐳 Docker Standards

### Python Service Dockerfile Template

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SERVICE_NAME={service_name} \
    SERVICE_PORT={port} \
    PYTHONPATH=/app/src:/app

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:{port}/health || exit 1

EXPOSE {port}

RUN useradd -u 1000 -m appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["./entrypoint.sh"]
```

### Rust Service Dockerfile Template

```dockerfile
FROM rust:1.75-slim as builder

WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
COPY src/ ./src/
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/{service_name} /app/{service_name}
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV SERVICE_NAME={service_name} \
    SERVICE_PORT={port} \
    RUST_LOG=info

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:{port}/health || exit 1

EXPOSE {port}

RUN useradd -u 1000 -m appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["./entrypoint.sh"]
```

### docker-compose.yml Template

```yaml
services:
  {service_name}:
    build:
      context: .
      dockerfile: Dockerfile
    image: nuniesmith/{service_name}:latest
    container_name: {service_name}
    ports:
      - "{port}:{port}"
    environment:
      - SERVICE_NAME={service_name}
      - SERVICE_PORT={port}
    networks:
      - fks-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{port}/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  fks-network:
    driver: bridge
```

## 📋 Service Port Assignments

| Service | Port | Language |
|---------|------|----------|
| fks_api | 8001 | Python |
| fks_web | 8000 | Python (Django) |
| fks_data | 8003 | Python |
| fks_execution | 8004 | Rust |
| fks_meta | 8005 | Rust |
| fks_ai | 8002 | Python |
| fks_monitor | 8006 | Python |
| fks_analyze | 8007 | Python |
| fks_app | 8008 | Python |
| fks_training | 8009 | Python |

## ✅ Checklist for New Services

- [ ] Create standard directory structure
- [ ] Add `src/main.rs` or `src/main.py` with health endpoint
- [ ] Create `tests/` directory with unit and integration tests
- [ ] Add `pytest.ini` (Python) or test configuration (Rust)
- [ ] Create `Dockerfile` following template
- [ ] Create `docker-compose.yml` following template
- [ ] Create `entrypoint.sh` script
- [ ] Add `.github/workflows/tests.yml`
- [ ] Add `.github/workflows/docker-build-push.yml`
- [ ] Add `.dockerignore` and `.gitignore`
- [ ] Create `README.md` with service documentation
- [ ] Add `LICENSE` file
- [ ] Configure service port in environment variables
- [ ] Implement health check endpoint (`/health`)
- [ ] Add metrics endpoint (`/metrics`) if applicable

## 🔍 Code Quality Standards

### Python
- Use `ruff` for linting (config in `ruff.toml`)
- Use `mypy` for type checking (config in `mypy.ini` or `pyproject.toml`)
- Minimum 60% test coverage
- Follow PEP 8 style guide

### Rust
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- All public functions should have doc comments
- Use `#[derive(Debug)]` on all public types

## 📚 Documentation Requirements

Each service README should include:
- Service overview and purpose
- Architecture diagram
- API endpoints (if applicable)
- Configuration options
- Development setup
- Testing instructions
- Deployment guide

