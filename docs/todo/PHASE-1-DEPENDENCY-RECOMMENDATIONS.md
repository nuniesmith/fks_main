# Phase 1.3: Dependency Audit - Recommendations

**Date**: 2025-01-15  
**Status**: Analysis Complete  
**Conflicts Found**: 57 packages, 11 high severity

---

## 📊 Summary

- **Total Packages**: 139
- **Conflicting Packages**: 57
- **High Severity Conflicts**: 11
- **Services Analyzed**: 13

---

## 🔴 High Severity Conflicts (Priority Fix)

### 1. FastAPI
**Services**: execution, data, ai, portfolio, api, app, analyze, main, monitor  
**Versions**: `>=0.121.1`, `>=0.104.0`, `>=0.115.0`, `==0.104.1`, `any`

**Recommendation**: Standardize on `fastapi>=0.115.0` (latest stable)
- Update all services to use `fastapi>=0.115.0`
- Remove pinned version `==0.104.1` in favor of minimum version

### 2. NumPy
**Services**: data, training, ai, portfolio, api, app, web, main  
**Versions**: `>=1.24.0`, `>=1.23.5,<2.0.0`, `>=1.26.0,<2.0`, `>=1.26.0`

**Recommendation**: Use `numpy>=1.26.0,<2.0.0` (consistent upper bound)
- NumPy 2.0 has breaking changes
- Most services already use `<2.0.0` constraint

### 3. Pandas
**Services**: data, training, ai, portfolio, app, web, main  
**Versions**: `>=2.2.0`, `==2.3.2`, `>=2.0.0`

**Recommendation**: Use `pandas>=2.2.0` (remove pinned version)
- Data service has `==2.3.2` - should use `>=2.2.0` for flexibility
- Ensure Python 3.11+ requirement is met

### 4. Redis
**Services**: web, analyze, main, app  
**Versions**: `>=5.2.0`, `>=5.0.0,<8.0.0`, `>=5.2.0,<5.3.0`, `>=5.0.0`

**Recommendation**: Use `redis>=5.2.0,<6.0.0` (consistent range)
- Main service has tight constraint `>=5.2.0,<5.3.0` for Celery compatibility
- Standardize on `>=5.2.0,<6.0.0` for all services

### 5. Celery
**Services**: web, app, main, api  
**Versions**: `[redis]>=5.5.3`, `>=5.3.0`, `[redis]>=5.3.0`, `>=5.5.3`

**Recommendation**: Use `celery[redis]>=5.5.3` (latest with redis extras)
- Most services already use 5.5.3
- Ensure redis extras are included consistently

### 6. Django REST Framework
**Services**: web, main  
**Versions**: `>=3.15.2`, `>=3.16.1`

**Recommendation**: Use `djangorestframework>=3.16.1` (latest)
- Minor version difference, easy to align

### 7. Django CORS Headers
**Services**: web, main  
**Versions**: `>=4.7.0`, `>=4.9.0`

**Recommendation**: Use `django-cors-headers>=4.9.0` (latest)

### 8. PyTorch
**Services**: web, main, training  
**Versions**: `>=2.4.0`, `==2.8.0`, `>=2.0.0`

**Recommendation**: Use `torch>=2.4.0` (remove pinned version)
- Training service has `==2.8.0` - should use `>=2.4.0` for flexibility
- Consider GPU vs CPU variants

### 9. Torchvision
**Services**: main, training  
**Versions**: `==0.23.0`, `>=0.19.0`

**Recommendation**: Use `torchvision>=0.19.0` (remove pinned version)
- Align with PyTorch version

### 10. pytest-django
**Services**: web, main  
**Versions**: `>=4.7.0`, `>=4.9.0`

**Recommendation**: Use `pytest-django>=4.9.0` (latest)

### 11. django-axes
**Services**: web, main  
**Versions**: `>=7.0.0`, `>=8.0.0`

**Recommendation**: Use `django-axes>=8.0.0` (latest)

---

## 🟡 Medium Priority Conflicts

### LangChain Ecosystem
- **langchain**: `>=0.3.0,<0.4.0` vs `>=0.3.0`
- **langchain-community**: Same pattern
- **Recommendation**: Use `>=0.3.0,<0.4.0` (more restrictive) for stability

### Uvicorn
- Multiple versions with `[standard]` extras
- **Recommendation**: Standardize on `uvicorn[standard]>=0.32.0`

### Pydantic
- Multiple version ranges
- **Recommendation**: Use `pydantic>=2.5.0` (consistent minimum)

---

## 📝 Action Plan

### Step 1: Create Unified Requirements Template
Create `repo/main/config/python/requirements-base.txt` with standardized versions for:
- FastAPI
- NumPy/Pandas
- Redis/Celery
- Django ecosystem
- PyTorch

### Step 2: Update Service Requirements
For each service:
1. Import base requirements
2. Add service-specific dependencies
3. Ensure version compatibility

### Step 3: Test Integration
- Run tests across all services
- Verify no breaking changes
- Check for runtime conflicts

### Step 4: Lock Versions (Optional)
Consider using:
- `pip-tools` for Python
- `poetry` for services using pyproject.toml
- `Cargo.lock` for Rust services (already in use)

---

## 🔧 Implementation Script

A script to automatically update requirements files is recommended:

```python
# phase1_fix_dependencies.py
# - Reads DEPENDENCY_AUDIT.json
# - Updates requirements.txt files with standardized versions
# - Creates backup before changes
```

---

## ⚠️ Notes

1. **Breaking Changes**: Some version updates may introduce breaking changes
   - Test thoroughly before deploying
   - Consider gradual rollout

2. **GPU vs CPU**: PyTorch has different variants
   - Ensure consistent variant across services
   - Document GPU requirements clearly

3. **Python Version**: Some packages require Python 3.11+
   - Verify Python version compatibility
   - Update Dockerfiles if needed

4. **Rust Dependencies**: Cargo.toml files need separate review
   - Rust ecosystem is more stable
   - Conflicts less likely but should be checked

---

## 📊 Expected Impact

- **Stability**: Reduced runtime conflicts
- **Maintainability**: Easier dependency management
- **Security**: Latest versions with security patches
- **Risk**: Low (most are minor version updates)

---

**Next Action**: Create unified requirements template and update service files.

