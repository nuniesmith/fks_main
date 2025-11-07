# Operations Documentation

This directory contains operational documentation, health reports, and troubleshooting guides for the FKS Trading Platform.

## 📊 Health Monitoring

### Current Status
- **Latest Health Report**: [WEEKLY_HEALTH_REPORT_2025_11_06.md](WEEKLY_HEALTH_REPORT_2025_11_06.md)
- **Action Items**: [ACTION_ITEMS_2025_11_06.md](ACTION_ITEMS_2025_11_06.md)
- **Health Dashboard**: [../PROJECT_HEALTH_DASHBOARD.md](../PROJECT_HEALTH_DASHBOARD.md)

### Weekly Health Reports
Weekly automated health reports are generated to track:
- Test pass rates
- Code quality metrics
- Technical debt
- Service operational status
- Import issues
- File statistics

**Schedule**: Every Friday at 5pm UTC  
**Script**: `python3 scripts/analyze_project.py --summary`

## 🔧 Infrastructure

### Kubernetes
- **Cluster Status**: [K8S_STATUS_REPORT.md](K8S_STATUS_REPORT.md)
- **Cluster Health**: [CLUSTER_HEALTHY.md](CLUSTER_HEALTHY.md)

### Services
- **Nginx**: [NGINX_QUICKREF.md](NGINX_QUICKREF.md)
- **GitHub Secrets**: [GITHUB_SECRETS_QUICKREF.md](GITHUB_SECRETS_QUICKREF.md)

## 🚨 Troubleshooting
- **General Guide**: [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
- **Health Check Process**: [HEALTH_CHECK_REPORT.md](HEALTH_CHECK_REPORT.md)

## 📋 Quick Commands

```bash
# Run health analysis
python3 scripts/analyze_project.py --summary

# Update health dashboard
python3 scripts/update_dashboard.py

# Weekly update (includes git commit)
bash scripts/weekly_update.sh --commit

# Check K8s cluster
kubectl get pods --all-namespaces

# View service logs
kubectl logs -f <pod-name>
```

## 🔄 Weekly Review Checklist

1. **Friday 5pm - Generate Report**
   - [ ] Run `python3 scripts/analyze_project.py --summary`
   - [ ] Review metrics.json
   - [ ] Update PROJECT_HEALTH_DASHBOARD.md
   - [ ] Create weekly health report if needed

2. **Assess Status**
   - [ ] Test pass rate (target: 100%)
   - [ ] Legacy imports (target: 0)
   - [ ] Technical debt trend
   - [ ] Service operational status

3. **Create Action Items**
   - [ ] Identify critical issues
   - [ ] Create GitHub issues for P0/P1 items
   - [ ] Assign owners
   - [ ] Set timelines

4. **Plan Next Week**
   - [ ] Prioritize top 3-5 tasks
   - [ ] Update sprint goals
   - [ ] Communicate blockers

## 📈 Metrics Thresholds

### 🔴 CRITICAL (Immediate Action)
- Test pass rate < 80%
- Legacy imports > 5 files
- Security vulnerabilities > 0
- Services down > 2

### 🟡 WARNING (Plan Action)
- Test pass rate 80-95%
- Legacy imports 1-5 files
- Tech debt increase > 50%
- Code coverage < 60%

### 🟢 HEALTHY (Maintain)
- Test pass rate > 95%
- Legacy imports = 0
- Tech debt decreasing
- Code coverage > 80%

## 🎯 Current Focus (Nov 6, 2025)

**Status**: 🔴 CRITICAL - System Stabilization Required

**Immediate Priorities**:
1. Restore test suite (41.2% → 100%)
2. Eliminate legacy imports (13 → 0)
3. Fix broken preprocessing.py file
4. Implement quality gates

**Health Score**: 35/100 (target: 85/100)

See [ACTION_ITEMS_2025_11_06.md](ACTION_ITEMS_2025_11_06.md) for detailed action plan.

---

**Last Updated**: November 6, 2025  
**Next Review**: November 13, 2025
