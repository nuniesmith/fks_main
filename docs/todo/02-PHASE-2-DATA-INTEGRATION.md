# Phase 2: Data Integration and Multi-Asset Handling
## Weeks 2-3 | Data Integration & Multi-Asset

**Duration**: 2-3 weeks (part-time)  
**Focus**: Gather and process data for diverse assets, ensuring BTC conversion and unified tracking  
**Goal**: Dashboard showing real-time asset data in BTC terms with sample diversified portfolio

---

## 🎯 Phase Objectives

1. Build data collection pipeline for multiple asset classes
2. Implement BTC conversion logic for unified tracking
3. Create correlation analysis for diversification
4. Build web dashboard for data visualization

---

## 📋 Task Breakdown

### Task 2.1: Data Collection Pipeline (Days 1-4)

**Objective**: Enhance fks_data or create portfolio-specific data collection

**Subtasks**:
- [ ] Set up data adapters for multiple sources:
  ```python
  # portfolio/src/data/adapters/coinmarketcap.py
  # portfolio/src/data/adapters/alphavantage.py
  # portfolio/src/data/adapters/yahoofinance.py
  # portfolio/src/data/adapters/coingecko.py
  ```
- [ ] Support multiple intervals:
  - Daily (for portfolio optimization)
  - Hourly (for swing signals)
  - Minute (for scalp signals, if needed)
- [ ] Implement caching layer (Redis or local cache):
  ```python
  # portfolio/src/data/cache.py
  def get_cached_price(symbol, interval):
      # Check Redis/local cache
      # Return cached if fresh (< 5 min for real-time)
  ```
- [ ] Add rate limiting to avoid API bans:
  - CoinGecko: 10-50 calls/minute (free tier)
  - Alpha Vantage: 5 calls/minute
  - Yahoo Finance: No official limit (be respectful)
- [ ] Handle API errors gracefully with retries
- [ ] Store historical data in database (SQLite or PostgreSQL)

**Milestone**: Script fetches data for 5-10 assets without errors

**Files to Create**:
- `portfolio/src/data/adapters/base.py` - Base adapter interface
- `portfolio/src/data/adapters/coinmarketcap.py`
- `portfolio/src/data/adapters/alphavantage.py`
- `portfolio/src/data/adapters/yahoofinance.py`
- `portfolio/src/data/adapters/coingecko.py`
- `portfolio/src/data/cache.py`
- `portfolio/src/data/storage.py` - Database storage
- `portfolio/tests/test_data_adapters.py`

---

### Task 2.2: BTC Conversion Logic (Days 5-7)

**Objective**: Convert all asset values to BTC equivalents for unified tracking

**Subtasks**:
- [ ] Create BTC conversion service:
  ```python
  # portfolio/src/data/btc_converter.py
  class BTCConverter:
      def to_btc(self, amount, asset_symbol, timestamp):
          # Fetch BTC price at timestamp
          # Convert: amount / btc_price
          return btc_amount
      
      def from_btc(self, btc_amount, target_symbol, timestamp):
          # Convert BTC to target asset
          return amount
  ```
- [ ] Implement unified portfolio value calculation:
  ```python
  # portfolio/src/portfolio/portfolio_value.py
  def calculate_portfolio_value_in_btc(holdings):
      total_btc = 0
      for asset, amount in holdings.items():
          btc_value = converter.to_btc(amount, asset, current_time)
          total_btc += btc_value
      return total_btc
  ```
- [ ] Track portfolio performance in BTC terms:
  - Daily BTC value
  - BTC-denominated returns
  - BTC allocation percentage
- [ ] Create conversion cache to minimize API calls

**Milestone**: All asset values displayed in BTC terms

**Files to Create**:
- `portfolio/src/data/btc_converter.py`
- `portfolio/src/portfolio/portfolio_value.py`
- `portfolio/tests/test_btc_conversion.py`

**Example Output**:
```json
{
  "portfolio_value_btc": 2.5,
  "holdings": {
    "BTC": 1.25,
    "ETH": 0.5,
    "SPY": 0.5,
    "SOL": 0.25
  },
  "btc_allocation": 0.50
}
```

---

### Task 2.3: Asset Diversification Logic (Days 8-10)

**Objective**: Categorize assets and optimize for low correlation with BTC

**Subtasks**:
- [ ] Categorize assets:
  ```python
  # portfolio/src/portfolio/asset_categories.py
  ASSET_CATEGORIES = {
      "high_vol_crypto": ["SOL", "AVAX", "MATIC"],
      "stable_crypto": ["BTC", "ETH"],
      "stocks": ["SPY", "QQQ", "AAPL"],
      "commodities": ["GLD", "SLV"],
      "stablecoins": ["USDT", "USDC"]
  }
  ```
- [ ] Calculate correlation matrix:
  ```python
  # portfolio/src/optimization/correlation.py
  import pandas as pd
  import numpy as np
  from scipy.stats import pearsonr
  
  def calculate_correlation_matrix(assets, lookback_days=90):
      # Fetch historical prices
      # Calculate pairwise correlations
      # Return matrix
  ```
- [ ] Optimize for low BTC correlation:
  - Select assets with correlation < 0.5 to BTC
  - Ensure diversification across categories
- [ ] Implement rebalancing logic:
  ```python
  # portfolio/src/portfolio/rebalancing.py
  def rebalance_to_btc(portfolio, target_btc_pct=0.50):
      # Calculate current BTC allocation
      # If below target, sell other assets to buy BTC
      # If above target, sell BTC to diversify
  ```

**Milestone**: Correlation matrix calculated and diversification optimized

**Files to Create**:
- `portfolio/src/portfolio/asset_categories.py`
- `portfolio/src/optimization/correlation.py`
- `portfolio/src/portfolio/rebalancing.py`
- `portfolio/tests/test_diversification.py`

---

### Task 2.4: Web Dashboard Integration (Days 11-14)

**Objective**: Create dashboard in fks_web showing real-time asset data

**Subtasks**:
- [ ] Create Django views for portfolio data:
  ```python
  # fks_web/src/portfolio/views.py
  def portfolio_dashboard(request):
      # Fetch current portfolio
      # Calculate BTC values
      # Return context
  ```
- [ ] Create template for dashboard:
  ```html
  <!-- fks_web/src/templates/portfolio/dashboard.html -->
  <div class="portfolio-overview">
      <h2>Portfolio Value: {{ portfolio_value_btc }} BTC</h2>
      <div class="asset-list">
          {% for asset in holdings %}
          <div class="asset-card">
              <span>{{ asset.symbol }}</span>
              <span>{{ asset.btc_value }} BTC</span>
              <span>{{ asset.percentage }}%</span>
          </div>
          {% endfor %}
      </div>
  </div>
  ```
- [ ] Add real-time price updates (WebSocket or polling):
  - Update prices every 30 seconds
  - Show price changes (green/red)
- [ ] Display correlation matrix visualization:
  - Use Chart.js or D3.js for heatmap
- [ ] Add asset selection interface:
  - Dropdown to add/remove assets
  - Real-time portfolio update

**Milestone**: Dashboard displays real-time asset data in BTC terms with sample portfolio

**Files to Modify**:
- `fks_web/src/urls.py` - Add portfolio routes
- `fks_web/src/portfolio/views.py` - Create views
- `fks_web/src/templates/portfolio/dashboard.html` - Dashboard template
- `fks_web/src/static/js/portfolio.js` - Frontend logic

---

## ✅ Phase 2 Milestone

**Deliverable**: Dashboard in fks_web showing real-time asset data in BTC terms, with a sample diversified portfolio. Data ingestion working for 5-10 assets.

**Success Criteria**:
- [ ] Dashboard loads without errors
- [ ] Real-time prices displayed (updates every 30s)
- [ ] All values shown in BTC terms
- [ ] Correlation matrix visualized
- [ ] Sample portfolio displayed (5-10 assets)
- [ ] Data ingestion tested for multiple sources

**URL to Access**:
```
http://localhost:8000/portfolio/dashboard
```

---

## 🔧 Technical Stack

- **Data Sources**: CoinGecko, Alpha Vantage, Yahoo Finance
- **Caching**: Redis (if available) or local file cache
- **Database**: SQLite (development) or PostgreSQL (production)
- **Frontend**: Django templates + Chart.js/D3.js
- **Real-time**: WebSocket (Django Channels) or polling

---

## 📚 References

- [CoinGecko API Documentation](https://www.coingecko.com/en/api)
- [Alpha Vantage API](https://www.alphavantage.co/documentation/)
- [Yahoo Finance Python Library](https://pypi.org/project/yfinance/)

---

## 🚦 Next Phase

Once Phase 2 is complete, proceed to [03-PHASE-3-SIGNAL-GENERATION.md](03-PHASE-3-SIGNAL-GENERATION.md)

---

**Estimated Effort**: 30-40 hours (part-time over 2-3 weeks)

