# Bitcoin Signal Demo - Quick Reference

**Date**: 2025-11-12  
**Purpose**: Quick reference guide for daily Bitcoin signal generation and trading

---

## 🚀 Quick Start (5 minutes)

### 1. Start Services
```bash
# Option A: Using script
./repo/main/scripts/start-bitcoin-demo.sh

# Option B: Manual
docker network create fks-network
cd repo/data && docker-compose up -d
cd repo/app && docker-compose up -d
cd repo/web && docker-compose up -d
```

### 2. Generate Daily Signals
```powershell
# Generate all signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Generate specific category
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -Categories @("swing")
```

### 3. Review Signals
- Check signals in `signals/` directory
- Review daily summary: `signals/daily_signals_summary_YYYYMMDD.json`
- Review signal details: Entry, TP, SL, Confidence, Rationale

### 4. Approve/Execute Signals
```bash
# Interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive

# Auto-approve
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
```

---

## 📊 API Endpoints

### Generate Signal
```bash
# Basic
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# With strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=scalp&strategy=ema_scalp&use_ai=false"
```

### Batch Signals
```bash
curl "http://localhost:8002/api/v1/signals/batch?symbols=BTCUSDT,ETHUSDT&category=swing&use_ai=false"
```

### Health Check
```bash
curl "http://localhost:8002/health"
curl "http://localhost:8003/health"
```

---

## 🎯 Strategies

### Available Strategies
- **RSI** - Relative Strength Index (swing trading)
- **MACD** - Moving Average Convergence Divergence (swing/long-term)
- **EMA Scalp** - Exponential Moving Average (scalp trading)
- **EMA Swing** - Exponential Moving Average (swing trading)
- **ASMBTR** - Advanced Strategy (fallback)

### Strategy Usage
```bash
# RSI Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# MACD Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"

# EMA Scalp Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=scalp&strategy=ema_scalp&use_ai=false"

# EMA Swing Strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=ema_swing&use_ai=false"
```

---

## 📈 Categories

### Scalp Trading
- **Timeframe**: 1 hour
- **Take Profit**: 0.5-1%
- **Stop Loss**: 0.5-1%
- **Default Strategy**: `ema_scalp`
- **Usage**: `category=scalp`

### Swing Trading
- **Timeframe**: 1 day
- **Take Profit**: 3.5%
- **Stop Loss**: 2.0%
- **Default Strategy**: `rsi`
- **Usage**: `category=swing`

### Long-Term Trading
- **Timeframe**: 1 week
- **Take Profit**: 10-20%
- **Stop Loss**: 5-10%
- **Default Strategy**: `macd`
- **Usage**: `category=long_term`

---

## 🛠️ CLI Tools

### Bitcoin Signal CLI Tool
```bash
# Generate signal
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed

# Interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive

# Auto-approve
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve

# Auto-reject
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --reject

# Output as JSON
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --json
```

### Daily Signal Generation Script
```powershell
# Generate all signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Generate specific categories
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -Categories @("swing")

# Generate without saving
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -NoSave

# Generate with AI enhancement
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT -UseAI
```

---

## 📁 File Structure

### Output Files
```
signals/
├── signals_scalp_YYYYMMDD.json               # Scalp signals
├── signals_swing_YYYYMMDD.json               # Swing signals
├── signals_long_term_YYYYMMDD.json           # Long-term signals
├── daily_signals_summary_YYYYMMDD.json       # Daily summary
├── approved_signals_YYYYMMDD.json            # Approved signals
└── rejected_signals_YYYYMMDD.json            # Rejected signals
```

### Scripts
```
repo/main/scripts/
├── bitcoin-signal-cli.py          # CLI tool
├── generate-daily-signals.ps1     # Daily signal generation (PowerShell)
├── generate-daily-signals.py      # Daily signal generation (Python)
├── test-bitcoin-signal.py         # Test script
├── start-bitcoin-demo.sh          # Startup script
└── start-bitcoin-demo.ps1         # PowerShell startup script
```

---

## 📊 Signal Format

### Signal Object
```json
{
  "symbol": "BTCUSDT",
  "signal_type": "BUY",
  "category": "swing",
  "strategy": "rsi",
  "entry_price": 103300.0,
  "take_profit": 106915.5,
  "stop_loss": 101234.0,
  "confidence": 0.65,
  "rationale": "MACD strong bullish momentum",
  "indicators": {
    "rsi": 29.5,
    "macd": -493.03,
    "signal": -557.99,
    "histogram": 64.96
  }
}
```

### Key Fields
- **symbol**: Trading symbol (e.g., BTCUSDT)
- **signal_type**: BUY, SELL, or HOLD
- **category**: scalp, swing, or long_term
- **strategy**: rsi, macd, ema_scalp, ema_swing, or asmbtr
- **entry_price**: Entry price for the trade
- **take_profit**: Take profit price
- **stop_loss**: Stop loss price
- **confidence**: Signal confidence (0-1)
- **rationale**: Signal rationale/explanation

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

## 📝 Daily Workflow

### Morning (5 minutes)
1. Start services (if not running)
2. Generate daily signals
3. Review signals from all categories

### Review (5 minutes)
1. Check entry price, TP, SL
2. Review confidence and rationale
3. Check indicators
4. Compare strategies

### Execute (5 minutes)
1. Approve/reject signals
2. Execute approved signals manually
3. Set stop loss and take profit
4. Monitor positions

### End of Day (5 minutes)
1. Review performance
2. Update trade log
3. Review signal accuracy
4. Plan next day

**Total Time**: ~20 minutes per day

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

---

## 📚 Documentation

### Quick Start
- `BITCOIN-QUICK-START.md` - Quick start guide
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow
- `BITCOIN-CLI-TOOL.md` - CLI tool documentation

### Features
- `BITCOIN-FEATURES-DOCUMENTATION.md` - Features documentation
- `BITCOIN-STRATEGIES-TEST-RESULTS.md` - Strategies test results

### Summaries
- `BITCOIN-DEMO-WORKING-SUMMARY.md` - Working summary
- `BITCOIN-DEMO-COMPLETE.md` - Completion summary
- `BITCOIN-DEMO-FINAL-SUMMARY.md` - Final summary

---

## ✅ Quick Checks

### Service Health
```bash
# Check all services
curl "http://localhost:8002/health"  # fks_app
curl "http://localhost:8003/health"  # fks_data
curl "http://localhost:8000/health"  # fks_web
```

### Signal Generation
```bash
# Test signal generation
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

### Data Service
```bash
# Test data service
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"
curl "http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
```

---

## 🚀 Common Commands

### Generate Signals
```bash
# Single signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Batch signals
curl "http://localhost:8002/api/v1/signals/batch?symbols=BTCUSDT,ETHUSDT&category=swing&use_ai=false"

# Daily script
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT
```

### Review Signals
```bash
# CLI tool
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed

# Interactive mode
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

### Approve Signals
```bash
# Auto-approve
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve

# Interactive approval
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

---

## 📞 Support

### Documentation
- Check `BITCOIN-QUICK-START.md` for setup
- Check `BITCOIN-DAILY-WORKFLOW.md` for workflow
- Check `BITCOIN-FEATURES-DOCUMENTATION.md` for features

### Troubleshooting
- Check service logs: `docker logs fks_app`
- Check service health: `curl "http://localhost:8002/health"`
- Check test scripts: `python repo/main/scripts/test-bitcoin-signal.py`

### Common Issues
- **Services not running**: Start services using `start-bitcoin-demo.sh`
- **No signals generated**: Check service logs and data service
- **CLI tool not working**: Install `requests` library: `pip install requests`

---

## 🎯 Success Criteria

### Minimum Viable
- ✅ Services running
- ✅ Signals generating
- ✅ API endpoints working
- ✅ CLI tools working
- ✅ Daily scripts working

### Production Ready
- ✅ Error handling
- ✅ File storage
- ✅ Summary generation
- ✅ Documentation complete
- ✅ Test scripts created

---

**Status**: ✅ **COMPLETE AND OPERATIONAL**

**Last Updated**: 2025-11-12

**Next Action**: Start using the system for daily manual trading!

---

## 🎉 Quick Tips

1. **Generate signals daily** - Use daily signal generation script
2. **Review all categories** - Check signals from scalp, swing, and long-term
3. **Compare strategies** - Test different strategies for same category
4. **Verify confidence** - Only trade signals with confidence > 60%
5. **Set stop losses** - Always set stop loss orders
6. **Risk management** - Risk 1-2% per trade
7. **Log decisions** - Keep record of approved/rejected signals
8. **Monitor performance** - Track signal accuracy and performance

---

**Happy Trading!** 🚀

