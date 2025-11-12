# Bitcoin Signal Daily Workflow
## Manual Trading Workflow for Bitcoin Signals

**Date**: 2025-01-15  
**Status**: 🚀 **READY TO USE**  
**Purpose**: Daily workflow for reviewing and executing Bitcoin signals

---

## 🎯 Daily Workflow Overview

### Morning Routine (5 minutes)
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

## 📋 Detailed Workflow

### Option 1: Using CLI Tool (Recommended)

#### Step 1: Morning Setup (5 minutes)

**1.1 Start Services**
```bash
# Option A: Using script
./repo/main/scripts/start-bitcoin-demo.sh

# Option B: Manual
docker network create fks-network
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

**1.2 Generate and Review Signal**
```bash
# Generate signal with detailed information
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed

# Or use interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

**1.3 Approve or Reject Signal**
```bash
# Interactive mode (recommended)
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive

# Or auto-approve
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
```

---

### Option 2: Using API Directly

#### Step 1: Morning Setup (5 minutes)

**1.1 Start Services**
```bash
# Option A: Using script
./repo/main/scripts/start-bitcoin-demo.sh

# Option B: Manual
docker network create fks-network
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

**1.2 Verify Services**
```bash
# Check all services
curl http://localhost:8003/health  # fks_data
curl http://localhost:8002/health  # fks_app
curl http://localhost:8000/health  # fks_web

# Or use test script
python repo/main/scripts/test-bitcoin-signal.py
```

**1.3 Generate Signal**
```bash
# Generate Bitcoin signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

**1.4 Review Signal**
- Check entry price, take profit, stop loss
- Review confidence and rationale
- Check indicators (RSI, MACD, etc.)
- Review position sizing

---

### Option 3: Using Dashboard (Requires Authentication)

#### Step 1: Morning Setup (5 minutes)

**1.1 Start Services**
```bash
# Option A: Using script
./repo/main/scripts/start-bitcoin-demo.sh

# Option B: Manual
docker network create fks-network
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

**1.2 Open Dashboard**
```
http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing
```

**1.3 Review Signals**
- View signals in dashboard
- Check signal details
- Review confidence and rationale

---

### Step 2: Signal Review (5 minutes)

#### 2.1 Review Signal Details
- **Entry Price**: Current Bitcoin price
- **Take Profit**: Target profit level (3.5% for swing)
- **Stop Loss**: Risk level (2% for swing)
- **Confidence**: Signal confidence (0-1)
- **Rationale**: Why the signal was generated

#### 2.2 Check Indicators
- **RSI**: Relative Strength Index (oversold < 30, overbought > 70)
- **MACD**: Moving Average Convergence Divergence
- **EMA**: Exponential Moving Average
- **Volume**: Trading volume confirmation

#### 2.3 Verify Risk/Reward
- **Risk/Reward Ratio**: Should be at least 1.5:1
- **Risk Amount**: 1-2% of portfolio
- **Position Size**: Calculated based on risk

---

### Step 3: Manual Execution (5 minutes)

#### 3.1 Approve Signal
1. Click "Approve" button
2. Verify signal details
3. Confirm execution
4. Log trade decision

#### 3.2 Reject Signal
1. Click "Reject" button
2. Document reason for rejection
3. Log rejection
4. Move to next signal

#### 3.3 Manual Execution (External)
1. Copy signal details
2. Execute on exchange manually
3. Log execution
4. Monitor position

---

### Step 4: End of Day (5 minutes)

#### 4.1 Review Performance
- Check executed trades
- Review signal accuracy
- Calculate win rate
- Review P&L

#### 4.2 Update Trade Log
- Log executed trades
- Document decisions
- Update performance metrics
- Plan next day

#### 4.3 Review Signal Accuracy
- Compare signals vs actual price movements
- Identify successful signals
- Learn from mistakes
- Adjust strategy if needed

---

## 🔧 Quick Reference

### Dashboard URLs
- **Signals**: `http://localhost:8000/portfolio/signals/?symbols=BTCUSDT&category=swing`
- **Performance**: `http://localhost:8000/portfolio/performance/`
- **Dashboard**: `http://localhost:8000/portfolio/`

### API Endpoints
- **Generate Signal**: `GET /api/v1/signals/latest/BTCUSDT?category=swing`
- **Batch Signals**: `GET /api/v1/signals/batch?symbols=BTCUSDT&category=swing`
- **Approve Signal**: `POST /portfolio/signals/approve/{signal_id}/`
- **Reject Signal**: `POST /portfolio/signals/reject/{signal_id}/`

### Signal Categories
- **Scalp**: 0.5-1% TP/SL, 1-hour timeframe
- **Swing**: 2-5% TP/SL, 1-day timeframe
- **Long-term**: 10-20% TP/SL, 1-week timeframe

### Strategies
- **RSI**: Relative Strength Index (default for swing)
- **MACD**: Moving Average Convergence Divergence
- **EMA**: Exponential Moving Average
- **ASMBTR**: Advanced strategy (fallback)

---

## 📊 Signal Evaluation Criteria

### Good Signal
- ✅ Confidence > 70%
- ✅ Risk/Reward > 1.5:1
- ✅ Clear rationale
- ✅ Strong indicators
- ✅ Volume confirmation

### Poor Signal
- ❌ Confidence < 50%
- ❌ Risk/Reward < 1.0:1
- ❌ Weak rationale
- ❌ Mixed indicators
- ❌ Low volume

---

## 🎯 Decision Matrix

| Signal Quality | Action | Reason |
|----------------|--------|--------|
| **Excellent** (Confidence > 80%, R/R > 2:1) | Approve | Strong signal, good risk/reward |
| **Good** (Confidence > 70%, R/R > 1.5:1) | Approve | Solid signal, acceptable risk |
| **Fair** (Confidence > 60%, R/R > 1.2:1) | Review | Decent signal, consider context |
| **Poor** (Confidence < 60%, R/R < 1.2:1) | Reject | Weak signal, high risk |

---

## 📝 Trade Log Template

### Trade Log Entry
```markdown
## Trade Log - [Date]

### Signal Details
- Symbol: BTCUSDT
- Signal: BUY/SELL
- Entry: $[price]
- TP: $[price]
- SL: $[price]
- Confidence: [%]
- Strategy: [strategy]

### Execution
- Approved: Yes/No
- Executed: Yes/No
- Entry Price: $[price]
- Position Size: [units]
- Risk Amount: $[amount]

### Outcome
- Status: Open/Closed
- Exit Price: $[price]
- P&L: $[amount]
- Result: Win/Loss

### Notes
- [Your notes]
```

---

## 🔄 Weekly Review

### Weekly Tasks
1. Review all signals from the week
2. Calculate win rate
3. Review P&L
4. Identify successful patterns
5. Adjust strategy if needed

### Weekly Metrics
- **Signals Generated**: [count]
- **Signals Approved**: [count]
- **Signals Executed**: [count]
- **Win Rate**: [%]
- **Total P&L**: $[amount]
- **Average R/R**: [ratio]

---

## 🎯 Success Criteria

### Daily
- ✅ Review all Bitcoin signals
- ✅ Make informed decisions
- ✅ Log all trades
- ✅ Monitor performance

### Weekly
- ✅ Calculate win rate
- ✅ Review P&L
- ✅ Identify patterns
- ✅ Adjust strategy

### Monthly
- ✅ Review overall performance
- ✅ Analyze signal accuracy
- ✅ Optimize strategy
- ✅ Plan improvements

---

## 📞 Troubleshooting

### Issue: No Signals Generated
**Solution**:
1. Check service logs
2. Verify data fetch
3. Check strategy configuration
4. Test API directly

### Issue: Low Signal Quality
**Solution**:
1. Review indicator settings
2. Adjust strategy parameters
3. Try different strategies
4. Check market conditions

### Issue: Dashboard Not Loading
**Solution**:
1. Check service health
2. Verify network connectivity
3. Check browser console
4. Review service logs

---

## 📚 References

### Documentation
- `BITCOIN-QUICK-START.md` - Quick start guide
- `BITCOIN-SIGNAL-DEMO-ACTION-PLAN.md` - Action plan
- `BITCOIN-DEMO-IMPLEMENTATION-STATUS.md` - Implementation status

### API Documentation
- `QUICK-REFERENCE.md` - API quick reference
- `API-REFERENCE.md` - Full API documentation

### Strategy Documentation
- `08-TRADE-CATEGORIES-REFERENCE.md` - Trade categories
- `03-PHASE-3-SIGNAL-GENERATION.md` - Signal generation

---

**Status**: 🚀 **READY TO USE**

**Next Action**: Start your daily workflow!

**Estimated Time**: ~20 minutes per day

---

**Last Updated**: 2025-01-15

