# Phase 3: Signal Generation Intelligence
## Weeks 3-5 | Signal Generation

**Duration**: 3-5 weeks (part-time)  
**Focus**: Develop logic for trading signals with entry/TP/SL and trade categories  
**Goal**: Daily signals generated for manual review, backtested with 60-70% win rate

---

## 🎯 Phase Objectives

1. Define and implement trade category algorithms (scalp, swing, long-term)
2. Build signal engine generating actionable signals
3. Implement bias removal mechanisms
4. Validate with historical backtesting

---

## 📋 Task Breakdown

### Task 3.1: Trade Category Definitions (Days 1-3)

**Objective**: Define algorithms for each trade category

**Subtasks**:
- [ ] Implement scalp/intraday signals:
  ```python
  # portfolio/src/signals/scalp.py
  class ScalpSignalGenerator:
      def generate_signal(self, asset_data):
          # EMA 5/13 crossover
          ema5 = ta.EMA(asset_data.close, 5)
          ema13 = ta.EMA(asset_data.close, 13)
          
          if ema5[-1] > ema13[-1] and ema5[-2] <= ema13[-2]:
              entry = asset_data.close[-1]
              tp = entry * 1.005  # 0.5% target
              sl = entry * 0.995  # 0.5% stop
              return Signal(entry, tp, sl, "SCALP")
  ```
- [ ] Implement swing signals:
  ```python
  # portfolio/src/signals/swing.py
  class SwingSignalGenerator:
      def generate_signal(self, asset_data):
          # RSI < 30 for buy, RSI > 70 for sell
          rsi = ta.RSI(asset_data.close, 14)
          
          if rsi[-1] < 30:
              entry = asset_data.close[-1]
              tp = entry * 1.03  # 3% target
              sl = entry * 0.98  # 2% stop
              return Signal(entry, tp, sl, "SWING")
  ```
- [ ] Implement long-term signals:
  ```python
  # portfolio/src/signals/longterm.py
  class LongTermSignalGenerator:
      def generate_signal(self, asset_data):
          # MACD histogram for BTC buys
          macd, signal, hist = ta.MACD(asset_data.close)
          
          if hist[-1] > 0 and asset_data.symbol == "BTC":
              entry = asset_data.close[-1]
              tp = entry * 1.15  # 15% target (wide)
              sl = entry * 0.85  # 15% stop (wide)
              return Signal(entry, tp, sl, "LONG_TERM")
  ```
- [ ] Create signal class:
  ```python
  # portfolio/src/signals/signal.py
  @dataclass
  class Signal:
      asset: str
      account: str  # "spot" or "futures"
      entry: float
      take_profit: float
      stop_loss: float
      trade_class: str  # "SCALP", "SWING", "LONG_TERM"
      rationale: str
      timestamp: datetime
  ```

**Milestone**: All three signal generators implemented and tested

**Files to Create**:
- `portfolio/src/signals/signal.py` - Signal data class
- `portfolio/src/signals/scalp.py`
- `portfolio/src/signals/swing.py`
- `portfolio/src/signals/longterm.py`
- `portfolio/src/signals/base.py` - Base generator interface
- `portfolio/tests/test_signals.py`

**Reference**: See [08-TRADE-CATEGORIES-REFERENCE.md](08-TRADE-CATEGORIES-REFERENCE.md) for detailed definitions

---

### Task 3.2: Signal Engine (Days 4-7)

**Objective**: Build main signal engine that scans assets and generates signals

**Subtasks**:
- [ ] Create signal engine orchestrator:
  ```python
  # portfolio/src/signals/engine.py
  class SignalEngine:
      def __init__(self):
          self.scalp_gen = ScalpSignalGenerator()
          self.swing_gen = SwingSignalGenerator()
          self.longterm_gen = LongTermSignalGenerator()
      
      def scan_assets(self, assets):
          signals = []
          for asset in assets:
              data = self.data_fetcher.get_data(asset)
              
              # Try each category
              scalp_signal = self.scalp_gen.generate_signal(data)
              if scalp_signal:
                  signals.append(scalp_signal)
              
              # ... similar for swing and long-term
          
          return signals
  ```
- [ ] Implement account selection logic:
  ```python
  # portfolio/src/signals/account_selector.py
  def select_account(signal):
      if signal.trade_class == "LONG_TERM":
          return "spot"  # Spot for long-term holds
      elif signal.trade_class == "SCALP":
          return "futures"  # Futures for leverage
      else:
          return "spot"  # Default to spot
  ```
- [ ] Add signal filtering:
  - Filter by risk level
  - Filter by asset category
  - Filter by correlation to BTC
- [ ] Generate signal JSON output:
  ```json
  {
    "asset": "SOL/USDT",
    "account": "futures",
    "entry": 150.5,
    "take_profit": 152.0,
    "stop_loss": 149.0,
    "trade_class": "swing",
    "rationale": "RSI oversold, EMA crossover bullish",
    "timestamp": "2025-01-15T10:30:00Z"
  }
  ```

**Milestone**: Signal engine generates daily signals for manual review

**Files to Create**:
- `portfolio/src/signals/engine.py`
- `portfolio/src/signals/account_selector.py`
- `portfolio/src/signals/filter.py`
- `portfolio/src/signals/output.py` - JSON/formatted output

---

### Task 3.3: Bias Removal Mechanisms (Days 8-10)

**Objective**: Add checks to prevent emotional trading decisions

**Subtasks**:
- [ ] Implement loss streak detection:
  ```python
  # portfolio/src/risk/bias_detection.py
  def check_loss_streak(trade_history):
      recent_trades = trade_history[-5:]  # Last 5 trades
      losses = [t for t in recent_trades if t.pnl < 0]
      
      if len(losses) >= 3:
          return "AVOID_TRADING", "Loss streak detected"
      return "OK", None
  ```
- [ ] Add rule-based filters:
  ```python
  # portfolio/src/signals/bias_filters.py
  class BiasFilter:
      def filter_signal(self, signal, user_state):
          # Check recent losses
          if user_state.recent_loss > 0.02:  # 2% loss
              return None, "Recent loss exceeds threshold"
          
          # Check position size
          if signal.position_size > user_state.capital * 0.02:  # 2% max
              return None, "Position size too large"
          
          # Check trading frequency
          if user_state.trades_today > 5:
              return None, "Daily trade limit reached"
          
          return signal, None
  ```
- [ ] Log all decisions for review:
  ```python
  # portfolio/src/signals/decision_logger.py
  def log_decision(signal, action, reason):
      log_entry = {
          "timestamp": datetime.now(),
          "signal": signal.to_dict(),
          "action": action,  # "ACCEPT", "REJECT", "MODIFY"
          "reason": reason
      }
      # Store in database or file
  ```
- [ ] Create bias report:
  - Number of signals filtered
  - Reasons for filtering
  - Override frequency (if user overrides)

**Milestone**: Bias detection active and logging decisions

**Files to Create**:
- `portfolio/src/signals/bias_filters.py`
- `portfolio/src/signals/decision_logger.py`
- `portfolio/src/risk/bias_detection.py` (extend from Phase 1)

---

### Task 3.4: Backtesting Signals (Days 11-14)

**Objective**: Validate signal quality with historical data

**Subtasks**:
- [ ] Extend backtesting framework from Phase 1:
  ```python
  # portfolio/src/backtesting/signal_backtest.py
  class SignalBacktest:
      def run(self, start_date, end_date):
          signals = []
          for date in date_range(start_date, end_date):
              # Generate signals for this date
              daily_signals = self.engine.scan_assets(assets, date)
              signals.extend(daily_signals)
          
          # Simulate execution
          results = self.simulate_execution(signals)
          
          # Calculate metrics
          win_rate = len([r for r in results if r.pnl > 0]) / len(results)
          return {
              "win_rate": win_rate,
              "total_trades": len(results),
              "avg_return": np.mean([r.pnl for r in results])
          }
  ```
- [ ] Calculate performance metrics:
  - Win rate (target: 60-70%)
  - Average return per trade
  - Sharpe ratio
  - Maximum drawdown
- [ ] Generate backtest report:
  - Performance by trade category
  - Best/worst performing assets
  - Recommendations for improvement

**Milestone**: Backtest shows 60-70% win rate in simulations

**Files to Create**:
- `portfolio/src/backtesting/signal_backtest.py`
- `portfolio/src/backtesting/execution_simulator.py`
- `portfolio/notebooks/signal_backtest_analysis.ipynb`

---

## ✅ Phase 3 Milestone

**Deliverable**: Script or API endpoint generating daily signals for manual review. Backtested on historical data with 60-70% win rate target.

**Success Criteria**:
- [ ] Signal engine generates signals for multiple assets
- [ ] Signals include all required fields (asset, account, entry, TP, SL, class)
- [ ] Bias filters active and logging
- [ ] Backtest completes successfully
- [ ] Win rate meets target (60-70%) or close with improvement plan

**Command to Run**:
```bash
# Generate signals
python portfolio/src/cli.py --generate-signals

# Run backtest
python portfolio/src/cli.py --backtest-signals --start 2024-01-01 --end 2024-12-31
```

---

## 📊 Trade Category Reference

| Category | Indicators | TP/SL Range | Example Assets | Risk Level |
|----------|------------|-------------|----------------|-------------|
| Scalp/Intraday | EMA Crossover, Volume | 0.5-1% | BTC/USDT, ETH/USDT | High |
| Swing | RSI, MACD | 2-5% | SOL, AVAX, altcoins | Medium |
| Long-Term | Fundamentals, 200-day MA | 10-20% | BTC, ETH, Stocks | Low |

**See**: [08-TRADE-CATEGORIES-REFERENCE.md](08-TRADE-CATEGORIES-REFERENCE.md) for detailed definitions

---

## 🔧 Technical Stack

- **TA-Lib**: Technical indicators
- **Pandas**: Data manipulation
- **NumPy**: Numerical calculations
- **Backtesting**: Custom framework (can integrate Backtrader later)

---

## 📚 References

- [TA-Lib Documentation](https://ta-lib.org/)
- [Top Trading Strategies for Scalping](https://www.investopedia.com/articles/active-trading/012815/top-technical-indicators-scalping-trading-strategy.asp)
- [Swing Trade Setup Ideas](https://tradewiththepros.com/swing-trade-setup-ideas/)

---

## 🚦 Next Phase

Once Phase 3 is complete, proceed to [04-PHASE-4-USER-GUIDANCE.md](04-PHASE-4-USER-GUIDANCE.md)

---

**Estimated Effort**: 40-50 hours (part-time over 3-5 weeks)

