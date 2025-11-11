# FKS Platform - API Reference

**Date**: 2025-01-XX  
**Version**: 1.0.0  
**Base URL**: `http://localhost:8001` (fks_ai), `http://localhost:8004` (fks_analyze)

---

## 🔌 Multi-Agent Trading Bots API

**Base URL**: `http://localhost:8001`  
**Service**: `fks_ai`

### Get StockBot Signal

Get trading signal from StockBot for a stock symbol.

**Endpoint**: `POST /ai/bots/stock/signal`

**Request Body**:
```json
{
  "symbol": "AAPL",
  "market_data": {
    "close": 150.0,
    "open": 149.0,
    "high": 151.0,
    "low": 148.0,
    "volume": 1000000,
    "data": [
      {
        "open": 149.0,
        "high": 151.0,
        "low": 148.0,
        "close": 150.0,
        "volume": 1000000
      }
    ]
  }
}
```

**Response**:
```json
{
  "symbol": "AAPL",
  "bot": "StockBot",
  "signal": "BUY",
  "confidence": 0.75,
  "strategy": "Trend Following",
  "entry_price": 150.0,
  "stop_loss": 145.0,
  "take_profit": 160.0,
  "reason": "Moving average crossover detected",
  "indicators": {
    "sma_20": 148.5,
    "sma_50": 145.0,
    "macd": 2.5
  },
  "timestamp": "2025-01-XXT00:00:00Z"
}
```

### Get ForexBot Signal

Get trading signal from ForexBot for a forex pair.

**Endpoint**: `POST /ai/bots/forex/signal`

**Request Body**:
```json
{
  "symbol": "EURUSD",
  "market_data": {
    "close": 1.1000,
    "open": 1.0990,
    "high": 1.1010,
    "low": 1.0980,
    "volume": 500000,
    "data": [
      {
        "open": 1.0990,
        "high": 1.1010,
        "low": 1.0980,
        "close": 1.1000,
        "volume": 500000
      }
    ]
  }
}
```

**Response**:
```json
{
  "symbol": "EURUSD",
  "bot": "ForexBot",
  "signal": "SELL",
  "confidence": 0.65,
  "strategy": "Mean Reversion",
  "entry_price": 1.1000,
  "stop_loss": 1.1050,
  "take_profit": 1.0950,
  "reason": "RSI overbought, mean reversion expected",
  "indicators": {
    "rsi": 72.5,
    "bb_upper": 1.1020,
    "bb_lower": 1.0980
  },
  "timestamp": "2025-01-XXT00:00:00Z"
}
```

### Get CryptoBot Signal

Get trading signal from CryptoBot for a cryptocurrency pair.

**Endpoint**: `POST /ai/bots/crypto/signal`

**Request Body**:
```json
{
  "symbol": "BTC-USD",
  "market_data": {
    "close": 50000.0,
    "open": 49000.0,
    "high": 51000.0,
    "low": 48000.0,
    "volume": 100000000,
    "data": [
      {
        "open": 49000.0,
        "high": 51000.0,
        "low": 48000.0,
        "close": 50000.0,
        "volume": 100000000
      }
    ]
  }
}
```

**Response**:
```json
{
  "symbol": "BTC-USD",
  "bot": "CryptoBot",
  "signal": "BUY",
  "confidence": 0.85,
  "strategy": "Breakout",
  "entry_price": 50000.0,
  "stop_loss": 48000.0,
  "take_profit": 55000.0,
  "reason": "Donchian channel breakout detected",
  "indicators": {
    "donchian_upper": 51000.0,
    "donchian_lower": 48000.0,
    "atr": 2000.0
  },
  "btc_priority": true,
  "timestamp": "2025-01-XXT00:00:00Z"
}
```

### Get Multi-Bot Consensus

Get consensus signal from multiple bots with BTC priority rules.

**Endpoint**: `POST /ai/bots/consensus`

**Request Body**:
```json
{
  "symbol": "BTC-USD",
  "market_data": {
    "close": 50000.0,
    "open": 49000.0,
    "high": 51000.0,
    "low": 48000.0,
    "volume": 100000000,
    "data": [
      {
        "open": 49000.0,
        "high": 51000.0,
        "low": 48000.0,
        "close": 50000.0,
        "volume": 100000000
      }
    ]
  },
  "include_stock": true,
  "include_forex": true,
  "include_crypto": true
}
```

**Response**:
```json
{
  "symbol": "BTC-USD",
  "consensus_signal": {
    "signal": "BUY",
    "confidence": 0.78,
    "reason": "Weighted consensus with BTC priority"
  },
  "bot_signals": {
    "stock": [
      {
        "signal": "BUY",
        "confidence": 0.7,
        "bot": "StockBot"
      }
    ],
    "forex": [
      {
        "signal": "HOLD",
        "confidence": 0.5,
        "bot": "ForexBot"
      }
    ],
    "crypto": [
      {
        "signal": "BUY",
        "confidence": 0.85,
        "bot": "CryptoBot",
        "btc_priority": true
      }
    ]
  },
  "timestamp": "2025-01-XXT00:00:00Z"
}
```

### Health Check

Check health status of bot endpoints.

**Endpoint**: `GET /ai/bots/health`

**Response**:
```json
{
  "status": "healthy",
  "message": "Trading bot endpoints are operational."
}
```

---

## 📚 RAG System API

**Base URL**: `http://localhost:8004`  
**Service**: `fks_analyze`

### RAG Analysis

Perform full RAG analysis (async job).

**Endpoint**: `POST /api/v1/rag/analyze`

**Request Body**:
```json
{
  "query": "How does portfolio optimization work?",
  "analysis_type": "code_review"
}
```

**Response**:
```json
{
  "status": "queued",
  "job_id": "job_12345",
  "message": "Analysis job queued successfully"
}
```

### RAG Query

Direct RAG query (synchronous).

**Endpoint**: `POST /api/v1/rag/query`

**Request Body**:
```json
{
  "query": "How does portfolio optimization work?",
  "filter": {
    "service": "fks_portfolio"
  }
}
```

**Response**:
```json
{
  "query": "How does portfolio optimization work?",
  "answer": "Portfolio optimization in FKS uses mean-variance optimization...",
  "sources": [
    {
      "source": "repo/portfolio/src/optimization/mean_variance.py",
      "score": 0.92,
      "content": "Mean-variance optimization implementation..."
    }
  ],
  "retrieved_count": 3
}
```

### Ingest Documents

Ingest documents into the vector store.

**Endpoint**: `POST /api/v1/rag/ingest`

**Request Body**:
```json
{
  "root_dir": "/path/to/fks",
  "include_code": true,
  "clear_existing": false
}
```

**Response**:
```json
{
  "status": "success",
  "documents_loaded": 150,
  "documents_added": 150,
  "include_code": true
}
```

### Suggest Optimizations

Get optimization suggestions from RAG.

**Endpoint**: `POST /api/v1/rag/suggest-optimizations`

**Request Body**:
```json
{
  "query": "How to optimize trading strategy?",
  "context": "Current strategy uses RSI indicator"
}
```

**Response**:
```json
{
  "query": "How to optimize trading strategy?",
  "suggestions": "Consider combining RSI with MACD for better signals...",
  "sources": [
    {
      "source": "docs/strategy_optimization.md",
      "score": 0.88
    }
  ]
}
```

### Evaluate RAG Quality

Evaluate RAG response quality using RAGAS.

**Endpoint**: `POST /api/v1/rag/evaluate`

**Request Body**:
```json
{
  "query": "How does portfolio optimization work?",
  "answer": "Portfolio optimization uses mean-variance optimization...",
  "contexts": [
    "Context 1: Mean-variance optimization...",
    "Context 2: Risk management..."
  ]
}
```

**Response**:
```json
{
  "query": "How does portfolio optimization work?",
  "metrics": {
    "faithfulness": 0.92,
    "answer_relevancy": 0.88,
    "context_precision": 0.85,
    "context_recall": 0.90
  },
  "overall_score": 0.89,
  "threshold_met": true
}
```

### Get Job Status

Get status of an async analysis job.

**Endpoint**: `GET /api/v1/rag/jobs/{job_id}`

**Response**:
```json
{
  "job_id": "job_12345",
  "status": "completed",
  "progress": 1.0,
  "created_at": "2025-01-XXT00:00:00Z",
  "updated_at": "2025-01-XXT00:00:00Z"
}
```

### Get Job Results

Get results of a completed async analysis job.

**Endpoint**: `GET /api/v1/rag/jobs/{job_id}/results`

**Response**:
```json
{
  "job_id": "job_12345",
  "results": {
    "ai_insights": "Analysis insights...",
    "recommendations": ["Recommendation 1", "Recommendation 2"]
  }
}
```

### Get RAG Statistics

Get statistics about the RAG system.

**Endpoint**: `GET /api/v1/rag/stats`

**Response**:
```json
{
  "status": "healthy",
  "document_count": 150,
  "vector_store_type": "chroma",
  "embedding_provider": "hybrid",
  "use_hyde": true,
  "use_raptor": true,
  "use_self_rag": true
}
```

### RAG Health Check

Check health status of RAG system.

**Endpoint**: `GET /api/v1/rag/health`

**Response**:
```json
{
  "status": "healthy",
  "rag_available": true,
  "vector_store_status": "initialized",
  "llm_status": "available"
}
```

---

## 🔐 Authentication

Currently, authentication is not required for development. For production:

- Use JWT tokens
- Include in `Authorization` header: `Bearer <token>`
- Rate limiting may apply

---

## ⚠️ Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid request format"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## 📝 Notes

- All timestamps are in ISO 8601 format (UTC)
- All prices are in base currency units
- Confidence scores range from 0.0 to 1.0
- Signal values: "BUY", "SELL", "HOLD"

---

**Last Updated**: 2025-01-XX  
**Version**: 1.0.0

