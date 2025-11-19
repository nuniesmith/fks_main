# Portfolio Namespace Fix

**Date**: 2025-11-12  
**Issue**: `NoReverseMatch: 'portfolio' is not a registered namespace`  
**Status**: ✅ **FIXED**

---

## Problem

The Django template was trying to use `{% url 'portfolio:dashboard' %}` but the portfolio namespace wasn't registered in the main URL configuration.

**Error**:
```
NoReverseMatch at /
'portfolio' is not a registered namespace
```

**Location**: `/app/src/templates/base.html` line 92

---

## Root Cause

The portfolio URLs were included without specifying the namespace:

```python
# Before (incorrect)
path("portfolio/", include("portfolio.urls")),
```

Even though `portfolio/urls.py` has `app_name = "portfolio"`, Django requires the namespace to be explicitly specified when using `include()` with namespaces.

---

## Fix Applied

### 1. Updated URL Configuration

**File**: `repo/web/src/urls.py`

**Changed**:
```python
# After (correct)
path("portfolio/", include(("portfolio.urls", "portfolio"), namespace="portfolio")),
```

The `include()` function now receives a tuple `(urlconf_module, app_name)` and the `namespace` parameter.

### 2. Template Already Correct

The template was already using the correct namespace syntax:
```django
{% url 'portfolio:dashboard' %}
{% url 'portfolio:signals' %}
{% url 'portfolio:performance' %}
```

---

## Files Changed

1. ✅ `repo/web/src/urls.py` - Added namespace to portfolio URL include
2. ✅ Committed and pushed to trigger GitHub Actions build

---

## Next Steps

1. **Wait for GitHub Actions build** (5-10 minutes)
2. **Update deployment**:
   ```bash
   kubectl rollout restart deployment/fks-web -n fks-trading
   ```

---

## Verification

After deployment, the home page should load without the `NoReverseMatch` error, and the Portfolio dropdown menu should work correctly.

---

**✅ Fix committed and pushed. Waiting for Docker build to complete.**

