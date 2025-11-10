# FKS Platform - Load Testing Guide

**Date**: 2025-01-XX  
**Purpose**: Guide for load testing FKS Platform services  
**Status**: Ready for Use

---

## 🎯 Load Testing Overview

Load testing helps verify that the FKS Platform can handle expected traffic and identify performance bottlenecks before production deployment.

---

## 🛠️ Load Testing Tools

### 1. Custom Load Testing Script

**Location**: `repo/main/scripts/load_test.py`

**Features**:
- Concurrent request testing
- Response time statistics
- Success rate tracking
- Error reporting
- Percentile calculations (P95, P99)

### 2. Apache Bench (ab)

**Installation**:
```bash
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd  # macOS
```

**Usage**:
```bash
# Test bot endpoint
ab -n 1000 -c 10 -p request.json -T application/json \
   http://localhost:8001/ai/bots/consensus

# Test RAG endpoint
ab -n 500 -c 5 -p request.json -T application/json \
   http://localhost:8004/api/v1/rag/query
```

### 3. Locust

**Installation**:
```bash
pip install locust
```

**Usage**:
```bash
locust -f locustfile.py --host=http://localhost:8001
```

---

## 🚀 Using the Load Testing Script

### Basic Usage

```bash
# Test bot consensus endpoint
python repo/main/scripts/load_test.py \
  --service ai \
  --endpoint /ai/bots/consensus \
  --concurrent 10 \
  --requests 100

# Test RAG query endpoint
python repo/main/scripts/load_test.py \
  --service analyze \
  --endpoint /api/v1/rag/query \
  --concurrent 5 \
  --requests 50

# Test with custom URL
python repo/main/scripts/load_test.py \
  --service ai \
  --endpoint /ai/bots/consensus \
  --base-url https://staging.fks-platform.com \
  --concurrent 20 \
  --requests 500
```

### Test Scenarios

#### 1. Light Load (Development)
```bash
# 10 concurrent, 100 requests
python load_test.py --service ai --endpoint /ai/bots/consensus \
  --concurrent 10 --requests 100
```

#### 2. Medium Load (Staging)
```bash
# 50 concurrent, 1000 requests
python load_test.py --service ai --endpoint /ai/bots/consensus \
  --concurrent 50 --requests 1000
```

#### 3. Heavy Load (Production Simulation)
```bash
# 100 concurrent, 5000 requests
python load_test.py --service ai --endpoint /ai/bots/consensus \
  --concurrent 100 --requests 5000
```

#### 4. Stress Test
```bash
# 200 concurrent, 10000 requests
python load_test.py --service ai --endpoint /ai/bots/consensus \
  --concurrent 200 --requests 10000
```

---

## 📊 Performance Targets

### Response Time Targets

| Endpoint | Target | Acceptable | Poor |
|----------|--------|------------|------|
| `/ai/bots/health` | <50ms | <100ms | >200ms |
| `/ai/bots/consensus` | <200ms | <500ms | >1000ms |
| `/api/v1/rag/query` | <2s | <5s | >10s |
| `/api/v1/rag/health` | <50ms | <100ms | >200ms |

### Throughput Targets

| Service | Target RPS | Acceptable RPS |
|---------|------------|----------------|
| **fks_ai** | >100 | >50 |
| **fks_analyze** | >20 | >10 |
| **fks_training** | >10 | >5 |

### Success Rate Targets

- **Target**: >99%
- **Acceptable**: >95%
- **Poor**: <90%

---

## 📈 Load Testing Scenarios

### Scenario 1: Bot Signal Generation

**Endpoint**: `/ai/bots/consensus`

**Test**:
```bash
python load_test.py \
  --service ai \
  --endpoint /ai/bots/consensus \
  --concurrent 20 \
  --requests 500
```

**Expected Results**:
- Mean response time: <200ms
- P95 response time: <500ms
- Success rate: >99%
- Requests/second: >50

### Scenario 2: RAG Query

**Endpoint**: `/api/v1/rag/query`

**Test**:
```bash
python load_test.py \
  --service analyze \
  --endpoint /api/v1/rag/query \
  --concurrent 10 \
  --requests 200
```

**Expected Results**:
- Mean response time: <2s
- P95 response time: <5s
- Success rate: >95%
- Requests/second: >10

### Scenario 3: Health Checks

**Endpoint**: `/health` endpoints

**Test**:
```bash
python load_test.py \
  --service ai \
  --endpoint /ai/bots/health \
  --method GET \
  --concurrent 50 \
  --requests 1000
```

**Expected Results**:
- Mean response time: <50ms
- P95 response time: <100ms
- Success rate: >99.9%
- Requests/second: >200

---

## 🔍 Monitoring During Load Tests

### Resource Monitoring

```bash
# CPU and Memory
docker stats

# Or for Kubernetes
kubectl top pods -n fks-staging

# System resources
htop
```

### Application Logs

```bash
# Docker
docker-compose logs -f fks_ai

# Kubernetes
kubectl logs -f deployment/fks-ai -n fks-staging
```

### Metrics

- Response times
- Error rates
- Throughput (RPS)
- Resource usage (CPU, memory)
- Database connections
- Queue lengths

---

## 📊 Interpreting Results

### Good Performance
- ✅ Mean response time within targets
- ✅ P95 response time acceptable
- ✅ Success rate >99%
- ✅ No memory leaks
- ✅ Stable resource usage

### Performance Issues
- ⚠️ High response times
- ⚠️ Increasing response times over time
- ⚠️ High error rates
- ⚠️ Memory leaks
- ⚠️ Resource exhaustion

### Action Items
1. **High Response Times**: Optimize code, add caching
2. **High Error Rates**: Fix bugs, improve error handling
3. **Memory Leaks**: Fix memory management
4. **Resource Exhaustion**: Scale horizontally, optimize

---

## 🎯 Load Testing Checklist

### Pre-Testing
- [ ] Services deployed and healthy
- [ ] Monitoring configured
- [ ] Test data prepared
- [ ] Baseline metrics recorded

### Testing
- [ ] Light load test completed
- [ ] Medium load test completed
- [ ] Heavy load test completed
- [ ] Stress test completed
- [ ] Results documented

### Post-Testing
- [ ] Results analyzed
- [ ] Issues identified
- [ ] Optimizations planned
- [ ] Performance targets verified

---

## 📝 Example Load Test Results

### Bot Consensus Endpoint

```
Load Test Results
============================================================
Endpoint: /ai/bots/consensus
Method: POST
Total Requests: 1000
Concurrent: 50
Total Time: 18.45s
Requests/Second: 54.20
Success Rate: 99.80%
Success: 998, Errors: 2

Response Times:
  Min: 45.23ms
  Max: 892.15ms
  Mean: 185.67ms
  Median: 165.32ms
  P95: 425.89ms
  P99: 678.12ms
============================================================
```

### Analysis
- ✅ Mean response time (185ms) < target (200ms)
- ✅ P95 (425ms) < acceptable (500ms)
- ✅ Success rate (99.8%) > target (99%)
- ✅ Throughput (54 RPS) > target (50 RPS)

**Verdict**: ✅ **Performance Acceptable**

---

## 🔧 Performance Optimization

### If Response Times Are High

1. **Add Caching**:
   ```python
   from functools import lru_cache
   
   @lru_cache(maxsize=100)
   def expensive_operation(...):
       ...
   ```

2. **Optimize Database Queries**:
   - Add indexes
   - Use connection pooling
   - Optimize queries

3. **Use Async**:
   - Ensure async/await for I/O
   - Use async HTTP clients

4. **Scale Horizontally**:
   - Add more service instances
   - Use load balancing

### If Error Rates Are High

1. **Improve Error Handling**
2. **Add Retry Logic**
3. **Increase Timeouts**
4. **Fix Bugs**

### If Resource Usage Is High

1. **Optimize Code**
2. **Reduce Memory Usage**
3. **Scale Resources**
4. **Use Caching**

---

## 📋 Load Testing Report Template

```markdown
# Load Test Report - [Service] - [Date]

## Test Configuration
- Endpoint: [endpoint]
- Concurrent: [number]
- Total Requests: [number]
- Duration: [time]

## Results
- Requests/Second: [number]
- Success Rate: [percentage]
- Mean Response Time: [ms]
- P95 Response Time: [ms]
- P99 Response Time: [ms]

## Analysis
- Performance: [Good/Acceptable/Poor]
- Issues Found: [list]
- Recommendations: [list]
```

---

## 🎯 Next Steps

1. **Run Load Tests**: Execute load tests on staging
2. **Analyze Results**: Review performance metrics
3. **Optimize**: Address performance issues
4. **Re-test**: Verify improvements
5. **Document**: Update performance baselines

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for Load Testing

