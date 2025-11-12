# GitHub Actions Workflows - Fix Summary

**Date**: 2025-01-15  
**Issues Fixed**: 2 workflow errors

---

## Issues Identified

### 1. Documentation Linting Workflow
**Error**: `Dependencies lock file is not found`  
**Cause**: Workflow tried to use npm cache without package-lock.json  
**Fix**: Removed `cache: 'npm'` from Node.js setup step

### 2. Build Documentation Site Workflow
**Error**: `cd: repo/main: No such file or directory`  
**Cause**: Workflow assumed monorepo structure, but `fks_main` is standalone  
**Fix**: Added conditional path detection for both monorepo and standalone structures

---

## Changes Made

### docs-lint.yml
- ✅ Removed npm cache requirement
- ✅ Added path detection for monorepo vs standalone
- ✅ Made markdownlint config optional

### docs-build.yml
- ✅ Added path detection for monorepo vs standalone
- ✅ Fixed site output directory paths
- ✅ Updated artifact upload paths

### docs-audit.yml
- ✅ Added path detection for monorepo vs standalone
- ✅ Fixed report file paths
- ✅ Updated artifact upload paths

---

## Testing

Workflows should now work for:
- ✅ Standalone `fks_main` repo (current structure)
- ✅ Monorepo structure (if repo is part of larger repo)

---

**Last Updated**: 2025-01-15

