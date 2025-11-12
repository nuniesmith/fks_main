# Docker Optimization Quick Reference

## Quick Build Commands

### Build All Optimized Images

**Linux/WSL:**
```bash
cd repo/scripts/docker
./build-optimized.sh
```

**With Shared Base (Faster):**
```bash
./build-optimized.sh shared
```

**Windows PowerShell:**
```powershell
cd repo\scripts\docker
.\build-optimized.ps1
.\build-optimized.ps1 shared
```

### Build Individual Services

```bash
# Training (CPU-only, saves ~2GB)
cd repo/training
docker build -f Dockerfile.optimized -t fks_training:optimized .

# Training (GPU version)
docker build --build-arg USE_GPU=true -f Dockerfile.optimized -t fks_training:gpu .

# Training (with shared base - faster)
docker build -f Dockerfile.optimized-shared -t fks_training:optimized .

# AI
cd repo/ai
docker build -f Dockerfile.optimized -t fks_ai:optimized .

# AI (with shared base - faster)
docker build -f Dockerfile.optimized-shared -t fks_ai:optimized .

# Analyze
cd repo/analyze
docker build -f Dockerfile.optimized -t fks_analyze:optimized .
```

### Build Shared Base Image

```bash
cd repo/docker-base
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
docker push nuniesmith/fks:builder-base  # Optional: push to registry
```

## Image Sizes

| Service | Optimized Size | Notes |
|---------|---------------|-------|
| Training | **1.12GB** | CPU-only PyTorch |
| AI | 12.1GB | ML dependencies are large |
| Analyze | 12.2GB | ML dependencies are large |
| Builder Base | 1.11GB | Shared base with TA-Lib |

## Testing

### Test Individual Service
```bash
# Training
docker run -p 8005:8005 fks_training:optimized

# AI
docker run -p 8007:8007 fks_ai:optimized

# Analyze
docker run -p 8008:8008 fks_analyze:optimized
```

### Test All Services
```bash
cd repo/scripts/docker
./test-services.sh
```

### Compare Sizes
```bash
cd repo/scripts/docker
./compare-sizes.sh
```

## Dockerfile Locations

### Optimized (Standalone)
- `repo/training/Dockerfile.optimized`
- `repo/ai/Dockerfile.optimized`
- `repo/analyze/Dockerfile.optimized`

### Optimized (Shared Base)
- `repo/training/Dockerfile.optimized-shared`
- `repo/ai/Dockerfile.optimized-shared`

### Shared Base
- `repo/docker-base/Dockerfile.builder`

## Key Optimizations Applied

1. ✅ **CPU-only PyTorch** (Training) - Saves ~2GB
2. ✅ **File Stripping** - Removes tests, docs, __pycache__
3. ✅ **Cache Cleanup** - Clears pip, huggingface, chromadb caches
4. ✅ **Shared Base** - TA-Lib pre-compiled, saves ~2-3 min per build

## Build Time Comparison

| Service | Standalone | With Shared Base | Time Saved |
|---------|-----------|------------------|------------|
| Training | ~5-6 min | ~3-4 min | ~2-3 min |
| AI | ~5-6 min | ~3-4 min | ~2-3 min |
| Analyze | ~5-6 min | ~5-6 min | 0 min* |

*Analyze doesn't use TA-Lib, so no time saved

## CI/CD Usage

### Pull Base Image First
```yaml
- name: Pull builder base
  run: docker pull nuniesmith/fks:builder-base || echo "Base not found"
```

### Build with Shared Base
```yaml
- name: Build training service
  run: |
    cd repo/training
    docker build -f Dockerfile.optimized-shared -t fks_training:optimized .
```

## Troubleshooting

### Base Image Not Found
```bash
# Build it locally
cd repo/docker-base
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
```

### Image Too Large
- Check if using CPU-only PyTorch (Training)
- Verify file stripping is working
- Consider using shared base for faster rebuilds

### Build Fails
- Check Docker BuildKit is enabled: `export DOCKER_BUILDKIT=1`
- Verify all dependencies are available
- Check Docker logs for specific errors

## Documentation

- **Full Guide**: `repo/DOCKER_OPTIMIZATION_GUIDE.md`
- **Shared Base**: `repo/DOCKER_SHARED_BASE_GUIDE.md`
- **Summary**: `repo/DOCKER_OPTIMIZATION_SUMMARY.md`
- **Results**: `repo/DOCKER_BUILD_RESULTS.md`

