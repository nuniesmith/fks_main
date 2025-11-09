# FKS Order Management System (OMS) Documentation

## Overview

The FKS Order Management System (OMS) is a centralized, FSM-based order execution engine that serves as the **ONLY** service communicating directly with exchanges and brokers. It provides order lifecycle management, position tracking, and exchange abstraction for multiple trading platforms.

**Critical Principle**: NO OTHER SERVICE should talk to exchanges directly. All market orders flow through `fks_execution`.

## Table of Contents

1. [Order Types](#order-types)
2. [Order Lifecycle (FSM)](#order-lifecycle-fsm)
3. [Order Matching and Partial Fills](#order-matching-and-partial-fills)
4. [Exchange Abstraction](#exchange-abstraction)
5. [Order Persistence and Recovery](#order-persistence-and-recovery)
6. [API Reference](#api-reference)
7. [Error Handling](#error-handling)

---

## Order Types

FKS supports the following order types across all exchanges:

### 1. Market Order

**Description**: Execute immediately at the best available market price.

**Characteristics**:
- **Execution**: Immediate (within milliseconds)
- **Price**: Not guaranteed (executes at current market price)
- **Use Case**: Fast entry/exit when price precision is less critical
- **Slippage**: May experience slippage in volatile markets

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "buy",
  "order_type": "market",
  "quantity": 0.01
}
```

**Exchange Mapping**:
- **Binance**: `MARKET` order type
- **Coinbase**: `market` order type
- **Kraken**: `market` order type

### 2. Limit Order

**Description**: Execute only at specified price or better.

**Characteristics**:
- **Execution**: May not execute immediately (waits for price)
- **Price**: Guaranteed (won't execute worse than limit price)
- **Use Case**: Precise entry/exit with price control
- **Time in Force**: Can be GTC (Good Till Cancel), IOC (Immediate or Cancel), FOK (Fill or Kill)

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "buy",
  "order_type": "limit",
  "quantity": 0.01,
  "price": 50000.0
}
```

**Exchange Mapping**:
- **Binance**: `LIMIT` order type with `timeInForce` parameter
- **Coinbase**: `limit` order type
- **Kraken**: `limit` order type

### 3. Stop-Loss Order

**Description**: Market order triggered when price reaches stop price (to limit losses).

**Characteristics**:
- **Trigger**: Activates when price touches stop price
- **Execution**: Converts to market order upon trigger
- **Use Case**: Risk management, automatic loss limiting
- **Direction**: Opposite of position (sell for long, buy for short)

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "sell",
  "order_type": "stop_loss",
  "quantity": 0.01,
  "stop_loss": 48000.0  // Triggers if price drops to 48000
}
```

**Exchange Mapping**:
- **Binance**: `STOP_MARKET` order type
- **Coinbase**: `stop` order type with `stop_price`
- **Kraken**: `stop-loss` order type

### 4. Take-Profit Order

**Description**: Limit order triggered when price reaches target profit level.

**Characteristics**:
- **Trigger**: Activates when price reaches take-profit price
- **Execution**: Converts to limit order upon trigger
- **Use Case**: Lock in profits automatically
- **Direction**: Opposite of position

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "sell",
  "order_type": "take_profit",
  "quantity": 0.01,
  "take_profit": 52000.0  // Triggers if price rises to 52000
}
```

**Exchange Mapping**:
- **Binance**: `TAKE_PROFIT_MARKET` or `TAKE_PROFIT_LIMIT`
- **Coinbase**: `stop` order type with `stop_price` and `limit_price`
- **Kraken**: `take-profit` order type

### 5. Stop-Limit Order

**Description**: Combination of stop and limit orders. Triggers at stop price, executes as limit order.

**Characteristics**:
- **Trigger**: Activates when price reaches stop price
- **Execution**: Places limit order at specified limit price
- **Use Case**: More control over execution price after stop trigger
- **Risk**: May not fill if price gaps past limit price

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "sell",
  "order_type": "stop_limit",
  "quantity": 0.01,
  "price": 47900.0,      // Limit price
  "stop_loss": 48000.0   // Stop trigger price
}
```

**Exchange Mapping**:
- **Binance**: `STOP_LOSS_LIMIT` order type
- **Coinbase**: `stop` order type with both `stop_price` and `limit_price`
- **Kraken**: `stop-loss-limit` order type

### 6. Trailing Stop Order

**Description**: Stop-loss that adjusts automatically as price moves favorably.

**Characteristics**:
- **Dynamic**: Stop price moves with favorable price movement
- **Trail Distance**: Fixed distance (price or percentage) from current price
- **Use Case**: Lock in profits while allowing for continued gains
- **Direction**: Only moves in favorable direction

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "sell",
  "order_type": "trailing_stop",
  "quantity": 0.01,
  "trail_distance": 500.0,      // Trail by $500
  "trail_percent": null          // Or use percentage
}
```

**Exchange Mapping**:
- **Binance**: `TRAILING_STOP_MARKET` order type
- **Coinbase**: Not natively supported (implemented via order updates)
- **Kraken**: `trailing-stop` order type

### 7. OCO (One-Cancels-Other) Order

**Description**: Two orders where execution of one automatically cancels the other.

**Characteristics**:
- **Pair**: Consists of two orders (typically stop-loss and take-profit)
- **Execution**: Only one order can execute
- **Use Case**: Set both stop-loss and take-profit simultaneously
- **Complexity**: Requires exchange support for OCO orders

**Example**:
```json
{
  "symbol": "BTCUSDT",
  "side": "buy",
  "order_type": "oco",
  "quantity": 0.01,
  "price": 50000.0,
  "stop_loss": 48000.0,
  "take_profit": 52000.0
}
```

**Exchange Mapping**:
- **Binance**: `OCO` order type (native support)
- **Coinbase**: Not natively supported (implemented via order management)
- **Kraken**: Not natively supported

### Order Type Support Matrix

| Order Type | Binance | Coinbase | Kraken | Implementation |
|------------|---------|----------|--------|----------------|
| Market | ✅ Native | ✅ Native | ✅ Native | Direct mapping |
| Limit | ✅ Native | ✅ Native | ✅ Native | Direct mapping |
| Stop-Loss | ✅ Native | ✅ Native | ✅ Native | Direct mapping |
| Take-Profit | ✅ Native | ✅ Native | ✅ Native | Direct mapping |
| Stop-Limit | ✅ Native | ✅ Native | ✅ Native | Direct mapping |
| Trailing Stop | ✅ Native | ⚠️ Simulated | ✅ Native | Order updates for Coinbase |
| OCO | ✅ Native | ❌ Not supported | ❌ Not supported | Manual management for unsupported |

---

## Order Lifecycle (FSM)

The Order Management System uses a Finite State Machine (FSM) to track order states throughout their lifecycle.

### Complete State Diagram

```
                    ┌─────────────┐
                    │   CREATED   │  (Initial state)
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   PENDING   │  (Submitted to exchange, awaiting confirmation)
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  SUBMITTED   │   │   REJECTED   │   │  CANCELLED   │
│  (Accepted)  │   │  (Exchange   │   │  (User/      │
│              │   │   rejected)  │   │   System)    │
└──────┬───────┘   └──────────────┘   └──────────────┘
        │
        ▼
┌──────────────┐
│     OPEN     │  (Order on exchange order book)
│  (Active)    │
└──────┬───────┘
        │
        ├─────────────────┐
        │                 │
        ▼                 ▼
┌──────────────┐   ┌──────────────┐
│ PARTIALLY    │   │    FILLED    │
│   FILLED     │   │  (Complete)  │
└──────┬───────┘   └──────┬───────┘
        │                  │
        └──────────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │   SETTLED    │  (Position updated, balance adjusted)
            └──────────────┘
```

### State Definitions

#### 1. CREATED

**Description**: Order object created in FKS but not yet submitted to exchange.

**Transitions**:
- → `PENDING`: When order is submitted to exchange

**Properties**:
- Order exists only in FKS system
- No exchange order ID yet
- Can be modified or cancelled before submission

**Example**:
```python
order = Order(
    symbol="BTCUSDT",
    side=OrderSide.Buy,
    order_type=OrderType.Market,
    quantity=0.01
)
# State: CREATED
```

#### 2. PENDING

**Description**: Order submitted to exchange, awaiting confirmation.

**Transitions**:
- → `SUBMITTED`: Exchange accepts order
- → `REJECTED`: Exchange rejects order
- → `CANCELLED`: User cancels before confirmation

**Properties**:
- Request sent to exchange API
- Waiting for exchange response
- Typically lasts < 1 second

**Timeout**: If no response within 5 seconds, transition to `REJECTED` with timeout error.

#### 3. SUBMITTED

**Description**: Exchange has accepted the order.

**Transitions**:
- → `OPEN`: Order placed on order book (for limit orders)
- → `FILLED`: Order immediately filled (for market orders)
- → `REJECTED`: Exchange later rejects (rare)

**Properties**:
- Exchange order ID assigned
- Order is valid and active
- For market orders, may immediately transition to `FILLED`

#### 4. OPEN

**Description**: Order is active on exchange order book (typically limit orders).

**Transitions**:
- → `PARTIALLY_FILLED`: Partial execution
- → `FILLED`: Complete execution
- → `CANCELLED`: User cancels order
- → `EXPIRED`: Order expires (if time-in-force set)

**Properties**:
- Order visible on order book
- Waiting for matching counterparty
- Can be cancelled at any time

**Monitoring**: System polls exchange every 1-5 seconds to check status.

#### 5. PARTIALLY_FILLED

**Description**: Order has been partially executed.

**Transitions**:
- → `FILLED`: Remaining quantity fills
- → `CANCELLED`: User cancels remaining quantity
- → `EXPIRED`: Remaining quantity expires

**Properties**:
- `filled_quantity` < `total_quantity`
- `remaining_quantity` = `total_quantity` - `filled_quantity`
- Average fill price may change with each partial fill

**Example**:
```python
# Order: Buy 1.0 BTC
# First fill: 0.3 BTC @ $50,000
# State: PARTIALLY_FILLED
# Remaining: 0.7 BTC

# Second fill: 0.7 BTC @ $50,100
# State: FILLED
# Average price: $50,030
```

#### 6. FILLED

**Description**: Order completely executed.

**Transitions**:
- → `SETTLED`: Position and balance updated

**Properties**:
- `filled_quantity` == `total_quantity`
- `average_price` calculated from all fills
- Execution complete, awaiting settlement

**Settlement Time**: Typically < 1 second for position update.

#### 7. SETTLED

**Description**: Order execution confirmed and position/balance updated.

**Transitions**:
- Terminal state (no further transitions)

**Properties**:
- Position updated in database
- Balance adjusted
- Trade record created
- Order lifecycle complete

**Post-Settlement**:
- Trade appears in trade history
- Position reflects new quantity
- Balance reflects realized P&L (if closing position)

#### 8. REJECTED

**Description**: Order rejected by exchange.

**Transitions**:
- Terminal state (no further transitions)

**Common Rejection Reasons**:
- Insufficient balance
- Invalid price (outside market bounds)
- Invalid quantity (below minimum)
- Symbol not tradable
- Exchange maintenance
- Rate limit exceeded
- Invalid order parameters

**Error Handling**: Error message stored in order record for analysis.

#### 9. CANCELLED

**Description**: Order cancelled by user or system.

**Transitions**:
- Terminal state (no further transitions)

**Cancellation Scenarios**:
- User-initiated cancellation
- System-initiated (risk limits, daily limits)
- Time-based expiration
- Strategy signal change

**Partial Cancellation**: If order is `PARTIALLY_FILLED`, only remaining quantity is cancelled.

#### 10. EXPIRED

**Description**: Order expired due to time-in-force (IOC, FOK, or custom expiration).

**Transitions**:
- Terminal state (no further transitions)

**Time-in-Force Options**:
- **GTC (Good Till Cancel)**: No expiration (default)
- **IOC (Immediate or Cancel)**: Fill immediately or cancel
- **FOK (Fill or Kill)**: Fill completely or cancel
- **GTD (Good Till Date)**: Expires at specific date/time

### State Transition Rules

**Valid Transitions** (enforced by FSM):

```python
VALID_TRANSITIONS = {
    "CREATED": ["PENDING", "CANCELLED"],
    "PENDING": ["SUBMITTED", "REJECTED", "CANCELLED"],
    "SUBMITTED": ["OPEN", "FILLED", "REJECTED"],
    "OPEN": ["PARTIALLY_FILLED", "FILLED", "CANCELLED", "EXPIRED"],
    "PARTIALLY_FILLED": ["FILLED", "CANCELLED", "EXPIRED"],
    "FILLED": ["SETTLED"],
    "SETTLED": [],  # Terminal
    "REJECTED": [],  # Terminal
    "CANCELLED": [],  # Terminal
    "EXPIRED": []  # Terminal
}
```

**Invalid Transition Handling**:
- Log error and alert
- Attempt to reconcile with exchange state
- If reconciliation fails, mark order as `REJECTED` with reconciliation error

---

## Order Matching and Partial Fills

### How Partial Fills Occur

Large orders may execute across multiple price levels, resulting in partial fills:

**Example Scenario**:
```
Order: Buy 1.0 BTC at market
Order Book:
  Ask 1: 0.3 BTC @ $50,000
  Ask 2: 0.4 BTC @ $50,100
  Ask 3: 0.3 BTC @ $50,200

Execution:
  Fill 1: 0.3 BTC @ $50,000  → State: PARTIALLY_FILLED
  Fill 2: 0.4 BTC @ $50,100  → State: PARTIALLY_FILLED
  Fill 3: 0.3 BTC @ $50,200  → State: FILLED

Average Price: (0.3*50000 + 0.4*50100 + 0.3*50200) / 1.0 = $50,100
```

### Partial Fill Tracking

**Database Schema**:
```sql
CREATE TABLE order_fills (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    fill_sequence INTEGER NOT NULL,  -- 1, 2, 3, ...
    fill_quantity DECIMAL(20, 8) NOT NULL,
    fill_price DECIMAL(20, 8) NOT NULL,
    fill_timestamp TIMESTAMPTZ NOT NULL,
    cumulative_quantity DECIMAL(20, 8) NOT NULL,
    average_price DECIMAL(20, 8) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_order_fills_order ON order_fills(order_id, fill_sequence);
```

**Tracking Logic**:
```python
class OrderFillTracker:
    def __init__(self, order_id: str, total_quantity: float):
        self.order_id = order_id
        self.total_quantity = total_quantity
        self.fills: list[Fill] = []
    
    def add_fill(self, quantity: float, price: float, timestamp: datetime):
        """Record a partial fill"""
        fill = Fill(
            order_id=self.order_id,
            fill_sequence=len(self.fills) + 1,
            fill_quantity=quantity,
            fill_price=price,
            fill_timestamp=timestamp
        )
        self.fills.append(fill)
        
        # Calculate cumulative metrics
        cumulative_qty = sum(f.fill_quantity for f in self.fills)
        total_cost = sum(f.fill_quantity * f.fill_price for f in self.fills)
        average_price = total_cost / cumulative_qty if cumulative_qty > 0 else 0
        
        fill.cumulative_quantity = cumulative_qty
        fill.average_price = average_price
        
        # Update order state
        if cumulative_qty >= self.total_quantity:
            return OrderState.FILLED
        elif cumulative_qty > 0:
            return OrderState.PARTIALLY_FILLED
        else:
            return OrderState.OPEN
```

### Exchange-Specific Partial Fill Handling

#### Binance

**WebSocket Updates**:
```python
# Binance sends execution reports via WebSocket
{
    "e": "executionReport",
    "s": "BTCUSDT",
    "c": "order_id_123",
    "x": "PARTIAL",  # Execution type: NEW, PARTIAL, FILLED, CANCELED
    "q": "0.3",      # Last executed quantity
    "p": "50000.00", # Last executed price
    "z": "0.3",      # Cumulative filled quantity
    "P": "50000.00"  # Average price
}
```

**Polling Fallback**:
```python
async def check_order_status_binance(order_id: str, symbol: str):
    """Poll Binance API for order status"""
    order = await exchange.fetch_order(order_id, symbol)
    
    if order['status'] == 'closed':
        if order['filled'] == order['amount']:
            return OrderState.FILLED
        else:
            return OrderState.PARTIALLY_FILLED
    elif order['status'] == 'open':
        if order['filled'] > 0:
            return OrderState.PARTIALLY_FILLED
        else:
            return OrderState.OPEN
```

#### Coinbase

**WebSocket Updates**:
```python
# Coinbase sends match messages
{
    "type": "match",
    "order_id": "order_123",
    "product_id": "BTC-USD",
    "price": "50000.00",
    "size": "0.3",
    "side": "buy"
}
```

**Polling**:
```python
async def check_order_status_coinbase(order_id: str, symbol: str):
    """Poll Coinbase API"""
    order = await exchange.fetch_order(order_id)
    
    filled_size = float(order.get('filled_size', 0))
    size = float(order.get('size', 0))
    
    if filled_size == size:
        return OrderState.FILLED
    elif filled_size > 0:
        return OrderState.PARTIALLY_FILLED
    else:
        return OrderState.OPEN
```

### Handling Fill Discrepancies

**Problem**: Exchange reports may not match FKS records due to:
- Network delays
- WebSocket message loss
- Exchange API inconsistencies

**Solution**: Reconciliation Process

```python
async def reconcile_order_fills(order_id: str, symbol: str):
    """Reconcile FKS records with exchange state"""
    # Get FKS records
    fks_fills = await db.get_order_fills(order_id)
    fks_total = sum(f.quantity for f in fks_fills)
    
    # Get exchange state
    exchange_order = await exchange.fetch_order(order_id, symbol)
    exchange_filled = exchange_order['filled']
    
    # Compare
    if abs(fks_total - exchange_filled) > 0.0001:  # Tolerance for rounding
        logger.warning(f"Fill discrepancy for {order_id}: FKS={fks_total}, Exchange={exchange_filled}")
        
        # Update FKS to match exchange (source of truth)
        if exchange_filled > fks_total:
            # Missing fills - fetch from exchange
            missing_fills = await exchange.fetch_order_trades(order_id)
            for fill in missing_fills:
                await db.insert_order_fill(order_id, fill)
        
        # Alert if significant discrepancy
        if abs(fks_total - exchange_filled) > 0.01:
            await alert_ops_team(order_id, fks_total, exchange_filled)
```

---

## Exchange Abstraction

FKS abstracts exchange-specific differences through a unified interface.

### Exchange Interface

```python
class ExchangeInterface:
    """Unified interface for all exchanges"""
    
    async def create_order(
        self,
        symbol: str,
        side: str,
        order_type: str,
        quantity: float,
        price: Optional[float] = None,
        **params
    ) -> Dict[str, Any]:
        """Create order on exchange"""
        pass
    
    async def fetch_order(self, order_id: str, symbol: str) -> Dict[str, Any]:
        """Fetch order status"""
        pass
    
    async def cancel_order(self, order_id: str, symbol: str) -> bool:
        """Cancel order"""
        pass
```

### Exchange-Specific Mappings

#### Symbol Format Conversion

```python
SYMBOL_MAPPING = {
    "binance": {
        "format": "{base}{quote}",  # BTCUSDT
        "separator": ""
    },
    "coinbase": {
        "format": "{base}-{quote}",  # BTC-USD
        "separator": "-"
    },
    "kraken": {
        "format": "{base}{quote}",  # XBTUSD
        "separator": ""
    }
}

def normalize_symbol(symbol: str, exchange: str) -> str:
    """Convert FKS symbol format to exchange format"""
    if exchange == "coinbase":
        # BTCUSDT -> BTC-USD
        base = symbol[:-4]  # BTC
        quote = symbol[-4:]  # USDT -> USD
        return f"{base}-{quote}"
    return symbol  # Binance/Kraken use same format
```

#### Order Type Mapping

```python
ORDER_TYPE_MAPPING = {
    "binance": {
        "market": "MARKET",
        "limit": "LIMIT",
        "stop_loss": "STOP_MARKET",
        "take_profit": "TAKE_PROFIT_MARKET",
        "stop_limit": "STOP_LOSS_LIMIT",
        "trailing_stop": "TRAILING_STOP_MARKET",
        "oco": "OCO"
    },
    "coinbase": {
        "market": "market",
        "limit": "limit",
        "stop_loss": "stop",
        "take_profit": "stop",
        "stop_limit": "stop",
        "trailing_stop": "stop",  # Simulated
        "oco": None  # Not supported
    }
}

def map_order_type(order_type: str, exchange: str) -> str:
    """Map FKS order type to exchange-specific type"""
    mapping = ORDER_TYPE_MAPPING.get(exchange, {})
    return mapping.get(order_type, order_type)
```

#### Parameter Mapping

```python
def map_order_params(order: Dict, exchange: str) -> Dict:
    """Map FKS order parameters to exchange-specific parameters"""
    base_params = {
        "symbol": normalize_symbol(order["symbol"], exchange),
        "side": order["side"],
        "type": map_order_type(order["order_type"], exchange),
        "amount": order["quantity"]
    }
    
    if exchange == "binance":
        if order["order_type"] == "limit":
            base_params["timeInForce"] = "GTC"  # Good Till Cancel
        if order.get("stop_loss"):
            base_params["stopPrice"] = order["stop_loss"]
        if order.get("take_profit"):
            base_params["takeProfitPrice"] = order["take_profit"]
    
    elif exchange == "coinbase":
        if order.get("price"):
            base_params["price"] = str(order["price"])  # Coinbase requires string
        if order.get("stop_loss"):
            base_params["stop_price"] = str(order["stop_loss"])
        base_params["product_id"] = normalize_symbol(order["symbol"], exchange)
    
    return base_params
```

### Exchange-Specific Limitations

#### Feature Support Matrix

| Feature | Binance | Coinbase | Kraken | Workaround |
|---------|---------|----------|--------|------------|
| OCO Orders | ✅ | ❌ | ❌ | Manual order pair management |
| Trailing Stop | ✅ | ❌ | ✅ | Periodic order updates for Coinbase |
| Post-Only | ✅ | ✅ | ✅ | Direct support |
| Iceberg Orders | ✅ | ❌ | ❌ | Not supported |
| Time-in-Force | ✅ | ⚠️ Limited | ✅ | Map to supported options |

#### Rate Limits

```python
RATE_LIMITS = {
    "binance": {
        "orders_per_second": 10,
        "orders_per_minute": 1200,
        "orders_per_day": 100000,
        "weight_per_minute": 1200
    },
    "coinbase": {
        "orders_per_second": 10,
        "orders_per_minute": 100,
        "orders_per_day": 10000
    },
    "kraken": {
        "orders_per_second": 1,
        "orders_per_minute": 60,
        "orders_per_day": 10000
    }
}

class RateLimiter:
    def __init__(self, exchange: str):
        self.limits = RATE_LIMITS[exchange]
        self.requests = deque()
    
    async def wait_if_needed(self):
        """Wait if rate limit would be exceeded"""
        now = time.time()
        # Remove old requests
        while self.requests and self.requests[0] < now - 60:
            self.requests.popleft()
        
        if len(self.requests) >= self.limits["orders_per_minute"]:
            sleep_time = 60 - (now - self.requests[0])
            await asyncio.sleep(sleep_time)
        
        self.requests.append(now)
```

---

## Order Persistence and Recovery

### Database Schema

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    fks_order_id VARCHAR(100) UNIQUE NOT NULL,
    exchange_order_id VARCHAR(100),
    exchange VARCHAR(50) NOT NULL,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    symbol VARCHAR(20) NOT NULL,
    side VARCHAR(10) NOT NULL CHECK (side IN ('buy', 'sell')),
    order_type VARCHAR(20) NOT NULL,
    quantity DECIMAL(20, 8) NOT NULL,
    filled_quantity DECIMAL(20, 8) DEFAULT 0,
    price DECIMAL(20, 8),
    average_price DECIMAL(20, 8),
    stop_loss DECIMAL(20, 8),
    take_profit DECIMAL(20, 8),
    status VARCHAR(20) NOT NULL,
    time_in_force VARCHAR(10) DEFAULT 'GTC',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    filled_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    error_message TEXT,
    order_metadata JSONB
);

CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_exchange_order ON orders(exchange, exchange_order_id);
CREATE INDEX idx_orders_account ON orders(account_id, created_at DESC);
```

### Order Recovery on Startup

**Problem**: System may restart while orders are in flight.

**Solution**: Recovery process on startup

```python
async def recover_orders_on_startup():
    """Recover orders that were in flight during system restart"""
    # Find orders that were not terminal
    active_states = ["PENDING", "SUBMITTED", "OPEN", "PARTIALLY_FILLED", "FILLED"]
    
    active_orders = await db.query("""
        SELECT * FROM orders
        WHERE status IN %s
        AND updated_at > NOW() - INTERVAL '24 hours'
    """, active_states)
    
    for order in active_orders:
        try:
            # Reconcile with exchange
            exchange_order = await exchange.fetch_order(
                order.exchange_order_id,
                order.symbol
            )
            
            # Update FKS state to match exchange
            new_status = map_exchange_status_to_fks(exchange_order['status'])
            
            if new_status != order.status:
                await update_order_status(order.id, new_status, exchange_order)
                logger.info(f"Recovered order {order.fks_order_id}: {order.status} -> {new_status}")
        
        except Exception as e:
            logger.error(f"Failed to recover order {order.fks_order_id}: {e}")
            # Mark as requiring manual review
            await mark_order_for_review(order.id, str(e))
```

### State Persistence

**On State Transition**:
```python
async def transition_order_state(order_id: str, new_state: OrderState, metadata: Dict = None):
    """Transition order state and persist"""
    # Validate transition
    current_state = await get_order_state(order_id)
    if not is_valid_transition(current_state, new_state):
        raise InvalidStateTransitionError(current_state, new_state)
    
    # Update database
    await db.update_order(
        order_id,
        status=new_state.value,
        updated_at=datetime.utcnow(),
        order_metadata=metadata
    )
    
    # Log state change
    await db.insert_order_state_log(
        order_id=order_id,
        from_state=current_state.value,
        to_state=new_state.value,
        timestamp=datetime.utcnow(),
        metadata=metadata
    )
    
    # Publish event (for other services)
    await event_bus.publish("order.state_changed", {
        "order_id": order_id,
        "from_state": current_state.value,
        "to_state": new_state.value,
        "timestamp": datetime.utcnow().isoformat()
    })
```

### Order State Log

**Audit Trail**:
```sql
CREATE TABLE order_state_log (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    from_state VARCHAR(20),
    to_state VARCHAR(20) NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT,
    metadata JSONB
);

CREATE INDEX idx_order_state_log_order ON order_state_log(order_id, timestamp DESC);
```

---

## API Reference

### Submit Order

**Endpoint**: `POST /orders`

**Request**:
```json
{
  "symbol": "BTCUSDT",
  "side": "buy",
  "order_type": "market",
  "quantity": 0.01,
  "price": null,
  "stop_loss": 48000.0,
  "take_profit": 52000.0,
  "exchange": "binance",
  "time_in_force": "GTC"
}
```

**Response**:
```json
{
  "success": true,
  "order_id": "fks_order_123",
  "exchange_order_id": "binance_456",
  "status": "PENDING",
  "timestamp": 1699113600000
}
```

### Get Order Status

**Endpoint**: `GET /orders/{order_id}`

**Response**:
```json
{
  "order_id": "fks_order_123",
  "exchange_order_id": "binance_456",
  "symbol": "BTCUSDT",
  "side": "buy",
  "order_type": "market",
  "quantity": 0.01,
  "filled_quantity": 0.01,
  "average_price": 50000.0,
  "status": "FILLED",
  "created_at": "2024-01-01T12:00:00Z",
  "filled_at": "2024-01-01T12:00:00.100Z"
}
```

### Cancel Order

**Endpoint**: `PUT /orders/{order_id}/cancel`

**Response**:
```json
{
  "success": true,
  "order_id": "fks_order_123",
  "status": "CANCELLED",
  "cancelled_at": "2024-01-01T12:00:05Z"
}
```

### List Orders

**Endpoint**: `GET /orders?status=OPEN&symbol=BTCUSDT&limit=100`

**Response**:
```json
{
  "orders": [
    {
      "order_id": "fks_order_123",
      "symbol": "BTCUSDT",
      "status": "OPEN",
      ...
    }
  ],
  "total": 50,
  "limit": 100,
  "offset": 0
}
```

---

## Error Handling

### Common Errors and Handling

#### 1. Insufficient Balance

**Error**: `INSUFFICIENT_BALANCE`

**Handling**:
```python
if error_code == "INSUFFICIENT_BALANCE":
    # Check actual balance
    balance = await exchange.fetch_balance()
    required = order.quantity * order.price
    
    if balance < required:
        # Reject order
        await transition_order_state(order_id, OrderState.REJECTED, {
            "error": "Insufficient balance",
            "required": required,
            "available": balance
        })
```

#### 2. Invalid Price

**Error**: `INVALID_PRICE`

**Handling**:
```python
if error_code == "INVALID_PRICE":
    # Fetch current market price
    ticker = await exchange.fetch_ticker(order.symbol)
    current_price = ticker['last']
    
    # Check if price is within reasonable bounds
    if order.price < current_price * 0.9 or order.price > current_price * 1.1:
        await transition_order_state(order_id, OrderState.REJECTED, {
            "error": "Price too far from market",
            "order_price": order.price,
            "market_price": current_price
        })
```

#### 3. Rate Limit Exceeded

**Error**: `RATE_LIMIT_EXCEEDED`

**Handling**:
```python
if error_code == "RATE_LIMIT_EXCEEDED":
    # Implement exponential backoff
    retry_after = response.headers.get('Retry-After', 60)
    await asyncio.sleep(retry_after)
    
    # Retry order submission
    await retry_order_submission(order_id)
```

#### 4. Exchange Maintenance

**Error**: `EXCHANGE_MAINTENANCE`

**Handling**:
```python
if error_code == "EXCHANGE_MAINTENANCE":
    # Mark exchange as unavailable
    await mark_exchange_unavailable(exchange)
    
    # Queue order for retry after maintenance
    await queue_order_for_retry(order_id, estimated_maintenance_end)
    
    # Alert operations team
    await alert_ops("Exchange maintenance", exchange)
```

### Retry Logic

```python
class OrderRetryHandler:
    def __init__(self, max_retries: int = 3, base_delay: float = 1.0):
        self.max_retries = max_retries
        self.base_delay = base_delay
    
    async def retry_order(self, order_id: str, attempt: int = 1):
        """Retry order submission with exponential backoff"""
        if attempt > self.max_retries:
            await transition_order_state(order_id, OrderState.REJECTED, {
                "error": "Max retries exceeded",
                "attempts": attempt
            })
            return
        
        delay = self.base_delay * (2 ** (attempt - 1))
        await asyncio.sleep(delay)
        
        try:
            order = await get_order(order_id)
            result = await submit_order_to_exchange(order)
            
            if result['success']:
                await transition_order_state(order_id, OrderState.SUBMITTED)
            else:
                # Retry if retryable error
                if is_retryable_error(result['error']):
                    await self.retry_order(order_id, attempt + 1)
                else:
                    await transition_order_state(order_id, OrderState.REJECTED, {
                        "error": result['error']
                    })
        
        except Exception as e:
            logger.error(f"Retry attempt {attempt} failed: {e}")
            await self.retry_order(order_id, attempt + 1)
```

---

## References

- [CCXT Documentation](https://docs.ccxt.com/)
- [Binance API Documentation](https://binance-docs.github.io/apidocs/spot/en/)
- [Coinbase Pro API Documentation](https://docs.pro.coinbase.com/)
- [Kraken API Documentation](https://docs.kraken.com/rest/)

