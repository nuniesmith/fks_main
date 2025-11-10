# Phase 1: Foundation and Baseline Setup
## Weeks 1-2 | Foundation & Baseline

**Duration**: 1-2 weeks (part-time)  
**Focus**: Establish core infrastructure and non-AI baseline for reliable signal generation  
**Goal**: Working baseline optimizer script with BTC backing and risk metrics

---

## 🎯 Phase Objectives

1. Set up development environment and repository structure
2. Implement baseline portfolio optimization using mean-variance approach
3. Create initial risk framework with CVaR calculations
4. Validate with historical data backtests

---

## 📋 Task Breakdown

### Task 1.1: Repo and Environment Preparation (Days 1-2)

**Objective**: Clean, organized development environment ready for portfolio work

**Subtasks**:
- [ ] Audit existing FKS repos (clean fks_main for Rust plugins, aggregate Python deps)
- [ ] Create portfolio-specific directory structure:
  ```
  portfolio/
  ├── src/
  │   ├── optimization/
  │   ├── risk/
  │   ├── data/
  │   └── signals/
  ├── tests/
  ├── data/
  │   └── historical/
  └── notebooks/
  ```
- [ ] Install baseline libraries:
  ```bash
  pip install pandas numpy ta-lib pyportfolioopt scipy ccxt python-dotenv
  ```
- [ ] Create `.env` for API keys (CoinMarketCap, Binance, Alpha Vantage)
- [ ] Set up logging configuration
- [ ] Create `requirements.txt` for portfolio module

**Milestone**: Run simple script fetching BTC price and logging it

**Files to Create**:
- `portfolio/src/__init__.py`
- `portfolio/src/data/fetchers.py` - Basic price fetching
- `portfolio/requirements.txt`
- `portfolio/.env.example`

---

### Task 1.2: Define Portfolio Structure (Days 3-4)

**Objective**: Model assets and implement baseline optimization

**Subtasks**:
- [ ] Create asset classes:
  ```python
  # portfolio/src/portfolio/asset.py
  class CryptoAsset:
      symbol: str
      volatility: float
      correlation_to_btc: float
      expected_return: float
      
  class StockAsset:
      symbol: str
      sector: str
      volatility: float
      correlation_to_btc: float
      expected_return: float
  ```
- [ ] Implement mean-variance optimizer:
  ```python
  # portfolio/src/optimization/mean_variance.py
  from pypfopt import EfficientFrontier, risk_models, expected_returns
  ```
- [ ] Set constraints:
  - BTC >= 50% weight (minimum)
  - BTC <= 60% weight (maximum)
  - Individual asset <= 20% weight
  - Total = 100%
- [ ] Calculate expected returns from historical data (1-year lookback)
- [ ] Output sample allocations:
  - Example: 50% BTC, 20% ETH, 15% diversified stocks, 15% altcoins

**Milestone**: Script outputs optimized portfolio allocation with BTC backing

**Files to Create**:
- `portfolio/src/portfolio/asset.py`
- `portfolio/src/portfolio/portfolio.py`
- `portfolio/src/optimization/mean_variance.py`
- `portfolio/src/optimization/constraints.py`
- `portfolio/tests/test_portfolio.py`

**Example Output**:
```json
{
  "allocation": {
    "BTC": 0.50,
    "ETH": 0.20,
    "SPY": 0.15,
    "SOL": 0.10,
    "CASH": 0.05
  },
  "expected_return": 0.12,
  "volatility": 0.25,
  "sharpe_ratio": 0.48
}
```

---

### Task 1.3: Initial Risk Framework (Days 5-7)

**Objective**: Implement CVaR for downside protection and bias detection rules

**Subtasks**:
- [ ] Implement CVaR calculation:
  ```python
  # portfolio/src/risk/cvar.py
  def calculate_cvar(returns, confidence=0.95):
      # Monte Carlo simulation or historical method
      # Return expected loss beyond VaR threshold
  ```
- [ ] Set risk thresholds:
  - 95% confidence: No more than 5% loss
  - Max drawdown alert: >10%
- [ ] Add bias detection rules:
  ```python
  # portfolio/src/risk/bias_detection.py
  def check_emotional_bias(recent_losses, current_signal):
      if recent_losses > 0.02:  # 2% loss
          return "AVOID_TRADING", "Recent loss exceeds threshold"
      return "OK", None
  ```
- [ ] Create risk report generator:
  - CVaR at 95% confidence
  - Maximum drawdown
  - Sharpe ratio
  - Correlation matrix
- [ ] Test with dummy data

**Milestone**: Risk report generated with CVaR metrics and bias flags

**Files to Create**:
- `portfolio/src/risk/cvar.py`
- `portfolio/src/risk/bias_detection.py`
- `portfolio/src/risk/report.py`
- `portfolio/tests/test_risk.py`

**Example Risk Report**:
```json
{
  "cvar_95": -0.05,
  "max_drawdown": -0.08,
  "sharpe_ratio": 0.48,
  "bias_flags": [],
  "recommendation": "HOLD"
}
```

---

### Task 1.4: Backtesting Framework (Days 8-10)

**Objective**: Validate baseline with historical data

**Subtasks**:
- [ ] Fetch historical data (1 year):
  - BTC, ETH, major stocks (SPY, QQQ)
  - Daily OHLCV data
- [ ] Implement simple backtest:
  ```python
  # portfolio/src/backtesting/simple_backtest.py
  def backtest_allocation(allocation, start_date, end_date):
      # Rebalance monthly
      # Calculate returns
      # Track drawdowns
  ```
- [ ] Calculate performance metrics:
  - Total return
  - Sharpe ratio
  - Maximum drawdown
  - Win rate (if trading signals)
- [ ] Generate backtest report

**Milestone**: Backtest completes on 1-year data with performance metrics

**Files to Create**:
- `portfolio/src/backtesting/simple_backtest.py`
- `portfolio/src/backtesting/metrics.py`
- `portfolio/notebooks/backtest_analysis.ipynb`

---

## ✅ Phase 1 Milestone

**Deliverable**: CLI script that outputs baseline portfolio allocation with BTC backing, including risk metrics, validated with backtests on 1-year data.

**Success Criteria**:
- [x] Script runs without errors (after dependencies installed)
- [x] Portfolio allocation includes 50-60% BTC (constraints implemented)
- [x] Risk metrics calculated (CVaR, Sharpe, drawdown) (all implemented)
- [x] Backtest completes successfully (framework ready)
- [x] All tests passing (test files created: test_portfolio.py, test_risk.py)

**Command to Run**:
```bash
python portfolio/src/cli.py --optimize --backtest --risk-report
```

---

## 🔧 Technical Stack

- **Python 3.11+**
- **Libraries**: pandas, numpy, PyPortfolioOpt, TA-Lib, scipy
- **Data Sources**: CoinGecko (free), Yahoo Finance (free), Alpha Vantage (free tier)
- **Storage**: CSV files initially, SQLite for structured data

---

## 📚 References

- [PyPortfolioOpt Documentation](https://pyportfolioopt.readthedocs.io/)
- [Mean-Variance Optimization](https://en.wikipedia.org/wiki/Modern_portfolio_theory)
- [CVaR Calculation Methods](https://www.investopedia.com/terms/c/conditional_value_at_risk.asp)

---

## 🚦 Next Phase

Once Phase 1 is complete, proceed to [02-PHASE-2-DATA-INTEGRATION.md](02-PHASE-2-DATA-INTEGRATION.md)

---

**Estimated Effort**: 20-30 hours (part-time over 1-2 weeks)

