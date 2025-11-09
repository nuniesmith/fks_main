# FKS Real-Time Data Streaming Architecture

## Overview

FKS uses a multi-layered streaming architecture to deliver real-time market data, trading signals, and order updates to clients. This document outlines the complete data flow, message queue strategies, error handling, and optimization techniques.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Flow Pipeline](#data-flow-pipeline)
3. [Message Queue Strategy](#message-queue-strategy)
4. [WebSocket Implementation](#websocket-implementation)
5. [Error Handling and Reconnection](#error-handling-and-reconnection)
6. [Backpressure Handling](#backpressure-handling)
7. [Stream Processing](#stream-processing)
8. [Performance Optimization](#performance-optimization)

---

## Architecture Overview

### High-Level Flow

```
Exchange APIs (Binance, Coinbase, etc.)
    ↓
Data Collectors (fks_data)
    ↓
ZeroMQ (ZMQ) Pub/Sub
    ↓
Redis Cache/Queue
    ↓
WebSocket Server (FastAPI)
    ↓
WebSocket Clients (Web UI, Trading Bots)
```

### Components

1. **Data Collectors** (`fks_data`): Fetch data from exchange APIs
2. **ZeroMQ (ZMQ)**: High-performance message queue for inter-service communication
3. **Redis**: Caching and pub/sub for real-time updates
4. **WebSocket Server**: FastAPI-based WebSocket endpoints
5. **Connection Manager**: Manages WebSocket client connections

---

## Data Flow Pipeline

### Stage 1: Data Collection

**Location**: `fks_data/src/collectors/`

Data collectors fetch market data from exchange APIs:

```python
# Example: Binance WebSocket collector
import asyncio
import websockets
import json
import zmq

async def collect_binance_data(symbol: str, zmq_publisher):
    """Collect real-time data from Binance WebSocket"""
    uri = f"wss://stream.binance.com:9443/ws/{symbol.lower()}@ticker"
    
    async with websockets.connect(uri) as websocket:
        while True:
            try:
                message = await websocket.recv()
                data = json.loads(message)
                
                # Transform to FKS format
                transformed = {
                    "symbol": data["s"],
                    "price": float(data["c"]),
                    "volume": float(data["v"]),
                    "timestamp": data["E"],
                    "exchange": "binance"
                }
                
                # Publish to ZMQ
                zmq_publisher.send_json(transformed)
                
            except Exception as e:
                logger.error(f"Error collecting data: {e}")
                await asyncio.sleep(1)  # Backoff before reconnect
```

### Stage 2: ZeroMQ Pub/Sub

**Location**: `fks_data/src/domain/trading/bridge/bridge.py`

ZeroMQ provides high-throughput, low-latency messaging:

```python
import zmq.asyncio

class MarketDataPublisher:
    def __init__(self, port: int = 5555):
        self.context = zmq.asyncio.Context()
        self.socket = self.context.socket(zmq.PUB)
        self.socket.bind(f"tcp://*:{port}")
    
    async def publish(self, data: dict):
        """Publish market data to subscribers"""
        await self.socket.send_json(data)
```

**Subscriber Setup**:
```python
class MarketDataSubscriber:
    def __init__(self, port: int = 5555):
        self.context = zmq.asyncio.Context()
        self.socket = self.context.socket(zmq.SUB)
        self.socket.connect(f"tcp://localhost:{port}")
        self.socket.subscribe(b"")  # Subscribe to all messages
    
    async def receive(self):
        """Receive market data"""
        return await self.socket.recv_json()
```

### Stage 3: Redis Caching

**Purpose**: 
- Cache recent market data for fast access
- Pub/Sub for real-time notifications
- Store calculated indicators

```python
import redis.asyncio as redis

class RedisCache:
    def __init__(self):
        self.client = redis.from_url("redis://localhost:6379")
        self.pubsub = self.client.pubsub()
    
    async def cache_market_data(self, symbol: str, data: dict):
        """Cache market data with TTL"""
        key = f"market:{symbol}:latest"
        await self.client.setex(
            key,
            60,  # 60 second TTL
            json.dumps(data)
        )
        
        # Publish to subscribers
        await self.client.publish(f"market:{symbol}", json.dumps(data))
    
    async def get_cached_data(self, symbol: str):
        """Get cached market data"""
        key = f"market:{symbol}:latest"
        data = await self.client.get(key)
        return json.loads(data) if data else None
```

### Stage 4: WebSocket Server

**Location**: `fks_data/src/domain/trading/api/main.py`

FastAPI WebSocket endpoint for client connections:

```python
from fastapi import WebSocket, WebSocketDisconnect

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.subscriptions: dict[str, set[WebSocket]] = {}  # symbol -> websockets
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        # Remove from all subscriptions
        for symbol, connections in self.subscriptions.items():
            connections.discard(websocket)
    
    async def subscribe(self, websocket: WebSocket, symbol: str):
        """Subscribe client to specific symbol"""
        if symbol not in self.subscriptions:
            self.subscriptions[symbol] = set()
        self.subscriptions[symbol].add(websocket)
    
    async def broadcast_to_symbol(self, symbol: str, message: dict):
        """Broadcast message to all subscribers of a symbol"""
        if symbol in self.subscriptions:
            disconnected = []
            for websocket in self.subscriptions[symbol]:
                try:
                    await websocket.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending to client: {e}")
                    disconnected.append(websocket)
            
            # Clean up disconnected clients
            for ws in disconnected:
                self.subscriptions[symbol].discard(ws)

@app.websocket("/ws/market")
async def market_websocket(websocket: WebSocket):
    await manager.connect(websocket)
    
    try:
        # Receive subscription requests
        while True:
            message = await websocket.receive_json()
            
            if message["type"] == "subscribe":
                symbol = message["symbol"]
                await manager.subscribe(websocket, symbol)
                await websocket.send_json({
                    "type": "subscribed",
                    "symbol": symbol
                })
            
            elif message["type"] == "unsubscribe":
                symbol = message["symbol"]
                if symbol in manager.subscriptions:
                    manager.subscriptions[symbol].discard(websocket)
                await websocket.send_json({
                    "type": "unsubscribed",
                    "symbol": symbol
                })
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

### Complete Integration Example

```python
# fks_data/src/streaming/pipeline.py

import asyncio
import zmq.asyncio
import redis.asyncio as redis
from fastapi import WebSocket

class StreamingPipeline:
    def __init__(self):
        self.zmq_context = zmq.asyncio.Context()
        self.redis_client = redis.from_url("redis://localhost:6379")
        self.subscriber = None
        self.connection_manager = None
    
    async def setup(self):
        """Initialize connections"""
        # ZMQ subscriber
        self.subscriber = self.zmq_context.socket(zmq.SUB)
        self.subscriber.connect("tcp://localhost:5555")
        self.subscriber.subscribe(b"")
        
        # Redis pub/sub
        self.pubsub = self.redis_client.pubsub()
    
    async def process_stream(self, connection_manager):
        """Process incoming data stream"""
        self.connection_manager = connection_manager
        
        while True:
            try:
                # Receive from ZMQ
                data = await self.subscriber.recv_json()
                symbol = data["symbol"]
                
                # Cache in Redis
                await self.redis_client.setex(
                    f"market:{symbol}:latest",
                    60,
                    json.dumps(data)
                )
                
                # Publish to Redis pub/sub
                await self.redis_client.publish(
                    f"market:{symbol}",
                    json.dumps(data)
                )
                
                # Broadcast to WebSocket clients
                await connection_manager.broadcast_to_symbol(symbol, data)
                
            except Exception as e:
                logger.error(f"Stream processing error: {e}")
                await asyncio.sleep(1)
```

---

## Message Queue Strategy

### When to Use Each Technology

| Technology | Use Case | Latency | Throughput | Best For |
|------------|----------|---------|------------|----------|
| **ZeroMQ** | Inter-service messaging | < 1ms | 1M+ msg/s | High-frequency market data, internal services |
| **Redis Pub/Sub** | Real-time notifications | < 5ms | 100K+ msg/s | WebSocket broadcasts, cache invalidation |
| **Redis Streams** | Persistent message queue | < 10ms | 50K+ msg/s | Order events, audit logs |
| **Kafka** | Event streaming (future) | < 10ms | 1M+ msg/s | Large-scale event processing, analytics |

### ZeroMQ Configuration

**Publisher (Data Collector)**:
```python
# High-performance publisher
socket = context.socket(zmq.PUB)
socket.bind("tcp://*:5555")
socket.setsockopt(zmq.SNDHWM, 1000)  # Send high-water mark
socket.setsockopt(zmq.LINGER, 0)     # Don't wait on close
```

**Subscriber (Bridge/API)**:
```python
# Reliable subscriber
socket = context.socket(zmq.SUB)
socket.connect("tcp://localhost:5555")
socket.subscribe(b"")  # Subscribe to all
socket.setsockopt(zmq.RCVHWM, 1000)  # Receive high-water mark
```

### Redis Pub/Sub Pattern

```python
# Publisher
await redis_client.publish("market:BTCUSDT", json.dumps(data))

# Subscriber
pubsub = redis_client.pubsub()
await pubsub.subscribe("market:BTCUSDT")

async for message in pubsub.listen():
    if message["type"] == "message":
        data = json.loads(message["data"])
        # Process data
```

### Redis Streams for Persistence

```python
# Producer (persistent queue)
await redis_client.xadd(
    "market:stream",
    {
        "symbol": "BTCUSDT",
        "price": 50000.0,
        "timestamp": int(time.time() * 1000)
    },
    maxlen=10000  # Keep last 10K messages
)

# Consumer (with consumer group)
await redis_client.xreadgroup(
    "market-group",
    "consumer-1",
    {"market:stream": ">"},
    count=100,
    block=1000  # Block for 1 second
)
```

---

## WebSocket Implementation

### Connection Management

**Enhanced Connection Manager**:

```python
class EnhancedConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, WebSocket] = {}  # client_id -> websocket
        self.subscriptions: dict[str, set[str]] = {}  # symbol -> set of client_ids
        self.client_subscriptions: dict[str, set[str]] = {}  # client_id -> set of symbols
        self.heartbeat_tasks: dict[str, asyncio.Task] = {}
    
    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.client_subscriptions[client_id] = set()
        
        # Start heartbeat
        self.heartbeat_tasks[client_id] = asyncio.create_task(
            self._heartbeat(client_id)
        )
    
    async def _heartbeat(self, client_id: str):
        """Send periodic heartbeat to keep connection alive"""
        while client_id in self.active_connections:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_json({
                    "type": "heartbeat",
                    "timestamp": int(time.time() * 1000)
                })
                await asyncio.sleep(30)  # Every 30 seconds
            except Exception:
                break  # Connection closed
    
    async def subscribe(self, client_id: str, symbol: str):
        """Subscribe client to symbol"""
        if symbol not in self.subscriptions:
            self.subscriptions[symbol] = set()
        
        self.subscriptions[symbol].add(client_id)
        self.client_subscriptions[client_id].add(symbol)
    
    async def broadcast_to_symbol(self, symbol: str, message: dict):
        """Broadcast to all subscribers of a symbol"""
        if symbol not in self.subscriptions:
            return
        
        disconnected = []
        for client_id in self.subscriptions[symbol]:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_json(message)
            except Exception:
                disconnected.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected:
            await self.disconnect(client_id)
    
    async def disconnect(self, client_id: str):
        """Disconnect client and cleanup"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        
        # Remove from subscriptions
        if client_id in self.client_subscriptions:
            for symbol in self.client_subscriptions[client_id]:
                if symbol in self.subscriptions:
                    self.subscriptions[symbol].discard(client_id)
            del self.client_subscriptions[client_id]
        
        # Cancel heartbeat
        if client_id in self.heartbeat_tasks:
            self.heartbeat_tasks[client_id].cancel()
            del self.heartbeat_tasks[client_id]
```

### WebSocket Endpoint with Authentication

```python
from fastapi import WebSocket, WebSocketException, status

@app.websocket("/ws/market")
async def market_websocket(
    websocket: WebSocket,
    token: str = None  # Query parameter or header
):
    # Authenticate
    if not token or not verify_token(token):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    
    client_id = get_client_id_from_token(token)
    await manager.connect(websocket, client_id)
    
    try:
        while True:
            message = await websocket.receive_json()
            
            if message["type"] == "subscribe":
                symbol = message["symbol"]
                await manager.subscribe(client_id, symbol)
                await websocket.send_json({
                    "type": "subscribed",
                    "symbol": symbol
                })
            
            elif message["type"] == "ping":
                await websocket.send_json({"type": "pong"})
    
    except WebSocketDisconnect:
        await manager.disconnect(client_id)
```

---

## Error Handling and Reconnection

### Automatic Reconnection

**Client-Side (JavaScript)**:
```javascript
class FKSWebSocketClient {
    constructor(url) {
        this.url = url;
        this.ws = null;
        this.reconnectDelay = 1000;
        this.maxReconnectDelay = 30000;
        this.subscriptions = new Set();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        
        this.ws.onopen = () => {
            console.log('Connected');
            this.reconnectDelay = 1000;
            // Resubscribe to all symbols
            this.subscriptions.forEach(symbol => {
                this.subscribe(symbol);
            });
        };
        
        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
        
        this.ws.onclose = () => {
            console.log('Disconnected, reconnecting...');
            this.reconnect();
        };
    }
    
    reconnect() {
        setTimeout(() => {
            this.reconnectDelay = Math.min(
                this.reconnectDelay * 2,
                this.maxReconnectDelay
            );
            this.connect();
        }, this.reconnectDelay);
    }
    
    subscribe(symbol) {
        this.subscriptions.add(symbol);
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                type: 'subscribe',
                symbol: symbol
            }));
        }
    }
}
```

**Server-Side Reconnection (ZMQ/Redis)**:

```python
class ResilientSubscriber:
    def __init__(self, zmq_port: int, redis_url: str):
        self.zmq_port = zmq_port
        self.redis_url = redis_url
        self.zmq_context = None
        self.subscriber = None
        self.redis_client = None
        self.max_retries = 5
        self.retry_delay = 1
    
    async def connect(self):
        """Connect with retry logic"""
        for attempt in range(self.max_retries):
            try:
                # Connect ZMQ
                self.zmq_context = zmq.asyncio.Context()
                self.subscriber = self.zmq_context.socket(zmq.SUB)
                self.subscriber.connect(f"tcp://localhost:{self.zmq_port}")
                self.subscriber.subscribe(b"")
                
                # Connect Redis
                self.redis_client = await redis.from_url(
                    self.redis_url,
                    retry_on_timeout=True,
                    socket_connect_timeout=5
                )
                
                logger.info("Connected to ZMQ and Redis")
                return True
                
            except Exception as e:
                logger.error(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(self.retry_delay * (2 ** attempt))
                else:
                    raise
        
        return False
    
    async def process_with_reconnect(self, handler):
        """Process messages with automatic reconnection"""
        while True:
            try:
                if not self.subscriber or not self.redis_client:
                    await self.connect()
                
                # Process messages
                while True:
                    data = await self.subscriber.recv_json()
                    await handler(data)
            
            except zmq.ZMQError as e:
                logger.error(f"ZMQ error: {e}, reconnecting...")
                self.subscriber = None
                await asyncio.sleep(self.retry_delay)
            
            except redis.ConnectionError as e:
                logger.error(f"Redis error: {e}, reconnecting...")
                self.redis_client = None
                await asyncio.sleep(self.retry_delay)
            
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                await asyncio.sleep(self.retry_delay)
```

---

## Backpressure Handling

### Problem

When consumers (WebSocket clients) are slower than producers (data collectors), messages can accumulate, causing:
- Memory pressure
- Increased latency
- Connection drops

### Solutions

#### 1. ZMQ High-Water Mark

```python
# Publisher: Drop messages if queue full
socket.setsockopt(zmq.SNDHWM, 1000)  # Max 1000 messages in queue

# Subscriber: Drop messages if queue full
socket.setsockopt(zmq.RCVHWM, 1000)  # Max 1000 messages in queue
```

#### 2. Rate Limiting

```python
from collections import deque
import time

class RateLimiter:
    def __init__(self, max_messages: int, window_seconds: int):
        self.max_messages = max_messages
        self.window_seconds = window_seconds
        self.messages = deque()
    
    def can_send(self) -> bool:
        now = time.time()
        # Remove old messages
        while self.messages and self.messages[0] < now - self.window_seconds:
            self.messages.popleft()
        
        if len(self.messages) >= self.max_messages:
            return False
        
        self.messages.append(now)
        return True

# Usage in WebSocket handler
rate_limiter = RateLimiter(max_messages=100, window_seconds=1)

async def broadcast_to_symbol(self, symbol: str, message: dict):
    if not rate_limiter.can_send():
        logger.warning(f"Rate limit exceeded for {symbol}, dropping message")
        return
    
    # Send message...
```

#### 3. Message Batching

```python
class MessageBatcher:
    def __init__(self, batch_size: int = 10, batch_interval: float = 0.1):
        self.batch_size = batch_size
        self.batch_interval = batch_interval
        self.buffer: dict[str, list] = {}  # symbol -> messages
        self.last_send: dict[str, float] = {}  # symbol -> timestamp
    
    async def add_message(self, symbol: str, message: dict):
        if symbol not in self.buffer:
            self.buffer[symbol] = []
            self.last_send[symbol] = time.time()
        
        self.buffer[symbol].append(message)
        
        # Send if batch full or interval elapsed
        now = time.time()
        if (len(self.buffer[symbol]) >= self.batch_size or
            now - self.last_send[symbol] >= self.batch_interval):
            await self._flush(symbol)
    
    async def _flush(self, symbol: str):
        if symbol not in self.buffer or not self.buffer[symbol]:
            return
        
        batch = self.buffer[symbol]
        self.buffer[symbol] = []
        self.last_send[symbol] = time.time()
        
        # Send batched message
        await connection_manager.broadcast_to_symbol(symbol, {
            "type": "batch",
            "symbol": symbol,
            "messages": batch,
            "count": len(batch)
        })
```

#### 4. Client-Side Backpressure

```python
# Server: Check if client is ready
async def send_if_ready(self, websocket: WebSocket, message: dict):
    try:
        # Check WebSocket buffer (if available in framework)
        if hasattr(websocket, '_send_buffer_size'):
            if websocket._send_buffer_size > 1000:  # Too many queued messages
                logger.warning(f"Client buffer full, dropping message")
                return
        
        await websocket.send_json(message)
    except Exception as e:
        logger.error(f"Error sending: {e}")
        raise
```

---

## Stream Processing

### Real-Time Aggregations

Use Apache Flink or similar for complex stream processing:

```python
# Example: Calculate 1-minute OHLCV from tick data
from flink import StreamExecutionEnvironment
from flink.datastream import StreamExecutionEnvironment

def aggregate_to_1min(tick_stream):
    """Aggregate tick data to 1-minute candles"""
    return (tick_stream
        .key_by(lambda x: x['symbol'])
        .window(TumblingEventTimeWindows.of(Time.minutes(1)))
        .aggregate(
            lambda acc, value: {
                'open': acc.get('open', value['price']),
                'high': max(acc.get('high', value['price']), value['price']),
                'low': min(acc.get('low', value['price']), value['price']),
                'close': value['price'],
                'volume': acc.get('volume', 0) + value['volume']
            }
        ))
```

### Simple In-Memory Aggregation

For smaller scale, use Python:

```python
from collections import defaultdict
import time

class TickAggregator:
    def __init__(self, interval_seconds: int = 60):
        self.interval_seconds = interval_seconds
        self.buffers: dict[str, list] = defaultdict(list)
        self.last_emit: dict[str, float] = {}
    
    async def add_tick(self, symbol: str, price: float, volume: float):
        now = time.time()
        self.buffers[symbol].append({
            'price': price,
            'volume': volume,
            'timestamp': now
        })
        
        # Emit if interval elapsed
        if (symbol not in self.last_emit or
            now - self.last_emit[symbol] >= self.interval_seconds):
            await self._emit_candle(symbol)
    
    async def _emit_candle(self, symbol: str):
        if not self.buffers[symbol]:
            return
        
        ticks = self.buffers[symbol]
        candle = {
            'symbol': symbol,
            'timeframe': '1m',
            'open': ticks[0]['price'],
            'high': max(t['price'] for t in ticks),
            'low': min(t['price'] for t in ticks),
            'close': ticks[-1]['price'],
            'volume': sum(t['volume'] for t in ticks),
            'timestamp': ticks[0]['timestamp']
        }
        
        # Clear buffer
        self.buffers[symbol] = []
        self.last_emit[symbol] = time.time()
        
        # Publish candle
        await zmq_publisher.send_json(candle)
```

---

## Performance Optimization

### Connection Pooling

```python
# Redis connection pool
redis_pool = redis.ConnectionPool.from_url(
    "redis://localhost:6379",
    max_connections=50,
    decode_responses=True
)

redis_client = redis.Redis(connection_pool=redis_pool)
```

### Message Compression

```python
import gzip
import json

def compress_message(data: dict) -> bytes:
    """Compress JSON message"""
    json_str = json.dumps(data)
    return gzip.compress(json_str.encode())

def decompress_message(compressed: bytes) -> dict:
    """Decompress message"""
    json_str = gzip.decompress(compressed).decode()
    return json.loads(json_str)
```

### Batching WebSocket Messages

```python
# Send multiple updates in one message
await websocket.send_json({
    "type": "batch",
    "updates": [
        {"symbol": "BTCUSDT", "price": 50000},
        {"symbol": "ETHUSDT", "price": 3000},
    ]
})
```

### Monitoring

```python
# Track WebSocket metrics
websocket_metrics = {
    "active_connections": len(manager.active_connections),
    "messages_sent": 0,
    "messages_dropped": 0,
    "avg_latency_ms": 0
}

# Export to Prometheus
from prometheus_client import Counter, Histogram

websocket_messages = Counter('websocket_messages_total', 'Total WebSocket messages')
websocket_latency = Histogram('websocket_latency_seconds', 'WebSocket message latency')
```

---

## References

- [ZeroMQ Guide](http://zguide.zeromq.org/)
- [Redis Pub/Sub](https://redis.io/docs/manual/pubsub/)
- [FastAPI WebSockets](https://fastapi.tiangolo.com/advanced/websockets/)
- [WebSocket Best Practices](https://www.ably.com/topic/websockets)

