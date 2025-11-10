# FKS Platform - Quick Start Guide

**Date**: 2025-01-XX  
**Purpose**: Quick reference for using all FKS implementations  
**Status**: Ready for Use

---

## 🚀 Quick Start

### 1. Multi-Agent Trading Bots

#### Get Bot Signal
```bash
# StockBot signal
curl -X POST http://localhost:8001/ai/bots/stock/signal \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "market_data": {
      "close": 150.0,
      "open": 149.0,
      "high": 151.0,
      "low": 148.0,
      "volume": 1000000
    }
  }'

# CryptoBot signal
curl -X POST http://localhost:8001/ai/bots/crypto/signal \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "BTC-USD",
    "market_data": {
      "close": 50000.0,
      "open": 49000.0,
      "high": 51000.0,
      "low": 48000.0,
      "volume": 100000000
    }
  }'

# Multi-bot consensus
curl -X POST http://localhost:8001/ai/bots/consensus \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "BTC-USD",
    "market_data": {
      "close": 50000.0,
      "open": 49000.0,
      "high": 51000.0,
      "low": 48000.0,
      "volume": 100000000
    },
    "include_stock": true,
    "include_forex": true,
    "include_crypto": true
  }'
```

#### Python Usage
```python
from src.agents.stockbot import StockBot
from src.agents.cryptobot import CryptoBot

# StockBot
stock_bot = StockBot()
signal = await stock_bot.analyze("AAPL", {"data": [...]})

# CryptoBot
crypto_bot = CryptoBot()
signal = await crypto_bot.analyze("BTC-USD", {"data": [...]})
```

---

### 2. PPO Training and Evaluation

#### Train PPO Model
```bash
cd repo/training

# Train on stock data
python -m src.ppo.train_trading_ppo \
  --ticker AAPL \
  --start-date 2020-01-01 \
  --end-date 2025-01-01 \
  --max-episodes 1000 \
  --data-source yfinance \
  --use-mlflow

# Train on crypto data
python -m src.ppo.train_trading_ppo \
  --ticker BTC-USD \
  --start-date 2020-01-01 \
  --end-date 2025-01-01 \
  --max-episodes 1000 \
  --data-source yfinance
```

#### Evaluate Trained Model
```bash
cd repo/training

# Basic evaluation
python -m src.ppo.evaluate_model \
  --model-path ./models/ppo/ppo_meta_learning.pt \
  --ticker AAPL \
  --start-date 2024-01-01 \
  --end-date 2025-01-01 \
  --n-episodes 10

# With baseline comparison
python -m src.ppo.evaluate_model \
  --model-path ./models/ppo/ppo_meta_learning.pt \
  --ticker AAPL \
  --compare-baseline \
  --n-episodes 10

# Generate report
python -m src.ppo.evaluate_model \
  --model-path ./models/ppo/ppo_meta_learning.pt \
  --ticker AAPL \
  --output-report ./reports/evaluation_report.txt \
  --n-episodes 10
```

#### Python Usage
```python
from src.ppo.policy_network import DualHeadPPOPolicy
from src.ppo.trading_env import TradingEnv
from src.ppo.evaluation import PPOEvaluator
import torch

# Load model
model = DualHeadPPOPolicy(feature_dim=22, num_actions=3)
model.load_state_dict(torch.load("model.pt"))

# Create environment
env = TradingEnv(ticker="AAPL", start_date="2024-01-01", end_date="2025-01-01")

# Evaluate
evaluator = PPOEvaluator(model, env)
metrics = evaluator.evaluate_performance(n_episodes=10)
```

---

### 3. RAG System

#### Ingest Documents
```bash
curl -X POST http://localhost:8004/api/v1/rag/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "root_dir": "/path/to/fks",
    "include_code": true,
    "clear_existing": false
  }'
```

#### Query RAG
```bash
# Basic query
curl -X POST http://localhost:8004/api/v1/rag/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How does the portfolio optimization work?"
  }'

# Query with filter
curl -X POST http://localhost:8004/api/v1/rag/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How does the portfolio optimization work?",
    "filter": {"service": "fks_portfolio"}
  }'
```

#### Python Usage
```python
from src.rag.query_service import RAGQueryService
from src.rag.config import RAGConfig
from src.rag.vector_store import VectorStoreManager

# Initialize
config = RAGConfig()
vector_store = VectorStoreManager(config)
query_service = RAGQueryService(config, vector_store)

# Query
result = query_service.query("How does portfolio optimization work?")
print(result["answer"])
```

---

### 4. Advanced RAG Features

#### HyDE Retrieval
```python
from src.rag.advanced.hyde import HyDERetriever
from src.rag.config import RAGConfig
from src.rag.vector_store import VectorStoreManager

config = RAGConfig(use_hyde=True)
vector_store = VectorStoreManager(config)
hyde = HyDERetriever(config, vector_store)

results = hyde.retrieve("How to optimize trading strategies?", k=5)
```

#### RAPTOR Retrieval
```python
from src.rag.advanced.raptor import RAPTORRetriever
from src.rag.config import RAGConfig
from src.rag.vector_store import VectorStoreManager

config = RAGConfig(use_raptor=True)
vector_store = VectorStoreManager(config)
raptor = RAPTORRetriever(config, vector_store)

results = raptor.retrieve("Complex trading system architecture?", k=5)
```

#### Self-RAG
```python
from src.rag.advanced.self_rag import SelfRAGWorkflow
from src.rag.config import RAGConfig
from src.rag.vector_store import VectorStoreManager

config = RAGConfig(use_self_rag=True)
vector_store = VectorStoreManager(config)
self_rag = SelfRAGWorkflow(config, vector_store)

result = self_rag.query("What is the best trading strategy?")
```

#### RAGAS Evaluation
```bash
curl -X POST http://localhost:8004/api/v1/rag/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How does portfolio optimization work?",
    "answer": "Portfolio optimization uses mean-variance optimization...",
    "contexts": ["Context 1", "Context 2"]
  }'
```

---

## 🧪 Testing

### Run All Tests
```bash
# Run all tests
./repo/main/scripts/run_all_tests.sh all

# Run with coverage
./repo/main/scripts/run_all_tests.sh all true

# Run specific service
./repo/main/scripts/run_all_tests.sh ai
./repo/main/scripts/run_all_tests.sh training
./repo/main/scripts/run_all_tests.sh analyze
```

### Run Specific Test Suites
```bash
# Multi-Agent Bots
cd repo/ai
pytest tests/unit/test_bots/ -v
pytest tests/integration/test_bot_integration.py -v

# PPO
cd repo/training
pytest tests/unit/test_ppo/ -v

# RAG
cd repo/analyze
pytest tests/unit/test_rag/ -v
pytest tests/integration/test_rag_api_endpoints.py -v
```

---

## 📊 Monitoring

### Health Checks
```bash
# Bot health
curl http://localhost:8001/ai/bots/health

# RAG health
curl http://localhost:8004/api/v1/rag/health

# RAG stats
curl http://localhost:8004/api/v1/rag/stats
```

### MLflow (PPO Training)
```bash
# Start MLflow UI
mlflow ui --port 5000

# View experiments
# Navigate to http://localhost:5000
```

---

## 🔧 Configuration

### Environment Variables

#### RAG Configuration
```bash
export GOOGLE_AI_API_KEY="your_gemini_key"
export OLLAMA_HOST="http://fks_ai:11434"
export RAG_USE_HYDE="true"
export RAG_USE_RAPTOR="true"
export RAG_USE_SELF_RAG="true"
export RAGAS_THRESHOLD="0.9"
```

#### PPO Configuration
```bash
export MLFLOW_TRACKING_URI="http://localhost:5000"
```

---

## 📚 Documentation

### Implementation Guides
- `14-MULTI-AGENT-TRADING-BOTS-IMPLEMENTATION.md` - Bot implementation
- `18-PPO-META-LEARNING-IMPLEMENTATION.md` - PPO implementation
- `16-RAG-IMPLEMENTATION-GUIDE.md` - RAG implementation

### Status Documents
- `IMPLEMENTATION-SUMMARY.md` - Overall summary
- `CURRENT-STATUS.md` - Current status
- `COMPLETE-IMPLEMENTATION-STATUS.md` - Complete status
- `TEST-EXECUTION-PLAN.md` - Test execution plan
- `VERIFICATION-CHECKLIST.md` - Verification checklist

### Feature-Specific
- `ADVANCED-RAG-COMPLETE.md` - Advanced RAG features
- `PPO-EVALUATION-COMPLETE.md` - PPO evaluation framework

---

## 🎯 Common Workflows

### 1. Get Trading Signal
```python
# Use multi-agent bots
from src.graph.trading_graph import analyze_symbol

result = await analyze_symbol(
    symbol="BTC-USD",
    market_data={"close": 50000.0, ...},
    regime="bull",
    include_bots=True
)

signal = result["consensus_signal"]["signal"]
confidence = result["consensus_signal"]["confidence"]
```

### 2. Train and Evaluate PPO Model
```python
# Train
from src.ppo.training_loop import run_ppo_training
from src.ppo.trading_env import TradingEnv

env_train = TradingEnv(ticker="AAPL", start_date="2020-01-01", end_date="2024-01-01")
env_test = TradingEnv(ticker="AAPL", start_date="2024-01-01", end_date="2025-01-01")

result = run_ppo_training(env_train, env_test, max_episodes=1000)

# Evaluate
from src.ppo.evaluation import PPOEvaluator

evaluator = PPOEvaluator(result["policy"], env_test)
metrics = evaluator.evaluate_performance(n_episodes=10)
```

### 3. Query RAG System
```python
# Query with advanced features
from src.rag.query_service import RAGQueryService
from src.rag.config import RAGConfig
from src.rag.vector_store import VectorStoreManager

config = RAGConfig(use_hyde=True, use_raptor=True, use_self_rag=True)
vector_store = VectorStoreManager(config)
query_service = RAGQueryService(config, vector_store)

result = query_service.query("How to optimize trading strategies?")
print(result["answer"])
```

---

## 🐛 Troubleshooting

### Common Issues

#### Bot Signals Not Working
- Check market data format
- Verify symbol is correct
- Check bot logs for errors

#### PPO Training Fails
- Verify data is available
- Check feature extractor is working
- Ensure sufficient historical data

#### RAG Queries Fail
- Check documents are ingested
- Verify vector store is initialized
- Check LLM configuration (Gemini/Ollama)

---

## 📞 Support

For issues or questions:
1. Check documentation in `repo/main/docs/`
2. Review test files for usage examples
3. Check service logs
4. Review implementation guides

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for Use

