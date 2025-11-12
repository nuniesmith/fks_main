# FKS Shared Docker Base Image Guide

## Overview

To speed up builds and reduce duplication, we've created a shared builder base image that contains common build dependencies used by multiple services.

## What's in the Base Image?

- ✅ **TA-Lib C library** (pre-compiled) - saves ~2-3 minutes per service build
- ✅ **Common build tools** (gcc, g++, make, cmake, autotools, etc.)
- ✅ **Python build dependencies** (pip, setuptools, wheel)
- ✅ **Scientific libraries** (OpenBLAS, LAPACK for numpy/scipy)

## Quick Start

### 1. Build the Base Image

**Linux/WSL:**
```bash
cd repo/docker-base
./build-base.sh
```

**Windows PowerShell:**
```powershell
cd repo/docker-base
.\build-base.ps1
```

**Or manually:**
```bash
cd repo/docker-base
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
```

### 2. Push to Registry (Optional)

```bash
docker push nuniesmith/fks:builder-base
```

### 3. Use in Services

Update your service Dockerfiles to use the shared base:

**Before:**
```dockerfile
FROM python:3.12-slim AS builder

# Install build dependencies...
# Compile TA-Lib... (takes 2-3 minutes)
```

**After:**
```dockerfile
FROM nuniesmith/fks:builder-base AS builder

# TA-Lib is already installed! Just install Python packages
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-warn-script-location --no-cache-dir -r requirements.txt
```

## Available Optimized Dockerfiles

We've created optimized Dockerfiles that use the shared base:

### Training Service
- `Dockerfile.optimized` - Standalone (includes TA-Lib build)
- `Dockerfile.optimized-shared` - Uses shared base (faster)

### AI Service
- `Dockerfile.optimized` - Standalone (includes TA-Lib build)
- `Dockerfile.optimized-shared` - Uses shared base (faster)

### Analyze Service
- `Dockerfile.optimized` - Standalone (no TA-Lib needed)

## Building Services with Shared Base

### Option 1: Pull Base First (Recommended for CI/CD)

```bash
# Pull the base image (or build locally if not available)
docker pull nuniesmith/fks:builder-base || \
  docker build -t nuniesmith/fks:builder-base -f repo/docker-base/Dockerfile.builder repo/docker-base

# Build service using shared base
cd repo/training
docker build -f Dockerfile.optimized-shared -t fks_training:optimized .
```

### Option 2: Build Base Locally First

```bash
# Build base image
cd repo/docker-base
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .

# Build services
cd ../training
docker build -f Dockerfile.optimized-shared -t fks_training:optimized .

cd ../ai
docker build -f Dockerfile.optimized-shared -t fks_ai:optimized .
```

## Benefits

1. **Faster Builds**: 
   - TA-Lib compilation (~2-3 minutes) happens once, not per service
   - Build tools are pre-installed
   - Total time saved: ~5-10 minutes for all services

2. **Smaller Total Size**:
   - Shared layers reduce total image size
   - Base image can be reused across multiple services

3. **Easier Maintenance**:
   - Update TA-Lib version in one place
   - Consistent build environment across services

4. **CI/CD Optimization**:
   - Build base image once, use many times
   - Cache base image in registry

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Base Image

on:
  push:
    branches: [main]
    paths:
      - 'repo/docker-base/**'

jobs:
  build-base:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      
      - name: Build and push base image
        run: |
          cd repo/docker-base
          docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
          docker push nuniesmith/fks:builder-base
```

### Service Builds (After Base is Available)

```yaml
- name: Pull builder base
  run: docker pull nuniesmith/fks:builder-base || echo "Base not found, will build locally"

- name: Build training service
  run: |
    cd repo/training
    docker build -f Dockerfile.optimized-shared -t fks_training:optimized .
```

## Versioning

Tag the base image with versions for stability:

```bash
# Tag with version
docker tag nuniesmith/fks:builder-base nuniesmith/fks:builder-base-v1.0.0
docker push nuniesmith/fks:builder-base-v1.0.0

# Use specific version in services
FROM nuniesmith/fks:builder-base-v1.0.0 AS builder
```

## Troubleshooting

### Base Image Not Found

If you get an error that the base image doesn't exist:

1. **Build it locally:**
   ```bash
   cd repo/docker-base
   docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
   ```

2. **Or pull from registry:**
   ```bash
   docker pull nuniesmith/fks:builder-base
   ```

### TA-Lib Not Found at Runtime

Make sure to copy TA-Lib libraries from the builder stage:

```dockerfile
# In runtime stage
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/
```

## Future Enhancements

- **Python Base**: Pre-install common Python packages (numpy, pandas, etc.)
- **GPU Base**: CUDA-enabled base for training service
- **Node Base**: For services that need Node.js
- **Rust Base**: For Rust services (fks_main, fks_auth, etc.)

## Files Created

- `repo/docker-base/Dockerfile.builder` - Base image definition
- `repo/docker-base/README.md` - Detailed documentation
- `repo/docker-base/build-base.sh` - Linux/WSL build script
- `repo/docker-base/build-base.ps1` - Windows PowerShell build script
- `repo/ai/Dockerfile.optimized-shared` - AI service using shared base
- `repo/training/Dockerfile.optimized-shared` - Training service using shared base

