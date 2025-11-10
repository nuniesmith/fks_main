# FKS Platform - Troubleshooting Guide

**Date**: 2025-01-XX  
**Purpose**: Common issues and solutions for FKS Platform

---

## 🔍 Quick Diagnosis

### Service Health Checks

```bash
# Check all services
curl http://localhost:8001/ai/bots/health  # fks_ai
curl http://localhost:8004/api/v1/rag/health  # fks_analyze
curl http://localhost:8002/health  # fks_training
```

### Check Logs

```bash
# Docker logs
docker-compose logs -f fks-ai
docker-compose logs -f fks-analyze
docker-compose logs -f fks-training

# Local logs
tail -f repo/ai/logs/*.log
tail -f repo/analyze/logs/*.log
```

---

## 🐛 Common Issues

### 1. Multi-Agent Trading Bots

#### Issue: Bot signals not generating

**Symptoms**:
- API returns error
- No signal in response
- Bot returns HOLD always

**Diagnosis**:
```bash
# Check bot logs
grep -i "error" repo/ai/logs/*.log

# Test bot directly
python -c "from src.agents.stockbot import StockBot; bot = StockBot(); print(bot)"
```

**Solutions**:
1. **Check market data format**:
   ```python
   # Ensure market_data has correct format
   market_data = {
       "data": [
           {"open": 100, "high": 105, "low": 95, "close": 102, "volume": 1000000}
       ]
   }
   ```

2. **Verify symbol format**:
   ```python
   # Stocks: "AAPL", "MSFT"
   # Crypto: "BTC-USD", "ETH-USD"
   # Forex: "EURUSD", "GBPUSD"
   ```

3. **Check bot initialization**:
   ```python
   from src.agents.stockbot import StockBot
   bot = StockBot()
   signal = await bot.analyze("AAPL", market_data)
   ```

---

#### Issue: Consensus mechanism not working

**Symptoms**:
- Consensus signal is always HOLD
- Bot signals not aggregating

**Diagnosis**:
```python
# Check bot signals
result = await analyze_symbol("BTC-USD", market_data, include_bots=True)
print(result["signals"])  # Should have bot signals
print(result["consensus_signal"])  # Should have consensus
```

**Solutions**:
1. **Verify bot nodes are called**:
   ```python
   # Check if bots are in workflow
   from src.graph.trading_graph import trading_graph
   print(trading_graph.nodes)  # Should include "bots" and "consensus"
   ```

2. **Check BTC priority rules**:
   ```python
   # Ensure BTC signals have btc_priority flag
   signal = {"signal": "BUY", "confidence": 0.8, "btc_priority": True}
   ```

---

### 2. PPO Training

#### Issue: Training fails to start

**Symptoms**:
- Training script errors
- Environment creation fails
- Data loading errors

**Diagnosis**:
```bash
# Check data availability
python -c "import yfinance as yf; data = yf.download('AAPL', start='2020-01-01'); print(len(data))"

# Check feature extractor
python -c "from src.ppo.feature_extractor import FKSFeatureExtractor; fe = FKSFeatureExtractor(); print('OK')"
```

**Solutions**:
1. **Verify data source**:
   ```bash
   # Test yfinance
   python -m src.ppo.train_trading_ppo --ticker AAPL --data-source yfinance --max-episodes 10
   
   # Test fks_data
   python -m src.ppo.train_trading_ppo --ticker AAPL --data-source fks_data --max-episodes 10
   ```

2. **Check feature extractor**:
   ```python
   from src.ppo.feature_extractor import FKSFeatureExtractor
   import pandas as pd
   
   fe = FKSFeatureExtractor()
   # Create sample data
   data = pd.DataFrame({
       'open': [100, 101, 102],
       'high': [105, 106, 107],
       'low': [95, 96, 97],
       'close': [102, 103, 104],
       'volume': [1000000, 1100000, 1200000]
   })
   features = fe.extract_features(data, current_idx=len(data)-1)
   print(features.shape)  # Should be (22,)
   ```

3. **Verify environment**:
   ```python
   from src.ppo.trading_env import TradingEnv
   
   env = TradingEnv(
       ticker="AAPL",
       start_date="2020-01-01",
       end_date="2025-01-01",
       data_source="yfinance"
   )
   state, info = env.reset()
   print(state.shape)  # Should be (22,)
   ```

---

#### Issue: Training is slow

**Symptoms**:
- Training takes too long
- Low episode throughput

**Solutions**:
1. **Reduce episode count for testing**:
   ```bash
   python -m src.ppo.train_trading_ppo --max-episodes 100
   ```

2. **Use smaller data window**:
   ```bash
   python -m src.ppo.train_trading_ppo --start-date 2024-01-01 --end-date 2025-01-01
   ```

3. **Check GPU availability**:
   ```python
   import torch
   print(torch.cuda.is_available())  # Should be True for GPU
   ```

---

#### Issue: Evaluation fails

**Symptoms**:
- Evaluation script errors
- Metrics not calculated

**Diagnosis**:
```bash
# Check model file exists
ls -lh models/ppo/ppo_meta_learning.pt

# Test model loading
python -c "import torch; from src.ppo.policy_network import DualHeadPPOPolicy; model = DualHeadPPOPolicy(22, 3); model.load_state_dict(torch.load('models/ppo/ppo_meta_learning.pt')); print('OK')"
```

**Solutions**:
1. **Verify model path**:
   ```bash
   python -m src.ppo.evaluate_model \
     --model-path ./models/ppo/ppo_meta_learning.pt \
     --ticker AAPL
   ```

2. **Check environment compatibility**:
   ```python
   # Ensure evaluation environment matches training
   env = TradingEnv(ticker="AAPL", start_date="2024-01-01", end_date="2025-01-01")
   state, info = env.reset()
   print(state.shape)  # Should match training (22,)
   ```

---

### 3. RAG System

#### Issue: RAG queries fail

**Symptoms**:
- Query returns error
- No documents found
- LLM errors

**Diagnosis**:
```bash
# Check vector store
ls -lh repo/analyze/chroma_db/

# Check document ingestion
curl -X POST http://localhost:8004/api/v1/rag/stats
```

**Solutions**:
1. **Ingest documents**:
   ```bash
   curl -X POST http://localhost:8004/api/v1/rag/ingest \
     -H "Content-Type: application/json" \
     -d '{"root_dir": "/path/to/fks", "include_code": true}'
   ```

2. **Check LLM configuration**:
   ```python
   # Verify Gemini API key
   import os
   print(os.getenv("GOOGLE_AI_API_KEY"))  # Should be set
   
   # Verify Ollama
   import httpx
   response = httpx.get("http://localhost:11434/api/tags")
   print(response.json())
   ```

3. **Test vector store**:
   ```python
   from src.rag.vector_store import VectorStoreManager
   from src.rag.config import RAGConfig
   
   config = RAGConfig()
   vs = VectorStoreManager(config)
   stats = vs.get_stats()
   print(stats)  # Should show document count
   ```

---

#### Issue: Advanced RAG features not working

**Symptoms**:
- HyDE not improving results
- RAPTOR errors
- Self-RAG not correcting

**Diagnosis**:
```python
# Check configuration
from src.rag.config import RAGConfig

config = RAGConfig()
print(config.use_hyde)  # Should be True
print(config.use_raptor)  # Should be True
print(config.use_self_rag)  # Should be True
```

**Solutions**:
1. **Enable features**:
   ```bash
   export RAG_USE_HYDE="true"
   export RAG_USE_RAPTOR="true"
   export RAG_USE_SELF_RAG="true"
   ```

2. **Test individually**:
   ```python
   # Test HyDE
   from src.rag.advanced.hyde import HyDERetriever
   hyde = HyDERetriever(config, vector_store)
   results = hyde.retrieve("query", k=5)
   print(len(results))  # Should have results
   ```

3. **Check LLM availability**:
   ```python
   # HyDE and RAPTOR need LLM for generation
   # Verify Ollama or Gemini is available
   ```

---

#### Issue: Document ingestion fails

**Symptoms**:
- Ingestion returns error
- Documents not indexed
- Vector store empty

**Diagnosis**:
```bash
# Check file permissions
ls -la repo/analyze/chroma_db/

# Check disk space
df -h
```

**Solutions**:
1. **Verify file paths**:
   ```python
   from pathlib import Path
   root_dir = Path("/path/to/fks")
   print(root_dir.exists())  # Should be True
   print(list(root_dir.glob("**/*.py"))[:5])  # Should find files
   ```

2. **Check ChromaDB**:
   ```python
   from src.rag.vector_store import VectorStoreManager
   from src.rag.config import RAGConfig
   
   config = RAGConfig()
   vs = VectorStoreManager(config)
   # Try to add a test document
   vs.add_documents(["test document"], [{"test": True}])
   ```

3. **Increase chunk size**:
   ```python
   # For large files, increase chunk size
   config = RAGConfig(chunk_size=2000, chunk_overlap=400)
   ```

---

### 4. General Issues

#### Issue: Import errors

**Symptoms**:
- ModuleNotFoundError
- ImportError

**Solutions**:
1. **Check Python path**:
   ```bash
   export PYTHONPATH="${PYTHONPATH}:$(pwd)/repo/ai/src:$(pwd)/repo/training/src:$(pwd)/repo/analyze/src"
   ```

2. **Reinstall dependencies**:
   ```bash
   pip install -r requirements.txt --force-reinstall
   ```

3. **Check __init__.py files**:
   ```bash
   find repo -name "__init__.py" -type f
   ```

---

#### Issue: Port conflicts

**Symptoms**:
- Address already in use
- Service won't start

**Solutions**:
1. **Find process using port**:
   ```bash
   lsof -i :8001
   netstat -tulpn | grep 8001
   ```

2. **Kill process**:
   ```bash
   kill -9 <PID>
   ```

3. **Use different port**:
   ```bash
   uvicorn src.main:app --port 8002
   ```

---

#### Issue: Memory issues

**Symptoms**:
- Out of memory errors
- Slow performance

**Solutions**:
1. **Reduce batch size**:
   ```python
   # In PPO training
   batch_size = 64  # Instead of 128
   ```

2. **Limit document chunks**:
   ```python
   # In RAG
   config = RAGConfig(top_k=3)  # Instead of 5
   ```

3. **Use smaller models**:
   ```bash
   # Use smaller Ollama model
   ollama pull qwen2.5:7b  # Instead of larger model
   ```

---

## 🔧 Debugging Tips

### Enable Debug Logging

```python
# Set log level to DEBUG
import logging
logging.basicConfig(level=logging.DEBUG)

# Or use loguru
from loguru import logger
logger.add("debug.log", level="DEBUG")
```

### Use Python Debugger

```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or use ipdb
import ipdb; ipdb.set_trace()
```

### Test Components Individually

```python
# Test feature extractor
from src.ppo.feature_extractor import FKSFeatureExtractor
fe = FKSFeatureExtractor()
# Test with sample data

# Test bot
from src.agents.stockbot import StockBot
bot = StockBot()
# Test with sample market data

# Test RAG
from src.rag.query_service import RAGQueryService
# Test with sample query
```

---

## 📞 Getting Help

1. **Check Documentation**:
   - `QUICK-START-GUIDE.md`
   - `PROJECT-OVERVIEW.md`
   - Implementation guides

2. **Review Logs**:
   - Service logs
   - Error logs
   - Debug logs

3. **Test Components**:
   - Run unit tests
   - Test individual components
   - Verify configurations

4. **Check Issues**:
   - Review known issues
   - Check GitHub issues (if applicable)
   - Review implementation guides

---

**Last Updated**: 2025-01-XX  
**Status**: Active

