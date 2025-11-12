# Phase 2: Demo Build - Getting Started

**Date**: 2025-01-15  
**Status**: Ready to Begin  
**Prerequisites**: Phase 1 Complete ✅

---

## 🎯 Phase 2 Objectives

Build a working manual trading demo with:
1. Stable data flow from multiple sources
2. Signal generation pipeline with AI enhancement
3. Interactive dashboard for signal viewing and approval

---

## ✅ Prerequisites Met

- ✅ All port conflicts resolved
- ✅ Service registry complete (14 services)
- ✅ Dependencies audited
- ✅ Health check tools ready

---

## 📋 Phase 2 Tasks

### Task 2.1: Stabilize Data Flow (20-25 hours)
**Objective**: Ensure reliable data ingestion from multiple sources

**Key Subtasks**:
- [ ] Configure fks_data adapters (Binance, Polygon, Yahoo)
- [ ] Enable Redis caching with TTL
- [ ] Implement webhook endpoints for real-time updates
- [ ] Add data quality validation
- [ ] Test with sample data

**Files to Work With**:
- `repo/data/src/adapters/` - Data source adapters
- `repo/data/src/api/routes/` - API endpoints
- `repo/data/docker-compose.yml` - Service configuration

---

### Task 2.2: Signal Generation Pipeline (20-25 hours)
**Objective**: Generate trading signals with AI enhancement

**Key Subtasks**:
- [ ] Integrate strategies in fks_app
- [ ] Connect to fks_ai for signal refinement
- [ ] Implement trade categories (Scalp, Swing, Long-term)
- [ ] Add position sizing logic (1-2% risk)
- [ ] Route signals to fks_portfolio for BTC optimization

**Files to Work With**:
- `repo/app/src/strategies/` - Trading strategies
- `repo/ai/src/agents/` - AI agents for signal refinement
- `repo/portfolio/src/signals/` - Signal generation

---

### Task 2.3: Dashboard Implementation (20-25 hours)
**Objective**: Create interactive web interface for signal viewing

**Key Subtasks**:
- [ ] Update fks_web templates with Chart.js
- [ ] Add signal approval buttons
- [ ] Link to simulated execution in fks_execution
- [ ] Implement real-time updates
- [ ] Add role-based views

**Files to Work With**:
- `repo/web/src/templates/portfolio/` - Dashboard templates
- `repo/web/src/views/portfolio.py` - View logic
- `repo/web/src/static/js/` - Frontend JavaScript

---

## 🚀 Quick Start

### 1. Start Core Services
```bash
# Start data service
cd repo/data && docker-compose up -d

# Start API service
cd repo/api && docker-compose up -d

# Start web service
cd repo/web && docker-compose up -d
```

### 2. Verify Services
```bash
# Run health check
python repo/main/scripts/phase1_verify_health.py

# Or manually check
curl http://localhost:8003/health  # fks_data
curl http://localhost:8001/health  # fks_api
curl http://localhost:8000/health  # fks_web
```

### 3. Test Data Flow
```bash
# Test data adapter
curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT

# Test signal generation
curl http://localhost:8002/api/v1/signals/generate
```

---

## 📊 Success Criteria

- [ ] Data ingestion working for 5+ assets
- [ ] Signals generated with all required fields
- [ ] Dashboard displays signals correctly
- [ ] Manual approval workflow functional
- [ ] End-to-end flow testable

---

## 🔗 Related Documentation

- [Phase 1 Complete Summary](./PHASE-1-FINAL-STATUS.md)
- [Portfolio Platform Master Plan](./00-PORTFOLIO-PLATFORM-MASTER-PLAN.md)
- [Phase 2 Data Integration](./02-PHASE-2-DATA-INTEGRATION.md)
- [Phase 3 Signal Generation](./03-PHASE-3-SIGNAL-GENERATION.md)

---

**Ready to begin Phase 2!** 🚀

