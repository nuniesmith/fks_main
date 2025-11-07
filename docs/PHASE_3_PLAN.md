# Phase 3: Integrations and Centralization - Kickoff

## Overview

Centralize all external communications in `fks_execution` service with a plugin architecture. This phase consolidates exchange interactions (CCXT), broker integrations (NinjaTrader, MT5), and webhook handling into a unified execution hub.

**Timeline**: 1-2 weeks (9 days planned)  
**Status**: IN PROGRESS 🚧  
**Started**: November 4, 2025

---

## Goals

1. **Plugin Framework**: Modular ExecutionPlugin trait for extensible integrations
2. **Broker Migration**: Move fks_ninja and mt5 to plugins
3. **CCXT Integration**: Unified exchange interface (Binance, Coinbase, Kraken, etc.)
4. **Webhook System**: TradingView signal validation and execution
5. **Security & Validation**: Rate limiting, auth, risk checks

---

## Architecture Vision

### Before (Current State):
```
fks_api ──┬──> fks_ninja (NinjaTrader, separate service)
          ├──> fks_metatrader (MT5, separate service)
          └──> Direct exchange API calls (scattered)
```

### After (Phase 3):
```
fks_api ──> fks_execution (Unified Hub)
            ├── plugins/
            │   ├── ninja_plugin.rs (NinjaTrader via C# bindings)
            │   ├── mt5_plugin.rs (MetaTrader via DLL bindings)
            │   └── ccxt_plugin.py (Exchanges via CCXT)
            ├── exchanges/
            │   └── manager.py (CCXT wrapper)
            └── webhooks/
                └── tradingview.py (Signal validation)
```

**Benefits**:
- Single point of entry for all executions
- Consistent error handling and logging
- Easier testing (mock plugins)
- Security centralized (auth, rate limits)
- Simplified deployment (fewer services)

---

## Phase 3.1: Plugin Framework (Days 1-2)

### Task 3.1.1: Define ExecutionPlugin Trait ✅ IN PROGRESS

**File**: `/src/services/execution/src/plugins/mod.rs`

**Trait Definition**:
```rust
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Order {
    pub symbol: String,
    pub side: OrderSide,
    pub order_type: OrderType,
    pub quantity: f64,
    pub price: Option<f64>,
    pub stop_loss: Option<f64>,
    pub take_profit: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrderSide {
    Buy,
    Sell,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrderType {
    Market,
    Limit,
    Stop,
    StopLimit,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionResult {
    pub success: bool,
    pub order_id: Option<String>,
    pub filled_quantity: f64,
    pub average_price: f64,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarketData {
    pub symbol: String,
    pub bid: f64,
    pub ask: f64,
    pub last: f64,
    pub volume: f64,
    pub timestamp: i64,
}

#[async_trait]
pub trait ExecutionPlugin: Send + Sync {
    /// Initialize the plugin with configuration
    async fn init(&mut self, config: serde_json::Value) -> Result<(), Box<dyn std::error::Error>>;
    
    /// Execute an order
    async fn execute_order(&self, order: Order) -> Result<ExecutionResult, Box<dyn std::error::Error>>;
    
    /// Fetch current market data
    async fn fetch_data(&self, symbol: &str) -> Result<MarketData, Box<dyn std::error::Error>>;
    
    /// Get plugin name
    fn name(&self) -> &str;
    
    /// Health check
    async fn health_check(&self) -> Result<bool, Box<dyn std::error::Error>>;
}
```

**Acceptance Criteria**:
- [x] Trait defined with 5 core methods
- [ ] Supports async operations
- [ ] Serializable data structures
- [ ] Error handling with Box<dyn Error>

---

### Task 3.1.2: Python Wrappers via PyO3 (Days 2-3)

**File**: `/src/services/execution/src/python_bridge.rs`

**Goal**: Allow Python code (CCXT) to call Rust ExecutionPlugin implementations

**Dependencies**:
```toml
[dependencies]
pyo3 = { version = "0.20", features = ["extension-module"] }
pyo3-asyncio = { version = "0.20", features = ["tokio-runtime"] }
```

**Implementation**:
```rust
use pyo3::prelude::*;
use pyo3_asyncio::tokio::future_into_py;

#[pyclass]
struct PyExecutionPlugin {
    plugin: Arc<dyn ExecutionPlugin>,
}

#[pymethods]
impl PyExecutionPlugin {
    fn execute_order<'py>(
        &self,
        py: Python<'py>,
        order: PyObject,
    ) -> PyResult<&'py PyAny> {
        let plugin = self.plugin.clone();
        future_into_py(py, async move {
            // Convert Python order to Rust Order
            let rust_order: Order = /* conversion */;
            let result = plugin.execute_order(rust_order).await?;
            // Convert result back to Python
            Ok(Python::with_gil(|py| result.into_py(py)))
        })
    }
}
```

**Acceptance Criteria**:
- [ ] Python can call Rust plugin methods
- [ ] Async bridge working (Tokio ↔ asyncio)
- [ ] Data serialization Python ↔ Rust

---

## Phase 3.2: Broker Migration (Days 3-5)

### Task 3.2.1: Migrate fks_ninja to Plugin

**Current**: `/src/services/ninja/` (C# service)  
**Target**: `/src/services/execution/src/plugins/ninja_plugin.rs`

**Approach**: Use `csbindgen` to generate Rust bindings for C# DLLs

**Steps**:
1. Keep C# NinjaTrader code as-is
2. Build C# project to DLL
3. Use `csbindgen` to generate Rust bindings
4. Implement `ExecutionPlugin` trait wrapping C# calls

**File**: `/src/services/execution/src/plugins/ninja_plugin.rs`
```rust
use crate::plugins::{ExecutionPlugin, Order, ExecutionResult, MarketData};
use async_trait::async_trait;

// Generated by csbindgen from C# DLL
mod ninja_bindings;

pub struct NinjaPlugin {
    // Handle to C# object
    handle: *mut std::ffi::c_void,
}

#[async_trait]
impl ExecutionPlugin for NinjaPlugin {
    async fn init(&mut self, config: serde_json::Value) -> Result<(), Box<dyn std::error::Error>> {
        // Call C# initialization via bindings
        unsafe {
            ninja_bindings::InitializeNinja(/* params */);
        }
        Ok(())
    }
    
    async fn execute_order(&self, order: Order) -> Result<ExecutionResult, Box<dyn std::error::Error>> {
        // Convert Rust Order to C# format
        // Call C# method via bindings
        // Convert result back to Rust
        todo!()
    }
    
    // ... other methods
}
```

**Acceptance Criteria**:
- [ ] C# bindings generated
- [ ] ExecutionPlugin trait implemented
- [ ] Orders route through plugin
- [ ] NinjaTrader functionality preserved

---

### Task 3.2.2: Migrate mt5 to Plugin

**Current**: `/src/services/metatrader/` (Python service)  
**Target**: `/src/services/execution/src/plugins/mt5_plugin.rs`

**Approach**: Use `bindgen` for MT5 DLL bindings (or keep Python wrapper)

**Option A - Rust Direct**:
```rust
mod mt5_bindings; // Generated by bindgen

pub struct MT5Plugin {
    // MT5 connection handle
}

#[async_trait]
impl ExecutionPlugin for MT5Plugin {
    async fn execute_order(&self, order: Order) -> Result<ExecutionResult, Box<dyn std::error::Error>> {
        // Call MT5 DLL functions
        unsafe {
            mt5_bindings::OrderSend(/* params */);
        }
        Ok(ExecutionResult { /* ... */ })
    }
}
```

**Option B - Python Wrapper** (simpler, recommended):
```python
# /src/services/execution/plugins/mt5_plugin.py
import MetaTrader5 as mt5

class MT5Plugin:
    async def execute_order(self, order):
        # Existing MT5 code
        result = mt5.order_send(order)
        return ExecutionResult(success=result.retcode == mt5.TRADE_RETCODE_DONE)
```

**Decision**: Start with Option B (Python wrapper), migrate to Rust if needed

**Acceptance Criteria**:
- [ ] MT5 functionality as plugin
- [ ] Compatible with ExecutionPlugin interface
- [ ] Tests passing

---

### Task 3.2.3: Test Plugin Bridges

**File**: `/tests/unit/test_trading/test_plugins.py`

```python
import pytest
from src.services.execution.plugins import NinjaPlugin, MT5Plugin

@pytest.mark.asyncio
async def test_ninja_plugin_execute_order():
    """Test NinjaTrader plugin executes orders."""
    plugin = NinjaPlugin()
    await plugin.init({"account": "Sim101"})
    
    order = {
        "symbol": "ES",
        "side": "Buy",
        "quantity": 1,
        "order_type": "Market"
    }
    
    result = await plugin.execute_order(order)
    
    assert result["success"] is True
    assert result["order_id"] is not None

@pytest.mark.asyncio
async def test_mt5_plugin_fetch_data():
    """Test MT5 plugin fetches market data."""
    plugin = MT5Plugin()
    await plugin.init({"login": 12345, "password": "pass"})
    
    data = await plugin.fetch_data("EURUSD")
    
    assert data["symbol"] == "EURUSD"
    assert data["bid"] > 0
    assert data["ask"] > data["bid"]
```

**Acceptance Criteria**:
- [ ] 10+ tests for plugin functionality
- [ ] Mocked broker responses
- [ ] Error handling validated

---

## Phase 3.3: CCXT Integration (Days 6-7)

### Task 3.3.1: Add CCXT Integration

**File**: `/src/services/execution/requirements.txt`
```
ccxt>=4.0.0
```

**File**: `/src/services/execution/exchanges/manager.py`
```python
import ccxt
from typing import Dict, List, Optional

class ExchangeManager:
    """Unified interface for crypto exchanges via CCXT."""
    
    def __init__(self):
        self.exchanges: Dict[str, ccxt.Exchange] = {}
    
    async def init_exchange(self, exchange_id: str, credentials: Dict) -> None:
        """Initialize an exchange connection.
        
        Args:
            exchange_id: CCXT exchange ID (e.g., 'binance', 'coinbase')
            credentials: API key, secret, etc.
        """
        exchange_class = getattr(ccxt, exchange_id)
        self.exchanges[exchange_id] = exchange_class({
            'apiKey': credentials.get('api_key'),
            'secret': credentials.get('api_secret'),
            'enableRateLimit': True,
        })
        
        # Test connection
        await self.exchanges[exchange_id].load_markets()
    
    async def fetch_ticker(self, exchange_id: str, symbol: str) -> Dict:
        """Fetch current ticker data.
        
        Returns:
            {
                'symbol': 'BTC/USDT',
                'bid': 67500.0,
                'ask': 67505.0,
                'last': 67502.5,
                'volume': 12345.67
            }
        """
        exchange = self.exchanges[exchange_id]
        ticker = await exchange.fetch_ticker(symbol)
        return {
            'symbol': ticker['symbol'],
            'bid': ticker['bid'],
            'ask': ticker['ask'],
            'last': ticker['last'],
            'volume': ticker['baseVolume']
        }
    
    async def place_order(
        self,
        exchange_id: str,
        symbol: str,
        side: str,
        order_type: str,
        amount: float,
        price: Optional[float] = None,
        stop_loss: Optional[float] = None,
        take_profit: Optional[float] = None
    ) -> Dict:
        """Place an order with optional TP/SL.
        
        Args:
            exchange_id: Exchange to use
            symbol: Trading pair (e.g., 'BTC/USDT')
            side: 'buy' or 'sell'
            order_type: 'market', 'limit', 'stop_loss', etc.
            amount: Order quantity
            price: Limit price (required for limit orders)
            stop_loss: Stop-loss price
            take_profit: Take-profit price
        
        Returns:
            {
                'id': '12345',
                'symbol': 'BTC/USDT',
                'status': 'closed',
                'filled': 0.1,
                'average': 67500.0
            }
        """
        exchange = self.exchanges[exchange_id]
        
        # Place main order
        order = await exchange.create_order(
            symbol=symbol,
            type=order_type,
            side=side,
            amount=amount,
            price=price
        )
        
        # Place stop-loss if provided
        if stop_loss:
            await exchange.create_order(
                symbol=symbol,
                type='stop_loss',
                side='sell' if side == 'buy' else 'buy',
                amount=amount,
                price=stop_loss,
                params={'stopPrice': stop_loss}
            )
        
        # Place take-profit if provided
        if take_profit:
            await exchange.create_order(
                symbol=symbol,
                type='take_profit',
                side='sell' if side == 'buy' else 'buy',
                amount=amount,
                price=take_profit,
                params={'stopPrice': take_profit}
            )
        
        return {
            'id': order['id'],
            'symbol': order['symbol'],
            'status': order['status'],
            'filled': order['filled'],
            'average': order['average']
        }
    
    def list_exchanges(self) -> List[str]:
        """Get list of supported exchanges."""
        return ccxt.exchanges
```

**Acceptance Criteria**:
- [ ] CCXT installed and imported
- [ ] ExchangeManager class complete
- [ ] Supports 10+ major exchanges
- [ ] TP/SL order placement working

---

### Task 3.3.2: CCXT Plugin Wrapper

**File**: `/src/services/execution/plugins/ccxt_plugin.py`
```python
from execution.exchanges.manager import ExchangeManager
from typing import Dict, Optional

class CCXTPlugin:
    """ExecutionPlugin wrapper for CCXT exchanges."""
    
    def __init__(self):
        self.manager = ExchangeManager()
        self.default_exchange = None
    
    async def init(self, config: Dict) -> None:
        """Initialize CCXT plugin.
        
        Config:
            {
                'exchange': 'binance',
                'credentials': {'api_key': '...', 'api_secret': '...'}
            }
        """
        self.default_exchange = config['exchange']
        await self.manager.init_exchange(
            exchange_id=config['exchange'],
            credentials=config['credentials']
        )
    
    async def execute_order(self, order: Dict) -> Dict:
        """Execute order via CCXT."""
        result = await self.manager.place_order(
            exchange_id=self.default_exchange,
            symbol=order['symbol'],
            side=order['side'].lower(),
            order_type=order['order_type'].lower(),
            amount=order['quantity'],
            price=order.get('price'),
            stop_loss=order.get('stop_loss'),
            take_profit=order.get('take_profit')
        )
        
        return {
            'success': result['status'] in ['closed', 'filled'],
            'order_id': result['id'],
            'filled_quantity': result['filled'],
            'average_price': result['average']
        }
    
    async def fetch_data(self, symbol: str) -> Dict:
        """Fetch market data via CCXT."""
        ticker = await self.manager.fetch_ticker(self.default_exchange, symbol)
        return {
            'symbol': ticker['symbol'],
            'bid': ticker['bid'],
            'ask': ticker['ask'],
            'last': ticker['last'],
            'volume': ticker['volume'],
            'timestamp': int(time.time() * 1000)
        }
    
    def name(self) -> str:
        return f"CCXT-{self.default_exchange}"
    
    async def health_check(self) -> bool:
        """Check if exchange connection is alive."""
        try:
            await self.manager.fetch_ticker(self.default_exchange, 'BTC/USDT')
            return True
        except Exception:
            return False
```

**Acceptance Criteria**:
- [ ] CCXTPlugin implements ExecutionPlugin interface
- [ ] Wraps ExchangeManager methods
- [ ] Health check functional

---

### Task 3.3.3: TradingView Webhooks

**File**: `/src/services/execution/webhooks/tradingview.py`
```python
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, validator
from typing import Optional
import hmac
import hashlib

router = APIRouter()

class TradingViewWebhook(BaseModel):
    """TradingView alert webhook payload."""
    symbol: str
    action: str  # BUY, SELL, CLOSE
    quantity: Optional[float] = None
    price: Optional[float] = None
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None
    confidence: Optional[float] = 0.6
    
    @validator('action')
    def validate_action(cls, v):
        if v.upper() not in ['BUY', 'SELL', 'CLOSE']:
            raise ValueError('action must be BUY, SELL, or CLOSE')
        return v.upper()
    
    @validator('confidence')
    def validate_confidence(cls, v):
        if not 0 <= v <= 1:
            raise ValueError('confidence must be between 0 and 1')
        return v

@router.post("/webhook/tradingview")
async def handle_tradingview_webhook(
    payload: TradingViewWebhook,
    signature: Optional[str] = Header(None, alias="X-TradingView-Signature")
):
    """
    Handle TradingView webhook alerts.
    
    Validates signature, checks confidence threshold, routes to appropriate plugin.
    """
    # 1. Verify signature (if configured)
    if signature:
        expected_sig = hmac.new(
            WEBHOOK_SECRET.encode(),
            payload.json().encode(),
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(signature, expected_sig):
            raise HTTPException(status_code=401, detail="Invalid signature")
    
    # 2. Validate confidence threshold
    if payload.confidence < 0.6:
        raise HTTPException(
            status_code=400,
            detail=f"Confidence {payload.confidence} below threshold 0.6"
        )
    
    # 3. Normalize data
    normalized = normalize_webhook_data(payload)
    
    # 4. Risk checks
    risk_check = validate_risk(normalized)
    if not risk_check['passed']:
        raise HTTPException(status_code=400, detail=risk_check['reason'])
    
    # 5. Route to CCXT plugin
    ccxt_plugin = get_plugin('ccxt')
    result = await ccxt_plugin.execute_order(normalized)
    
    return {
        'status': 'success' if result['success'] else 'failed',
        'order_id': result.get('order_id'),
        'message': f"Executed {payload.action} for {payload.symbol}"
    }

def normalize_webhook_data(payload: TradingViewWebhook) -> dict:
    """Normalize webhook data for execution."""
    return {
        'symbol': payload.symbol.replace('BINANCE:', ''),  # Remove exchange prefix
        'side': payload.action,
        'order_type': 'market' if not payload.price else 'limit',
        'quantity': payload.quantity or calculate_position_size(payload.symbol),
        'price': payload.price,
        'stop_loss': payload.stop_loss,
        'take_profit': payload.take_profit
    }

def validate_risk(order: dict) -> dict:
    """Validate order against risk rules."""
    # Check position size (max 1% of capital)
    account_balance = get_account_balance()
    max_position = account_balance * 0.01
    
    if order['quantity'] * order.get('price', 0) > max_position:
        return {
            'passed': False,
            'reason': f"Position size exceeds 1% capital limit"
        }
    
    # Check risk-reward ratio (min 2:1)
    if order['stop_loss'] and order['take_profit']:
        risk = abs(order['price'] - order['stop_loss'])
        reward = abs(order['take_profit'] - order['price'])
        
        if reward / risk < 2.0:
            return {
                'passed': False,
                'reason': f"Risk-reward ratio {reward/risk:.2f} below 2.0 minimum"
            }
    
    return {'passed': True}
```

**Acceptance Criteria**:
- [ ] Webhook endpoint functional
- [ ] Signature verification working
- [ ] Confidence threshold enforced (≥0.6)
- [ ] Risk validation implemented
- [ ] Routes to CCXT plugin

---

## Phase 3.4: Validation and Security (Days 8-9)

### Task 3.4.1: Validation and Normalization

**File**: `/src/services/execution/validation.py`
```python
import numpy as np
from typing import Dict, Any

def normalize_order_data(order: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalize order data handling NaN, type conversion, edge cases.
    
    Ensures:
    - No NaN values
    - Correct types (float for prices, int for quantities)
    - Valid ranges
    """
    normalized = order.copy()
    
    # Handle NaN values
    for key in ['price', 'stop_loss', 'take_profit', 'quantity']:
        if key in normalized:
            value = normalized[key]
            if value is None or (isinstance(value, float) and np.isnan(value)):
                if key == 'quantity':
                    raise ValueError(f"{key} cannot be None or NaN")
                normalized[key] = None
    
    # Type conversion
    if normalized.get('quantity'):
        normalized['quantity'] = float(normalized['quantity'])
    
    if normalized.get('price'):
        normalized['price'] = float(normalized['price'])
    
    # Validate ranges
    if normalized.get('quantity', 0) <= 0:
        raise ValueError("Quantity must be positive")
    
    if normalized.get('price', 0) < 0:
        raise ValueError("Price cannot be negative")
    
    return normalized
```

**Acceptance Criteria**:
- [ ] NaN handling complete
- [ ] Type conversion robust
- [ ] Edge cases covered (zero, negative, very large numbers)

---

### Task 3.4.2: Security Measures

**Features**:
1. **Rate Limiting**: Max 10 requests/second per IP
2. **Authentication**: JWT tokens for webhook endpoints
3. **Circuit Breakers**: Auto-disable on repeated failures

**File**: `/src/services/execution/security.py`
```python
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from datetime import datetime, timedelta
from collections import defaultdict
import time

# Rate limiting
request_counts = defaultdict(list)
RATE_LIMIT = 10  # requests per second

def rate_limit_check(ip: str):
    """Check if IP is within rate limit."""
    now = time.time()
    
    # Remove old timestamps
    request_counts[ip] = [ts for ts in request_counts[ip] if now - ts < 1.0]
    
    if len(request_counts[ip]) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")
    
    request_counts[ip].append(now)

# Authentication
security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)):
    """Verify JWT token."""
    try:
        payload = jwt.decode(
            credentials.credentials,
            JWT_SECRET,
            algorithms=["HS256"]
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Circuit breaker
class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure_time = None
        self.state = "closed"  # closed, open, half-open
    
    def call(self, func):
        """Execute function with circuit breaker protection."""
        if self.state == "open":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "half-open"
            else:
                raise Exception("Circuit breaker is open")
        
        try:
            result = func()
            if self.state == "half-open":
                self.state = "closed"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = "open"
            
            raise e
```

**Acceptance Criteria**:
- [ ] Rate limiting functional (10 req/s)
- [ ] JWT authentication working
- [ ] Circuit breaker prevents cascading failures

---

### Task 3.4.3: Validation Gate

**End-to-End Test**:
```python
@pytest.mark.asyncio
async def test_full_execution_flow():
    """
    Test complete flow: Webhook → Validation → CCXT → Execution
    """
    # 1. Send TradingView webhook
    webhook_payload = {
        "symbol": "BTC/USDT",
        "action": "BUY",
        "quantity": 0.01,
        "stop_loss": 67000,
        "take_profit": 69000,
        "confidence": 0.75
    }
    
    response = client.post(
        "/webhook/tradingview",
        json=webhook_payload,
        headers={"Authorization": f"Bearer {get_test_token()}"}
    )
    
    # 2. Verify response
    assert response.status_code == 200
    assert response.json()['status'] == 'success'
    
    # 3. Check order was placed via CCXT
    order_id = response.json()['order_id']
    ccxt_plugin = get_plugin('ccxt')
    order = await ccxt_plugin.fetch_order(order_id)
    
    assert order['symbol'] == 'BTC/USDT'
    assert order['side'] == 'buy'
    assert order['filled'] > 0
```

**Acceptance Criteria**:
- [ ] 10+ end-to-end tests passing
- [ ] All components integrated
- [ ] Performance acceptable (<500ms per order)

---

## Timeline and Milestones

| Days | Phase | Tasks | Deliverables |
|------|-------|-------|--------------|
| 1-2 | 3.1 | Plugin Framework | ExecutionPlugin trait, PyO3 bridge |
| 3-5 | 3.2 | Broker Migration | ninja_plugin, mt5_plugin, tests |
| 6-7 | 3.3 | CCXT Integration | ExchangeManager, CCXTPlugin, webhooks |
| 8-9 | 3.4 | Validation & Security | Normalization, rate limiting, E2E tests |

**Milestone 1** (Day 2): Plugin framework operational  
**Milestone 2** (Day 5): Brokers migrated to plugins  
**Milestone 3** (Day 7): CCXT and webhooks functional  
**Milestone 4** (Day 9): Full system validated and secured  

---

## Success Criteria

✅ **Plugin Framework**:
- ExecutionPlugin trait implemented in Rust
- Python bridge working via PyO3
- At least 2 plugins operational (ninja, CCXT)

✅ **Centralized Execution**:
- All external calls go through fks_execution
- fks_ninja and mt5 as plugins (not separate services)
- CCXT managing all exchange interactions

✅ **Quality & Security**:
- Confidence thresholds enforced (≥0.6)
- Rate limiting active (10 req/s)
- Circuit breakers prevent failures
- End-to-end tests passing

✅ **Performance**:
- Order execution <500ms (p95)
- Webhook processing <100ms
- No memory leaks in long-running tests

---

## Risks and Mitigations

1. **C# Bindings Complexity**:
   - Risk: csbindgen difficult to configure
   - Mitigation: Start with simple methods, expand gradually
   - Fallback: Keep ninja as HTTP service, add REST plugin

2. **CCXT API Limits**:
   - Risk: Exchange rate limits hit
   - Mitigation: Built-in rate limiting in CCXT
   - Monitoring: Track API usage via metrics

3. **Plugin Performance Overhead**:
   - Risk: Abstraction adds latency
   - Mitigation: Benchmark early, optimize hot paths
   - Target: <10ms overhead per plugin call

---

## Next Steps After Phase 3

**Phase 4: Testing and Quality Assurance** (1 week)
- Comprehensive test coverage (>85%)
- Load testing (1000 orders/min)
- Chaos engineering (failure scenarios)

**Phase 5: Deployment and Monitoring** (1 week)
- K8s deployment for fks_execution
- Prometheus metrics for plugins
- Alerting for failures

---

**Status**: Task 3.1.1 IN PROGRESS  
**Started**: November 4, 2025  
**Target Completion**: November 13-15, 2025

Let's begin! 🚀
