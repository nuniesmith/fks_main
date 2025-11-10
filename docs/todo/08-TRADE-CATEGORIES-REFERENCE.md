# Trade Categories Reference
## Detailed Definitions and Examples

**Last Updated**: 2025-01-XX  
**Purpose**: Reference guide for trade category definitions used in signal generation

---

## 📊 Trade Category Overview

| Category | Key Indicators | Typical TP/SL Range | Example Assets | Risk Level | Hold Time |
|----------|----------------|---------------------|----------------|------------|-----------|
| **Scalp/Intraday** | EMA Crossover, Volume Spikes | 0.5-1% from entry | High-liq crypto (BTC/USDT) | High | Minutes to hours |
| **Swing** | RSI, MACD | 2-5% from entry | Altcoins (SOL, AVAX) | Medium | Days to weeks |
| **Long-Term** | Fundamentals, 200-day MA | 10-20% from entry | BTC, ETH, Stocks | Low | Months to years |

---

## 🔍 Detailed Category Definitions

### 1. Scalp/Intraday Trading

**Definition**: High-frequency, short-term trades targeting small price movements

**Characteristics**:
- **Timeframe**: Minutes to hours
- **Entry Method**: Technical indicators (EMA crossovers, volume spikes)
- **Profit Target**: 0.5-1% from entry
- **Stop Loss**: 0.5-1% from entry (tight)
- **Risk Level**: High (requires constant monitoring)
- **Capital Allocation**: 5-10% of portfolio max

**Indicators Used**:
```python
# EMA Crossover
ema5 = ta.EMA(close, 5)
ema13 = ta.EMA(close, 13)
signal = ema5[-1] > ema13[-1] and ema5[-2] <= ema13[-2]

# Volume Spike
volume_avg = ta.SMA(volume, 20)
volume_spike = volume[-1] > volume_avg[-1] * 1.5
```

**Example Signal**:
```json
{
  "asset": "BTC/USDT",
  "account": "futures",
  "entry": 45000.0,
  "take_profit": 45225.0,  // 0.5% target
  "stop_loss": 44775.0,     // 0.5% stop
  "trade_class": "SCALP",
  "rationale": "EMA 5/13 bullish crossover with volume spike",
  "timeframe": "1h"
}
```

**Best For**:
- High-liquidity assets (BTC, ETH, major pairs)
- Active trading sessions
- Experienced traders with time to monitor

**Risks**:
- High transaction costs (fees eat into small profits)
- Requires constant attention
- Emotional stress from frequent trading

---

### 2. Swing Trading

**Definition**: Medium-term trades based on trend following and momentum

**Characteristics**:
- **Timeframe**: Days to weeks
- **Entry Method**: RSI oversold/overbought, MACD crossovers
- **Profit Target**: 2-5% from entry
- **Stop Loss**: 2% from entry
- **Risk Level**: Medium
- **Capital Allocation**: 20-30% of portfolio

**Indicators Used**:
```python
# RSI Oversold
rsi = ta.RSI(close, 14)
buy_signal = rsi[-1] < 30  # Oversold

# MACD Crossover
macd, signal, hist = ta.MACD(close)
buy_signal = hist[-1] > 0 and hist[-2] <= 0  # Bullish crossover
```

**Example Signal**:
```json
{
  "asset": "SOL/USDT",
  "account": "spot",
  "entry": 150.0,
  "take_profit": 157.5,   // 5% target
  "stop_loss": 147.0,     // 2% stop
  "trade_class": "SWING",
  "rationale": "RSI oversold at 28, MACD bullish crossover",
  "timeframe": "4h"
}
```

**Best For**:
- Altcoins with good volatility
- Trend-following strategies
- Part-time traders

**Risks**:
- Overnight/weekend gaps
- Trend reversals
- Moderate drawdowns

---

### 3. Long-Term Trading

**Definition**: Fundamental-driven, BTC-focused holdings with wide stops

**Characteristics**:
- **Timeframe**: Months to years
- **Entry Method**: Fundamental analysis, 200-day moving average
- **Profit Target**: 10-20% from entry (or higher)
- **Stop Loss**: 10-20% from entry (wide, to weather volatility)
- **Risk Level**: Low (but large position sizes)
- **Capital Allocation**: 50-60% of portfolio (BTC-focused)

**Indicators Used**:
```python
# 200-day Moving Average
sma200 = ta.SMA(close, 200)
price_above_ma = close[-1] > sma200[-1]  # Bullish trend

# MACD Histogram for BTC
macd, signal, hist = ta.MACD(close)
btc_buy = hist[-1] > 0 and asset == "BTC"
```

**Example Signal**:
```json
{
  "asset": "BTC/USDT",
  "account": "spot",
  "entry": 45000.0,
  "take_profit": 51750.0,  // 15% target
  "stop_loss": 38250.0,     // 15% stop
  "trade_class": "LONG_TERM",
  "rationale": "BTC above 200-day MA, MACD histogram positive, fundamental outlook bullish",
  "timeframe": "1d"
}
```

**Best For**:
- BTC and major cryptocurrencies
- Long-term wealth building
- Passive investors

**Risks**:
- Large drawdowns during volatility
- Opportunity cost if wrong
- Requires patience

---

## 🎯 Account Selection Logic

### Spot vs Futures

**Spot Account** (Recommended for):
- Long-term holdings
- Swing trades (safer)
- Lower risk tolerance

**Futures Account** (Use for):
- Scalp trades (leverage)
- Short-term positions
- Experienced traders only

**Selection Algorithm**:
```python
def select_account(signal):
    if signal.trade_class == "LONG_TERM":
        return "spot"  # Always spot for long-term
    elif signal.trade_class == "SCALP":
        return "futures"  # Futures for leverage on scalps
    elif signal.trade_class == "SWING":
        return "spot"  # Default to spot for swing
    else:
        return "spot"  # Default
```

---

## 📈 Risk Management by Category

### Position Sizing

```python
def calculate_position_size(signal, portfolio_value, risk_per_trade=0.02):
    if signal.trade_class == "SCALP":
        max_risk = portfolio_value * 0.01  # 1% for scalps
    elif signal.trade_class == "SWING":
        max_risk = portfolio_value * 0.02  # 2% for swing
    elif signal.trade_class == "LONG_TERM":
        max_risk = portfolio_value * 0.05  # 5% for long-term (but larger positions)
    
    stop_distance = abs(signal.entry - signal.stop_loss)
    position_size = max_risk / stop_distance
    
    return position_size
```

### Maximum Concurrent Trades

- **Scalp**: 2-3 max (requires attention)
- **Swing**: 5-7 max
- **Long-Term**: 3-5 max (BTC + diversification)

---

## 🔄 Rebalancing by Category

### When to Rebalance

**Scalp Positions**:
- Close when TP or SL hit
- No rebalancing needed (short-term)

**Swing Positions**:
- Rebalance monthly
- Close if trend reverses

**Long-Term Positions**:
- Rebalance quarterly
- Add to BTC if allocation drops below 50%

---

## 📚 References

- [Top Trading Strategies for Scalping](https://www.investopedia.com/articles/active-trading/012815/top-technical-indicators-scalping-trading-strategy.asp)
- [Swing Trade Setup Ideas](https://tradewiththepros.com/swing-trade-setup-ideas/)
- [Long-Term Crypto Investment Strategies](https://www.investopedia.com/articles/investing/052014/basics-bitcoin-investing.asp)

---

**See Also**: [03-PHASE-3-SIGNAL-GENERATION.md](03-PHASE-3-SIGNAL-GENERATION.md) for implementation details

