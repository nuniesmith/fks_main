# Bitcoin Signal Demo - Action Plan
## Get Working Bitcoin Signals for Daily Manual Trading

**Date**: 2025-01-15  
**Status**: 🚀 **READY TO IMPLEMENT**  
**Goal**: Working Bitcoin signal generation demo for daily manual trading

---

## 🎯 Objective

Get a working demo that:
1. ✅ Generates Bitcoin (BTCUSDT) trading signals
2. ✅ Displays signals in dashboard
3. ✅ Allows manual approval/rejection
4. ✅ Works reliably for daily trading
5. ✅ Focuses on Bitcoin only (expand later)

---

## 📋 Current Status

### ✅ What's Already Working

1. **Signal Pipeline** (`repo/app/src/domain/trading/signals/pipeline.py`)
   - ✅ Multiple strategies (RSI, MACD, EMA, ASMBTR)
   - ✅ AI enhancement (optional)
   - ✅ Trade categorization (scalp, swing, long_term)
   - ✅ Position sizing (1-2% risk)

2. **API Endpoints** (`repo/app/src/api/routes/signals.py`)
   - ✅ `POST /api/v1/signals/generate` - Generate signal
   - ✅ `GET /api/v1/signals/latest/{symbol}` - Get latest signal
   - ✅ `GET /api/v1/signals/batch` - Batch signals

3. **Dashboard** (`repo/web/src/portfolio/views.py`)
   - ✅ Fetches signals from fks_app
   - ✅ Displays signals with approval buttons
   - ✅ Approval/rejection workflow

4. **Data Service** (`repo/data`)
   - ✅ Binance adapter
   - ✅ Price and OHLCV endpoints
   - ✅ Caching support

### ⚠️ What Needs Testing/Fixing

1. **Service Communication**
   - ⚠️ Verify fks_data is accessible
   - ⚠️ Verify fks_app can fetch data
   - ⚠️ Verify fks_web can fetch signals

2. **Signal Generation**
   - ⚠️ Test Bitcoin signal generation
   - ⚠️ Verify strategies work correctly
   - ⚠️ Verify AI enhancement (optional)

3. **Dashboard Display**
   - ⚠️ Test signal display
   - ⚠️ Verify approval workflow
   - ⚠️ Test error handling

4. **Manual Execution**
   - ⚠️ Test approval workflow
   - ⚠️ Verify execution integration (optional)
   - ⚠️ Test logging

---

## 🚀 Implementation Steps

### Step 1: Test Services (30 minutes)

**Objective**: Verify all services are running and accessible

**Tasks**:
1. Start all required services
   ```bash
   # Start data service
   cd repo/data && docker-compose up -d
   
   # Start app service
   cd repo/app && docker-compose up -d
   
   # Start web service
   cd repo/web && docker-compose up -d
   
   # Optional: Start AI service (for AI enhancement)
   cd repo/ai && docker-compose up -d
   ```

2. Verify service health
   ```bash
   # Check fks_data
   curl http://localhost:8003/health
   
   # Check fks_app
   curl http://localhost:8002/health
   
   # Check fks_web
   curl http://localhost:8000/health
   ```

3. Test data flow
   ```bash
   # Test Bitcoin price fetch
   curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"
   
   # Test OHLCV fetch
   curl "http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
   ```

**Success Criteria**:
- ✅ All services respond to health checks
- ✅ Bitcoin price data is accessible
- ✅ OHLCV data is available

---

### Step 2: Test Signal Generation (30 minutes)

**Objective**: Verify Bitcoin signal generation works

**Tasks**:
1. Test signal generation API
   ```bash
   # Generate Bitcoin signal (swing)
   curl -X POST "http://localhost:8002/api/v1/signals/generate" \
     -H "Content-Type: application/json" \
     -d '{
       "symbol": "BTCUSDT",
       "category": "swing",
       "use_ai": false
     }'
   
   # Get latest Bitcoin signal
   curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
   ```

2. Test different strategies
   ```bash
   # RSI strategy
   curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi"
   
   # MACD strategy
   curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd"
   
   # EMA strategy
   curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing"
   ```

3. Test AI enhancement (optional)
   ```bash
   # With AI enhancement
   curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=true"
   ```

**Success Criteria**:
- ✅ Signal generation returns valid signal
- ✅ Signal includes entry_price, take_profit, stop_loss
- ✅ Signal includes confidence and rationale
- ✅ Multiple strategies work

**Expected Response**:
```json
{
  "symbol": "BTCUSDT",
  "signal_type": "BUY",
  "category": "swing",
  "entry_price": 45000.0,
  "take_profit": 46350.0,
  "stop_loss": 44100.0,
  "position_size_pct": 0.015,
  "confidence": 0.75,
  "timestamp": "2025-01-15T10:30:00",
  "rationale": "RSI oversold, bullish signal",
  "ai_enhanced": false,
  "indicators": {
    "rsi": 28.5,
    "macd": 2.3
  }
}
```

---

### Step 3: Test Dashboard (30 minutes)

**Objective**: Verify dashboard displays Bitcoin signals

**Tasks**:
1. Access dashboard
   ```bash
   # Open in browser
   http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing
   ```

2. Test signal display
   - ✅ Verify Bitcoin signals are displayed
   - ✅ Verify signal details (entry, TP, SL)
   - ✅ Verify confidence and rationale
   - ✅ Verify approval/rejection buttons

3. Test approval workflow
   - ✅ Click "Approve" button
   - ✅ Verify signal is sent to execution
   - ✅ Verify confirmation message
   - ✅ Test rejection workflow

**Success Criteria**:
- ✅ Dashboard displays Bitcoin signals
- ✅ Signal details are correct
- ✅ Approval workflow works
- ✅ Error handling works

---

### Step 4: Create Daily Workflow (1 hour)

**Objective**: Create simple daily workflow for manual trading

**Tasks**:
1. Create daily workflow document
   - Morning routine (check signals)
   - Signal review process
   - Manual execution steps
   - Trade logging

2. Create quick reference guide
   - API endpoints
   - Dashboard URLs
   - Common commands

3. Create troubleshooting guide
   - Common issues
   - Solutions
   - Debugging tips

**Deliverables**:
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow guide
- `BITCOIN-QUICK-REFERENCE.md` - Quick reference
- `BITCOIN-TROUBLESHOOTING.md` - Troubleshooting guide

---

### Step 5: Fix Issues (As Needed)

**Objective**: Fix any issues found during testing

**Common Issues**:
1. **Service Communication**
   - Issue: Services can't communicate
   - Fix: Check Docker network, service URLs
   
2. **Data Fetching**
   - Issue: Can't fetch Bitcoin data
   - Fix: Check Binance API, adapter configuration
   
3. **Signal Generation**
   - Issue: No signals generated
   - Fix: Check strategy implementation, data quality
   
4. **Dashboard Display**
   - Issue: Signals not displayed
   - Fix: Check API calls, template rendering

---

## 📊 Testing Checklist

### Service Health
- [ ] fks_data service running
- [ ] fks_app service running
- [ ] fks_web service running
- [ ] fks_ai service running (optional)
- [ ] All services respond to health checks

### Data Flow
- [ ] Bitcoin price data accessible
- [ ] OHLCV data available
- [ ] Data caching working
- [ ] Error handling works

### Signal Generation
- [ ] Bitcoin signal generation works
- [ ] RSI strategy works
- [ ] MACD strategy works
- [ ] EMA strategy works
- [ ] Signal includes all required fields
- [ ] AI enhancement works (optional)

### Dashboard
- [ ] Dashboard displays signals
- [ ] Signal details are correct
- [ ] Approval workflow works
- [ ] Rejection workflow works
- [ ] Error messages displayed
- [ ] Loading states work

### Manual Execution
- [ ] Approval sends to execution
- [ ] Rejection logs correctly
- [ ] Confirmation messages work
- [ ] Trade logging works

---

## 🎯 Success Criteria

### Minimum Viable Demo
- ✅ Bitcoin signals generate successfully
- ✅ Dashboard displays signals
- ✅ Manual approval workflow works
- ✅ Daily workflow is documented

### Production Ready
- ✅ All services stable
- ✅ Error handling comprehensive
- ✅ Logging complete
- ✅ Performance acceptable
- ✅ Documentation complete

---

## 📝 Daily Workflow (Quick Start)

### Morning Routine (5 minutes)
1. Start services (if not running)
2. Open dashboard: `http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing`
3. Review Bitcoin signals
4. Check signal confidence and rationale

### Signal Review (5 minutes)
1. Review entry price, TP, SL
2. Check confidence level
3. Review rationale and indicators
4. Verify risk/reward ratio

### Manual Execution (5 minutes)
1. Click "Approve" for good signals
2. Click "Reject" for poor signals
3. Log trade decisions
4. Monitor execution (if integrated)

### End of Day (5 minutes)
1. Review trade performance
2. Update trade log
3. Review signal accuracy
4. Plan next day

**Total Time**: ~20 minutes per day

---

## 🔧 Quick Commands

### Start Services
```bash
# Start all services
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

### Generate Signal
```bash
# Generate Bitcoin signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing"
```

### Access Dashboard
```bash
# Open in browser
http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing
```

### Check Service Health
```bash
# Check all services
curl http://localhost:8003/health  # fks_data
curl http://localhost:8002/health  # fks_app
curl http://localhost:8000/health  # fks_web
```

---

## 📚 Next Steps

### Immediate (Today)
1. ✅ Test services
2. ✅ Test signal generation
3. ✅ Test dashboard
4. ✅ Create daily workflow

### Short-term (This Week)
1. Fix any issues found
2. Improve error handling
3. Add logging
4. Create documentation

### Medium-term (Next Week)
1. Add more strategies
2. Improve AI enhancement
3. Add performance tracking
4. Expand to other assets

---

## 🎉 Expected Results

After completing this plan, you should have:
- ✅ Working Bitcoin signal generation
- ✅ Functional dashboard for signal review
- ✅ Manual approval workflow
- ✅ Daily workflow documentation
- ✅ Ready for daily manual trading

---

## 📞 Support

If you encounter issues:
1. Check service logs
2. Review troubleshooting guide
3. Check API responses
4. Verify service health

---

**Status**: 🚀 **READY TO START**

**Next Action**: Start with Step 1 - Test Services

**Estimated Time**: 2-3 hours total

---

**Last Updated**: 2025-01-15

