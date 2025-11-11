# Phase 2.1: Data Flow Stabilization - Analysis

**Date**: 2025-01-15  
**Status**: Analysis Complete  
**Objective**: Stabilize data flow from multiple sources

---

## 📊 Current State Analysis

### Data Adapters Available

| Adapter | Status | Rate Limit | Caching | Notes |
|---------|--------|------------|---------|-------|
| **Binance** | ✅ Implemented | 10 req/sec | ❌ No | Futures API (fapi.binance.com) |
| **Polygon** | ✅ Implemented | 4 req/sec | ❌ No | Requires API key |
| **CoinGecko** | ✅ Implemented | Unknown | ❌ No | Free tier available |
| **CoinMarketCap** | ✅ Implemented | Unknown | ❌ No | Requires API key |
| **Alpha Vantage** | ✅ Implemented | 5 req/min | ❌ No | Free tier: 5 calls/min |
| **EODHD** | ✅ Implemented | 1 req/sec | ✅ Yes | Has Redis caching |

### Key Findings

1. **Caching**: Only EODHD adapter has Redis caching implemented
   - Other adapters need caching added
   - Redis backend exists in framework but not used by all adapters

2. **Rate Limiting**: All adapters have rate limiting built into base class
   - Configurable via environment variables
   - Exponential backoff implemented

3. **Multi-Provider Manager**: Exists for failover
   - Can use multiple sources for same asset
   - Verification logic present

4. **Webhooks**: Not fully implemented
   - WebSocket endpoints exist for real-time data
   - HTTP webhook endpoints need to be added

5. **API Routes**: Custom endpoint system in main.py
   - Provider-specific routes exist
   - Need standardized REST API routes

---

## 🎯 Stabilization Tasks

### Task 2.1.1: Enable Redis Caching for All Adapters (Priority: High)

**Current**: Only EODHD adapter uses Redis caching

**Action**: Add caching to Binance, Polygon, CoinGecko adapters

**Implementation**:
```python
# Add to base adapter or individual adapters
from framework.cache import get_cache_backend

cache = get_cache_backend()
cache_key = f"data:{adapter_name}:{symbol}:{interval}"

# Check cache first
cached = await cache.get(cache_key)
if cached:
    return cached

# Fetch from API
data = await self._fetch_from_api(...)

# Cache with TTL
await cache.set(cache_key, data, ttl=300)  # 5 minutes
```

**Files to Modify**:
- `repo/data/src/adapters/binance.py`
- `repo/data/src/adapters/polygon.py`
- `repo/data/src/adapters/coingecko.py`
- `repo/data/src/adapters/cmc.py`

---

### Task 2.1.2: Implement Webhook Endpoints (Priority: Medium)

**Current**: WebSocket exists, HTTP webhooks missing

**Action**: Add webhook endpoints for real-time updates

**Implementation**:
```python
# Add to main.py or routes
@app.post("/webhooks/binance")
async def binance_webhook(request: Request):
    """Receive webhook from Binance for real-time updates"""
    data = await request.json()
    # Validate signature
    # Process data
    # Store in database
    # Publish to Redis for other services
    return {"status": "ok"}

@app.post("/webhooks/polygon")
async def polygon_webhook(request: Request):
    """Receive webhook from Polygon"""
    # Similar implementation
```

**Files to Create**:
- `repo/data/src/api/routes/webhooks.py`

---

### Task 2.1.3: Standardize API Routes (Priority: High)

**Current**: Custom endpoint system in main.py

**Action**: Create standardized REST API routes

**Implementation**:
```python
# Create standardized routes
@app.get("/api/v1/data/price")
async def get_price(symbol: str, provider: Optional[str] = None):
    """Get current price for symbol"""
    # Use MultiProviderManager
    # Return normalized data

@app.get("/api/v1/data/ohlcv")
async def get_ohlcv(symbol: str, interval: str, start: Optional[datetime], end: Optional[datetime]):
    """Get OHLCV data"""
    # Fetch from adapters
    # Return normalized format
```

**Files to Create**:
- `repo/data/src/api/routes/data.py`

---

### Task 2.1.4: Enhance Data Validation (Priority: Medium)

**Current**: OutlierDetector exists but not integrated

**Action**: Integrate validation into data pipeline

**Implementation**:
```python
# In data pipeline
from validators.outlier_detector import OutlierDetector

detector = OutlierDetector(method='zscore', threshold=3.0)
results = detector.detect(df, fields=['close', 'volume'])

# Alert on high severity
for result in results:
    if result.severity == 'high':
        # Send alert via fks_monitor
        await send_alert(f"High severity outliers in {result.field}")
```

**Files to Modify**:
- `repo/data/src/pipelines/etl.py`
- `repo/data/src/adapters/base.py` (add validation step)

---

## 📋 Implementation Checklist

### High Priority
- [ ] Add Redis caching to Binance adapter
- [ ] Add Redis caching to Polygon adapter
- [ ] Add Redis caching to CoinGecko adapter
- [ ] Create standardized API routes (`/api/v1/data/*`)
- [ ] Test with sample data (BTC, ETH, SPY)

### Medium Priority
- [ ] Implement webhook endpoints
- [ ] Integrate outlier detection
- [ ] Add data freshness monitoring
- [ ] Configure rate limits per provider

### Low Priority
- [ ] Add circuit breakers for adapters
- [ ] Implement data quality scoring
- [ ] Add metrics collection

---

## 🔧 Configuration Needed

### Environment Variables
```bash
# Redis
REDIS_URL=redis://redis:6379/0

# API Keys (for free tiers)
POLYGON_API_KEY=your_key
ALPHA_VANTAGE_API_KEY=your_key
COINMARKETCAP_API_KEY=your_key

# Rate Limits
FKS_BINANCE_RPS=10
FKS_POLYGON_RPS=4
FKS_ALPHA_VANTAGE_RPS=0.083  # 5 per minute
```

### Docker Compose
Ensure Redis is available:
```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
```

---

## 🧪 Testing Plan

1. **Test Adapter Caching**:
   ```bash
   # First request (cache miss)
   curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT
   
   # Second request (cache hit - should be faster)
   curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT
   ```

2. **Test Multi-Provider**:
   ```bash
   # Request with failover
   curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT&provider=binance
   ```

3. **Test Validation**:
   ```bash
   # Request with validation
   curl http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&validate=true
   ```

---

## 📊 Success Criteria

- [ ] All major adapters have Redis caching enabled
- [ ] Standardized API routes working (`/api/v1/data/*`)
- [ ] Webhook endpoints functional (at least for Binance)
- [ ] Data validation integrated
- [ ] Test with 5+ assets successful

---

**Next Steps**: Begin implementation of caching and standardized routes.

