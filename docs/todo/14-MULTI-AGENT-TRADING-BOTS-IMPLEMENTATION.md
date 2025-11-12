# Multi-Agent Trading Bots Implementation - Complete Task Guide
## AI Agent Instructions for FKS Platform Enhancement

**Date**: 2025-01-XX  
**Status**: Ready for Implementation  
**Purpose**: Step-by-step guide for AI agents to implement specialized trading bots, chaos engineering, and service refinements  
**Estimated Effort**: 400-600 hours over 8-12 weeks

---

## 🎯 Project Overview

**Objective**: Integrate specialized multi-agent trading bots (stocks, forex, crypto) into the FKS platform, enhance system resilience with chaos engineering, refine service roles, and improve CI/CD pipelines.

**Key Deliverables**:
1. Three specialized trading bots (StockBot, ForexBot, CryptoBot) integrated into fks_ai
2. Chaos engineering framework integrated into fks_monitor and fks_ai
3. Service role refinements (fks_analyze, fks_app, fks_engine)
4. Advanced CI/CD integration with GitOps and progressive delivery
5. Enhanced monitoring and resilience testing

**Success Criteria**:
- Bots generate accurate signals (10-20% performance improvement)
- System survives 95% of chaos scenarios
- Zero-downtime deployments
- 15-25% faster AI-driven feature iterations

---

## 📋 Phase 1: Preparation and Research (Weeks 1-2)

### Task 1.1: Review and Map Multi-Agent Concepts

**Objective**: Understand multi-agent trading concepts and map them to FKS architecture

**Actions for AI Agent**:

1. **Read and analyze the following concepts**:
   - Stock trend-following strategies (moving averages, momentum)
   - Forex mean-reversion strategies (RSI, Bollinger Bands)
   - Crypto breakout strategies (channel breakouts, volume spikes)
   - Multi-agent debate systems for consensus
   - RAG chatbot integration for historical trade queries

2. **Map to FKS services**:
   - **fks_ai**: Extend existing LangGraph multi-agent system
   - **fks_portfolio**: Integrate bot signals into optimization
   - **fks_data**: Use existing adapters (Binance, Polygon, Yahoo Finance)
   - **fks_execution**: Manual execution workflow (respect manual-first principle)
   - **fks_app**: Market analysis computations (trend, volatility)

3. **Create mapping document**:
   ```
   File: repo/main/docs/multi-agent-mapping.md
   Content:
   - Strategy → Service mapping
   - Data flow diagrams
   - Integration points
   - BTC-centric rules (50-60% allocation)
   ```

**Deliverable**: `repo/main/docs/multi-agent-mapping.md` with complete strategy-to-service mappings

**Success Criteria**: 100% alignment with FKS principles (data-driven, BTC-centric, manual-first)

---

### Task 1.2: Audit FKS Services

**Objective**: Analyze current FKS services to identify gaps and integration points

**Actions for AI Agent**:

1. **Analyze fks_ai service**:
   ```bash
   # Review current agent structure
   cd repo/ai
   # Examine:
   # - src/agents/ directory structure
   # - LangGraph implementation
   # - Multi-agent debate system
   # - GPU utilization
   ```

   **Create audit report**:
   ```
   File: repo/main/docs/service-audit-fks-ai.md
   Content:
   - Current agent architecture
   - LangGraph nodes and edges
   - GPU usage patterns
   - Missing: Market-specific bots
   - Integration points for new bots
   ```

2. **Analyze fks_portfolio service**:
   ```bash
   cd repo/portfolio
   # Examine:
   # - Signal generation (4 categories)
   # - Portfolio optimization
   # - BTC conversion logic
   # - API endpoints (37 total)
   ```

   **Create audit report**:
   ```
   File: repo/main/docs/service-audit-fks-portfolio.md
   Content:
   - Current signal categories
   - Optimization algorithms
   - BTC allocation constraints
   - Missing: Bot signal integration
   - API endpoints for bot signals
   ```

3. **Analyze fks_data service**:
   ```bash
   cd repo/data
   # Examine:
   # - Data adapters (6 total)
   # - Rate limiting
   # - Data validation
   # - Storage (TimescaleDB)
   ```

   **Create audit report**:
   ```
   File: repo/main/docs/service-audit-fks-data.md
   Content:
   - Available data sources
   - Adapter capabilities
   - Rate limits per source
   - Missing: Real-time streaming for bots
   - Data format requirements
   ```

4. **Analyze fks_execution service**:
   ```bash
   cd repo/execution
   # Examine:
   # - Order management
   # - Circuit breakers
   # - Exchange integration
   # - Manual execution workflow
   ```

   **Create audit report**:
   ```
   File: repo/main/docs/service-audit-fks-execution.md
   Content:
   - Order lifecycle
   - Circuit breaker logic
   - Manual execution support
   - Missing: Bot signal triggers
   - Integration requirements
   ```

5. **Analyze fks_analyze service**:
   ```bash
   cd repo/analyze
   # Examine current functionality
   # Identify: Should focus on internal code analysis, NOT market data
   ```

   **Create audit report**:
   ```
   File: repo/main/docs/service-audit-fks-analyze.md
   Content:
   - Current analysis capabilities
   - Service boundary clarification
   - Recommendation: Remove market analysis
   - Focus: Code quality, service health, performance metrics
   ```

**Deliverable**: 5 audit reports in `repo/main/docs/service-audit-*.md`

**Success Criteria**: All services audited, gaps identified, integration points documented

---

### Task 1.3: Define Scope and Bot Specifications

**Objective**: Define detailed specifications for three trading bots

**Actions for AI Agent**:

1. **Create StockBot specification**:
   ```
   File: repo/ai/docs/bots/stockbot-spec.md
   Content:
   - Purpose: Stock market trend-following
   - Symbols: AAPL.US, SPY, QQQ, etc.
   - Strategy: Fast/slow moving averages, momentum indicators
   - Indicators: EMA(5), EMA(13), EMA(50), EMA(200), MACD, Volume
   - Entry Conditions:
     * EMA(5) > EMA(13) (bullish crossover)
     * Price > EMA(200) (uptrend)
     * MACD histogram positive
     * Volume > 20-day average
   - Exit Conditions:
     * EMA(5) < EMA(13) (bearish crossover)
     * Stop loss: 2% from entry
     * Take profit: 5% from entry
   - Risk: Max 2% portfolio risk per trade
   - Data Source: fks_data (Yahoo Finance adapter)
   - Output: TradingSignal with category=SWING
   ```

2. **Create ForexBot specification**:
   ```
   File: repo/ai/docs/bots/forexbot-spec.md
   Content:
   - Purpose: Forex mean-reversion trading
   - Symbols: EUR/USD, GBP/USD, USD/JPY, etc.
   - Strategy: RSI-based mean reversion
   - Indicators: RSI(14), Bollinger Bands(20,2), ATR(14)
   - Entry Conditions:
     * RSI < 30 (oversold) for long
     * RSI > 70 (overbought) for short
     * Price touches lower BB (long) or upper BB (short)
   - Exit Conditions:
     * RSI returns to 50
     * Stop loss: 1.5% from entry
     * Take profit: 3% from entry
   - Risk: Max 1% portfolio risk per trade
   - Data Source: fks_data (Alpha Vantage adapter)
   - Output: TradingSignal with category=INTRADAY
   ```

3. **Create CryptoBot specification**:
   ```
   File: repo/ai/docs/bots/cryptobot-spec.md
   Content:
   - Purpose: Crypto breakout trading with BTC priority
   - Symbols: BTC-USD, ETH-USD, SOL-USD, etc.
   - Strategy: Channel breakouts, volume confirmation
   - Indicators: Donchian Channels(20), Volume, RSI(14)
   - Entry Conditions:
     * Price breaks above upper channel (bullish breakout)
     * Volume > 1.5x 20-day average
     * RSI < 70 (not overbought)
     * For BTC: Prioritize long-term holds (50-60% allocation)
   - Exit Conditions:
     * Price breaks below lower channel
     * Stop loss: 3% from entry (wider for volatility)
     * Take profit: 8% from entry
   - Risk: Max 2% portfolio risk per trade
   - BTC Rules: 
     * BTC gets 50-60% portfolio allocation
     * BTC signals have wider stops (10-15%)
     * Long-term focus for BTC
   - Data Source: fks_data (Binance, CoinGecko adapters)
   - Output: TradingSignal with category=SWING or LONG_TERM
   ```

4. **Create collaboration specification**:
   ```
   File: repo/ai/docs/bots/collaboration-spec.md
   Content:
   - Multi-agent debate system
   - Consensus mechanism:
     * Each bot votes on signal (BUY/SELL/HOLD)
     * Weight votes by confidence (0.0-1.0)
     * Require 2/3 consensus for execution
   - Portfolio allocation:
     * Default: 33% stocks, 33% forex, 33% crypto
     * Adjustable based on market conditions
     * BTC always 50-60% of crypto allocation
   - Signal aggregation:
     * Combine bot signals into portfolio signals
     * Apply risk management
     * Filter through fks_portfolio optimization
   ```

**Deliverable**: 4 specification files in `repo/ai/docs/bots/`

**Success Criteria**: All bot specifications complete, aligned with FKS principles

---

### Task 1.4: Risk Assessment and Mitigation

**Objective**: Identify risks and create mitigation strategies

**Actions for AI Agent**:

1. **Create risk assessment document**:
   ```
   File: repo/main/docs/risk-assessment-multi-agent.md
   Content:
   - Risk: Direct exchange queries (violates fks_data principle)
     Mitigation: All bots MUST use fks_data adapters
     Validation: Code review, integration tests
   
   - Risk: Overfitting to historical data
     Mitigation: Use walk-forward optimization, out-of-sample testing
     Validation: Backtest on 30+ days, compare with baseline
   
   - Risk: Latency in signal generation
     Mitigation: Use fks_execution's Rust for high-performance
     Validation: Benchmark <100ms for signal generation
   
   - Risk: Service failures during trading
     Mitigation: Implement chaos engineering (Phase 5)
     Validation: 95% survival rate in chaos scenarios
   
   - Risk: BTC allocation drift
     Mitigation: Enforce 50-60% constraints in optimization
     Validation: Portfolio rebalancing checks
   
   - Risk: Manual execution errors
     Mitigation: Clear workflow in fks_web, decision logging
     Validation: Adherence tracking, override frequency monitoring
   ```

2. **Create compliance checklist**:
   ```
   File: repo/main/docs/compliance-checklist.md
   Content:
   - [ ] No direct exchange queries (all via fks_data)
   - [ ] No automated execution (manual-first principle)
   - [ ] BTC allocation constraints enforced
   - [ ] Risk limits per trade (1-2%)
   - [ ] All signals logged for audit
   - [ ] Chaos tests in staging only
   - [ ] Rate limiting on all APIs
   - [ ] Authentication via fks_auth
   ```

**Deliverable**: Risk assessment and compliance checklist

**Success Criteria**: All risks identified, mitigations documented, compliance checklist complete

---

### Task 1.5: Tool Setup and Environment

**Objective**: Install and configure required tools

**Actions for AI Agent**:

1. **Update fks_ai dependencies**:
   ```bash
   cd repo/ai
   # Update requirements.txt
   ```
   
   **Add to `repo/ai/requirements.txt`**:
   ```
   # Multi-agent trading bots
   langgraph>=0.2.0
   langchain>=0.3.0
   langchain-community>=0.3.0
   
   # Technical analysis
   ta-lib>=0.4.28
   pandas-ta>=0.3.14b0
   
   # Backtesting
   backtrader>=1.9.78
   
   # Data processing
   numpy>=1.24.0
   pandas>=2.0.0
   
   # GPU support (if available)
   torch>=2.0.0
   torchvision>=0.15.0
   ```
   
   **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure GPU (if available)**:
   ```bash
   # Check CUDA availability
   python -c "import torch; print(torch.cuda.is_available())"
   
   # Verify CUDA version (12.2+ required)
   nvidia-smi
   ```
   
   **Create GPU configuration**:
   ```
   File: repo/ai/config/gpu_config.py
   Content:
   import torch
   import os
   
   GPU_ENABLED = torch.cuda.is_available()
   GPU_DEVICE = "cuda:0" if GPU_ENABLED else "cpu"
   GPU_MEMORY_LIMIT = int(os.getenv("GPU_MEMORY_LIMIT", "8192"))  # 8GB default
   
   if GPU_ENABLED:
       torch.cuda.set_per_process_memory_fraction(0.8)  # Use 80% of GPU
   ```

3. **Update service registry**:
   ```bash
   cd repo/main/config
   # Edit service_registry.json
   ```
   
   **Add bot endpoints to fks_ai**:
   ```json
   {
     "fks_ai": {
       "name": "fks_ai",
       "port": 8007,
       "base_url": "http://fks_ai:8007",
       "health_url": "http://fks_ai:8007/health",
       "bot_endpoints": {
         "stockbot": "/ai/bots/stock/signal",
         "forexbot": "/ai/bots/forex/signal",
         "cryptobot": "/ai/bots/crypto/signal",
         "debate": "/ai/bots/debate",
         "consensus": "/ai/bots/consensus"
       }
     }
   }
   ```

**Deliverable**: Updated dependencies, GPU config, service registry

**Success Criteria**: All tools installed, GPU configured (if available), service registry updated

---

### Task 1.6: Create Feasibility Report

**Objective**: Compile all research into comprehensive feasibility report

**Actions for AI Agent**:

1. **Create feasibility report**:
   ```
   File: repo/main/docs/feasibility-report-multi-agent.md
   Content:
   # Multi-Agent Trading Bots - Feasibility Report
   
   ## Executive Summary
   - Project: Integrate specialized trading bots into FKS
   - Timeline: 8-12 weeks
   - Effort: 400-600 hours
   - Budget: $50K-$80K
   - ROI: 10-20% performance improvement expected
   
   ## Strategy Mappings
   [Include mappings from Task 1.1]
   
   ## Service Audits
   [Include summaries from Task 1.2]
   
   ## Bot Specifications
   [Include summaries from Task 1.3]
   
   ## Risk Assessment
   [Include from Task 1.4]
   
   ## Technical Feasibility
   - ✅ LangGraph supports multi-agent systems
   - ✅ fks_data has required adapters
   - ✅ fks_portfolio can integrate bot signals
   - ✅ GPU available for AI processing
   - ⚠️ Latency concerns (mitigated with Rust)
   - ⚠️ Testing complexity (mitigated with chaos engineering)
   
   ## Resource Requirements
   - Team: 3-5 developers (AI/ML, backend, DevOps)
   - GPU: CUDA 12.2+, 8GB VRAM minimum
   - Tools: LangGraph, PyTorch, Ollama, Chaos Mesh
   - Infrastructure: Kubernetes cluster, monitoring stack
   
   ## Timeline
   - Phase 1: Weeks 1-2 (Preparation)
   - Phase 2: Weeks 2-3 (Design)
   - Phase 3: Weeks 4-6 (Development)
   - Phase 4: Weeks 6-8 (Integration)
   - Phase 5: Weeks 8-10 (Testing)
   - Phase 6: Weeks 10-11 (Deployment)
   - Phase 7: Week 12+ (Iteration)
   
   ## Success Metrics
   - Bots generate accurate signals (10-15% simulated ROI)
   - System survives 95% of chaos scenarios
   - Zero-downtime deployments
   - 15-25% faster AI-driven feature iterations
   
   ## Recommendations
   - Proceed with implementation
   - Start with StockBot (simplest)
   - Integrate chaos engineering early
   - Focus on BTC-centric rules
   ```

**Deliverable**: Complete feasibility report

**Success Criteria**: Report approved by team, all stakeholders aligned

---

## 📋 Phase 2: Design and Architecture (Weeks 2-3)

### Task 2.1: Design Agent Structure

**Objective**: Design LangGraph-based agent structure for three trading bots

**Actions for AI Agent**:

1. **Create agent base class**:
   ```
   File: repo/ai/src/agents/base_bot.py
   Content:
   from abc import ABC, abstractmethod
   from typing import Dict, Any, Optional
   from datetime import datetime
   import httpx
   from loguru import logger
   
   class BaseTradingBot(ABC):
       """Base class for all trading bots"""
       
       def __init__(self, name: str, data_service_url: str = "http://fks_data:8003"):
           self.name = name
           self.data_service_url = data_service_url
           self.logger = logger.bind(bot=name)
       
       @abstractmethod
       async def analyze(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Analyze market data and generate signal"""
           pass
       
       @abstractmethod
       def get_strategy_name(self) -> str:
           """Return strategy name"""
           pass
       
       async def fetch_market_data(self, symbol: str, interval: str = "1h") -> Dict[str, Any]:
           """Fetch market data from fks_data service"""
           try:
               async with httpx.AsyncClient(timeout=10.0) as client:
                   response = await client.get(
                       f"{self.data_service_url}/api/v1/data/{symbol}",
                       params={"interval": interval, "limit": 100}
                   )
                   response.raise_for_status()
                   return response.json()
           except Exception as e:
               self.logger.error(f"Failed to fetch data for {symbol}: {e}")
               return {}
       
       def calculate_risk(self, entry_price: float, stop_loss: float, portfolio_value: float, risk_pct: float = 0.02) -> float:
           """Calculate position size based on risk"""
           risk_amount = portfolio_value * risk_pct
           price_diff = abs(entry_price - stop_loss)
           if price_diff == 0:
               return 0.0
           position_size = risk_amount / price_diff
           return min(position_size, portfolio_value * 0.1)  # Max 10% per position
   ```

2. **Create StockBot implementation**:
   ```
   File: repo/ai/src/agents/stockbot.py
   Content:
   import pandas as pd
   import numpy as np
   import talib
   from typing import Dict, Any
   from .base_bot import BaseTradingBot
   
   class StockBot(BaseTradingBot):
       """Stock market trend-following bot"""
       
       def __init__(self):
           super().__init__("StockBot")
       
       def get_strategy_name(self) -> str:
           return "Trend Following (Moving Averages)"
       
       async def analyze(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Analyze stock data and generate signal"""
           # Extract OHLCV data
           df = pd.DataFrame(market_data.get("data", []))
           if len(df) < 200:
               return {"signal": "HOLD", "confidence": 0.0, "reason": "Insufficient data"}
           
           close = df["close"].values
           volume = df["volume"].values
           
           # Calculate indicators
           ema5 = talib.EMA(close, timeperiod=5)
           ema13 = talib.EMA(close, timeperiod=13)
           ema50 = talib.EMA(close, timeperiod=50)
           ema200 = talib.EMA(close, timeperiod=200)
           macd, macd_signal, macd_hist = talib.MACD(close)
           volume_avg = talib.SMA(volume, timeperiod=20)
           
           current_price = close[-1]
           current_ema5 = ema5[-1]
           current_ema13 = ema13[-1]
           current_ema50 = ema50[-1]
           current_ema200 = ema200[-1]
           current_macd_hist = macd_hist[-1]
           current_volume = volume[-1]
           avg_volume = volume_avg[-1]
           
           # Entry conditions
           bullish_crossover = current_ema5 > current_ema13 and ema5[-2] <= ema13[-2]
           uptrend = current_price > current_ema200
           macd_bullish = current_macd_hist > 0
           volume_confirmation = current_volume > avg_volume
           
           # Calculate confidence
           confidence = 0.0
           if bullish_crossover:
               confidence += 0.3
           if uptrend:
               confidence += 0.3
           if macd_bullish:
               confidence += 0.2
           if volume_confirmation:
               confidence += 0.2
           
           # Generate signal
           if confidence >= 0.6:
               entry_price = current_price
               stop_loss = entry_price * 0.98  # 2% stop
               take_profit = entry_price * 1.05  # 5% target
               
               return {
                   "signal": "BUY",
                   "confidence": min(confidence, 1.0),
                   "entry_price": entry_price,
                   "stop_loss": stop_loss,
                   "take_profit": take_profit,
                   "reason": f"Bullish crossover, uptrend, MACD positive, volume confirmation",
                   "indicators": {
                       "ema5": current_ema5,
                       "ema13": current_ema13,
                       "ema50": current_ema50,
                       "ema200": current_ema200,
                       "macd_hist": current_macd_hist,
                       "volume_ratio": current_volume / avg_volume
                   }
               }
           elif confidence <= 0.3:
               return {
                   "signal": "SELL",
                   "confidence": 1.0 - confidence,
                   "reason": "Bearish conditions detected"
               }
           else:
               return {
                   "signal": "HOLD",
                   "confidence": 0.5,
                   "reason": "Mixed signals, waiting for confirmation"
               }
   ```

3. **Create ForexBot implementation**:
   ```
   File: repo/ai/src/agents/forexbot.py
   Content:
   import pandas as pd
   import numpy as np
   import talib
   from typing import Dict, Any
   from .base_bot import BaseTradingBot
   
   class ForexBot(BaseTradingBot):
       """Forex mean-reversion trading bot"""
       
       def __init__(self):
           super().__init__("ForexBot")
       
       def get_strategy_name(self) -> str:
           return "Mean Reversion (RSI + Bollinger Bands)"
       
       async def analyze(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Analyze forex data and generate signal"""
           df = pd.DataFrame(market_data.get("data", []))
           if len(df) < 50:
               return {"signal": "HOLD", "confidence": 0.0, "reason": "Insufficient data"}
           
           close = df["close"].values
           high = df["high"].values
           low = df["low"].values
           
           # Calculate indicators
           rsi = talib.RSI(close, timeperiod=14)
           upper_bb, middle_bb, lower_bb = talib.BBANDS(close, timeperiod=20, nbdevup=2, nbdevdn=2)
           atr = talib.ATR(high, low, close, timeperiod=14)
           
           current_price = close[-1]
           current_rsi = rsi[-1]
           current_upper_bb = upper_bb[-1]
           current_lower_bb = lower_bb[-1]
           current_atr = atr[-1]
           
           # Entry conditions (mean reversion)
           oversold = current_rsi < 30
           overbought = current_rsi > 70
           touch_lower_bb = current_price <= current_lower_bb
           touch_upper_bb = current_price >= current_upper_bb
           
           # Long signal (oversold + lower BB)
           if oversold and touch_lower_bb:
               entry_price = current_price
               stop_loss = entry_price - (current_atr * 1.5)  # 1.5x ATR stop
               take_profit = entry_price + (current_atr * 2.0)  # 2x ATR target
               
               confidence = 0.7 + (30 - current_rsi) / 100  # Higher confidence for lower RSI
               
               return {
                   "signal": "BUY",
                   "confidence": min(confidence, 1.0),
                   "entry_price": entry_price,
                   "stop_loss": stop_loss,
                   "take_profit": take_profit,
                   "reason": f"Oversold (RSI={current_rsi:.2f}), touched lower Bollinger Band",
                   "indicators": {
                       "rsi": current_rsi,
                       "upper_bb": current_upper_bb,
                       "lower_bb": current_lower_bb,
                       "atr": current_atr
                   }
               }
           
           # Short signal (overbought + upper BB)
           elif overbought and touch_upper_bb:
               entry_price = current_price
               stop_loss = entry_price + (current_atr * 1.5)
               take_profit = entry_price - (current_atr * 2.0)
               
               confidence = 0.7 + (current_rsi - 70) / 100
               
               return {
                   "signal": "SELL",
                   "confidence": min(confidence, 1.0),
                   "entry_price": entry_price,
                   "stop_loss": stop_loss,
                   "take_profit": take_profit,
                   "reason": f"Overbought (RSI={current_rsi:.2f}), touched upper Bollinger Band",
                   "indicators": {
                       "rsi": current_rsi,
                       "upper_bb": current_upper_bb,
                       "lower_bb": current_lower_bb,
                       "atr": current_atr
                   }
               }
           
           else:
               return {
                   "signal": "HOLD",
                   "confidence": 0.5,
                   "reason": f"RSI={current_rsi:.2f}, no mean-reversion opportunity"
               }
   ```

4. **Create CryptoBot implementation**:
   ```
   File: repo/ai/src/agents/cryptobot.py
   Content:
   import pandas as pd
   import numpy as np
   import talib
   from typing import Dict, Any
   from .base_bot import BaseTradingBot
   
   class CryptoBot(BaseTradingBot):
       """Crypto breakout trading bot with BTC priority"""
       
       def __init__(self):
           super().__init__("CryptoBot")
           self.btc_symbols = ["BTC-USD", "BTCUSDT", "BTC/USD"]
       
       def get_strategy_name(self) -> str:
           return "Breakout Trading (Donchian Channels + Volume)"
       
       def is_btc(self, symbol: str) -> bool:
           """Check if symbol is BTC"""
           return any(btc in symbol.upper() for btc in self.btc_symbols)
       
       async def analyze(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Analyze crypto data and generate signal"""
           df = pd.DataFrame(market_data.get("data", []))
           if len(df) < 50:
               return {"signal": "HOLD", "confidence": 0.0, "reason": "Insufficient data"}
           
           close = df["close"].values
           high = df["high"].values
           low = df["low"].values
           volume = df["volume"].values
           
           # Calculate indicators
           # Donchian Channels (20-period)
           upper_channel = pd.Series(high).rolling(20).max().values
           lower_channel = pd.Series(low).rolling(20).min().values
           middle_channel = (upper_channel + lower_channel) / 2
           
           rsi = talib.RSI(close, timeperiod=14)
           volume_avg = talib.SMA(volume, timeperiod=20)
           
           current_price = close[-1]
           current_upper = upper_channel[-1]
           current_lower = lower_channel[-1]
           current_rsi = rsi[-1]
           current_volume = volume[-1]
           avg_volume = volume_avg[-1]
           
           # Breakout conditions
           bullish_breakout = current_price > current_upper
           bearish_breakout = current_price < current_lower
           volume_confirmation = current_volume > (avg_volume * 1.5)
           not_overbought = current_rsi < 70
           
           # BTC-specific rules (wider stops, long-term focus)
           is_btc_symbol = self.is_btc(symbol)
           
           if bullish_breakout and volume_confirmation and not_overbought:
               entry_price = current_price
               
               if is_btc_symbol:
                   # BTC: Wider stops for long-term holds
                   stop_loss = entry_price * 0.90  # 10% stop
                   take_profit = entry_price * 1.15  # 15% target
                   confidence = 0.8  # Higher confidence for BTC
               else:
                   # Other crypto: Standard stops
                   stop_loss = entry_price * 0.97  # 3% stop
                   take_profit = entry_price * 1.08  # 8% target
                   confidence = 0.7
               
               return {
                   "signal": "BUY",
                   "confidence": confidence,
                   "entry_price": entry_price,
                   "stop_loss": stop_loss,
                   "take_profit": take_profit,
                   "reason": f"Bullish breakout above upper channel, volume confirmation",
                   "btc_priority": is_btc_symbol,
                   "indicators": {
                       "upper_channel": current_upper,
                       "lower_channel": current_lower,
                       "rsi": current_rsi,
                       "volume_ratio": current_volume / avg_volume
                   }
               }
           
           elif bearish_breakout:
               return {
                   "signal": "SELL",
                   "confidence": 0.6,
                   "reason": "Bearish breakout below lower channel"
               }
           
           else:
               return {
                   "signal": "HOLD",
                   "confidence": 0.5,
                   "reason": "No breakout detected, waiting for confirmation"
               }
   ```

**Deliverable**: Base bot class and three bot implementations

**Success Criteria**: All bots implement BaseTradingBot, generate signals with confidence scores

---

### Task 2.2: Design LangGraph Multi-Agent System

**Objective**: Design LangGraph workflow for multi-agent collaboration

**Actions for AI Agent**:

1. **Create LangGraph agent workflow**:
   ```
   File: repo/ai/src/agents/multi_agent_workflow.py
   Content:
   from langgraph.graph import StateGraph, END
   from typing import TypedDict, List, Dict, Any
   from .stockbot import StockBot
   from .forexbot import ForexBot
   from .cryptobot import CryptoBot
   from loguru import logger
   
   class AgentState(TypedDict):
       symbol: str
       market_data: Dict[str, Any]
       stock_signal: Dict[str, Any]
       forex_signal: Dict[str, Any]
       crypto_signal: Dict[str, Any]
       debate_results: Dict[str, Any]
       consensus: Dict[str, Any]
       final_signal: Dict[str, Any]
   
   class MultiAgentWorkflow:
       """LangGraph workflow for multi-agent trading bot collaboration"""
       
       def __init__(self):
           self.stockbot = StockBot()
           self.forexbot = ForexBot()
           self.cryptobot = CryptoBot()
           self.workflow = self._build_workflow()
           self.logger = logger.bind(component="MultiAgentWorkflow")
       
       def _build_workflow(self) -> StateGraph:
           """Build LangGraph workflow"""
           workflow = StateGraph(AgentState)
           
           # Add nodes
           workflow.add_node("stock_analysis", self._stock_analysis)
           workflow.add_node("forex_analysis", self._forex_analysis)
           workflow.add_node("crypto_analysis", self._crypto_analysis)
           workflow.add_node("debate", self._debate)
           workflow.add_node("consensus", self._consensus)
           workflow.add_node("finalize", self._finalize)
           
           # Define edges
           workflow.set_entry_point("stock_analysis")
           workflow.add_edge("stock_analysis", "forex_analysis")
           workflow.add_edge("forex_analysis", "crypto_analysis")
           workflow.add_edge("crypto_analysis", "debate")
           workflow.add_edge("debate", "consensus")
           workflow.add_edge("consensus", "finalize")
           workflow.add_edge("finalize", END)
           
           return workflow.compile()
       
       async def _stock_analysis(self, state: AgentState) -> AgentState:
           """Stock bot analysis"""
           try:
               signal = await self.stockbot.analyze(state["symbol"], state["market_data"])
               state["stock_signal"] = signal
               self.logger.info(f"StockBot signal: {signal.get('signal')} (confidence: {signal.get('confidence', 0)})")
           except Exception as e:
               self.logger.error(f"StockBot error: {e}")
               state["stock_signal"] = {"signal": "HOLD", "confidence": 0.0, "error": str(e)}
           return state
       
       async def _forex_analysis(self, state: AgentState) -> AgentState:
           """Forex bot analysis"""
           try:
               signal = await self.forexbot.analyze(state["symbol"], state["market_data"])
               state["forex_signal"] = signal
               self.logger.info(f"ForexBot signal: {signal.get('signal')} (confidence: {signal.get('confidence', 0)})")
           except Exception as e:
               self.logger.error(f"ForexBot error: {e}")
               state["forex_signal"] = {"signal": "HOLD", "confidence": 0.0, "error": str(e)}
           return state
       
       async def _crypto_analysis(self, state: AgentState) -> AgentState:
           """Crypto bot analysis"""
           try:
               signal = await self.cryptobot.analyze(state["symbol"], state["market_data"])
               state["crypto_signal"] = signal
               self.logger.info(f"CryptoBot signal: {signal.get('signal')} (confidence: {signal.get('confidence', 0)})")
           except Exception as e:
               self.logger.error(f"CryptoBot error: {e}")
               state["crypto_signal"] = {"signal": "HOLD", "confidence": 0.0, "error": str(e)}
           return state
       
       async def _debate(self, state: AgentState) -> AgentState:
           """Multi-agent debate"""
           signals = [
               state.get("stock_signal", {}),
               state.get("forex_signal", {}),
               state.get("crypto_signal", {})
           ]
           
           # Extract votes and confidence
           votes = {"BUY": 0, "SELL": 0, "HOLD": 0}
           total_confidence = 0.0
           
           for signal in signals:
               signal_type = signal.get("signal", "HOLD")
               confidence = signal.get("confidence", 0.0)
               votes[signal_type] += confidence
               total_confidence += confidence
           
           # Determine consensus
           max_vote = max(votes.values())
           consensus_signal = [k for k, v in votes.items() if v == max_vote][0]
           consensus_confidence = max_vote / total_confidence if total_confidence > 0 else 0.0
           
           state["debate_results"] = {
               "votes": votes,
               "total_confidence": total_confidence,
               "consensus_signal": consensus_signal,
               "consensus_confidence": consensus_confidence
           }
           
           self.logger.info(f"Debate consensus: {consensus_signal} (confidence: {consensus_confidence:.2f})")
           return state
       
       async def _consensus(self, state: AgentState) -> AgentState:
           """Build consensus signal"""
           debate = state.get("debate_results", {})
           consensus_signal = debate.get("consensus_signal", "HOLD")
           consensus_confidence = debate.get("consensus_confidence", 0.0)
           
           # Require 2/3 consensus (0.67) for execution
           if consensus_confidence >= 0.67:
               # Use the signal with highest confidence
               signals = [
                   state.get("stock_signal", {}),
                   state.get("forex_signal", {}),
                   state.get("crypto_signal", {})
               ]
               
               best_signal = max(signals, key=lambda s: s.get("confidence", 0.0))
               
               state["consensus"] = {
                   "signal": consensus_signal,
                   "confidence": consensus_confidence,
                   "entry_price": best_signal.get("entry_price"),
                   "stop_loss": best_signal.get("stop_loss"),
                   "take_profit": best_signal.get("take_profit"),
                   "reason": f"Multi-agent consensus: {consensus_confidence:.2%}",
                   "bot_signals": {
                       "stock": state.get("stock_signal", {}),
                       "forex": state.get("forex_signal", {}),
                       "crypto": state.get("crypto_signal", {})
                   }
               }
           else:
               state["consensus"] = {
                   "signal": "HOLD",
                   "confidence": consensus_confidence,
                   "reason": f"Insufficient consensus: {consensus_confidence:.2%} < 67%"
               }
           
           return state
       
       async def _finalize(self, state: AgentState) -> AgentState:
           """Finalize signal for portfolio"""
           consensus = state.get("consensus", {})
           
           state["final_signal"] = {
               "symbol": state["symbol"],
               "signal_type": consensus.get("signal", "HOLD"),
               "confidence": consensus.get("confidence", 0.0),
               "entry_price": consensus.get("entry_price"),
               "stop_loss": consensus.get("stop_loss"),
               "take_profit": consensus.get("take_profit"),
               "reason": consensus.get("reason", ""),
               "bot_analysis": {
                   "stock": state.get("stock_signal", {}),
                   "forex": state.get("forex_signal", {}),
                   "crypto": state.get("crypto_signal", {}),
                   "debate": state.get("debate_results", {}),
                   "consensus": consensus
               },
               "timestamp": datetime.now().isoformat()
           }
           
           return state
       
       async def run(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Run multi-agent workflow"""
           initial_state: AgentState = {
               "symbol": symbol,
               "market_data": market_data,
               "stock_signal": {},
               "forex_signal": {},
               "crypto_signal": {},
               "debate_results": {},
               "consensus": {},
               "final_signal": {}
           }
           
           result = await self.workflow.ainvoke(initial_state)
           return result.get("final_signal", {})
   ```

**Deliverable**: Complete LangGraph multi-agent workflow

**Success Criteria**: Workflow runs end-to-end, generates consensus signals

---

### Task 2.3: Design Integration Points

**Objective**: Design how bots integrate with FKS ecosystem

**Actions for AI Agent**:

1. **Create integration design document**:
   ```
   File: repo/main/docs/integration-design-multi-agent.md
   Content:
   # Multi-Agent Bots Integration Design
   
   ## Data Flow
   ```
   fks_data (market data)
        ↓
   fks_ai (bot analysis)
        ↓
   fks_portfolio (signal optimization)
        ↓
   fks_web (manual review)
        ↓
   fks_execution (manual execution)
   ```
   
   ## Integration Points
   
   ### fks_data → fks_ai
   - Bots query fks_data via HTTP API
   - Endpoint: GET /api/v1/data/{symbol}
   - Parameters: interval, limit, start_date, end_date
   - Response: OHLCV data in JSON format
   - Rate limiting: Respect fks_data rate limits
   
   ### fks_ai → fks_portfolio
   - Bot signals sent to fks_portfolio
   - Endpoint: POST /api/signals/bot-signals
   - Payload: {
       "symbol": "BTC-USD",
       "signals": {
         "stock": {...},
         "forex": {...},
         "crypto": {...},
         "consensus": {...}
       }
     }
   - fks_portfolio applies optimization (mean-variance, CVaR)
   - Enforces BTC allocation (50-60%)
   
   ### fks_portfolio → fks_web
   - Optimized signals displayed in dashboard
   - Endpoint: GET /api/dashboard/signals
   - Includes bot analysis and consensus
   - Manual review interface
   
   ### fks_web → fks_execution
   - User approves signal
   - Endpoint: POST /api/execution/manual
   - Manual execution workflow (7-step guide)
   - Logs decision in fks_portfolio
   ```

2. **Create API endpoint specifications**:
   ```
   File: repo/ai/docs/api-endpoints-bots.md
   Content:
   # Bot API Endpoints
   
   ## GET /ai/bots/stock/signal?symbol=AAPL.US
   - Description: Get StockBot signal
   - Response: {
       "signal": "BUY|SELL|HOLD",
       "confidence": 0.0-1.0,
       "entry_price": float,
       "stop_loss": float,
       "take_profit": float,
       "reason": string,
       "indicators": {...}
     }
   
   ## GET /ai/bots/forex/signal?symbol=EUR/USD
   - Description: Get ForexBot signal
   - Response: Same as StockBot
   
   ## GET /ai/bots/crypto/signal?symbol=BTC-USD
   - Description: Get CryptoBot signal
   - Response: Same as StockBot + "btc_priority": bool
   
   ## POST /ai/bots/debate
   - Description: Run multi-agent debate
   - Request: {
       "symbol": "BTC-USD",
       "market_data": {...}
     }
   - Response: {
       "consensus": "BUY|SELL|HOLD",
       "confidence": 0.0-1.0,
       "votes": {"BUY": float, "SELL": float, "HOLD": float},
       "bot_signals": {
         "stock": {...},
         "forex": {...},
         "crypto": {...}
       }
     }
   
   ## GET /ai/bots/consensus?symbol=BTC-USD
   - Description: Get consensus signal (full workflow)
   - Response: {
       "final_signal": {...},
       "bot_analysis": {...},
       "timestamp": ISO8601
     }
   ```

**Deliverable**: Integration design document and API specifications

**Success Criteria**: All integration points documented, API specs complete

---

### Task 2.4: Design Chaos Engineering Integration

**Objective**: Design chaos engineering framework for FKS

**Actions for AI Agent**:

1. **Create chaos engineering design**:
   ```
   File: repo/main/docs/chaos-engineering-design.md
   Content:
   # Chaos Engineering Design for FKS
   
   ## Overview
   - Tool: Chaos Mesh (Kubernetes-native, open-source)
   - Integration: fks_monitor for experiment orchestration
   - Target Services: fks_ai, fks_data, fks_execution, fks_portfolio
   
   ## Experiment Types
   
   ### Network Chaos
   - Simulate data feed delays (fks_data)
   - Test signal latency (fks_ai)
   - Verify fallback mechanisms
   
   ### Pod Chaos
   - Kill bot agents (fks_ai)
   - Test auto-recovery
   - Verify consensus with missing agents
   
   ### Resource Chaos
   - Throttle GPU (fks_ai)
   - Stress CPU (fks_portfolio)
   - Test batch recovery (fks_training)
   
   ## Implementation
   - Install Chaos Mesh via Helm
   - Create experiment CRDs
   - Integrate with fks_monitor
   - Schedule "game days"
   ```

2. **Create Chaos Mesh installation script**:
   ```
   File: repo/main/scripts/install-chaos-mesh.sh
   Content:
   #!/bin/bash
   # Install Chaos Mesh for FKS
   
   set -e
   
   echo "=== Installing Chaos Mesh ==="
   
   # Add Helm repo
   helm repo add chaos-mesh https://charts.chaos-mesh.org
   helm repo update
   
   # Install Chaos Mesh
   helm install chaos-mesh chaos-mesh/chaos-mesh \
     --namespace=chaos-mesh \
     --create-namespace \
     --set chaosDaemon.privileged=true \
     --set dashboard.enabled=true
   
   # Wait for pods
   kubectl wait --for=condition=ready pod \
     -l app.kubernetes.io/name=chaos-mesh \
     -n chaos-mesh \
     --timeout=300s
   
   # Port-forward dashboard
   echo "Chaos Mesh Dashboard: http://localhost:2333"
   kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333 &
   
   echo "=== Chaos Mesh installed successfully ==="
   ```

3. **Create example chaos experiments**:
   ```
   File: repo/main/k8s/chaos-experiments/network-delay-fks-data.yaml
   Content:
   apiVersion: chaos-mesh.org/v1alpha1
   kind: NetworkChaos
   metadata:
     name: fks-data-network-delay
     namespace: fks-trading
   spec:
     action: delay
     mode: one
     duration: "60s"
     selector:
       labelSelectors:
         app: fks_data
     delay:
       latency: "2000ms"
       jitter: "500ms"
     direction: to
   ```

   ```
   File: repo/main/k8s/chaos-experiments/pod-kill-fks-ai.yaml
   Content:
   apiVersion: chaos-mesh.org/v1alpha1
   kind: PodChaos
   metadata:
     name: fks-ai-pod-kill
     namespace: fks-trading
   spec:
     action: pod-kill
     mode: fixed-percent
     value: "50"
     duration: "30s"
     selector:
       labelSelectors:
         app: fks_ai
   ```

**Deliverable**: Chaos engineering design, installation script, example experiments

**Success Criteria**: Chaos Mesh can be installed, experiments can be run

---

### Task 2.5: Create Architecture Diagrams

**Objective**: Generate visual architecture diagrams

**Actions for AI Agent**:

1. **Create PlantUML architecture diagram**:
   ```
   File: repo/main/docs/diagrams/multi-agent-architecture.puml
   Content:
   @startuml Multi-Agent Architecture
   !theme plain
   
   package "fks_data" {
     [Data Adapters] as adapters
     [TimescaleDB] as db
   }
   
   package "fks_ai" {
     [StockBot] as stock
     [ForexBot] as forex
     [CryptoBot] as crypto
     [LangGraph Workflow] as workflow
     [Multi-Agent Debate] as debate
   }
   
   package "fks_portfolio" {
     [Signal Optimizer] as optimizer
     [BTC Converter] as btc
     [Risk Manager] as risk
   }
   
   package "fks_web" {
     [Dashboard] as dashboard
     [Manual Review] as review
   }
   
   package "fks_execution" {
     [Order Manager] as orders
   }
   
   adapters --> stock : Market Data
   adapters --> forex : Market Data
   adapters --> crypto : Market Data
   
   stock --> workflow : Signal
   forex --> workflow : Signal
   crypto --> workflow : Signal
   
   workflow --> debate : All Signals
   debate --> optimizer : Consensus Signal
   
   optimizer --> btc : BTC Conversion
   optimizer --> risk : Risk Check
   
   risk --> dashboard : Optimized Signal
   dashboard --> review : User Approval
   review --> orders : Manual Execution
   
   @enduml
   ```

2. **Create Mermaid sequence diagram**:
   ```
   File: repo/main/docs/diagrams/bot-signal-flow.md
   Content:
   ```mermaid
   sequenceDiagram
       participant User
       participant fks_web
       participant fks_ai
       participant StockBot
       participant ForexBot
       participant CryptoBot
       participant fks_data
       participant fks_portfolio
       participant fks_execution
       
       User->>fks_web: Request signal for BTC-USD
       fks_web->>fks_ai: POST /ai/bots/consensus
       fks_ai->>fks_data: GET /api/v1/data/BTC-USD
       fks_data-->>fks_ai: OHLCV Data
       
       fks_ai->>StockBot: analyze(BTC-USD, data)
       StockBot-->>fks_ai: BUY signal (0.7 confidence)
       
       fks_ai->>ForexBot: analyze(BTC-USD, data)
       ForexBot-->>fks_ai: HOLD signal (0.5 confidence)
       
       fks_ai->>CryptoBot: analyze(BTC-USD, data)
       CryptoBot-->>fks_ai: BUY signal (0.8 confidence, BTC priority)
       
       fks_ai->>fks_ai: Multi-agent debate
       fks_ai-->>fks_ai: Consensus: BUY (0.75 confidence)
       
       fks_ai-->>fks_web: Consensus signal
       fks_web->>fks_portfolio: POST /api/signals/bot-signals
       fks_portfolio->>fks_portfolio: Optimize (BTC 50-60%)
       fks_portfolio-->>fks_web: Optimized signal
       
       fks_web->>User: Display signal for review
       User->>fks_web: Approve signal
       fks_web->>fks_execution: POST /api/execution/manual
       fks_execution-->>fks_web: Order placed
   ```
   ```

3. **Generate diagrams** (if PlantUML/Mermaid tools available):
   ```bash
   # Install PlantUML (if not available)
   # Generate PNG from PlantUML
   plantuml repo/main/docs/diagrams/multi-agent-architecture.puml
   
   # Mermaid diagrams can be rendered in Markdown viewers
   ```

**Deliverable**: Architecture diagrams (PlantUML, Mermaid)

**Success Criteria**: Diagrams accurately represent system architecture

---

### Task 2.6: Create Design Specification Document

**Objective**: Compile all design work into comprehensive specification

**Actions for AI Agent**:

1. **Create design specification**:
   ```
   File: repo/main/docs/design-specification-multi-agent.md
   Content:
   # Multi-Agent Trading Bots - Design Specification
   
   ## Executive Summary
   [Summary of design decisions]
   
   ## Agent Architecture
   [From Task 2.1]
   
   ## LangGraph Workflow
   [From Task 2.2]
   
   ## Integration Points
   [From Task 2.3]
   
   ## Chaos Engineering
   [From Task 2.4]
   
   ## Architecture Diagrams
   [From Task 2.5]
   
   ## API Specifications
   [From Task 2.3]
   
   ## Security Considerations
   - Authentication via fks_auth
   - Rate limiting via NGINX
   - Input validation
   - Secret management
   
   ## Performance Targets
   - Signal generation: <100ms
   - Consensus calculation: <50ms
   - Total workflow: <200ms
   
   ## Testing Strategy
   - Unit tests for each bot
   - Integration tests for workflow
   - Chaos tests for resilience
   - Backtesting on 30+ days
   ```

**Deliverable**: Complete design specification document

**Success Criteria**: Design reviewed and approved, ready for implementation

---

## 📋 Phase 3: Development - Core Bots (Weeks 4-6)

### Task 3.1: Implement StockBot

**Objective**: Implement and unit-test StockBot

**Actions for AI Agent**:

1. **Create StockBot implementation** (already designed in Task 2.1, now implement):
   ```
   File: repo/ai/src/agents/stockbot.py
   [Use code from Task 2.1]
   ```

2. **Create unit tests**:
   ```
   File: repo/ai/tests/test_stockbot.py
   Content:
   import pytest
   import pandas as pd
   import numpy as np
   from src.agents.stockbot import StockBot
   
   @pytest.fixture
   def stockbot():
       return StockBot()
   
   @pytest.fixture
   def sample_market_data():
       """Generate sample market data"""
       dates = pd.date_range(start='2024-01-01', periods=200, freq='D')
       np.random.seed(42)
       close = 100 + np.cumsum(np.random.randn(200) * 2)
       high = close + np.random(200) * 2
       low = close - np.random(200) * 2
       volume = np.random.randint(1000000, 5000000, 200)
       
       return {
           "data": [
               {
                   "timestamp": d.isoformat(),
                   "open": c * 0.99,
                   "high": h,
                   "low": l,
                   "close": c,
                   "volume": v
               }
               for d, c, h, l, v in zip(dates, close, high, low, volume)
           ]
       }
   
   @pytest.mark.asyncio
   async def test_stockbot_buy_signal(stockbot, sample_market_data):
       """Test StockBot generates BUY signal"""
       result = await stockbot.analyze("AAPL.US", sample_market_data)
       
       assert "signal" in result
       assert result["signal"] in ["BUY", "SELL", "HOLD"]
       assert "confidence" in result
       assert 0.0 <= result["confidence"] <= 1.0
       
       if result["signal"] == "BUY":
           assert "entry_price" in result
           assert "stop_loss" in result
           assert "take_profit" in result
           assert result["stop_loss"] < result["entry_price"]
           assert result["take_profit"] > result["entry_price"]
   
   @pytest.mark.asyncio
   async def test_stockbot_insufficient_data(stockbot):
       """Test StockBot handles insufficient data"""
       result = await stockbot.analyze("AAPL.US", {"data": []})
       
       assert result["signal"] == "HOLD"
       assert result["confidence"] == 0.0
       assert "Insufficient data" in result["reason"]
   
   @pytest.mark.asyncio
   async def test_stockbot_fetch_data(stockbot):
       """Test StockBot fetches data from fks_data"""
       # Mock httpx response
       # Test data fetching logic
       pass
   ```

3. **Create integration test**:
   ```
   File: repo/ai/tests/integration/test_stockbot_integration.py
   Content:
   import pytest
   import httpx
   from src.agents.stockbot import StockBot
   
   @pytest.mark.asyncio
   @pytest.mark.integration
   async def test_stockbot_with_fks_data():
       """Test StockBot with real fks_data service"""
       bot = StockBot()
       
       # Fetch real data
       market_data = await bot.fetch_market_data("AAPL.US", interval="1d")
       
       assert "data" in market_data or len(market_data) > 0
       
       # Generate signal
       signal = await bot.analyze("AAPL.US", market_data)
       
       assert "signal" in signal
       assert "confidence" in signal
   ```

4. **Run tests**:
   ```bash
   cd repo/ai
   pytest tests/test_stockbot.py -v
   pytest tests/integration/test_stockbot_integration.py -v --integration
   ```

**Deliverable**: StockBot implementation with 80%+ test coverage

**Success Criteria**: All tests pass, StockBot generates valid signals

---

### Task 3.2: Implement ForexBot

**Objective**: Implement and unit-test ForexBot

**Actions for AI Agent**:

1. **Create ForexBot implementation** (use code from Task 2.1)

2. **Create unit tests** (similar structure to StockBot)

3. **Create integration tests**

4. **Run tests and verify**

**Deliverable**: ForexBot implementation with 80%+ test coverage

**Success Criteria**: All tests pass, ForexBot generates valid signals

---

### Task 3.3: Implement CryptoBot

**Objective**: Implement and unit-test CryptoBot with BTC priority

**Actions for AI Agent**:

1. **Create CryptoBot implementation** (use code from Task 2.1, ensure BTC rules)

2. **Create unit tests with BTC-specific cases**:
   ```
   File: repo/ai/tests/test_cryptobot.py
   Content:
   # ... standard tests ...
   
   @pytest.mark.asyncio
   async def test_cryptobot_btc_priority(cryptobot, sample_market_data):
       """Test CryptoBot prioritizes BTC"""
       result = await cryptobot.analyze("BTC-USD", sample_market_data)
       
       if result["signal"] == "BUY":
           assert result.get("btc_priority") == True
           # BTC should have wider stops
           stop_pct = (result["entry_price"] - result["stop_loss"]) / result["entry_price"]
           assert stop_pct >= 0.10  # 10% stop for BTC
   ```

3. **Create integration tests**

4. **Run tests and verify**

**Deliverable**: CryptoBot implementation with BTC priority, 80%+ test coverage

**Success Criteria**: All tests pass, CryptoBot correctly prioritizes BTC

---

### Task 3.4: Implement Multi-Agent Framework

**Objective**: Implement LangGraph workflow and debate system

**Actions for AI Agent**:

1. **Create workflow implementation** (use code from Task 2.2)

2. **Create unit tests**:
   ```
   File: repo/ai/tests/test_multi_agent_workflow.py
   Content:
   import pytest
   from src.agents.multi_agent_workflow import MultiAgentWorkflow
   
   @pytest.mark.asyncio
   async def test_workflow_consensus():
       """Test workflow generates consensus"""
       workflow = MultiAgentWorkflow()
       
       # Mock market data
       market_data = {...}
       
       result = await workflow.run("BTC-USD", market_data)
       
       assert "final_signal" in result
       assert "bot_analysis" in result
       assert "consensus" in result["bot_analysis"]
   ```

3. **Create integration tests**

4. **Run tests and verify**

**Deliverable**: Complete multi-agent workflow with tests

**Success Criteria**: Workflow runs end-to-end, generates consensus signals

---

### Task 3.5: Create Bot API Endpoints

**Objective**: Create FastAPI endpoints for bot signals

**Actions for AI Agent**:

1. **Create bot routes**:
   ```
   File: repo/ai/src/api/bot_routes.py
   Content:
   from fastapi import APIRouter, HTTPException, Query
   from typing import Optional, Dict, Any
   from ..agents.stockbot import StockBot
   from ..agents.forexbot import ForexBot
   from ..agents.cryptobot import CryptoBot
   from ..agents.multi_agent_workflow import MultiAgentWorkflow
   import httpx
   from loguru import logger
   
   router = APIRouter(prefix="/ai/bots", tags=["trading-bots"])
   
   stockbot = StockBot()
   forexbot = ForexBot()
   cryptobot = CryptoBot()
   workflow = MultiAgentWorkflow()
   
   @router.get("/stock/signal")
   async def get_stock_signal(
       symbol: str = Query(..., description="Stock symbol (e.g., AAPL.US)"),
       interval: str = Query("1h", description="Data interval")
   ):
       """Get StockBot signal for symbol"""
       try:
           market_data = await stockbot.fetch_market_data(symbol, interval)
           signal = await stockbot.analyze(symbol, market_data)
           return signal
       except Exception as e:
           logger.error(f"StockBot error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.get("/forex/signal")
   async def get_forex_signal(
       symbol: str = Query(..., description="Forex pair (e.g., EUR/USD)"),
       interval: str = Query("1h", description="Data interval")
   ):
       """Get ForexBot signal for symbol"""
       try:
           market_data = await forexbot.fetch_market_data(symbol, interval)
           signal = await forexbot.analyze(symbol, market_data)
           return signal
       except Exception as e:
           logger.error(f"ForexBot error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.get("/crypto/signal")
   async def get_crypto_signal(
       symbol: str = Query(..., description="Crypto symbol (e.g., BTC-USD)"),
       interval: str = Query("1h", description="Data interval")
   ):
       """Get CryptoBot signal for symbol"""
       try:
           market_data = await cryptobot.fetch_market_data(symbol, interval)
           signal = await cryptobot.analyze(symbol, market_data)
           return signal
       except Exception as e:
           logger.error(f"CryptoBot error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.post("/debate")
   async def run_debate(request: Dict[str, Any]):
       """Run multi-agent debate"""
       try:
           symbol = request.get("symbol")
           market_data = request.get("market_data", {})
           
           if not symbol:
               raise HTTPException(status_code=400, detail="symbol required")
           
           result = await workflow.run(symbol, market_data)
           return result
       except Exception as e:
           logger.error(f"Debate error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.get("/consensus")
   async def get_consensus(
       symbol: str = Query(..., description="Symbol to analyze"),
       interval: str = Query("1h", description="Data interval")
   ):
       """Get consensus signal from all bots"""
       try:
           # Fetch market data
           async with httpx.AsyncClient() as client:
               response = await client.get(
                   f"http://fks_data:8003/api/v1/data/{symbol}",
                   params={"interval": interval, "limit": 200}
               )
               response.raise_for_status()
               market_data = response.json()
           
           # Run workflow
           result = await workflow.run(symbol, market_data)
           return result
       except Exception as e:
           logger.error(f"Consensus error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   ```

2. **Register routes in main app**:
   ```
   File: repo/ai/src/api/routes.py
   # Add import
   from .bot_routes import router as bot_router
   
   # Add to app
   app.include_router(bot_router)
   ```

3. **Create API tests**:
   ```
   File: repo/ai/tests/api/test_bot_routes.py
   Content:
   import pytest
   from fastapi.testclient import TestClient
   from src.api.routes import app
   
   client = TestClient(app)
   
   def test_stock_signal_endpoint():
       response = client.get("/ai/bots/stock/signal?symbol=AAPL.US")
       assert response.status_code == 200
       data = response.json()
       assert "signal" in data
       assert "confidence" in data
   ```

**Deliverable**: Bot API endpoints with tests

**Success Criteria**: All endpoints work, return valid signals

---

## 📋 Phase 4: Integration and Collaboration (Weeks 6-8)

### Task 4.1: Integrate Bots with fks_portfolio

**Objective**: Connect bot signals to portfolio optimization

**Actions for AI Agent**:

1. **Create bot signal receiver in fks_portfolio**:
   ```
   File: repo/portfolio/src/api/bot_signal_routes.py
   Content:
   from fastapi import APIRouter, HTTPException
   from typing import Dict, Any, List
   from pydantic import BaseModel
   from ..signals.signal_generator import SignalGenerator
   from ..portfolio.portfolio import Portfolio
   from ..optimization.mean_variance import MeanVarianceOptimizer
   from loguru import logger
   
   router = APIRouter(prefix="/api/signals", tags=["bot-signals"])
   
   class BotSignalRequest(BaseModel):
       symbol: str
       signals: Dict[str, Any]
       consensus: Dict[str, Any]
   
   @router.post("/bot-signals")
   async def receive_bot_signals(request: BotSignalRequest):
       """Receive bot signals and optimize portfolio"""
       try:
           # Convert bot signal to TradingSignal
           from ..signals.trading_signal import TradingSignal, SignalType, SignalStrength
           from ..signals.trade_categories import TradeCategory
           
           consensus = request.consensus
           signal_type = SignalType.BUY if consensus.get("signal") == "BUY" else SignalType.SELL
           
           trading_signal = TradingSignal(
               symbol=request.symbol,
               signal_type=signal_type,
               category=TradeCategory.SWING,  # Default, adjust based on bot
               entry_price=consensus.get("entry_price", 0),
               take_profit=consensus.get("take_profit", 0),
               stop_loss=consensus.get("stop_loss", 0),
               confidence=consensus.get("confidence", 0.5),
               strength=SignalStrength.STRONG if consensus.get("confidence", 0) > 0.7 else SignalStrength.MODERATE,
               ai_enhancements={
                   "bot_analysis": request.signals,
                   "consensus": consensus,
                   "source": "multi-agent-bots"
               }
           )
           
           # Apply portfolio optimization
           portfolio = Portfolio()
           optimizer = MeanVarianceOptimizer()
           
           # Get current portfolio
           current_allocation = portfolio.get_allocation()
           
           # Optimize with new signal
           optimized = optimizer.optimize(
               assets=[request.symbol],
               target_btc_pct=0.55,  # 50-60% BTC
               constraints={"max_position": 0.20}  # Max 20% per asset
           )
           
           return {
               "signal": trading_signal.to_dict(),
               "optimized_allocation": optimized,
               "btc_allocation": optimized.get("BTC", 0),
               "recommendation": "BUY" if optimized.get(request.symbol, 0) > 0 else "HOLD"
           }
       except Exception as e:
           logger.error(f"Bot signal integration error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   ```

2. **Update portfolio routes**:
   ```
   File: repo/portfolio/src/api/routes.py
   # Add import
   from .bot_signal_routes import router as bot_signal_router
   
   # Add to app
   app.include_router(bot_signal_router)
   ```

3. **Create integration tests**

**Deliverable**: Bot signals integrated with portfolio optimization

**Success Criteria**: Bot signals flow through portfolio, BTC constraints enforced

---

### Task 4.2: Enhance fks_web Dashboard

**Objective**: Add bot monitoring to web dashboard

**Actions for AI Agent**:

1. **Create bot dashboard view**:
   ```
   File: repo/web/src/portfolio/views.py
   # Add to existing file
   
   class BotDashboardView(LoginRequiredMixin, TemplateView):
       template_name = "portfolio/bot_dashboard.html"
       
       def get_context_data(self, **kwargs):
           context = super().get_context_data(**kwargs)
           
           # Fetch bot signals
           try:
               response = requests.get(
                   f"{PORTFOLIO_SERVICE_URL}/api/signals/bot-signals/recent",
                   timeout=10
               )
               if response.status_code == 200:
                   context["bot_signals"] = response.json()
           except Exception as e:
               logger.error(f"Error fetching bot signals: {e}")
               context["bot_signals"] = []
           
           return context
   ```

2. **Create bot dashboard template**:
   ```
   File: repo/web/src/templates/portfolio/bot_dashboard.html
   Content:
   {% extends "base.html" %}
   
   {% block content %}
   <div class="container-fluid">
       <h1>Multi-Agent Bot Dashboard</h1>
       
       <!-- Bot Status Cards -->
       <div class="row">
           <div class="col-md-4">
               <div class="card">
                   <div class="card-header">StockBot</div>
                   <div class="card-body">
                       <p>Status: Active</p>
                       <p>Last Signal: ...</p>
                   </div>
               </div>
           </div>
           <!-- Similar for ForexBot and CryptoBot -->
       </div>
       
       <!-- Consensus Signals -->
       <div class="row mt-4">
           <div class="col-12">
               <h2>Consensus Signals</h2>
               <table class="table">
                   <!-- Signal table -->
               </table>
           </div>
       </div>
   </div>
   {% endblock %}
   ```

3. **Add route**:
   ```
   File: repo/web/src/portfolio/urls.py
   path("bots/", views.BotDashboardView.as_view(), name="bot_dashboard"),
   ```

**Deliverable**: Bot dashboard in fks_web

**Success Criteria**: Dashboard displays bot signals and consensus

---

### Task 4.3: Implement RAG Trading Chatbot

**Objective**: Build RAG-powered chatbot for trade queries

**Actions for AI Agent**:

1. **Create RAG chatbot service**:
   ```
   File: repo/ai/src/rag/trading_chatbot.py
   Content:
   from langchain.vectorstores import Chroma
   from langchain.embeddings import OllamaEmbeddings
   from langchain.llms import Ollama
   from langchain.chains import RetrievalQA
   from typing import List, Dict, Any
   import pandas as pd
   
   class TradingChatbot:
       """RAG-powered chatbot for trading queries"""
       
       def __init__(self):
           self.embeddings = OllamaEmbeddings(model="llama3.2")
           self.llm = Ollama(model="llama3.2")
           self.vectorstore = None
       
       def load_trade_history(self, trades: List[Dict[str, Any]]):
           """Load trade history into vector store"""
           # Convert trades to documents
           documents = []
           for trade in trades:
               doc = f"""
               Trade: {trade['symbol']}
               Entry: {trade['entry_price']}
               Exit: {trade['exit_price']}
               PnL: {trade['pnl']}
               Strategy: {trade['strategy']}
               Date: {trade['date']}
               """
               documents.append(doc)
           
           # Create vector store
           self.vectorstore = Chroma.from_texts(
               documents,
               embedding=self.embeddings
           )
       
       def query(self, question: str) -> str:
           """Answer trading question using RAG"""
           if not self.vectorstore:
               return "No trade history loaded"
           
           qa_chain = RetrievalQA.from_chain_type(
               llm=self.llm,
               chain_type="stuff",
               retriever=self.vectorstore.as_retriever()
           )
           
           result = qa_chain.run(question)
           return result
   ```

2. **Create chatbot API endpoint**:
   ```
   File: repo/ai/src/api/chatbot_routes.py
   Content:
   from fastapi import APIRouter
   from pydantic import BaseModel
   from ..rag.trading_chatbot import TradingChatbot
   
   router = APIRouter(prefix="/ai/chatbot", tags=["chatbot"])
   
   chatbot = TradingChatbot()
   
   class ChatRequest(BaseModel):
       question: str
       context: Dict[str, Any] = {}
   
   @router.post("/query")
   async def chat(request: ChatRequest):
       """Query trading chatbot"""
       answer = chatbot.query(request.question)
       return {"answer": answer}
   ```

**Deliverable**: RAG trading chatbot

**Success Criteria**: Chatbot answers trade-related questions using historical data

---

## 📋 Phase 5: Testing and Resilience (Weeks 8-10)

### Task 5.1: Implement Chaos Engineering

**Objective**: Integrate Chaos Mesh and create experiments

**Actions for AI Agent**:

1. **Install Chaos Mesh** (use script from Task 2.4)

2. **Create chaos experiment orchestrator**:
   ```
   File: repo/monitor/src/chaos/orchestrator.py
   Content:
   from kubernetes import client, config
   from typing import List, Dict, Any
   import yaml
   from loguru import logger
   
   class ChaosOrchestrator:
       """Orchestrate chaos experiments for FKS"""
       
       def __init__(self):
           config.load_incluster_config()  # Or kubeconfig for local
           self.api = client.CustomObjectsApi()
           self.namespace = "fks-trading"
       
       def run_experiment(self, experiment_yaml: str):
           """Run chaos experiment from YAML"""
           experiment = yaml.safe_load(experiment_yaml)
           
           try:
               self.api.create_namespaced_custom_object(
                   group="chaos-mesh.org",
                   version="v1alpha1",
                   namespace=self.namespace,
                   plural="networkchaos",  # or podchaos, etc.
                   body=experiment
               )
               logger.info(f"Chaos experiment started: {experiment['metadata']['name']}")
           except Exception as e:
               logger.error(f"Failed to start experiment: {e}")
       
       def stop_experiment(self, experiment_name: str, experiment_type: str):
           """Stop chaos experiment"""
           try:
               self.api.delete_namespaced_custom_object(
                   group="chaos-mesh.org",
                   version="v1alpha1",
                   namespace=self.namespace,
                   plural=experiment_type,
                   name=experiment_name
               )
               logger.info(f"Chaos experiment stopped: {experiment_name}")
           except Exception as e:
               logger.error(f"Failed to stop experiment: {e}")
   ```

3. **Create chaos test suite**:
   ```
   File: repo/monitor/tests/test_chaos.py
   Content:
   import pytest
   from src.chaos.orchestrator import ChaosOrchestrator
   
   @pytest.mark.chaos
   def test_network_delay_recovery():
       """Test system recovers from network delay"""
       orchestrator = ChaosOrchestrator()
       
       # Start network delay experiment
       # Verify system continues operating
       # Stop experiment
       # Verify full recovery
       pass
   ```

**Deliverable**: Chaos engineering framework integrated

**Success Criteria**: Chaos experiments can be run, system survives 95% of scenarios

---

### Task 5.2: Comprehensive Testing

**Objective**: Create full test suite for bots and integration

**Actions for AI Agent**:

1. **Create end-to-end test**:
   ```
   File: repo/ai/tests/e2e/test_full_workflow.py
   Content:
   import pytest
   import httpx
   
   @pytest.mark.e2e
   async def test_full_bot_workflow():
       """Test full workflow: data → bots → portfolio → web"""
       # Test complete signal generation and optimization flow
       pass
   ```

2. **Create performance tests**

3. **Create backtesting suite**

**Deliverable**: Comprehensive test suite with 90%+ coverage

**Success Criteria**: All tests pass, performance targets met

---

## 📋 Phase 6: Deployment and Monitoring (Weeks 10-11)

### Task 6.1: Dockerize and Deploy

**Objective**: Containerize bots and deploy to production

**Actions for AI Agent**:

1. **Update Dockerfiles**

2. **Update docker-compose.yml**

3. **Create deployment scripts**

4. **Deploy to staging, then production**

**Deliverable**: Bots deployed and running

**Success Criteria**: Zero-downtime deployment, all services healthy

---

## 📋 Phase 7: Iteration and Optimization (Week 12+)

### Task 7.1: Monitor and Iterate

**Objective**: Monitor performance and optimize

**Actions for AI Agent**:

1. **Create monitoring dashboards**

2. **Collect performance metrics**

3. **Iterate on strategies**

4. **Update documentation**

**Deliverable**: Optimized system with improved performance

**Success Criteria**: 15%+ improvement in portfolio metrics

---

## 🔧 Service Refinements

### Task SR.1: Refine fks_analyze Service Role

**Objective**: Clarify fks_analyze focuses on internal analysis, not market data

**Actions for AI Agent**:

1. **Review fks_analyze code**:
   ```bash
   cd repo/analyze
   # Identify market analysis code
   # Remove or move to fks_app
   ```

2. **Update fks_analyze to focus on**:
   - Code quality analysis
   - Service health metrics
   - Performance profiling
   - Internal system analytics

3. **Move market analysis to fks_app**:
   ```bash
   cd repo/app
   # Add market analysis modules
   # Trend detection, volatility calculations
   ```

**Deliverable**: fks_analyze refocused, market analysis in fks_app

**Success Criteria**: Clear service boundaries, no overlap

---

### Task SR.2: Create fks_engine Service (Optional)

**Objective**: Create lightweight service for advanced market computations

**Actions for AI Agent**:

1. **Create new service structure**:
   ```
   repo/engine/
   ├── src/
   │   ├── market/
   │   │   ├── trend_analyzer.py
   │   │   ├── volatility_calculator.py
   │   │   └── advanced_indicators.py
   │   └── api/
   │       └── routes.py
   ├── Dockerfile
   ├── docker-compose.yml
   └── requirements.txt
   ```

2. **Implement advanced computations**

3. **Add to service registry** (port 8013)

**Deliverable**: fks_engine service (if needed)

**Success Criteria**: Service operational, integrated with fks_app

---

## 📊 Success Metrics

### Performance Targets
- Signal generation: <100ms
- Consensus calculation: <50ms
- Total workflow: <200ms
- System uptime: >99%
- Chaos survival rate: >95%

### Business Metrics
- Signal accuracy: 10-20% improvement
- Portfolio performance: 15%+ improvement
- User satisfaction: >80%
- Deployment frequency: Daily
- Mean time to recovery: <5 minutes

---

## 🎯 Implementation Checklist

### Phase 1: Preparation ✅
- [ ] Research complete
- [ ] Services audited
- [ ] Bot specifications defined
- [ ] Risk assessment complete
- [ ] Tools installed
- [ ] Feasibility report approved

### Phase 2: Design ✅
- [ ] Agent structure designed
- [ ] LangGraph workflow designed
- [ ] Integration points defined
- [ ] Chaos engineering designed
- [ ] Architecture diagrams created
- [ ] Design specification approved

### Phase 3: Development
- [ ] StockBot implemented
- [ ] ForexBot implemented
- [ ] CryptoBot implemented
- [ ] Multi-agent framework implemented
- [ ] API endpoints created
- [ ] Unit tests written (80%+ coverage)

### Phase 4: Integration
- [ ] Bots integrated with fks_portfolio
- [ ] fks_web dashboard enhanced
- [ ] RAG chatbot implemented
- [ ] End-to-end flow working

### Phase 5: Testing
- [ ] Chaos engineering integrated
- [ ] Integration tests complete
- [ ] Performance tests pass
- [ ] Backtesting complete

### Phase 6: Deployment
- [ ] Services dockerized
- [ ] CI/CD pipelines updated
- [ ] Staging deployment
- [ ] Production deployment

### Phase 7: Iteration
- [ ] Monitoring dashboards created
- [ ] Performance optimized
- [ ] Documentation updated

---

**This document provides complete, step-by-step instructions for AI agents to implement the multi-agent trading bot system. Follow tasks sequentially, ensuring all deliverables are created and success criteria are met.**

