# Bitcoin Signal Demo - Features Documentation

**Date**: 2025-11-12  
**Status**: ✅ **COMPLETE**  
**Purpose**: Comprehensive documentation of all available features and options

---

## 📋 Table of Contents

1. [Strategies](#strategies)
2. [Signal Categories](#signal-categories)
3. [API Endpoints](#api-endpoints)
4. [CLI Tools](#cli-tools)
5. [Daily Workflow Scripts](#daily-workflow-scripts)
6. [Configuration Options](#configuration-options)
7. [Signal Output Format](#signal-output-format)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)

---

## 🎯 Strategies

### Available Strategies

#### 1. RSI (Relative Strength Index)
- **Category**: Swing trading
- **Description**: Identifies overbought/oversold conditions
- **Parameters**: RSI < 30 (oversold, BUY), RSI > 70 (overbought, SELL)
- **Usage**: `strategy=rsi`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
  ```

#### 2. MACD (Moving Average Convergence Divergence)
- **Category**: Swing/Long-term trading
- **Description**: Identifies trend changes and momentum
- **Parameters**: MACD line crossover, histogram momentum
- **Usage**: `strategy=macd`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=macd&use_ai=false"
  ```

#### 3. EMA (Exponential Moving Average)
- **Category**: Scalp/Swing trading
- **Description**: Identifies trend direction using exponential moving averages
- **Parameters**: EMA 12 vs EMA 26 crossover
- **Usage**: 
  - `strategy=ema_scalp` (for scalp trading)
  - `strategy=ema_swing` (for swing trading)
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=scalp&strategy=ema_scalp&use_ai=false"
  ```

#### 4. ASMBTR (Advanced Strategy)
- **Category**: Fallback strategy
- **Description**: Advanced trading strategy (fallback)
- **Usage**: `strategy=asmbtr` (or auto-select if no strategy specified)
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=asmbtr&use_ai=false"
  ```

#### 5. Auto-Select (Default)
- **Category**: All categories
- **Description**: Automatically selects best strategy based on category
- **Usage**: No strategy parameter (default)
- **Default Mapping**:
  - `scalp` → `ema_scalp`
  - `swing` → `rsi`
  - `long_term` → `macd`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
  ```

---

## 📊 Signal Categories

### 1. Scalp Trading
- **Timeframe**: 1 hour
- **Take Profit**: 0.5-1%
- **Stop Loss**: 0.5-1%
- **Risk/Reward**: 1:1
- **Default Strategy**: `ema_scalp`
- **Usage**: `category=scalp`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=scalp&use_ai=false"
  ```

### 2. Swing Trading
- **Timeframe**: 1 day
- **Take Profit**: 3.5%
- **Stop Loss**: 2.0%
- **Risk/Reward**: ~1.75:1
- **Default Strategy**: `rsi`
- **Usage**: `category=swing`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
  ```

### 3. Long-Term Trading
- **Timeframe**: 1 week
- **Take Profit**: 10-20%
- **Stop Loss**: 5-10%
- **Risk/Reward**: 2:1
- **Default Strategy**: `macd`
- **Usage**: `category=long_term`
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=long_term&use_ai=false"
  ```

---

## 🔌 API Endpoints

### 1. Get Latest Signal
- **Endpoint**: `GET /api/v1/signals/latest/{symbol}`
- **Parameters**:
  - `symbol` (path): Trading symbol (e.g., BTCUSDT)
  - `category` (query): Trade category (scalp, swing, long_term)
  - `strategy` (query, optional): Strategy to use (rsi, macd, ema_scalp, ema_swing, asmbtr)
  - `use_ai` (query, optional): Use AI enhancement (true/false, default: true)
- **Response**: Signal object with all details
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"
  ```

### 2. Generate Signal (POST)
- **Endpoint**: `POST /api/v1/signals/generate`
- **Request Body**:
  ```json
  {
    "symbol": "BTCUSDT",
    "category": "swing",
    "strategy": "rsi",
    "use_ai": false,
    "market_data": null
  }
  ```
- **Response**: Signal object with all details
- **Example**:
  ```bash
  curl -X POST "http://localhost:8002/api/v1/signals/generate" \
    -H "Content-Type: application/json" \
    -d '{"symbol":"BTCUSDT","category":"swing","strategy":"rsi","use_ai":false}'
  ```

### 3. Batch Signals
- **Endpoint**: `GET /api/v1/signals/batch`
- **Parameters**:
  - `symbols` (query): Comma-separated symbols (e.g., BTCUSDT,ETHUSDT)
  - `category` (query): Trade category (scalp, swing, long_term)
  - `strategy` (query, optional): Strategy to use
  - `use_ai` (query, optional): Use AI enhancement (true/false)
- **Response**: Array of signals
- **Example**:
  ```bash
  curl "http://localhost:8002/api/v1/signals/batch?symbols=BTCUSDT,ETHUSDT&category=swing&use_ai=false"
  ```

---

## 🛠️ CLI Tools

### 1. Bitcoin Signal CLI Tool
- **Script**: `repo/main/scripts/bitcoin-signal-cli.py`
- **Purpose**: Interactive signal generation and approval workflow
- **Features**:
  - Generate signals with detailed information
  - Interactive mode for approval workflow
  - Auto-approve/reject functionality
  - File-based signal storage
- **Usage**:
  ```bash
  # Generate signal
  python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed
  
  # Interactive mode
  python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
  
  # Auto-approve
  python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
  ```
- **Requirements**: `pip install requests`
- **Documentation**: `BITCOIN-CLI-TOOL.md`

### 2. Daily Signal Generation Script
- **Script**: `repo/main/scripts/generate-daily-signals.py` (Python)
- **Script**: `repo/main/scripts/generate-daily-signals.ps1` (PowerShell)
- **Purpose**: Automatically generate signals for all categories
- **Features**:
  - Generate signals for multiple categories
  - Save signals to JSON files
  - Generate daily summary
  - Support for multiple strategies
- **Usage**:
  ```bash
  # Python (requires requests)
  python repo/main/scripts/generate-daily-signals.py BTCUSDT
  
  # PowerShell (no dependencies)
  .\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT
  ```
- **Options**:
  - `--categories`: Specify categories to generate (default: all)
  - `--use-ai`: Use AI enhancement
  - `--no-save`: Don't save signals to files
  - `--output-dir`: Output directory for signals (default: signals)

### 3. Test Scripts
- **Script**: `repo/main/scripts/test-bitcoin-signal.py`
- **Script**: `repo/main/scripts/test-bitcoin-signal.sh`
- **Purpose**: Test signal generation and service health
- **Usage**:
  ```bash
  python repo/main/scripts/test-bitcoin-signal.py
  ./repo/main/scripts/test-bitcoin-signal.sh
  ```

---

## 📅 Daily Workflow Scripts

### 1. Morning Signal Generation
- **Script**: `generate-daily-signals.ps1`
- **Purpose**: Generate all signals for the day
- **Usage**:
  ```powershell
  .\repo\main\scripts\generate-daily-signals.ps1 -Symbol BTCUSDT
  ```
- **Output**: 
  - Individual signal files: `signals_<category>_<date>.json`
  - Summary file: `daily_signals_summary_<date>.json`

### 2. Signal Review and Approval
- **Script**: `bitcoin-signal-cli.py`
- **Purpose**: Review and approve/reject signals
- **Usage**:
  ```bash
  python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
  ```
- **Output**: 
  - Approved signals: `approved_signals_<date>.json`
  - Rejected signals: `rejected_signals_<date>.json`

---

## ⚙️ Configuration Options

### 1. Service URLs
- **Data Service**: `http://fks_data:8003` (internal), `http://localhost:8003` (external)
- **App Service**: `http://fks_app:8002` (internal), `http://localhost:8002` (external)
- **AI Service**: `http://fks_ai:8007` (internal), `http://localhost:8007` (external)
- **Execution Service**: `http://fks_execution:8004` (internal), `http://localhost:8004` (external)

### 2. Signal Parameters
- **Risk Percentage**: 1.5% (default, configurable)
- **Position Sizing**: Based on risk percentage
- **Confidence Threshold**: 50% (minimum)
- **AI Enhancement**: Optional (default: false)

### 3. Strategy Defaults
- **Scalp**: `ema_scalp`
- **Swing**: `rsi`
- **Long-term**: `macd`

---

## 📊 Signal Output Format

### Signal Object Structure
```json
{
  "symbol": "BTCUSDT",
  "signal_type": "BUY",
  "category": "swing",
  "entry_price": 103300.0,
  "take_profit": 106915.5,
  "stop_loss": 101234.0,
  "position_size_pct": 75.0,
  "position_size_usd": 7500.0,
  "position_size_units": 0.0726,
  "risk_amount": 150.0,
  "risk_pct": 1.5,
  "risk_reward": 1.75,
  "confidence": 0.65,
  "timestamp": "2025-11-12T04:54:36.533017",
  "rationale": "MACD strong bullish momentum (histogram: 64.9626)",
  "ai_enhanced": false,
  "indicators": {
    "macd": -493.03,
    "signal": -557.99,
    "histogram": 64.96
  },
  "strategy": "macd",
  "tp_pct": 3.5,
  "sl_pct": 2.0,
  "timeframe": "1d"
}
```

### Signal Fields
- **symbol**: Trading symbol (e.g., BTCUSDT)
- **signal_type**: Signal type (BUY, SELL, HOLD)
- **category**: Trade category (scalp, swing, long_term)
- **entry_price**: Entry price for the trade
- **take_profit**: Take profit price
- **stop_loss**: Stop loss price
- **position_size_pct**: Position size as percentage of portfolio
- **position_size_usd**: Position size in USD
- **position_size_units**: Position size in units
- **risk_amount**: Risk amount in USD
- **risk_pct**: Risk percentage
- **risk_reward**: Risk/reward ratio
- **confidence**: Signal confidence (0-1)
- **timestamp**: Signal generation timestamp
- **rationale**: Signal rationale/explanation
- **ai_enhanced**: Whether AI enhancement was used
- **indicators**: Technical indicators used
- **strategy**: Strategy used to generate signal
- **tp_pct**: Take profit percentage
- **sl_pct**: Stop loss percentage
- **timeframe**: Trading timeframe

---

## 🚨 Error Handling

### Common Errors

#### 1. Service Not Available
- **Error**: `Failed to connect to signal service`
- **Solution**: Check if services are running (`docker ps`)
- **Fix**: Start services using `start-bitcoin-demo.sh`

#### 2. No Market Data
- **Error**: `No market data for {symbol}`
- **Solution**: Check if data service is running and can fetch data
- **Fix**: Verify data service health and Binance API connectivity

#### 3. No Signal Generated
- **Error**: `No signal generated for {symbol}`
- **Solution**: Check market conditions and strategy parameters
- **Fix**: Try different strategy or category

#### 4. Invalid Strategy
- **Error**: `Invalid strategy: {strategy}`
- **Solution**: Use valid strategy names (rsi, macd, ema_scalp, ema_swing, asmbtr)
- **Fix**: Use auto-select (no strategy parameter) or valid strategy name

---

## 🎯 Best Practices

### 1. Signal Generation
- **Generate signals daily**: Use daily signal generation script
- **Review all signals**: Check signals from all categories
- **Compare strategies**: Test different strategies for same category
- **Verify confidence**: Only trade signals with confidence > 60%

### 2. Risk Management
- **Follow position sizing**: Use calculated position sizes
- **Set stop losses**: Always set stop loss orders
- **Risk 1-2% per trade**: Don't risk more than 2% per trade
- **Diversify**: Don't put all capital in one signal

### 3. Signal Approval
- **Review rationale**: Understand why signal was generated
- **Check indicators**: Verify technical indicators
- **Consider context**: Check market conditions and news
- **Log decisions**: Keep record of approved/rejected signals

### 4. Daily Workflow
- **Morning routine**: Generate signals in the morning
- **Review signals**: Review all signals before trading
- **Approve/reject**: Make informed decisions
- **Execute trades**: Execute approved signals manually
- **End of day**: Review performance and log results

---

## 📚 Additional Resources

### Documentation
- `BITCOIN-QUICK-START.md` - Quick start guide
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow
- `BITCOIN-CLI-TOOL.md` - CLI tool documentation
- `BITCOIN-DEMO-COMPLETE.md` - Completion summary
- `BITCOIN-DEMO-WORKING-SUMMARY.md` - Working summary

### Scripts
- `repo/main/scripts/bitcoin-signal-cli.py` - CLI tool
- `repo/main/scripts/generate-daily-signals.py` - Daily signal generation (Python)
- `repo/main/scripts/generate-daily-signals.ps1` - Daily signal generation (PowerShell)
- `repo/main/scripts/test-bitcoin-signal.py` - Test script
- `repo/main/scripts/start-bitcoin-demo.sh` - Startup script

### API Documentation
- `QUICK-REFERENCE.md` - API quick reference
- Service health endpoints: `http://localhost:8002/health`

---

## ✅ Summary

### Available Features
- ✅ **Multiple Strategies**: RSI, MACD, EMA (scalp/swing), ASMBTR
- ✅ **Multiple Categories**: Scalp, Swing, Long-term
- ✅ **AI Enhancement**: Optional AI enhancement
- ✅ **CLI Tools**: Interactive signal generation and approval
- ✅ **Daily Scripts**: Automated daily signal generation
- ✅ **API Endpoints**: RESTful API for signal generation
- ✅ **File Storage**: JSON file storage for signals
- ✅ **Error Handling**: Comprehensive error handling
- ✅ **Documentation**: Complete documentation

### Next Steps
1. **Use Daily Scripts**: Set up daily signal generation
2. **Review Signals**: Review signals from all categories
3. **Approve Signals**: Use CLI tool for approval workflow
4. **Execute Trades**: Execute approved signals manually
5. **Track Performance**: Monitor signal accuracy and performance

---

**Status**: ✅ **COMPLETE**

**Last Updated**: 2025-11-12

