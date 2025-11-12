# Docker Image Size Optimization Guide

This guide documents optimizations applied to reduce Docker image sizes for FKS microservices, particularly for the larger services: `ai`, `analyze`, and `training`.

## Current Issues

1. **Training Service**: ~3-4GB due to PyTorch (torch, torchvision, torchaudio)
2. **AI Service**: ~1.5-2GB due to chromadb, sentence-transformers, langchain
3. **Analyze Service**: ~1.5-2GB due to chromadb, sentence-transformers, google-cloud-aiplatform

## Optimization Strategies Applied

### 1. Multi-Stage Builds
- ✅ Already implemented in all services
- Separates build dependencies from runtime dependencies
- Reduces final image size significantly

### 2. PyTorch CPU-Only Build (Training Service)
**Savings: ~2GB**

The training service can use CPU-only PyTorch if GPU isn't always needed:

```dockerfile
# Use CPU-only PyTorch (saves ~2GB)
RUN python -m pip install --user --no-warn-script-location --no-cache-dir \
    torch==2.8.0 \
    torchvision==0.23.0 \
    --index-url https://download.pytorch.org/whl/cpu
```

**To use GPU version**, set build arg:
```bash
docker build --build-arg USE_GPU=true -t fks_training:gpu .
```

### 3. Remove Unnecessary Files After Installation
**Savings: ~200-500MB per service**

Strip unnecessary files from installed packages:
- `__pycache__/` directories
- `*.pyc` and `*.pyo` files
- `tests/` and `test/` directories
- `docs/` and `doc/` directories
- `*.md`, `LICENSE*`, `CHANGELOG*` files
- `.dist-info` directories (after installation)

### 4. Remove Unused Packages
**Savings: ~200MB (training service)**

- Remove `torchaudio` if not used (saves ~200MB)
- Only install packages actually imported in code

### 5. Clean Up Package Caches
**Savings: ~100-300MB**

- Clear pip cache after installation
- Clear huggingface cache (sentence-transformers)
- Clear chromadb cache
- Clear google-cloud cache

### 6. Optimize Layer Caching
- Copy `requirements.txt` before source code
- Use BuildKit cache mounts for pip
- Combine RUN commands where possible

## Implementation

### Training Service (`repo/training/Dockerfile.optimized`)

**Key Changes:**
1. CPU-only PyTorch by default (use `USE_GPU=true` build arg for GPU)
2. Remove torchaudio if not needed
3. Strip all unnecessary files after installation
4. Better cleanup of build artifacts

**Usage:**
```bash
# CPU-only build (default, saves ~2GB)
docker build -f Dockerfile.optimized -t fks_training:cpu .

# GPU build
docker build --build-arg USE_GPU=true -f Dockerfile.optimized -t fks_training:gpu .
```

**Expected Size Reduction:**
- Before: ~3-4GB
- After (CPU): ~1-1.5GB
- After (GPU): ~2.5-3GB

### AI Service (`repo/ai/Dockerfile.optimized`)

**Key Changes:**
1. Strip unnecessary files (tests, docs, __pycache__)
2. Clean up chromadb and huggingface caches
3. Remove documentation files

**Expected Size Reduction:**
- Before: ~1.5-2GB
- After: ~1-1.3GB

### Analyze Service (`repo/analyze/Dockerfile.optimized`)

**Key Changes:**
1. Strip unnecessary files (tests, docs, __pycache__)
2. Clean up chromadb, huggingface, and google-cloud caches
3. Remove documentation files

**Expected Size Reduction:**
- Before: ~1.5-2GB
- After: ~1-1.3GB

## Migration Steps

1. **Test the optimized Dockerfiles:**
   ```bash
   # Build and test each service
   cd repo/training && docker build -f Dockerfile.optimized -t fks_training:optimized .
   cd repo/ai && docker build -f Dockerfile.optimized -t fks_ai:optimized .
   cd repo/analyze && docker build -f Dockerfile.optimized -t fks_analyze:optimized .
   ```

2. **Verify functionality:**
   ```bash
   # Run and test each service
   docker run -p 8005:8005 fks_training:optimized
   docker run -p 8007:8007 fks_ai:optimized
   docker run -p 8008:8008 fks_analyze:optimized
   ```

3. **Compare sizes:**
   ```bash
   docker images | grep fks
   ```

4. **Replace original Dockerfiles:**
   ```bash
   # Backup originals
   mv repo/training/Dockerfile repo/training/Dockerfile.original
   mv repo/ai/Dockerfile repo/ai/Dockerfile.original
   mv repo/analyze/Dockerfile repo/analyze/Dockerfile.original
   
   # Use optimized versions
   mv repo/training/Dockerfile.optimized repo/training/Dockerfile
   mv repo/ai/Dockerfile.optimized repo/ai/Dockerfile
   mv repo/analyze/Dockerfile.optimized repo/analyze/Dockerfile
   ```

## Additional Optimizations (Future)

### 1. Use Alpine-based Images
- Can reduce base image size by ~100MB
- **Warning**: May cause issues with some Python packages (especially those with C extensions)

### 2. Use Distroless Images
- Minimal runtime images
- **Warning**: Harder to debug, may not work with all packages

### 3. Remove Unused Dependencies
- Audit `requirements.txt` files
- Only include packages actually imported in code
- Use `pipreqs` or similar tools to generate minimal requirements

### 4. Model File Optimization
- Download models at runtime instead of baking into image
- Use model caching volumes
- Only include models actually used

### 5. Use .dockerignore Effectively
- Already implemented, but review for completeness
- Exclude tests, docs, CI/CD files, etc.

## Monitoring Image Sizes

```bash
# Check current image sizes
docker images | grep -E "fks_(ai|analyze|training)" | awk '{print $1, $7}'

# Compare before/after
docker history fks_training:latest --format "{{.Size}}" | head -1
docker history fks_training:optimized --format "{{.Size}}" | head -1
```

## Notes

- **CPU-only PyTorch**: If you need GPU support, use the `USE_GPU=true` build arg
- **Model Files**: If models are downloaded at runtime, ensure proper caching
- **Testing**: Always test optimized images thoroughly before deploying
- **CI/CD**: Update GitHub Actions workflows to use optimized Dockerfiles

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Python Docker Optimization](https://pythonspeed.com/articles/docker-python-best-practices/)
- [PyTorch CPU Installation](https://pytorch.org/get-started/locally/)

