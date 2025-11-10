# FKS Platform - First Steps Guide

**Date**: 2025-01-XX  
**Purpose**: Step-by-step guide for new users to get started  
**Audience**: New developers, users, and contributors

---

## 🎯 Welcome to FKS Platform!

This guide will help you get started with the FKS Platform in just a few steps.

---

## 📋 Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Python 3.9+ installed
- [ ] Git installed
- [ ] Docker installed (optional, for containerized deployment)
- [ ] Text editor or IDE (VS Code, PyCharm, etc.)
- [ ] Terminal/command line access

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd fks

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
cd repo/ai && pip install -r requirements.txt
cd ../training && pip install -r requirements.txt
cd ../analyze && pip install -r requirements.txt
```

### Step 2: Configure Environment

```bash
# Set environment variables
export GOOGLE_AI_API_KEY="your_gemini_key"  # Optional, for RAG
export OLLAMA_HOST="http://localhost:11434"  # Optional, for local LLM
export MLFLOW_TRACKING_URI="http://localhost:5000"  # Optional, for PPO training
```

### Step 3: Start Services

```bash
# Start fks_ai (Multi-Agent Bots)
cd repo/ai
uvicorn src.main:app --host 0.0.0.0 --port 8001 --reload

# In another terminal: Start fks_analyze (RAG System)
cd repo/analyze
uvicorn src.main:app --host 0.0.0.0 --port 8004 --reload
```

### Step 4: Test Your Setup

```bash
# Test bot endpoint
curl -X POST http://localhost:8001/ai/bots/stock/signal \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "market_data": {
      "close": 150.0,
      "data": [{"open": 149, "high": 151, "low": 148, "close": 150, "volume": 1000000}]
    }
  }'

# Test RAG endpoint
curl -X POST http://localhost:8004/api/v1/rag/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is FKS?"}'
```

**✅ Success!** If you get responses, your setup is working!

---

## 📚 Next Steps

### For Developers

1. **Read Development Guide**: `DEVELOPMENT-GUIDE.md`
2. **Review Implementation Guides**: `todo/` directory
3. **Check Examples**: `examples/example_usage.py`
4. **Run Tests**: `./repo/main/scripts/run_all_tests.sh all`

### For Users

1. **Read Quick Start Guide**: `QUICK-START-GUIDE.md`
2. **Review API Reference**: `API-REFERENCE.md`
3. **Check Examples**: `examples/example_usage.py`
4. **Read Project Overview**: `PROJECT-OVERVIEW.md`

### For DevOps

1. **Read Deployment Guide**: `DEPLOYMENT-GUIDE.md`
2. **Review Troubleshooting Guide**: `TROUBLESHOOTING-GUIDE.md`
3. **Check Readiness Checklist**: `READINESS-CHECKLIST.md`

---

## 🎓 Learning Path

### Beginner (Day 1)
1. Read `QUICK-START-GUIDE.md`
2. Run example scripts
3. Test API endpoints
4. Review `PROJECT-OVERVIEW.md`

### Intermediate (Week 1)
1. Read implementation guides
2. Understand architecture
3. Run tests
4. Modify examples

### Advanced (Week 2+)
1. Contribute code
2. Add features
3. Deploy services
4. Optimize performance

---

## 🔧 Common First Tasks

### 1. Get a Trading Signal

```python
import asyncio
import httpx

async def get_signal():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8001/ai/bots/consensus",
            json={
                "symbol": "BTC-USD",
                "market_data": {
                    "close": 50000.0,
                    "data": [{"open": 49000, "high": 51000, "low": 48000, "close": 50000, "volume": 100000000}]
                }
            }
        )
        return response.json()

result = asyncio.run(get_signal())
print(f"Signal: {result['consensus_signal']['signal']}")
```

### 2. Query RAG System

```python
async def query_rag():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8004/api/v1/rag/query",
            json={"query": "How does portfolio optimization work?"}
        )
        return response.json()

result = asyncio.run(query_rag())
print(result["answer"])
```

### 3. Train PPO Model

```bash
cd repo/training
python -m src.ppo.train_trading_ppo \
    --ticker AAPL \
    --start-date 2020-01-01 \
    --end-date 2025-01-01 \
    --max-episodes 100
```

---

## 📖 Essential Documentation

### Must Read
1. **[QUICK-START-GUIDE.md](QUICK-START-GUIDE.md)** - Get started quickly
2. **[PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)** - Understand the platform
3. **[API-REFERENCE.md](API-REFERENCE.md)** - API documentation

### Reference
1. **[DEVELOPMENT-GUIDE.md](DEVELOPMENT-GUIDE.md)** - Development practices
2. **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Deployment instructions
3. **[TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)** - Common issues

---

## 🐛 Troubleshooting

### Service Won't Start
- Check if port is available: `lsof -i :8001`
- Verify dependencies: `pip list | grep fastapi`
- Check logs for errors

### Import Errors
- Verify PYTHONPATH is set
- Reinstall dependencies: `pip install -r requirements.txt --force-reinstall`
- Check virtual environment is activated

### API Errors
- Verify service is running: `curl http://localhost:8001/health`
- Check request format matches API reference
- Review error messages in logs

**For more help**: See `TROUBLESHOOTING-GUIDE.md`

---

## 🎯 Success Criteria

You're ready to proceed when:

- [ ] Services start without errors
- [ ] API endpoints respond correctly
- [ ] Example scripts run successfully
- [ ] Tests can be executed
- [ ] Documentation is accessible

---

## 📞 Getting Help

1. **Check Documentation**: Start with `QUICK-START-GUIDE.md`
2. **Review Examples**: See `examples/example_usage.py`
3. **Check Troubleshooting**: See `TROUBLESHOOTING-GUIDE.md`
4. **Review Code**: Check test files for usage examples

---

## 🎉 You're Ready!

Once you've completed these steps, you're ready to:
- Use the FKS Platform
- Develop new features
- Deploy services
- Contribute to the project

**Welcome to FKS Platform!**

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for New Users

