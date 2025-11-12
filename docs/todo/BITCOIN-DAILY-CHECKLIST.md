# Bitcoin Signal Demo - Daily Checklist

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Daily checklist for Bitcoin signal generation and trading workflow

---

## 📋 Daily Checklist

### ☐ Morning Routine (5 minutes)

#### 1. Start Services
- [ ] Check if services are running: `docker ps | grep fks_`
- [ ] Start services if needed: `./repo/main/scripts/start-bitcoin-demo.sh`
- [ ] Verify services are healthy: `curl "http://localhost:8002/health"`

#### 2. Generate Daily Signals
- [ ] Generate signals for all categories: `.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT`
- [ ] Verify signals were generated: `ls signals/`
- [ ] Check daily summary: `cat signals/daily_signals_summary_YYYYMMDD.json`

#### 3. Review Signals
- [ ] Review signals from all categories: `.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed`
- [ ] Check entry price, TP, SL, confidence
- [ ] Review rationale and indicators
- [ ] Compare strategies for same category

---

### ☐ Signal Review (5 minutes)

#### 1. Review Signal Details
- [ ] **Scalp Trading**:
  - [ ] Entry price: $XXX
  - [ ] Take profit: $XXX (0.5-1%)
  - [ ] Stop loss: $XXX (0.5-1%)
  - [ ] Confidence: XX%
  - [ ] Rationale: XXX
  - [ ] Indicators: RSI, MACD, EMA

- [ ] **Swing Trading**:
  - [ ] Entry price: $XXX
  - [ ] Take profit: $XXX (3.5%)
  - [ ] Stop loss: $XXX (2.0%)
  - [ ] Confidence: XX%
  - [ ] Rationale: XXX
  - [ ] Indicators: RSI, MACD, EMA

- [ ] **Long-Term Trading**:
  - [ ] Entry price: $XXX
  - [ ] Take profit: $XXX (10-20%)
  - [ ] Stop loss: $XXX (5-10%)
  - [ ] Confidence: XX%
  - [ ] Rationale: XXX
  - [ ] Indicators: RSI, MACD, EMA

#### 2. Compare Strategies
- [ ] Compare RSI vs MACD vs EMA for same category
- [ ] Check confidence levels
- [ ] Review risk/reward ratios
- [ ] Consider market conditions

#### 3. Verify Signal Quality
- [ ] Confidence > 60%?
- [ ] Risk/Reward > 1.5:1?
- [ ] Clear rationale?
- [ ] Strong indicators?
- [ ] Volume confirmation?

---

### ☐ Signal Approval (5 minutes)

#### 1. Approve/Reject Signals
- [ ] Review signals: `.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed`
- [ ] Approve/reject signals: `.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action interactive`
- [ ] Document approval/rejection reasons
- [ ] Verify approved signals: `ls signals/approved/`
- [ ] Verify rejected signals: `ls signals/rejected/`

#### 2. Signal Decision Matrix
- [ ] **Excellent** (Confidence > 80%, R/R > 2:1): Approve
- [ ] **Good** (Confidence > 70%, R/R > 1.5:1): Approve
- [ ] **Fair** (Confidence > 60%, R/R > 1.2:1): Review
- [ ] **Poor** (Confidence < 60%, R/R < 1.2:1): Reject

#### 3. Document Decisions
- [ ] Log approved signals with reasons
- [ ] Log rejected signals with reasons
- [ ] Update trade log
- [ ] Plan execution

---

### ☐ Manual Execution (5 minutes)

#### 1. Execute Approved Signals
- [ ] Review approved signals: `cat signals/approved/approved_YYYYMMDD.json`
- [ ] Execute trades manually on exchange
- [ ] Set stop loss orders
- [ ] Set take profit orders
- [ ] Monitor positions

#### 2. Trade Execution Checklist
- [ ] Verify entry price
- [ ] Set stop loss
- [ ] Set take profit
- [ ] Calculate position size
- [ ] Risk 1-2% per trade
- [ ] Log trade execution

#### 3. Position Management
- [ ] Monitor open positions
- [ ] Adjust stop loss if needed
- [ ] Take profit when target reached
- [ ] Close positions if stop loss hit
- [ ] Update trade log

---

### ☐ End of Day (5 minutes)

#### 1. Review Performance
- [ ] Check executed trades: `cat signals/approved/approved_YYYYMMDD.json`
- [ ] Review signal accuracy: `.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT`
- [ ] Calculate win rate
- [ ] Review P&L
- [ ] Update performance metrics

#### 2. Update Trade Log
- [ ] Log executed trades
- [ ] Document decisions
- [ ] Update performance metrics
- [ ] Plan next day

#### 3. Review Signal Accuracy
- [ ] Compare signals vs actual price movements
- [ ] Identify successful signals
- [ ] Learn from mistakes
- [ ] Adjust strategy if needed

---

## 📊 Performance Tracking

### Daily Metrics
- [ ] Total signals generated
- [ ] Signals approved
- [ ] Signals rejected
- [ ] Signals pending
- [ ] Approval rate
- [ ] Average confidence
- [ ] Win rate
- [ ] Total P&L

### Weekly Metrics
- [ ] Weekly win rate
- [ ] Weekly P&L
- [ ] Average R/R
- [ ] Best performing strategy
- [ ] Best performing category
- [ ] Signal accuracy

### Monthly Metrics
- [ ] Monthly win rate
- [ ] Monthly P&L
- [ ] Overall performance
- [ ] Strategy optimization
- [ ] Category optimization
- [ ] Performance trends

---

## 🔧 Quick Commands

### Morning Routine
```bash
# Start services
./repo/main/scripts/start-bitcoin-demo.sh

# Generate daily signals
.\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT

# Review signals
.\repo\main\scripts\review-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed
```

### Signal Approval
```bash
# Approve/reject signals
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action interactive

# Auto-approve all
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action approve

# Auto-reject all
.\repo\main\scripts\approve-signals.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Action reject -Reason "Manual rejection"
```

### Performance Tracking
```bash
# Track performance
.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Detailed

# Summary only
.\repo\main\scripts\track-performance.ps1 -Date YYYYMMDD -Symbol BTCUSDT -Summary
```

---

## 📝 Notes

### Signal Quality Criteria
- **Confidence**: Should be > 60%
- **Risk/Reward**: Should be > 1.5:1
- **Rationale**: Should be clear and logical
- **Indicators**: Should be strong and consistent
- **Volume**: Should confirm signal

### Risk Management
- **Position Sizing**: Risk 1-2% per trade
- **Stop Loss**: Always set stop loss
- **Take Profit**: Set take profit targets
- **Diversification**: Don't put all capital in one signal
- **Risk Management**: Follow risk management rules

### Best Practices
- **Generate signals daily**: Use daily signal generation script
- **Review all signals**: Check signals from all categories
- **Compare strategies**: Test different strategies for same category
- **Verify confidence**: Only trade signals with confidence > 60%
- **Set stop losses**: Always set stop loss orders
- **Log decisions**: Keep record of approved/rejected signals
- **Monitor performance**: Track signal accuracy and performance

---

## 🎯 Success Criteria

### Daily
- [ ] All signals generated
- [ ] All signals reviewed
- [ ] All signals approved/rejected
- [ ] All trades executed
- [ ] Performance tracked
- [ ] Trade log updated

### Weekly
- [ ] Weekly performance reviewed
- [ ] Win rate calculated
- [ ] P&L calculated
- [ ] Strategy optimization
- [ ] Performance trends analyzed

### Monthly
- [ ] Monthly performance reviewed
- [ ] Overall performance analyzed
- [ ] Strategy optimization
- [ ] Category optimization
- [ ] Performance trends analyzed

---

## ✅ Checklist Summary

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

## 📞 Support

### Documentation
- Check `BITCOIN-GETTING-STARTED.md` for setup
- Check `BITCOIN-QUICK-REFERENCE.md` for daily commands
- Check `BITCOIN-DAILY-WORKFLOW.md` for workflow

### Troubleshooting
- Check service logs: `docker logs fks_app`
- Check service health: `curl "http://localhost:8002/health"`
- Check test scripts: `python repo/main/scripts/test-bitcoin-signal.py`

### Common Issues
- **Services not running**: Start services using `start-bitcoin-demo.sh`
- **No signals generated**: Check service logs and data service
- **CLI tool not working**: Install `requests` library: `pip install requests`

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Start using the daily checklist for Bitcoin signal generation and trading!

---

**Happy Trading!** 🚀

