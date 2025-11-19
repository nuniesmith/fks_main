# Docker Image Optimization - Size Reduction

**Date**: 2025-11-12  
**Issue**: GitHub Actions failing with "No space left on device" when exporting/pushing large images  
**Solution**: ✅ **Optimized Dockerfiles to use base images directly**

---

## Problem

The multi-stage builds were creating huge final images:
- **fks-ai**: Copying all ML packages (4.31 GB) into slim Python image
- **fks-analyze**: Copying all ML packages (4.31 GB) into slim Python image  
- **fks-training**: Copying all GPU packages (5.95 GB) into slim Python image

This caused GitHub Actions runners to run out of disk space during the export/push phase.

---

## Solution

Changed from multi-stage builds to **direct base image usage**:

### Before (Multi-Stage - Large Final Image)
```dockerfile
FROM nuniesmith/fks:docker-ml AS builder
# Install packages...

FROM python:3.12-slim
# Copy all packages from builder (4.31 GB!)
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
```

### After (Direct Base - Smaller Final Image)
```dockerfile
FROM nuniesmith/fks:docker-ml-latest
# Base image already has all ML packages
# Just install service-specific packages
RUN pip install -r requirements.txt
```

---

## Benefits

1. **Smaller final images**: Use base image directly instead of copying everything
2. **Faster builds**: No need to copy large package directories
3. **Less disk usage**: Base image layers are reused, not duplicated
4. **Faster pushes**: Smaller images push faster to Docker Hub

---

## Changes Made

### ✅ fks-ai
- **Before**: Multi-stage build copying 4.31 GB of packages
- **After**: Direct use of `nuniesmith/fks:docker-ml-latest`
- **Files**: `Dockerfile` optimized, `Dockerfile.old` saved

### ✅ fks-analyze
- **Before**: Multi-stage build copying 4.31 GB of packages
- **After**: Direct use of `nuniesmith/fks:docker-ml-latest`
- **Files**: `Dockerfile` optimized, `Dockerfile.old` saved

### ✅ fks-training
- **Before**: Multi-stage build copying 5.95 GB of packages
- **After**: Direct use of `nuniesmith/fks:docker-gpu`
- **Files**: `Dockerfile` optimized, `Dockerfile.old` saved

---

## Image Size Comparison

### Expected Results

**Before** (Multi-stage):
- fks-ai: ~5-6 GB (base + copied packages)
- fks-analyze: ~5-6 GB
- fks-training: ~7-8 GB

**After** (Direct base):
- fks-ai: ~4.5 GB (base image + service code)
- fks-analyze: ~4.5 GB
- fks-training: ~6 GB

**Savings**: ~1-2 GB per image, plus faster builds and pushes!

---

## Commits Made

1. **fks-ai**: `optimize: Use base image directly instead of multi-stage to reduce image size`
2. **fks-analyze**: `optimize: Use base image directly instead of multi-stage to reduce image size`
3. **fks-training**: `optimize: Use base image directly instead of multi-stage to reduce image size`

All changes have been **committed and pushed** to trigger GitHub Actions builds.

---

## Next Steps

1. **Wait for GitHub Actions builds** (should complete successfully now)
2. **Verify image sizes** on Docker Hub after builds
3. **Update deployments** to use new optimized images
4. **Monitor** for any runtime issues (should be none, base images are the same)

---

## Rollback

If needed, the old Dockerfiles are saved as `Dockerfile.old` in each service directory.

---

**✅ Optimization complete! Images should build and push successfully now.** 🚀

