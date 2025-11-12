# Bitcoin Signal Demo - Quick Start Guide
## Get Bitcoin Signals Working in 30 Minutes

**Date**: 2025-01-15  
**Status**: 🚀 **READY TO USE**  
**Goal**: Get working Bitcoin signals for daily manual trading

---

## 🎯 What You'll Get

- ✅ Bitcoin signal generation
- ✅ Dashboard for signal review
- ✅ Manual approval workflow
- ✅ Ready for daily trading

---

## 🚀 Quick Start (30 Minutes)

### Step 1: Start Services (5 minutes)

**Option A: Using Script (Recommended)**
```bash
# Linux/Mac
./repo/main/scripts/start-bitcoin-demo.sh

# Windows (PowerShell)
cd repo/main/scripts
.\start-bitcoin-demo.sh
```

**Option B: Manual Start**
```bash
# Create Docker network first (if not exists)
docker network create fks-network

# Start data service
cd repo/data && docker-compose up -d

# Start app service (signal generation)
cd repo/app && docker-compose up -d

# Start web service (dashboard)
cd repo/web && docker-compose up -d
```

**Verify Services**:
```bash
# Check all services
curl http://localhost:8003/health  # fks_data
curl http://localhost:8002/health  # fks_app
curl http://localhost:8000/health  # fks_web

# Or use Python script
python repo/main/scripts/test-bitcoin-signal.py
```

**Expected**: All services return `{"status": "healthy"}`

---

### Step 2: Test Bitcoin Data (5 minutes)

```bash
# Test Bitcoin price
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"

# Test Bitcoin OHLCV
curl "http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
```

**Expected**: 
- Price returns current Bitcoin price
- OHLCV returns 100 candles of hourly data

---

### Step 3: Generate Bitcoin Signal (5 minutes)

**Option A: Using Test Script (Recommended)**
```bash
# Linux/Mac
./repo/main/scripts/test-bitcoin-signal.sh

# Windows (PowerShell)
python repo/main/scripts/test-bitcoin-signal.py
```

**Option B: Manual Test**
```bash
# Generate Bitcoin signal (swing)
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

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

**Try Different Strategies**:
```bash
# RSI strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi"

# MACD strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd"

# EMA strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing"
```

---

### Step 4: Open Dashboard (5 minutes)

**Open in Browser**:
```
http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing
```

**What You'll See**:
- ✅ Bitcoin signals displayed
- ✅ Entry price, TP, SL
- ✅ Confidence and rationale
- ✅ Approval/rejection buttons

**Test Approval Workflow**:
1. Click "Approve" for a signal
2. Verify confirmation message
3. Test rejection workflow

---

### Step 5: Daily Workflow (10 minutes)

**Morning Routine**:
1. Start services (if not running)
2. Open dashboard: `http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing`
3. Review Bitcoin signals
4. Check signal confidence and rationale

**Signal Review**:
1. Review entry price, TP, SL
2. Check confidence level
3. Review rationale and indicators
4. Verify risk/reward ratio

**Manual Execution**:
1. Click "Approve" for good signals
2. Click "Reject" for poor signals
3. Log trade decisions
4. Monitor execution (if integrated)

---

## 🎯 Success Criteria

### Minimum Viable Demo
- ✅ Services start successfully
- ✅ Bitcoin price data accessible
- ✅ Signal generation works
- ✅ Dashboard displays signals
- ✅ Approval workflow works

### Production Ready
- ✅ All services stable
- ✅ Error handling works
- ✅ Logging complete
- ✅ Performance acceptable

---

## 🔧 Troubleshooting

### Issue: Services Won't Start

**Solution**:
```bash
# Check Docker
docker ps

# Check logs
docker-compose logs -f

# Restart services
docker-compose restart
```

### Issue: Can't Fetch Bitcoin Data

**Solution**:
```bash
# Check Binance API
curl "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"

# Check fks_data logs
cd repo/data && docker-compose logs -f
```

### Issue: No Signals Generated

**Solution**:
```bash
# Check fks_app logs
cd repo/app && docker-compose logs -f

# Test data fetch manually
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"
```

### Issue: Dashboard Shows No Signals

**Solution**:
```bash
# Check fks_web logs
cd repo/web && docker-compose logs -f

# Test API directly
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing"
```

---

## 📊 API Endpoints

### Data Service (fks_data)
- `GET /api/v1/data/price?symbol=BTCUSDT` - Get Bitcoin price
- `GET /api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100` - Get OHLCV

### App Service (fks_app)
- `GET /api/v1/signals/latest/BTCUSDT?category=swing` - Get latest signal
- `POST /api/v1/signals/generate` - Generate signal
- `GET /api/v1/signals/batch?symbols=BTCUSDT&category=swing` - Batch signals

### Web Service (fks_web)
- `GET /portfolio/signals/?symbols=BTCUSDT&category=swing` - Dashboard
- `POST /portfolio/signals/approve/{signal_id}/` - Approve signal
- `POST /portfolio/signals/reject/{signal_id}/` - Reject signal

---

## 📝 Daily Workflow

### Morning (5 minutes)
1. Start services
2. Open dashboard
3. Review Bitcoin signals

### Signal Review (5 minutes)
1. Check entry price, TP, SL
2. Review confidence and rationale
3. Verify risk/reward ratio

### Manual Execution (5 minutes)
1. Approve good signals
2. Reject poor signals
3. Log trade decisions

### End of Day (5 minutes)
1. Review trade performance
2. Update trade log
3. Plan next day

**Total Time**: ~20 minutes per day

---

## 🎉 Next Steps

### Immediate
1. ✅ Test services
2. ✅ Generate Bitcoin signals
3. ✅ Test dashboard
4. ✅ Create daily workflow

### Short-term
1. Fix any issues found
2. Improve error handling
3. Add logging
4. Create documentation

### Medium-term
1. Add more strategies
2. Improve AI enhancement
3. Add performance tracking
4. Expand to other assets

---

## 📞 Support

If you encounter issues:
1. Check service logs
2. Review troubleshooting guide
3. Check API responses
4. Verify service health

---

**Status**: 🚀 **READY TO USE**

**Next Action**: Start with Step 1 - Start Services

**Estimated Time**: 30 minutes

---

**Last Updated**: 2025-01-15

