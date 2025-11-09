# Next Steps - Phase 8.1 Testing

**Date**: November 2, 2025  
**Current Status**: Infrastructure 90% complete, ready for testing  
**Priority**: HIGH - Test deployment to validate infrastructure

---

## 🎯 Immediate Action (Next 2 Hours)

### Step 1: Start Local Kubernetes Cluster

```bash
# Install/start minikube
minikube start --cpus=6 --memory=16384 --disk-size=50g

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### Step 2: Deploy FKS Platform

```bash
# Navigate to project
cd /home/jordan/Documents/fks

# Deploy with one command
make k8s-dev

# This will:
# - Create fks-system namespace
# - Generate secrets
# - Install cert-manager
# - Deploy NGINX Ingress
# - Deploy all 8 services + databases
# - Verify deployment
```

### Step 3: Verify Deployment

```bash
# Watch pods start (should see 11+ pods)
watch kubectl get pods -n fks-system

# Check all resources
kubectl get all -n fks-system

# Verify health
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &
curl http://localhost:8000/health/
```

**Expected Result**: All pods in Running state within 5 minutes

---

## 📋 Testing Sequence (Next 4-6 Hours)

Follow the comprehensive guide: **`k8s/TESTING.md`**

### Phase 1: Basic Deployment (30 min)
- [x] Cluster started
- [ ] All pods Running
- [ ] No errors in pod logs
- [ ] Services created correctly

### Phase 2: Health & Connectivity (30 min)
- [ ] Port-forward working
- [ ] Health endpoints responding
- [ ] Service-to-service communication
- [ ] Database connections working

### Phase 3: Functional Testing (1 hour)
- [ ] Django migrations successful
- [ ] AI agent endpoints responding
- [ ] Signal generation working
- [ ] Application tests passing

### Phase 4: Performance Testing (1 hour)
- [ ] Install k6: `sudo apt-get install k6`
- [ ] Run load tests
- [ ] Verify p95 latency <500ms
- [ ] Check HPA scaling

### Phase 5: Resilience Testing (30 min)
- [ ] Delete pod, verify recovery <30s
- [ ] Network policy blocking test
- [ ] Graceful shutdown test

### Phase 6: Monitoring Testing (30 min)
- [ ] Prometheus targets all up
- [ ] Grafana dashboards loading
- [ ] Trigger test alert

### Phase 7: Security Testing (30 min)
- [ ] Verify non-root execution
- [ ] Network isolation working
- [ ] Secret encryption verified

### Phase 8: Backup Testing (30 min)
- [ ] Trigger manual backup
- [ ] Verify backup file created
- [ ] Test restore process

---

## 🐳 Docker Images (After Testing Passes)

### Build All Images

```bash
# Set your container registry
export DOCKER_REGISTRY=ghcr.io/nuniesmith

# Build all 9 service images
make docker-build-all

# Expected build time: 15-30 minutes
# Images will be tagged as:
# - fks-platform/fks-main:latest
# - fks-platform/fks-api:latest
# - fks-platform/fks-app:latest
# - fks-platform/fks-ai:latest (largest, ~10GB)
# - fks-platform/fks-data:latest
# - fks-platform/fks-execution:latest
# - fks-platform/fks-ninja:latest
# - fks-platform/fks-mt5:latest
# - fks-platform/fks-web:latest
```

### Push to Registry

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u nuniesmith --password-stdin

# Push all images
make docker-push-all

# Expected push time: 30-60 minutes
```

### Update Helm Values

```bash
# Edit k8s/charts/fks-platform/values.yaml
# Update image tags from 'latest' to specific versions
# Example: image: ghcr.io/nuniesmith/fks-main:v1.0.0
```

---

## 📝 Document Results

### Create Test Report

After completing all 8 testing phases:

```bash
# Create test results document
cat > docs/PHASE_8_1_TEST_RESULTS.md << 'EOF'
# Phase 8.1 Test Results

**Date**: $(date)
**Tester**: Jordan
**Environment**: Minikube local cluster

## Test Summary
- Phase 1 (Deployment): ✅/❌
- Phase 2 (Health): ✅/❌
- Phase 3 (Functional): ✅/❌
- Phase 4 (Performance): ✅/❌
- Phase 5 (Resilience): ✅/❌
- Phase 6 (Monitoring): ✅/❌
- Phase 7 (Security): ✅/❌
- Phase 8 (Backup): ✅/❌

## Issues Found
1. [Issue description]
2. [Issue description]

## Performance Metrics
- p95 API latency: XXX ms
- Error rate: X.XX%
- Pod recovery time: XX seconds

## Next Steps
- [Action items]
EOF
```

### Update Progress Tracker

```bash
# Mark Phase 8.1 as complete
# Update docs/PHASE_8_1_PROGRESS.md
# Set status to 100% complete
```

---

## 🚨 Common Issues & Quick Fixes

### Issue: Pods in ImagePullBackOff
```bash
# Cause: Docker images don't exist yet
# Fix: Build images first or use existing images
make docker-build-all
```

### Issue: Pods in CrashLoopBackOff
```bash
# Check logs for errors
kubectl logs -n fks-system <pod-name>

# Common causes:
# - Database connection issues
# - Missing environment variables
# - Configuration errors
```

### Issue: Insufficient resources
```bash
# Increase minikube resources
minikube delete
minikube start --cpus=8 --memory=24576 --disk-size=100g
```

### Issue: Can't access services
```bash
# Verify port-forward is running
ps aux | grep port-forward

# Restart port-forward
pkill -f port-forward
kubectl port-forward -n fks-system svc/fks-main 8000:8000 &
```

---

## 🎯 Success Criteria

Phase 8.1 is 100% complete when:

- [x] Infrastructure created (Helm charts, scripts, docs)
- [ ] **Local deployment successful**
- [ ] **All 8 testing phases passed**
- [ ] **Docker images built and pushed**
- [ ] Test results documented
- [ ] Issues (if any) documented and addressed

**Current**: 90% complete
**After testing**: 100% complete

---

## 📅 Timeline

**Today (Nov 2)**:
- 11:00 PM - Infrastructure complete ✅
- 11:30 PM - Testing begins ⏳

**Tomorrow (Nov 3)**:
- Morning: Complete local testing
- Afternoon: Build Docker images
- Evening: Document results, mark Phase 8.1 complete

**Next Week (Nov 4-8)**:
- Production preparation (sealed-secrets, SSL/TLS)
- Staging deployment
- Load testing
- Begin Phase 8.2

---

## 🔗 Quick Links

**Documentation**:
- Testing Guide: `k8s/TESTING.md`
- Quick Start: `k8s/QUICKSTART.md`
- Deployment Guide: `docs/K8S_DEPLOYMENT_GUIDE.md`
- Ready Guide: `PHASE_8_1_READY.md`

**Commands**:
```bash
# Deploy
make k8s-dev

# Test
make k8s-test

# Destroy
make k8s-destroy

# Build images
make docker-build-all

# Check status
kubectl get all -n fks-system
```

---

## 🚀 Start Now

**Single command to begin**:
```bash
minikube start --cpus=6 --memory=16384 --disk-size=50g && make k8s-dev
```

Then open `k8s/TESTING.md` and follow the 8-phase testing guide.

---

**Priority**: HIGH  
**Time Required**: 6-8 hours total  
**Complexity**: Medium  
**Blocker**: None - Ready to start immediately

**LET'S GO!** 🚀
