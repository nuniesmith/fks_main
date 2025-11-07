# Action Items from Weekly Health Report (Nov 6, 2025)

## 🔴 CRITICAL Priority - Week 1 (Nov 6-13)

### 1. Restore Test Suite (Priority: P0)
**Issue**: Test pass rate dropped from 100% to 41.2% (14/34 passing)

**Actions**:
- [ ] Install Django and all project dependencies
- [ ] Fix `src/services/data/src/domain/processing/layers/preprocessing.py` (empty file but imported!)
- [ ] Investigate and document all 20 failing tests
- [ ] Create GitHub issue: "Fix test suite regression"

**Timeline**: 1-2 days  
**Owner**: Dev Team  
**Blocker**: Django not installed, broken imports

---

### 2. Eliminate Legacy Imports (Priority: P0)
**Issue**: 13 files reverted to legacy import patterns (was 0 in Phase 1)

**Files to Fix**:

*shared_python imports (10 files):*
1. src/services/api/sitecustomize.py
2. src/services/data/scripts/test_shared_integration.py
3. src/services/data/src/bars.py
4. src/services/data/src/tests/test_adapter_retries.py
5. src/services/data/src/tests/test_shared_import.py
6. src/services/data/src/tests/test_logging_json_adapter.py
7. src/services/data/src/tests/test_adapters_errors.py
8. src/services/data/src/adapters/polygon.py
9. src/services/data/src/adapters/binance.py
10. src/services/data/src/adapters/base.py

*config_module imports (3 files):*
1. src/services/api/src/app.py
2. src/framework/config/constants.py
3. (1 additional - identify)

**Actions**:
- [ ] Migrate all imports to framework-based patterns
- [ ] Add pre-commit hook to prevent future legacy imports
- [ ] Update CI/CD to fail on legacy import patterns
- [ ] Create GitHub issue: "Resolve legacy import regression"

**Timeline**: 1 day  
**Owner**: Dev Team  
**Validation**: `python3 scripts/analyze_project.py` shows 0 legacy imports

---

## 🟡 HIGH Priority - Week 2 (Nov 13-20)

### 3. Code Audit and Documentation (Priority: P1)
**Issue**: Codebase grew 224% (436 → 1,413 files) without corresponding QA

**Questions to Answer**:
- What was added in the 977 new files?
- Are they all necessary?
- Do they follow architectural patterns?
- Are there duplicates?

**Actions**:
- [ ] Review file additions since Oct 28
- [ ] Document purpose and architecture changes
- [ ] Identify redundant/unnecessary files
- [ ] Ensure new code has adequate test coverage
- [ ] Create GitHub issue: "Code audit and consolidation"

**Timeline**: 2-3 days  
**Owner**: Tech Lead

---

### 4. Technical Debt Reduction (Priority: P1)
**Issue**: Debt markers increased 146% (89 → 219)

**Breakdown**:
- legacy: 122 markers
- stub: 55 markers
- TODO: 38 markers

**Actions**:
- [ ] Categorize debt by priority
- [ ] Create technical debt reduction roadmap
- [ ] Implement or remove stub code
- [ ] Address high-priority TODOs
- [ ] Create GitHub issue: "Technical debt reduction sprint"

**Timeline**: 2 weeks (20% per sprint)  
**Target**: Reduce to <150 markers in Week 2

---

### 5. Implement Quality Gates (Priority: P1)
**Issue**: Lack of automated quality controls allowed regressions

**Actions**:
- [ ] Add pre-commit hooks (legacy import detection, linting)
- [ ] Update CI/CD to enforce quality standards
- [ ] Require code reviews for all PRs
- [ ] Add automated test coverage reporting
- [ ] Create GitHub issue: "Implement quality gates"

**Timeline**: 1 week  
**Owner**: DevOps

---

## 🟢 MEDIUM Priority - Ongoing

### 6. Improve Test Coverage (Priority: P2)
**Issue**: Test-to-code ratio dropped 83%

**Current**: 58 test files for 775 Python files (7.5%)  
**Target**: 60% code coverage minimum

**Actions**:
- [ ] Add tests for new code
- [ ] Identify critical paths needing coverage
- [ ] Set up coverage reporting in CI/CD
- [ ] Create GitHub issue: "Improve test coverage"

**Timeline**: Ongoing, 2-3 weeks initial push

---

### 7. Validate Service Status (Priority: P2)
**Issue**: Unknown operational status post-regression

**Actions**:
- [ ] Verify all 16 services operational
- [ ] Document any service failures
- [ ] Update health dashboard with actual status
- [ ] Create GitHub issue: "Validate service operational status"

**Timeline**: 3-5 hours

---

## Recovery Milestones

### Week 1 Target (Nov 13)
- ✅ Test pass rate: 100% (34/34)
- ✅ Legacy imports: 0
- ✅ preprocessing.py: Fixed
- ✅ Health Score: 60/100

### Week 2 Target (Nov 20)
- ✅ Tech debt: <155 markers
- ✅ Quality gates: Implemented
- ✅ Services: All validated
- ✅ Health Score: 75/100

### Week 3 Target (Nov 27)
- ✅ Code coverage: 60%+
- ✅ Code audit: Complete
- ✅ Documentation: Updated
- ✅ Health Score: 85/100

### Week 4 Target (Dec 4)
- ✅ Health Score: 90/100
- ✅ Resume AI Enhancement work
- ✅ All quality gates passing

---

## GitHub Issues to Create

1. **P0**: Fix test suite regression (14/34 passing)
2. **P0**: Resolve legacy import issues (13 files)
3. **P1**: Code audit and consolidation (977 new files)
4. **P1**: Technical debt reduction sprint (219 markers)
5. **P1**: Implement quality gates (CI/CD, hooks)
6. **P2**: Improve test coverage (target 60%)
7. **P2**: Validate service operational status

---

## References

- **Detailed Report**: `/docs/operations/WEEKLY_HEALTH_REPORT_2025_11_06.md`
- **Health Dashboard**: `/docs/PROJECT_HEALTH_DASHBOARD.md`
- **Metrics**: `/metrics.json`
- **Analysis Script**: `python3 scripts/analyze_project.py --summary`

---

**Generated**: November 6, 2025  
**Status**: 🔴 CRITICAL - Immediate action required  
**Health Score**: 35/100 (target: 85/100)
