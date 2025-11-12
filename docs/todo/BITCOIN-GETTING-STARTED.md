# Bitcoin Signal Demo - Getting Started Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Step-by-step guide to get started with Bitcoin signal generation

---

## 🎯 Overview

The Bitcoin Signal Demo is a complete system for generating, reviewing, and managing Bitcoin trading signals for daily manual trading. This guide will walk you through setting up and using the system.

---

## 📋 Prerequisites

### Required
- Docker and Docker Compose
- Python 3.7+ (for CLI tools)
- PowerShell (for PowerShell scripts)
- Internet connection (for data fetching)

### Optional
- `requests` library (for Python CLI tools): `pip install requests`

---

## 🚀 Step 1: Start Services (5 minutes)

### Option A: Using Script (Recommended)
```bash
# Linux/Mac
./repo/main/scripts/start-bitcoin-demo.sh

# Windows (PowerShell)
cd repo/main/scripts
.\start-bitcoin-demo.ps1
```

### Option B: Manual Start
```bash
# Create Docker network
docker network create fks-network

# Start data service
cd repo/data && docker-compose up -d

# Start app service
cd repo/app && docker-compose up -d

# Start web service
cd repo/web && docker-compose up -d
```

### Verify Services
```bash
# Check services
docker ps | grep fks_

# Check health
curl "http://localhost:8002/health"  # fks_app
curl "http://localhost:8003/health"  # fks_data
curl "http://localhost:8000/health"  # fks_web
```

---

## 📊 Step 2: Generate Your First Signal (5 minutes)

### Option A: Using Daily Script (Recommended)
```powershell
# Generate all signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Generate specific category
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -Categories @("swing")
```

### Option B: Using API
```bash
# Generate swing trading signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Generate with specific strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
```

### Option C: Using CLI Tool
```bash
# Generate signal with details
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed

# Interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

---

## 📈 Step 3: Review Signals (5 minutes)

### Check Signal Files
```bash
# Check signals directory
ls signals/

# View daily summary
cat signals/daily_signals_summary_YYYYMMDD.json

# View specific category
cat signals/signals_swing_YYYYMMDD.json
```

### Review Signal Details
- **Entry Price**: Current Bitcoin price
- **Take Profit**: Target profit level
- **Stop Loss**: Risk level
- **Confidence**: Signal confidence (0-1)
- **Rationale**: Why the signal was generated
- **Indicators**: Technical indicators used

### Compare Strategies
```bash
# RSI Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# MACD Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"

# EMA Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing&use_ai=false"
```

---

## ✅ Step 4: Approve and Execute Signals (5 minutes)

### Option A: Using CLI Tool (Recommended)
```bash
# Interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive

# Auto-approve
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve

# Auto-reject
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --reject
```

### Option B: Manual Approval
1. Review signal details
2. Check confidence and rationale
3. Verify indicators
4. Approve or reject signal
5. Execute approved signal manually on exchange

### Signal Files
- **Approved Signals**: `signals/approved_signals_YYYYMMDD.json`
- **Rejected Signals**: `signals/rejected_signals_YYYYMMDD.json`

---

## 📝 Step 5: Daily Workflow (20 minutes)

### Morning Routine (5 minutes)
1. **Start Services** (if not running):
   ```bash
   ./repo/main/scripts/start-bitcoin-demo.sh
   ```

2. **Generate Daily Signals**:
   ```powershell
   .\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT
   ```

3. **Review Signals**:
   - Check signals from all categories
   - Review entry price, TP, SL, confidence
   - Check rationale and indicators

### Signal Review (5 minutes)
1. **Review Signal Details**:
   - Entry price, take profit, stop loss
   - Confidence and rationale
   - Indicators (RSI, MACD, EMA)
   - Risk/reward ratio

2. **Compare Strategies**:
   - Compare signals from different strategies
   - Choose best signal based on confidence
   - Consider market conditions

### Manual Execution (5 minutes)
1. **Approve Signals**:
   ```bash
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
   ```

2. **Execute Trades**:
   - Execute approved signals manually
   - Set stop loss and take profit
   - Monitor positions

### End of Day (5 minutes)
1. **Review Performance**:
   - Check executed trades
   - Review signal accuracy
   - Calculate win rate
   - Update trade log

2. **Review Signals**:
   - Review approved/rejected signals
   - Analyze signal accuracy
   - Plan next day

---

## 🎯 Step 6: Advanced Usage

### Multiple Strategies
```bash
# Test different strategies
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing&use_ai=false"
```

### Multiple Categories
```bash
# Generate signals for all categories
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -Categories @("scalp", "swing", "long_term")
```

### Batch Signals
```bash
# Generate signals for multiple symbols
curl "http://localhost:8002/api/v1/signals/batch?symbols=BTCUSDT,ETHUSDT&category=swing&use_ai=false"
```

### AI Enhancement
```bash
# Generate signal with AI enhancement
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=true"

# Daily script with AI
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -UseAI
```

---

## 🔧 Troubleshooting

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

### CLI Tool Not Working
```bash
# Install dependencies
pip install requests

# Test CLI tool
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --help
```

---

## 📚 Documentation

### Quick Reference
- `BITCOIN-QUICK-REFERENCE.md` - Quick reference guide
- `BITCOIN-QUICK-START.md` - Quick start guide
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow

### Features
- `BITCOIN-FEATURES-DOCUMENTATION.md` - Features documentation
- `BITCOIN-STRATEGIES-TEST-RESULTS.md` - Strategies test results
- `BITCOIN-CLI-TOOL.md` - CLI tool documentation

### Summaries
- `BITCOIN-DEMO-WORKING-SUMMARY.md` - Working summary
- `BITCOIN-DEMO-COMPLETE.md` - Completion summary
- `BITCOIN-DEMO-FINAL-SUMMARY.md` - Final summary

---

## ✅ Success Checklist

### Setup
- [ ] Docker and Docker Compose installed
- [ ] Services started and running
- [ ] Health checks passing
- [ ] Data service fetching data

### Signal Generation
- [ ] Signals generating successfully
- [ ] All categories working (scalp, swing, long_term)
- [ ] All strategies working (RSI, MACD, EMA)
- [ ] Daily script working

### Signal Review
- [ ] Signals saved to files
- [ ] Daily summary generated
- [ ] Signal details complete
- [ ] Indicators displayed

### Signal Approval
- [ ] CLI tool working
- [ ] Interactive mode working
- [ ] Approved signals saved
- [ ] Rejected signals logged

### Daily Workflow
- [ ] Morning routine established
- [ ] Signal review process working
- [ ] Manual execution process working
- [ ] End of day review working

---

## 🎯 Next Steps

### Immediate
1. **Start Using**: Begin using the system for daily manual trading
2. **Monitor Performance**: Track signal accuracy and performance
3. **Optimize Strategies**: Optimize strategy parameters based on results

### Future
1. **Expand Assets**: Add other assets (ETH, SOL, etc.)
2. **Add Features**: Add more features as needed
3. **Scale Up**: Scale to multiple symbols and categories
4. **Automation**: Add automation for signal execution

---

## 🎉 Congratulations!

You're now ready to start using the Bitcoin Signal Demo for daily manual trading!

### Quick Start Commands
```bash
# Start services
./repo/main/scripts/start-bitcoin-demo.sh

# Generate daily signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Review and approve signals
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

### Daily Workflow
1. **Morning**: Generate signals (5 minutes)
2. **Review**: Review signals (5 minutes)
3. **Execute**: Approve and execute (5 minutes)
4. **End of Day**: Review performance (5 minutes)

**Total Time**: ~20 minutes per day

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Start using the system for daily manual trading!

---

**Happy Trading!** 🚀

