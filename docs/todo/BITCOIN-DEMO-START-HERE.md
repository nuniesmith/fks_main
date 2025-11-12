# Bitcoin Signal Demo - START HERE
## Quick Start Guide for Bitcoin Signal Generation

**Date**: 2025-01-15  
**Status**: 🚀 **READY TO TEST**  
**Goal**: Get Bitcoin signals working for daily manual trading

---

## 🎯 What You're Building

A working Bitcoin signal generation system that:
1. ✅ Fetches Bitcoin price data from Binance
2. ✅ Generates trading signals using RSI, MACD, EMA strategies
3. ✅ Displays signals in a web dashboard
4. ✅ Allows manual approval/rejection of signals
5. ✅ Ready for daily manual trading

---

## 🚀 Quick Start (30 Minutes)

### Step 1: Verify Setup (2 minutes)

```bash
# Check if everything is ready
python repo/main/scripts/verify-bitcoin-setup.py
```

**Expected Output**:
- ✓ Docker available
- ✓ Docker Compose available
- ⚠ Services not running (will start them next)

---

### Step 2: Create Docker Network (1 minute)

```bash
# Create Docker network (if not exists)
docker network create fks-network
```

**Expected Output**:
- Network created or already exists

---

### Step 3: Start Services (5 minutes)

**Option A: Using Script (Recommended)**
```bash
# Linux/Mac
./repo/main/scripts/start-bitcoin-demo.sh

# Windows (PowerShell)
cd repo/main/scripts
.\start-bitcoin-demo.ps1
```

**Option B: Manual Start**
```bash
# Start data service
cd repo/data
docker-compose up -d

# Start app service (signal generation)
cd ../app
docker-compose up -d

# Start web service (dashboard)
cd ../web
docker-compose up -d
```

**Verify Services**:
```bash
# Check all services
curl http://localhost:8003/health  # fks_data
curl http://localhost:8002/health  # fks_app
curl http://localhost:8000/health  # fks_web
```

**Expected**: All services return `{"status": "healthy"}`

---

### Step 4: Test Bitcoin Data (3 minutes)

```bash
# Test Bitcoin price
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"

# Test Bitcoin OHLCV
curl "http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
```

**Expected Output**:
- Price: Current Bitcoin price (e.g., `{"symbol": "BTCUSDT", "price": 45000.0, ...}`)
- OHLCV: 100 candles of hourly data

---

### Step 5: Generate Bitcoin Signal (5 minutes)

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
  "take_profit": 46575.0,
  "stop_loss": 44100.0,
  "position_size_pct": 0.015,
  "confidence": 0.75,
  "timestamp": "2025-01-15T10:30:00",
  "rationale": "RSI oversold (28.5 < 30) - Buy signal",
  "ai_enhanced": false,
  "indicators": {
    "rsi": 28.5
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

### Step 6: Open Dashboard (5 minutes)

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

### Step 7: Test Everything (5 minutes)

**Use Test Script**:
```bash
# Linux/Mac
./repo/main/scripts/test-bitcoin-signal.sh

# Windows (PowerShell)
python repo/main/scripts/test-bitcoin-signal.py
```

**Expected Output**:
- ✓ All services running
- ✓ Bitcoin price data accessible
- ✓ Bitcoin signals generated
- ✓ Dashboard displays signals

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
# Check Binance API directly
curl "https://fapi.binance.com/fapi/v1/ticker/price?symbol=BTCUSDT"

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
curl "http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
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

## 📊 Expected Results

### Service Health
```json
{
  "status": "healthy",
  "service": "fks_data",
  "providers": {
    "binance": "available"
  }
}
```

### Bitcoin Price
```json
{
  "symbol": "BTCUSDT",
  "price": 45000.0,
  "timestamp": 1705315200,
  "provider": "binance",
  "cached": false
}
```

### Bitcoin Signal
```json
{
  "symbol": "BTCUSDT",
  "signal_type": "BUY",
  "category": "swing",
  "entry_price": 45000.0,
  "take_profit": 46575.0,
  "stop_loss": 44100.0,
  "position_size_pct": 0.015,
  "confidence": 0.75,
  "rationale": "RSI oversold (28.5 < 30) - Buy signal",
  "indicators": {
    "rsi": 28.5
  }
}
```

---

## 📝 Daily Workflow

### Morning (5 minutes)
1. Start services (if not running)
2. Open dashboard
3. Review Bitcoin signals
4. Check signal confidence and rationale

### Signal Review (5 minutes)
1. Review entry price, TP, SL
2. Check confidence level
3. Review rationale and indicators
4. Verify risk/reward ratio

### Manual Execution (5 minutes)
1. Approve good signals
2. Reject poor signals
3. Log trade decisions
4. Monitor execution (if integrated)

### End of Day (5 minutes)
1. Review trade performance
2. Update trade log
3. Review signal accuracy
4. Plan next day

**Total Time**: ~20 minutes per day

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

## 📚 Documentation

### Quick Start
- `BITCOIN-QUICK-START.md` - 30-minute quick start guide
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow guide
- `BITCOIN-DEMO-START-HERE.md` - This file

### Implementation
- `BITCOIN-SIGNAL-DEMO-ACTION-PLAN.md` - Complete action plan
- `BITCOIN-DEMO-IMPLEMENTATION-STATUS.md` - Implementation status
- `BITCOIN-DEMO-READY-SUMMARY.md` - Ready summary

### Reference
- `QUICK-REFERENCE.md` - API quick reference
- `API-REFERENCE.md` - Full API documentation

---

## 🚀 Next Steps

### Immediate (Today)
1. ✅ Start services
2. ✅ Test Bitcoin signal generation
3. ✅ Test dashboard
4. ✅ Create daily workflow

### Short-term (This Week)
1. Fix any issues found
2. Improve error handling
3. Add logging
4. Create documentation

### Medium-term (Next Week)
1. Improve signal quality
2. Add more strategies
3. Add AI enhancement
4. Add performance tracking

### Long-term (Next Month)
1. Expand to other assets (ETH, SOL)
2. Add more strategies
3. Improve AI enhancement
4. Add performance analytics

---

## 📞 Support

If you encounter issues:
1. Check service logs
2. Review troubleshooting guide
3. Check API responses
4. Verify service health

---

## 🎉 Ready to Start!

**Next Action**: Run the verification script and start services!

```bash
# 1. Verify setup
python repo/main/scripts/verify-bitcoin-setup.py

# 2. Start services
./repo/main/scripts/start-bitcoin-demo.sh

# 3. Test Bitcoin signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing"

# 4. Open dashboard
# http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing
```

---

**Status**: 🚀 **READY TO TEST**

**Estimated Time**: 30 minutes to get working demo

**Focus**: Bitcoin signals only - expand to other assets later

---

**Last Updated**: 2025-01-15

