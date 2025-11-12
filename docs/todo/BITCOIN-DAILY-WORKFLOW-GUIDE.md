# Bitcoin Signal Demo - Daily Workflow Guide

**Date**: 2025-11-12  
**Status**: ✅ **COMPLETE AND TESTED**  
**Purpose**: Complete guide to the daily Bitcoin signal generation and trading workflow

---

## 🎯 Overview

This guide provides a complete step-by-step workflow for using the Bitcoin Signal Demo system for daily manual trading. The workflow is designed to take approximately 20-25 minutes per day and includes all necessary steps from signal generation to performance tracking.

---

## 📋 Complete Workflow (20-25 minutes)

### Step 1: Morning Routine (5 minutes) ☀️

#### 1.1 Start Services

**Check if services are running:**
```bash
docker ps | grep fks_
```

**Start services if needed:**
```bash
# Option A: Using script (recommended)
./repo/main/scripts/start-bitcoin-demo.sh

# Option B: Manual
docker network create fks-network
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

**Verify services are healthy:**
```bash
curl "http://localhost:8002/health"  # fks_app
curl "http://localhost:8003/health"  # fks_data
curl "http://localhost:8000/health"  # fks_web
```

#### 1.2 Generate Daily Signals

**Generate signals for all categories:**
```powershell
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT
```

**Output:**
- Individual signal files: `signals/signals_<category>_YYYYMMDD.json`
- Daily summary: `signals/daily_signals_summary_YYYYMMDD.json`

**Expected Result:**
- ✅ Signals generated for scalp, swing, and long_term categories
- ✅ All signals saved to JSON files
- ✅ Daily summary generated
- ✅ All strategies working (RSI, MACD, EMA)

#### 1.3 Review Signals

**Review signals with detailed information:**
```powershell
.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed
```

**Review with strategy comparison:**
```powershell
.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed -Compare
```

**Expected Result:**
- ✅ Signal details displayed for all categories
- ✅ Summary statistics calculated
- ✅ Strategy comparison displayed
- ✅ Category breakdown displayed

---

### Step 2: Signal Review (5 minutes) 📊

#### 2.1 Review Signal Details

**For each category, review:**
- **Entry Price**: Current Bitcoin price
- **Take Profit**: Target profit level
- **Stop Loss**: Risk level
- **Confidence**: Signal confidence (0-1)
- **Rationale**: Why the signal was generated
- **Indicators**: Technical indicators (RSI, MACD, EMA)
- **Risk/Reward**: Risk/reward ratio

#### 2.2 Compare Strategies

**Compare signals from different strategies:**
```bash
# RSI Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# MACD Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"

# EMA Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing&use_ai=false"
```

#### 2.3 Verify Signal Quality

**Check signal quality criteria:**
- ✅ **Confidence**: Should be > 60%
- ✅ **Risk/Reward**: Should be > 1.5:1
- ✅ **Rationale**: Should be clear and logical
- ✅ **Indicators**: Should be strong and consistent
- ✅ **Volume**: Should confirm signal

---

### Step 3: Signal Approval (5 minutes) ✅

#### 3.1 Approve/Reject Signals

**Interactive approval:**
```powershell
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action interactive
```

**Approve all signals:**
```powershell
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action approve
```

**Reject all signals:**
```powershell
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action reject -Reason "Manual rejection"
```

**Approve specific category:**
```powershell
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Category swing -Action approve
```

#### 3.2 Signal Decision Matrix

**Use decision matrix to approve/reject:**
- **Excellent** (Confidence > 80%, R/R > 2:1): ✅ Approve
- **Good** (Confidence > 70%, R/R > 1.5:1): ✅ Approve
- **Fair** (Confidence > 60%, R/R > 1.2:1): ⚠️ Review
- **Poor** (Confidence < 60%, R/R < 1.2:1): ❌ Reject

#### 3.3 Document Decisions

**Verify approved signals:**
```bash
# Check approved signals
ls signals/approved/

# View approved signals
cat signals/approved/approved_YYYYMMDD.json
```

**Verify rejected signals:**
```bash
# Check rejected signals
ls signals/rejected/

# View rejected signals
cat signals/rejected/rejected_YYYYMMDD.json
```

---

### Step 4: Manual Execution (5 minutes) 💰

#### 4.1 Execute Approved Signals

**Review approved signals:**
```bash
cat signals/approved/approved_YYYYMMDD.json
```

**Execute trades manually:**
1. Open your exchange platform
2. Review approved signal details
3. Execute trade at entry price
4. Set stop loss order
5. Set take profit order
6. Monitor position

#### 4.2 Trade Execution Checklist

**For each approved signal:**
- [ ] Verify entry price
- [ ] Set stop loss
- [ ] Set take profit
- [ ] Calculate position size
- [ ] Risk 1-2% per trade
- [ ] Log trade execution
- [ ] Monitor position

#### 4.3 Position Management

**Monitor open positions:**
- [ ] Check open positions daily
- [ ] Adjust stop loss if needed
- [ ] Take profit when target reached
- [ ] Close positions if stop loss hit
- [ ] Update trade log

---

### Step 5: End of Day (5 minutes) 📈

#### 5.1 Review Performance

**Track performance:**
```powershell
.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed
```

**Review metrics:**
- Total signals generated
- Signals approved
- Signals rejected
- Approval rate
- Average confidence
- Win rate (if trades executed)
- Total P&L (if trades executed)

#### 5.2 Update Trade Log

**Log executed trades:**
- [ ] Log executed trades
- [ ] Document decisions
- [ ] Update performance metrics
- [ ] Plan next day

#### 5.3 Review Signal Accuracy

**Compare signals vs actual price movements:**
- [ ] Check if signals were accurate
- [ ] Identify successful signals
- [ ] Learn from mistakes
- [ ] Adjust strategy if needed

---

## 🛠️ Scripts and Tools

### Daily Signal Generation
**Script**: `generate-daily-signals.ps1`
```powershell
# Generate all signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Generate specific categories
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -Categories @("swing")

# Generate without saving
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -NoSave
```

### Signal Review
**Script**: `review-signals.ps1`
```powershell
# Review signals with details
.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed

# Review with strategy comparison
.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed -Compare
```

### Signal Approval
**Script**: `approve-signals.ps1`
```powershell
# Interactive approval
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action interactive

# Approve all
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action approve

# Reject all
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action reject -Reason "Manual rejection"
```

### Performance Tracking
**Script**: `track-performance.ps1`
```powershell
# Track performance
.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed

# Summary only
.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Summary
```

---

## 📁 File Structure

### Signal Files
```
signals/
├── signals_scalp_YYYYMMDD.json               # Scalp signals
├── signals_swing_YYYYMMDD.json               # Swing signals
├── signals_long_term_YYYYMMDD.json           # Long-term signals
├── daily_signals_summary_YYYYMMDD.json       # Daily summary
├── approved/
│   └── approved_YYYYMMDD.json                # Approved signals
├── rejected/
│   └── rejected_YYYYMMDD.json                # Rejected signals
└── performance/
    └── performance_YYYYMMDD.json             # Performance metrics
```

---

## 📊 Example Workflow

### Morning (5 minutes)
```powershell
# 1. Start services
./repo/main/scripts/start-bitcoin-demo.sh

# 2. Generate daily signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# 3. Review signals
.\repo\main\scripts\review-signals.ps1 -Date 20251112 -Symbol BTCUSDT -Detailed
```

### Review (5 minutes)
```powershell
# Review signal details
.\repo\main\scripts\review-signals.ps1 -Date 20251112 -Symbol BTCUSDT -Detailed -Compare

# Compare strategies
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"
```

### Approval (5 minutes)
```powershell
# Approve/reject signals
.\repo\main\scripts\approve-signals.ps1 -Date 20251112 -Symbol BTCUSDT -Action interactive

# Verify approved signals
cat signals/approved/approved_20251112.json
```

### Execution (5 minutes)
```bash
# Review approved signals
cat signals/approved/approved_20251112.json

# Execute trades manually on exchange
# Set stop loss and take profit
# Monitor positions
```

### End of Day (5 minutes)
```powershell
# Track performance
.\repo\main\scripts\track-performance.ps1 -Date 20251112 -Symbol BTCUSDT -Detailed

# Review performance metrics
cat signals/performance/performance_20251112.json
```

---

## ✅ Daily Checklist

### Morning (5 minutes)
- [ ] Start services
- [ ] Generate daily signals
- [ ] Review signals

### Review (5 minutes)
- [ ] Review signal details
- [ ] Compare strategies
- [ ] Verify signal quality

### Approval (5 minutes)
- [ ] Approve/reject signals
- [ ] Document decisions
- [ ] Plan execution

### Execution (5 minutes)
- [ ] Execute approved signals
- [ ] Set stop loss and take profit
- [ ] Monitor positions

### End of Day (5 minutes)
- [ ] Review performance
- [ ] Update trade log
- [ ] Review signal accuracy

**Total Time**: ~25 minutes per day

---

## 📊 Performance Tracking

### Daily Metrics
- Total signals generated
- Signals approved
- Signals rejected
- Approval rate
- Average confidence
- Win rate
- Total P&L

### Weekly Metrics
- Weekly win rate
- Weekly P&L
- Average R/R
- Best performing strategy
- Best performing category
- Signal accuracy

### Monthly Metrics
- Monthly win rate
- Monthly P&L
- Overall performance
- Strategy optimization
- Category optimization
- Performance trends

---

## 🎯 Best Practices

### Signal Generation
- Generate signals daily
- Review all categories
- Compare strategies
- Verify confidence > 60%

### Risk Management
- Follow position sizing
- Set stop losses
- Risk 1-2% per trade
- Diversify positions

### Signal Approval
- Review rationale
- Check indicators
- Consider market context
- Log decisions

### Performance Tracking
- Track signal accuracy
- Monitor win rate
- Review P&L
- Optimize strategies

---

## 🚨 Troubleshooting

### Services Not Running
```bash
# Check services
docker ps | grep fks_

# Start services
./repo/main/scripts/start-bitcoin-demo.sh

# Check logs
docker logs fks_app
docker logs fks_data
```

### No Signals Generated
```bash
# Check service health
curl "http://localhost:8002/health"
curl "http://localhost:8003/health"

# Check data service
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"

# Check signal service logs
docker logs fks_app
```

### Script Errors
```bash
# Check script syntax
Get-Content repo/main/scripts/generate-daily-signals.ps1

# Check file paths
Test-Path signals/
Test-Path signals/approved/
Test-Path signals/rejected/
Test-Path signals/performance/
```

---

## 📚 Documentation

### Getting Started
- `BITCOIN-GETTING-STARTED.md` - Getting started guide
- `BITCOIN-QUICK-START.md` - Quick start guide
- `BITCOIN-QUICK-REFERENCE.md` - Quick reference

### Daily Workflow
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow
- `BITCOIN-DAILY-CHECKLIST.md` - Daily checklist
- `BITCOIN-COMPLETE-DAILY-WORKFLOW.md` - Complete workflow guide
- `BITCOIN-DAILY-WORKFLOW-GUIDE.md` - This file

### Features
- `BITCOIN-FEATURES-DOCUMENTATION.md` - Features documentation
- `BITCOIN-STRATEGIES-TEST-RESULTS.md` - Strategies test results
- `BITCOIN-CLI-TOOL.md` - CLI tool documentation

---

## ✅ Success Criteria

### Daily
- ✅ All signals generated
- ✅ All signals reviewed
- ✅ All signals approved/rejected
- ✅ All trades executed
- ✅ Performance tracked
- ✅ Trade log updated

### Weekly
- ✅ Weekly performance reviewed
- ✅ Win rate calculated
- ✅ P&L calculated
- ✅ Strategy optimization
- ✅ Performance trends analyzed

### Monthly
- ✅ Monthly performance reviewed
- ✅ Overall performance analyzed
- ✅ Strategy optimization
- ✅ Category optimization
- ✅ Performance trends analyzed

---

## 🎉 Summary

### Complete Workflow
1. **Morning**: Start services and generate signals (5 minutes)
2. **Review**: Review signals from all categories (5 minutes)
3. **Approval**: Approve/reject signals (5 minutes)
4. **Execution**: Execute approved signals manually (5 minutes)
5. **End of Day**: Review performance and update logs (5 minutes)

**Total Time**: ~25 minutes per day

### Tools Available
- ✅ Daily signal generation script
- ✅ Signal review script
- ✅ Signal approval script
- ✅ Performance tracking script
- ✅ CLI tool for interactive workflow
- ✅ API endpoints for signal generation

### Documentation Available
- ✅ Getting started guide
- ✅ Quick reference guide
- ✅ Daily workflow guide
- ✅ Daily checklist
- ✅ Features documentation
- ✅ Strategies test results

---

**Status**: ✅ **WORKFLOW COMPLETE AND TESTED**

**Last Updated**: 2025-11-12

**Next Action**: Start using the complete daily workflow for Bitcoin signal generation and trading!

---

**Happy Trading!** 🚀

