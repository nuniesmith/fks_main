# FKS Platform - Development Guide

**Date**: 2025-01-XX  
**Purpose**: Guide for developers working on FKS Platform  
**Status**: Active

---

## 🛠️ Development Setup

### Prerequisites

```bash
# Python 3.9+
python --version

# Git
git --version

# Docker (optional, for local testing)
docker --version
```

### Initial Setup

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

---

## 📁 Project Structure

```
fks/
├── repo/
│   ├── ai/                    # Multi-agent trading bots
│   │   ├── src/
│   │   │   ├── agents/        # StockBot, ForexBot, CryptoBot
│   │   │   ├── graph/         # LangGraph workflow
│   │   │   └── api/           # FastAPI endpoints
│   │   └── tests/             # Test suites
│   │
│   ├── training/              # PPO meta-learning
│   │   ├── src/
│   │   │   └── ppo/           # PPO implementation
│   │   └── tests/             # Test suites
│   │
│   ├── analyze/               # RAG system
│   │   ├── src/
│   │   │   └── rag/           # RAG implementation
│   │   └── tests/             # Test suites
│   │
│   └── main/                  # Main service
│       ├── docs/              # Documentation
│       └── scripts/           # Utility scripts
│
└── todo/                      # Planning documents
```

---

## 🔨 Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

```bash
# Edit files
vim repo/ai/src/agents/your_bot.py

# Run tests
cd repo/ai
pytest tests/ -v

# Check linting
ruff check src/
```

### 3. Commit Changes

```bash
git add .
git commit -m "feat: add new feature description"
```

### 4. Run Tests

```bash
# Run all tests
./repo/main/scripts/run_all_tests.sh all

# Run specific service tests
cd repo/ai && pytest tests/ -v --cov=src
```

### 5. Create Pull Request

```bash
git push origin feature/your-feature-name
# Create PR on GitHub/GitLab
```

---

## 🧪 Testing

### Running Tests

```bash
# All tests
./repo/main/scripts/run_all_tests.sh all

# Specific service
./repo/main/scripts/run_all_tests.sh ai
./repo/main/scripts/run_all_tests.sh training
./repo/main/scripts/run_all_tests.sh analyze

# With coverage
./repo/main/scripts/run_all_tests.sh all true
```

### Writing Tests

```python
# Example test structure
import pytest
from unittest.mock import Mock, patch

class TestYourFeature:
    """Test suite for your feature"""
    
    @pytest.fixture
    def mock_dependency(self):
        """Mock dependency"""
        return Mock()
    
    def test_feature_basic(self, mock_dependency):
        """Test basic functionality"""
        # Arrange
        feature = YourFeature(mock_dependency)
        
        # Act
        result = feature.do_something()
        
        # Assert
        assert result is not None
        mock_dependency.method.assert_called_once()
```

### Test Markers

```python
@pytest.mark.unit          # Unit tests
@pytest.mark.integration   # Integration tests
@pytest.mark.slow          # Slow tests
@pytest.mark.benchmark     # Performance tests
```

---

## 📝 Code Style

### Python Style Guide

Follow PEP 8 with these additions:

```python
# Type hints
def process_data(data: Dict[str, Any]) -> List[float]:
    """Process data and return results"""
    pass

# Docstrings
def calculate_metric(values: List[float]) -> float:
    """
    Calculate metric from values.
    
    Args:
        values: List of numeric values
    
    Returns:
        Calculated metric value
    
    Raises:
        ValueError: If values is empty
    """
    if not values:
        raise ValueError("Values cannot be empty")
    return sum(values) / len(values)
```

### Linting

```bash
# Run ruff
ruff check src/

# Auto-fix
ruff check --fix src/

# Run mypy (if configured)
mypy src/
```

---

## 🏗️ Architecture Patterns

### Service Structure

```python
# Service layer pattern
class YourService:
    """Service for handling business logic"""
    
    def __init__(self, dependency: Dependency):
        self.dependency = dependency
    
    async def process(self, data: Dict) -> Dict:
        """Process data"""
        # Business logic
        result = await self.dependency.fetch(data)
        return self._transform(result)
    
    def _transform(self, data: Any) -> Dict:
        """Private helper method"""
        return {"result": data}
```

### API Endpoints

```python
# FastAPI endpoint pattern
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/your-feature", tags=["your-feature"])

class RequestModel(BaseModel):
    """Request model"""
    field: str

class ResponseModel(BaseModel):
    """Response model"""
    result: str

@router.post("/endpoint", response_model=ResponseModel)
async def your_endpoint(request: RequestModel):
    """Endpoint description"""
    try:
        result = await process_request(request)
        return ResponseModel(result=result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 🔌 Integration Points

### Adding New Bot

```python
# 1. Create bot class
from src.agents.base_bot import BaseTradingBot

class YourBot(BaseTradingBot):
    """Your custom bot"""
    
    def get_strategy_name(self) -> str:
        return "Your Strategy"
    
    async def analyze(self, symbol: str, market_data: Dict) -> Dict:
        # Your analysis logic
        return {
            "signal": "BUY",
            "confidence": 0.8,
            "reason": "Your reason"
        }

# 2. Add to graph
from src.graph.bot_nodes import run_bots_parallel

# 3. Add API endpoint
from src.api.routes.bots import router

@router.post("/your-bot/signal")
async def get_your_bot_signal(request: BotSignalRequest):
    bot = YourBot()
    signal = await bot.analyze(request.symbol, request.market_data)
    return BotSignalResponse(...)
```

### Adding RAG Feature

```python
# 1. Create retriever/feature
from src.rag.advanced.hyde import HyDERetriever

class YourRetriever:
    """Your custom retriever"""
    
    def retrieve(self, query: str, k: int = 5) -> List[Dict]:
        # Your retrieval logic
        return results

# 2. Integrate into query service
from src.rag.query_service import RAGQueryService

# Add to query pipeline
```

### Adding PPO Component

```python
# 1. Create component
from src.ppo.feature_extractor import FKSFeatureExtractor

class YourFeatureExtractor:
    """Your custom feature extractor"""
    
    def extract_features(self, data: pd.DataFrame) -> np.ndarray:
        # Your feature extraction
        return features

# 2. Integrate into training
from src.ppo.training_loop import run_ppo_training
```

---

## 🐛 Debugging

### Enable Debug Logging

```python
import logging
from loguru import logger

# Set log level
logger.add("debug.log", level="DEBUG")

# Use in code
logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
```

### Use Debugger

```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or use ipdb
import ipdb; ipdb.set_trace()

# Or use IDE debugger
# Set breakpoint in IDE and run in debug mode
```

### Test Components

```python
# Test individual components
from src.agents.stockbot import StockBot

bot = StockBot()
# Test with sample data
result = await bot.analyze("AAPL", sample_market_data)
print(result)
```

---

## 📚 Documentation

### Writing Documentation

```markdown
# Feature Name

**Date**: YYYY-MM-DD  
**Status**: Active/Complete  
**Purpose**: Brief description

## Overview

Detailed description of the feature.

## Usage

```python
# Code examples
```

## API Reference

### Endpoints

- `POST /api/endpoint` - Description

## Examples

Real-world examples.
```

### Updating Documentation

1. Update relevant documentation files
2. Update `README.md` if needed
3. Update implementation guides if architecture changes
4. Update quick start guide if usage changes

---

## 🔄 Version Control

### Commit Messages

Follow conventional commits:

```
feat: add new feature
fix: fix bug
docs: update documentation
test: add tests
refactor: refactor code
perf: performance improvement
chore: maintenance tasks
```

### Branch Naming

```
feature/feature-name
bugfix/bug-description
hotfix/critical-fix
docs/documentation-update
```

---

## 🚀 Deployment

### Local Testing

```bash
# Start services locally
cd repo/ai && uvicorn src.main:app --reload
cd repo/analyze && uvicorn src.main:app --reload
```

### Docker Testing

```bash
# Build and run
docker-compose up -d --build

# View logs
docker-compose logs -f
```

### Pre-Deployment Checklist

- [ ] All tests pass
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Linting passes
- [ ] Type checking passes
- [ ] Security review (if applicable)

---

## 🔍 Code Review

### Review Checklist

- [ ] Code follows style guide
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No hardcoded secrets
- [ ] Error handling is appropriate
- [ ] Performance considerations addressed
- [ ] Security considerations addressed

### Review Process

1. Create PR
2. Request review from team
3. Address review comments
4. Get approval
5. Merge to main

---

## 📊 Performance

### Profiling

```python
# Use cProfile
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()

# Your code
your_function()

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats()
```

### Optimization Tips

1. Use async/await for I/O operations
2. Cache expensive computations
3. Use generators for large datasets
4. Profile before optimizing
5. Measure improvements

---

## 🔒 Security

### Best Practices

1. **Never commit secrets**:
   ```bash
   # Use .env files
   # Add to .gitignore
   ```

2. **Validate input**:
   ```python
   from pydantic import BaseModel, validator
   
   class Request(BaseModel):
       value: int
       
       @validator('value')
       def validate_value(cls, v):
           if v < 0:
               raise ValueError('Value must be positive')
           return v
   ```

3. **Use authentication**:
   ```python
   from fastapi import Depends, HTTPException
   from fastapi.security import HTTPBearer
   
   security = HTTPBearer()
   
   async def verify_token(token: str = Depends(security)):
       # Verify token
       if not is_valid(token):
           raise HTTPException(status_code=401)
   ```

---

## 📞 Getting Help

1. **Check Documentation**:
   - `QUICK-START-GUIDE.md`
   - `PROJECT-OVERVIEW.md`
   - Implementation guides

2. **Review Code**:
   - Check existing implementations
   - Review test files
   - Check examples

3. **Ask Questions**:
   - Review team discussions
   - Check issue tracker
   - Contact team lead

---

## 🎯 Development Goals

### Code Quality
- Maintain 80%+ test coverage
- Follow style guide
- Write clear documentation
- Handle errors gracefully

### Performance
- Optimize critical paths
- Use async where appropriate
- Cache expensive operations
- Monitor performance

### Security
- Validate all inputs
- Use authentication
- Never commit secrets
- Follow security best practices

---

**Last Updated**: 2025-01-XX  
**Status**: Active Development Guide

