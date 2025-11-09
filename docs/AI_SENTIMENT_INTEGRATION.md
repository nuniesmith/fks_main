# ASMBTR Sentiment Integration - Complete Documentation

**Date**: November 7, 2025  
**Status**: ✅ Implemented  
**Phase**: 6.1.3 - ASMBTR Strategy Integration

---

## Overview

Successfully integrated LLM-powered sentiment analysis into the ASMBTR (Adaptive State Model on Binary Tree Representation) trading strategy. The hybrid system combines technical signals from ASMBTR with market sentiment from news sources to improve prediction accuracy.

### Key Achievements

- ✅ **Sentiment Module**: FinBERT-powered sentiment analysis with Redis caching
- ✅ **Hybrid Signals**: Weighted blending of technical (75%) + sentiment (25%)
- ✅ **Graceful Fallback**: Works with or without sentiment module
- ✅ **Configuration**: Adjustable sentiment weight and enable/disable flag
- ✅ **Comprehensive Tests**: 15+ test cases covering all scenarios

### Target Performance

- **Expected Improvement**: +15-20% return improvement in backtests
- **Signal Quality**: 30-40% reduction in false signals (research-based target)
- **Sharpe Ratio**: +0.5 improvement with sentiment integration

---

## Architecture

### Hybrid Signal Calculation

```
hybrid_signal = (technical_weight × technical_signal) + (sentiment_weight × sentiment_score)

Where:
- technical_signal: -1.0 (DOWN), 0.0 (NEUTRAL), 1.0 (UP)
- sentiment_score: -1.0 (bearish) to +1.0 (bullish)
- technical_weight: 0.75 (default)
- sentiment_weight: 0.25 (default)
```

### Decision Logic

```python
if hybrid_signal > 0.1:
    final_prediction = "UP"
elif hybrid_signal < -0.1:
    final_prediction = "DOWN"
else:
    final_prediction = "NEUTRAL"
```

### Example Scenarios

| Technical | Sentiment | Hybrid Signal | Final Prediction |
|-----------|-----------|---------------|------------------|
| UP (+1.0) | +0.5 | 0.875 | UP |
| UP (+1.0) | -0.6 | 0.600 | UP |
| DOWN (-1.0) | +0.8 | -0.550 | DOWN |
| NEUTRAL (0.0) | +0.3 | 0.075 | NEUTRAL |
| DOWN (-1.0) | +1.0 | -0.500 | DOWN |

---

## Implementation Details

### Modified Files

1. **`/repo/app/src/tasks/asmbtr_prediction.py`** (390 lines)
   - Added sentiment module import with fallback
   - Extended `ASMBTRPredictionService.__init__` with sentiment parameters
   - Enhanced `generate_prediction` to fetch sentiment and blend signals
   - Added logging for sentiment scores and hybrid signals

2. **`/tests/unit/test_asmbtr_with_sentiment.py`** (NEW, 450 lines)
   - 15+ test cases covering sentiment integration
   - Hybrid signal calculation tests
   - Edge case tests (extreme sentiment, disabled sentiment)
   - Symbol format handling tests
   - Celery task integration tests

3. **`/src/services/ai/src/sentiment/`** (Created in Task 2)
   - `sentiment_analyzer.py`: FinBERT sentiment analysis
   - `config.py`: Configuration management
   - `README.md`: Module documentation

### Code Changes

#### 1. Sentiment Import with Fallback

```python
# Import sentiment analysis
try:
    from src.services.ai.src.sentiment import get_sentiment_from_news
    SENTIMENT_AVAILABLE = True
    logger.info("✅ Sentiment analysis module loaded")
except ImportError:
    logger.warning("⚠️ Sentiment analysis not available, running in technical-only mode")
    SENTIMENT_AVAILABLE = False
    
    def get_sentiment_from_news(symbol: str) -> float:
        """Fallback when sentiment module unavailable."""
        return 0.0
```

#### 2. Enhanced Initialization

```python
def __init__(
    self,
    redis_url: Optional[str] = None,
    depth: int = 8,
    confidence_threshold: Decimal = Decimal("0.60"),
    decay_rate: Decimal = Decimal("0.95"),
    min_observations: int = 10,
    sentiment_weight: float = 0.25,  # NEW
    enable_sentiment: bool = True,   # NEW
):
    # ... existing code ...
    
    # Sentiment configuration
    self.sentiment_weight = sentiment_weight
    self.enable_sentiment = enable_sentiment and SENTIMENT_AVAILABLE
    self.technical_weight = 1.0 - sentiment_weight
    
    logger.info(
        f"🔮 ASMBTR Prediction Service initialized "
        f"(depth={depth}, threshold={confidence_threshold}, decay={decay_rate}, "
        f"sentiment={self.enable_sentiment}, weight={sentiment_weight:.2f})"
    )
```

#### 3. Hybrid Prediction Generation

```python
def generate_prediction(self, symbol: str, state) -> Optional[dict[str, Any]]:
    """Generate prediction with sentiment integration."""
    
    # ... existing ASMBTR prediction code ...
    
    # Get sentiment score if enabled
    sentiment_score = 0.0
    if self.enable_sentiment:
        try:
            base_symbol = symbol.split('/')[0] if '/' in symbol else symbol
            sentiment_score = get_sentiment_from_news(base_symbol)
        except Exception as e:
            logger.warning(f"⚠️ Sentiment fetch failed for {symbol}: {e}")
            sentiment_score = 0.0
    
    # Convert technical prediction to signal
    technical_signal = 0.0
    if pred_value == "UP":
        technical_signal = 1.0
    elif pred_value == "DOWN":
        technical_signal = -1.0
    
    # Create hybrid signal
    hybrid_signal = (
        self.technical_weight * technical_signal + 
        self.sentiment_weight * sentiment_score
    )
    
    # Determine final prediction
    final_prediction = "NEUTRAL"
    if hybrid_signal > 0.1:
        final_prediction = "UP"
    elif hybrid_signal < -0.1:
        final_prediction = "DOWN"
    
    # Return enriched result
    result = {
        "symbol": symbol,
        "prediction": final_prediction,
        "technical_prediction": pred_value,
        "confidence": float(prediction.confidence),
        "sentiment_score": float(sentiment_score),
        "technical_signal": float(technical_signal),
        "hybrid_signal": float(hybrid_signal),
        "sentiment_enabled": self.enable_sentiment,
        "sentiment_weight": self.sentiment_weight,
        # ... other fields ...
    }
    
    return result
```

---

## Configuration

### Environment Variables

Set in `docker-compose.yml` or K8s ConfigMap:

```yaml
services:
  celery-worker:
    environment:
      # Sentiment configuration
      - ASMBTR_SENTIMENT_WEIGHT=0.25      # Default: 0.25 (25% sentiment)
      - ASMBTR_ENABLE_SENTIMENT=true      # Default: true
      
      # Sentiment module dependencies
      - CRYPTOPANIC_API_KEY=your_key_here
      - NEWSAPI_KEY=your_key_here
      - REDIS_URL=redis://:@redis:6379/1
```

### Python Configuration

```python
from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

# Default configuration (25% sentiment)
service = ASMBTRPredictionService()

# Custom sentiment weight (40%)
service = ASMBTRPredictionService(sentiment_weight=0.4)

# Disable sentiment
service = ASMBTRPredictionService(enable_sentiment=False)

# Full configuration
service = ASMBTRPredictionService(
    redis_url="redis://localhost:6379/1",
    depth=8,
    confidence_threshold=Decimal("0.60"),
    decay_rate=Decimal("0.95"),
    min_observations=10,
    sentiment_weight=0.3,
    enable_sentiment=True,
)
```

---

## Testing

### Run Tests

```bash
# All sentiment integration tests
pytest tests/unit/test_asmbtr_with_sentiment.py -v

# Specific test class
pytest tests/unit/test_asmbtr_with_sentiment.py::TestSentimentIntegration -v

# Single test
pytest tests/unit/test_asmbtr_with_sentiment.py::TestSentimentIntegration::test_hybrid_signal_calculation_positive_sentiment -v

# With coverage
pytest tests/unit/test_asmbtr_with_sentiment.py --cov=repo.app.src.tasks.asmbtr_prediction --cov-report=html
```

### Test Coverage

```
tests/unit/test_asmbtr_with_sentiment.py::TestSentimentIntegration
✅ test_sentiment_weight_in_init                                    PASSED
✅ test_disable_sentiment                                           PASSED
✅ test_sentiment_fetched_during_prediction                         PASSED
✅ test_hybrid_signal_calculation_positive_sentiment                PASSED
✅ test_hybrid_signal_calculation_negative_sentiment                PASSED
✅ test_hybrid_signal_down_technical_positive_sentiment             PASSED
✅ test_hybrid_signal_neutral_technical                             PASSED
✅ test_sentiment_fallback_on_error                                 PASSED
✅ test_sentiment_disabled                                          PASSED

tests/unit/test_asmbtr_with_sentiment.py::TestHybridSignalEdgeCases
✅ test_extreme_positive_sentiment                                  PASSED
✅ test_extreme_negative_sentiment                                  PASSED
✅ test_high_sentiment_weight                                       PASSED

tests/unit/test_asmbtr_with_sentiment.py::TestSymbolFormatHandling
✅ test_symbol_with_slash                                           PASSED
✅ test_symbol_without_slash                                        PASSED

tests/unit/test_asmbtr_with_sentiment.py::TestCeleryTask
✅ test_task_uses_default_symbols                                   PASSED
✅ test_task_uses_custom_symbols                                    PASSED

tests/unit/test_asmbtr_with_sentiment.py::TestPredictionStorage
✅ test_store_prediction_includes_sentiment_fields                  PASSED

TOTAL: 17/17 tests passed ✅
```

---

## Usage

### Celery Task

The `asmbtr.predict` task runs every 60 seconds via Celery Beat:

```python
# Task runs automatically with default symbols
# No manual invocation needed (configured in celeryconfig.py)

# Manual invocation for testing
from repo.app.src.tasks.asmbtr_prediction import predict_asmbtr_task

result = predict_asmbtr_task.delay()  # Async
# or
result = predict_asmbtr_task()  # Sync
```

### Accessing Predictions

```python
import redis
import json

# Connect to Redis
client = redis.from_url("redis://localhost:6379/1", decode_responses=True)

# Get latest prediction
prediction_json = client.get("asmbtr:predictions:BTC/USDT")
prediction = json.loads(prediction_json)

print(f"Symbol: {prediction['symbol']}")
print(f"Prediction: {prediction['prediction']}")
print(f"Technical: {prediction['technical_prediction']}")
print(f"Sentiment: {prediction['sentiment_score']:+.3f}")
print(f"Hybrid Signal: {prediction['hybrid_signal']:+.3f}")
print(f"Confidence: {prediction['confidence']:.2%}")
```

### Kubernetes Logs

```bash
# Watch Celery worker logs for predictions
kubectl logs -f deployment/celery-worker -n fks-trading | grep ASMBTR

# Example output:
# ✅ BTC/USDT prediction: UP (technical: UP, sentiment: +0.450, hybrid: +0.862, confidence: 75.0%)
# ✅ ETH/USDT prediction: DOWN (technical: DOWN, sentiment: -0.320, hybrid: -0.830, confidence: 68.5%)
```

---

## Performance Monitoring

### Prometheus Metrics

Existing ASMBTR metrics extended with sentiment:

```promql
# Prediction rate with sentiment
rate(asmbtr_predictions_total[5m])

# Confidence distribution
histogram_quantile(0.95, asmbtr_prediction_confidence_bucket)

# Execution time (includes sentiment fetch)
rate(asmbtr_execution_seconds_sum[5m]) / rate(asmbtr_execution_seconds_count[5m])
```

### Grafana Dashboard

Add panels to `/monitoring/grafana/dashboards/execution_pipeline.json`:

1. **Sentiment Score Distribution**: Histogram of sentiment scores
2. **Hybrid vs Technical Signals**: Compare predictions with/without sentiment
3. **Sentiment API Latency**: Track sentiment fetch time
4. **Cache Hit Rate**: Monitor Redis sentiment cache efficiency

---

## Validation Steps

### 1. Unit Tests (Completed ✅)

```bash
pytest tests/unit/test_asmbtr_with_sentiment.py -v
# Result: 17/17 tests passed
```

### 2. Integration Testing (Next)

```bash
# Test with live sentiment API
python scripts/test_sentiment.py

# Run ASMBTR prediction cycle manually
kubectl exec -it deployment/celery-worker -n fks-trading -- \
  python -c "from repo.app.src.tasks.asmbtr_prediction import predict_asmbtr_task; predict_asmbtr_task()"

# Check Redis for predictions
kubectl exec -it deployment/redis -n fks-trading -- \
  redis-cli GET "asmbtr:predictions:BTC/USDT"
```

### 3. Backtesting (Pending)

```python
# TODO: Create backtesting script
# Compare performance: ASMBTR vs ASMBTR+Sentiment
# Target: +15-20% return improvement
# File: /scripts/backtest_asmbtr_sentiment.py

from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService
import pandas as pd

# Load 2024 crypto data
data = pd.read_csv('/data/market_data/btc_2024.csv')

# Run backtest with sentiment
service_with_sentiment = ASMBTRPredictionService(sentiment_weight=0.25)
# ... backtesting logic ...

# Run backtest without sentiment
service_no_sentiment = ASMBTRPredictionService(enable_sentiment=False)
# ... backtesting logic ...

# Compare results
# - Total returns
# - Sharpe ratio
# - Max drawdown
# - Win rate
```

---

## Troubleshooting

### Issue: Sentiment Not Fetched

**Symptoms**: `sentiment_score` always 0.0, `sentiment_enabled` is `false`

**Solutions**:
1. Check sentiment module installation:
   ```bash
   kubectl exec -it deployment/celery-worker -n fks-trading -- \
     python -c "from src.services.ai.src.sentiment import get_sentiment_from_news; print('OK')"
   ```

2. Verify API keys:
   ```bash
   kubectl exec -it deployment/celery-worker -n fks-trading -- \
     env | grep -E "CRYPTOPANIC|NEWSAPI"
   ```

3. Check logs:
   ```bash
   kubectl logs deployment/celery-worker -n fks-trading | grep sentiment
   ```

### Issue: High Sentiment Fetch Latency

**Symptoms**: ASMBTR prediction cycle >5 seconds

**Solutions**:
1. Check Redis cache hit rate:
   ```bash
   kubectl exec -it deployment/redis -n fks-trading -- \
     redis-cli INFO stats | grep keyspace_hits
   ```

2. Increase cache TTL in `/src/services/ai/src/sentiment/sentiment_analyzer.py`:
   ```python
   self.cache.setex(f"sentiment:{symbol}", 600, score)  # 10 min instead of 5
   ```

3. Pre-warm cache for active symbols:
   ```python
   from src.services.ai.src.sentiment import get_sentiment_from_news
   for symbol in ["BTC", "ETH", "SOL"]:
       get_sentiment_from_news(symbol)
   ```

### Issue: Sentiment API Rate Limits

**Symptoms**: Errors like "API rate limit exceeded"

**Solutions**:
1. Use free tier limits (250 req/day CryptoPanic):
   ```python
   # In config.py
   CRYPTOPANIC_RATE_LIMIT = 250  # requests per day
   ```

2. Increase Redis cache TTL:
   ```python
   cache_ttl = 600  # 10 minutes instead of 5
   ```

3. Reduce prediction frequency:
   ```python
   # In celeryconfig.py
   beat_schedule = {
       'asmbtr-predict': {
           'task': 'asmbtr.predict',
           'schedule': 120.0,  # 2 minutes instead of 60 seconds
       },
   }
   ```

---

## Next Steps

### Task 5: Phase 7.1.1 - Monorepo Backup

1. Create git bundle backup
2. Install git-filter-repo
3. Document baseline structure
4. Prepare for repository split

### Future Enhancements

1. **Fine-Tune Sentiment Model** (Phase 6.3)
   - Use LoRA adapters on FinBERT for crypto-specific sentiment
   - Target: 60-70% API cost reduction
   - Estimated cost: ~$300 one-time

2. **Multi-Source Sentiment Aggregation** (Phase 6.2)
   - Add Twitter/Reddit sentiment via social APIs
   - Combine news + social with weighted average
   - Improve sentiment accuracy by 10-15%

3. **Adaptive Sentiment Weight** (Phase 6.3)
   - Dynamically adjust sentiment_weight based on market regime
   - Bull markets: increase sentiment weight (0.35)
   - Bear markets: decrease sentiment weight (0.15)

4. **Backtesting Validation** (Phase 6.1.3)
   - Implement `/scripts/backtest_asmbtr_sentiment.py`
   - Run on 2024 crypto data (BTC/ETH)
   - Validate +15-20% return target
   - Generate performance report

---

## Research References

- **FinGPT**: Open-source financial LLMs, F1 score 0.88 on sentiment
  - https://github.com/AI4Finance-Foundation/FinGPT

- **CryptoTrade**: Reflective LLM agent, 2.38% ETH returns
  - https://github.com/Xtra-Computing/CryptoTrade
  - https://aclanthology.org/2024.emnlp-main.63.pdf

- **TradingAgents**: Multi-agent LLM framework
  - https://github.com/TauricResearch/TradingAgents

- **Alpha Arena**: AI trading competition results
  - https://www.chaincatcher.com/en/article/2213902

- **FinBERT Model**: ProsusAI/finbert on Hugging Face
  - https://huggingface.co/ProsusAI/finbert

---

## Summary

Successfully integrated sentiment analysis into ASMBTR trading strategy with:
- ✅ Hybrid signal blending (75% technical + 25% sentiment)
- ✅ Graceful fallback when sentiment unavailable
- ✅ Comprehensive test suite (17/17 tests passed)
- ✅ Production-ready configuration options
- ⏳ Backtesting validation pending

**Expected Impact**:
- +15-20% return improvement
- 30-40% reduction in false signals
- +0.5 Sharpe ratio improvement

**Next Action**: Proceed to Task 5 (Phase 7.1.1 - Monorepo Backup)
