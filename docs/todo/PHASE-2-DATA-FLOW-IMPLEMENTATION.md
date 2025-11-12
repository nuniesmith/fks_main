# Phase 2.1: Data Flow Stabilization - Implementation Plan

**Date**: 2025-01-15  
**Status**: In Progress  
**Objective**: Stabilize data flow from multiple sources

---

## ✅ Completed

1. **Analysis Document Created**: `PHASE-2-DATA-FLOW-ANALYSIS.md`
2. **Standardized API Routes Created**: `repo/data/src/api/routes/data.py`
3. **Webhook Endpoints Created**: `repo/data/src/api/routes/webhooks.py`

---

## 📋 Implementation Tasks

### Task 1: Register New Routes in FastAPI App

**File**: `repo/data/src/main.py` or `repo/data/src/app.py`

**Action**: Register the new routes with the FastAPI/Flask app

**For FastAPI** (if using FastAPI):
```python
from api.routes import data, webhooks

app.include_router(data.router)
app.include_router(webhooks.router)
```

**For Flask** (if using Flask):
```python
from api.routes.data import router as data_router
from api.routes.webhooks import router as webhooks_router

# Convert FastAPI routes to Flask blueprints
# Or create Flask versions
```

**Status**: ⚠️ Need to determine which framework is actually used

---

### Task 2: Add Redis Caching to Binance Adapter

**File**: `repo/data/src/adapters/binance.py`

**Action**: Add caching similar to EODHD adapter

**Implementation**:
```python
import os
import json
import logging

try:
    import redis
    HAS_REDIS = True
except ImportError:
    HAS_REDIS = False

logger = logging.getLogger(__name__)

class BinanceAdapter(APIAdapter):
    # ... existing code ...
    
    def __init__(self, http=None, *, timeout=None, enable_cache=True, redis_url=None):
        super().__init__(http, timeout=timeout)
        
        # Initialize Redis cache
        self.enable_cache = enable_cache and HAS_REDIS
        self.redis_client = None
        
        if self.enable_cache:
            try:
                redis_url = redis_url or os.getenv("REDIS_URL", "redis://:@redis:6379/0")
                self.redis_client = redis.from_url(redis_url, decode_responses=True)
                self.redis_client.ping()
                logger.info("Binance adapter initialized with Redis cache")
            except Exception as e:
                logger.warning(f"Failed to initialize Redis cache: {e}")
                self.enable_cache = False
    
    def _build_cache_key(self, **kwargs) -> str:
        symbol = kwargs.get("symbol", "BTCUSDT")
        interval = kwargs.get("interval", "1m")
        limit = kwargs.get("limit", 500)
        return f"binance:{symbol}:{interval}:{limit}"
    
    def fetch(self, **kwargs) -> dict[str, Any]:
        # Check cache first
        if self.enable_cache and self.redis_client:
            cache_key = self._build_cache_key(**kwargs)
            try:
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    logger.debug(f"Cache HIT: {cache_key}")
                    return json.loads(cached_data)
            except Exception as e:
                logger.warning(f"Cache GET error: {e}")
        
        # Fetch from API
        result = super().fetch(**kwargs)
        
        # Store in cache (5 minute TTL for market data)
        if self.enable_cache and self.redis_client and result:
            cache_key = self._build_cache_key(**kwargs)
            try:
                self.redis_client.setex(cache_key, 300, json.dumps(result, default=str))
                logger.debug(f"Cached: {cache_key} (TTL=300s)")
            except Exception as e:
                logger.warning(f"Cache SET error: {e}")
        
        return result
```

**Status**: ⏳ Pending

---

### Task 3: Add Redis Caching to Polygon Adapter

**File**: `repo/data/src/adapters/polygon.py`

**Action**: Similar to Binance adapter

**Status**: ⏳ Pending

---

### Task 4: Test Standardized Routes

**Action**: Test the new API routes

**Test Commands**:
```bash
# Test price endpoint
curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT

# Test OHLCV endpoint
curl http://localhost:8003/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h

# Test providers list
curl http://localhost:8003/api/v1/data/providers

# Test health endpoint
curl http://localhost:8003/api/v1/data/health
```

**Status**: ⏳ Pending (routes need to be registered first)

---

### Task 5: Test Webhook Endpoints

**Action**: Test webhook endpoints

**Test Commands**:
```bash
# Test webhook endpoint
curl -X POST http://localhost:8003/webhooks/binance \
  -H "Content-Type: application/json" \
  -d '{"e":"kline","s":"BTCUSDT","k":{"t":1234567890,"o":"50000","h":"51000","l":"49000","c":"50500","v":"100.5","x":true}}'

# Test webhook test endpoint
curl http://localhost:8003/webhooks/test
```

**Status**: ⏳ Pending

---

## 🔧 Configuration Updates Needed

### Environment Variables

Add to `repo/data/.env` or `docker-compose.yml`:
```bash
# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Webhook Secrets (optional, for signature verification)
BINANCE_WEBHOOK_SECRET=your_secret_here
POLYGON_WEBHOOK_SECRET=your_secret_here
```

### Docker Compose

Ensure Redis service is available:
```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
```

---

## 📊 Testing Checklist

- [ ] Routes registered and accessible
- [ ] Price endpoint returns data
- [ ] OHLCV endpoint returns data
- [ ] Caching works (second request faster)
- [ ] Webhook endpoints accept POST requests
- [ ] Multi-provider failover works
- [ ] Error handling works correctly

---

## 🚀 Next Steps

1. **Determine Framework**: Check if fks_data uses FastAPI or Flask
2. **Register Routes**: Add routes to main app
3. **Add Caching**: Implement Redis caching in adapters
4. **Test Endpoints**: Verify all endpoints work
5. **Documentation**: Update API documentation

---

**Current Status**: Routes created, need to be integrated into main app.

