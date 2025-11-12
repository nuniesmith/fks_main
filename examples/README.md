# FKS Platform - Example Usage

**Purpose**: Example scripts and usage patterns for FKS Platform

---

## 📝 Example Files

### `example_usage.py`
Comprehensive example script demonstrating:
- Multi-agent trading bots API usage
- RAG system API usage
- PPO training and evaluation
- Python API usage

---

## 🚀 Quick Examples

### Multi-Agent Trading Bots

```python
import asyncio
import httpx

async def get_stock_signal():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8001/ai/bots/stock/signal",
            json={
                "symbol": "AAPL",
                "market_data": {
                    "close": 150.0,
                    "data": [{"open": 149, "high": 151, "low": 148, "close": 150, "volume": 1000000}]
                }
            }
        )
        return response.json()

# Run
result = asyncio.run(get_stock_signal())
print(result)
```

### RAG System

```python
async def query_rag():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8004/api/v1/rag/query",
            json={"query": "How does portfolio optimization work?"}
        )
        return response.json()

# Run
result = asyncio.run(query_rag())
print(result["answer"])
```

### PPO Training

```bash
# Train model
python -m training.src.ppo.train_trading_ppo \
    --ticker AAPL \
    --start-date 2020-01-01 \
    --end-date 2025-01-01 \
    --max-episodes 1000

# Evaluate model
python -m training.src.ppo.evaluate_model \
    --model-path ./models/ppo/ppo_meta_learning.pt \
    --ticker AAPL \
    --n-episodes 10
```

---

## 📚 More Examples

See `example_usage.py` for comprehensive examples of all features.

---

**Last Updated**: 2025-01-XX

