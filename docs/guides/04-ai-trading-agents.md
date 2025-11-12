# AI-Driven Trading Agents with LLM Integration

**Status**: Research & Planning Phase  
**Priority**: High Value Feature (Production-Ready Framework)  
**Timeline**: 4-6 weeks for full implementation  
**Last Updated**: November 7, 2025

## 🎯 Overview

Transformation of FKS from rule-based trading bot to adaptive AI agent system using Large Language Models (LLMs) for contextual intelligence. Research shows 20-40% return improvements in volatile crypto markets with multi-agent architectures.

### Key Benefits

- **Return Improvement**: +20-40% in volatile markets (FinGPT benchmarks)
- **Sharpe Ratio**: +0.5-1.0 improvement with multi-agent debate
- **False Signals**: 30-40% reduction via agent consensus
- **Adaptivity**: 60% outperformance vs non-adaptive models
- **Cost Efficiency**: Fine-tuning ~$300 vs $3M for full training

## 📚 Research Foundation

### LLM Trading Performance

**Key Findings**:
- FinGPT achieves F1 score 0.88 on financial sentiment analysis
- CryptoTrade reflective agent: 2.38% ETH returns in bull markets
- Alpha Arena competition: DeepSeek agent +39.9% returns with "patient sniper" tactics
- TradingGPT multi-agent: 15-25% higher returns vs baselines with <8% drawdowns

### Implementation Models

| Model | Use Case | Cost | Performance |
|-------|----------|------|-------------|
| **FinBERT** | Sentiment analysis | Free (local) | F1 score 0.88 |
| **GPT-4** | Critical trading decisions | $5/1M tokens | Highest accuracy |
| **GPT-3.5** | Routine analysis | $0.50/1M tokens | Cost-effective |
| **Gemini 1.5** | Free tier offloading | $0.30/1M paid | 1,500 req/day free |
| **Llama 3** | Local inference | Hardware only | Privacy-focused |

## 🏗️ Architecture: 4-Phase Implementation

### Phase 6.1: Sentiment Analysis Integration (Week 1)

Transform market sentiment from news/social media into actionable trading signals.

#### Task 6.1.1: LLM Infrastructure Setup (Days 1-2)

**Installation**:
```bash
# Add to fks_ai/requirements.txt
transformers>=4.36.0
openai>=1.0.0
google-generativeai>=0.3.0
torch>=2.1.0
sentencepiece>=0.1.99
```

**API Configuration**:
```python
# fks_ai/src/sentiment/config.py
import os
from dataclasses import dataclass

@dataclass
class LLMConfig:
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    
    # Model selection
    sentiment_model: str = "ProsusAI/finbert"  # Local FinBERT
    reasoning_model: str = "gpt-4-turbo"       # Critical decisions
    fallback_model: str = "gemini-1.5-flash"   # Free tier
    
    # Rate limiting
    max_requests_per_minute: int = 60
    cache_ttl_seconds: int = 300  # 5 min
```

**GitHub Action** (add model download to CI/CD):
```yaml
# fks_ai/.github/workflows/model-download.yml
name: Download ML Models
on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  download-models:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      
      - name: Download FinBERT
        run: |
          pip install transformers torch
          python -c "from transformers import pipeline; pipeline('sentiment-analysis', model='ProsusAI/finbert')"
      
      - name: Cache models
        uses: actions/cache@v4
        with:
          path: ~/.cache/huggingface
          key: finbert-${{ runner.os }}
```

#### Task 6.1.2: News/Social Sentiment Engine (Days 3-4)

**Sentiment Analyzer Implementation**:
```python
# fks_ai/src/sentiment/analyzer.py
from transformers import pipeline
import requests
import redis
from typing import Dict, List
import json

class SentimentAnalyzer:
    def __init__(self, cache_host='redis', cache_port=6379):
        self.classifier = pipeline("sentiment-analysis", model="ProsusAI/finbert")
        self.cache = redis.Redis(host=cache_host, port=cache_port, decode_responses=True)
        self.news_sources = {
            'cryptopanic': 'https://cryptopanic.com/api/v1/posts/',
            'newsapi': 'https://newsapi.org/v2/everything'
        }
    
    def get_sentiment_from_news(self, symbol: str, limit: int = 5) -> Dict:
        """
        Analyze sentiment from recent news headlines.
        Returns score from -1 (bearish) to 1 (bullish).
        """
        # Check cache
        cached = self.cache.get(f"sentiment:{symbol}")
        if cached:
            return json.loads(cached)
        
        # Fetch news
        headlines = self._fetch_headlines(symbol, limit)
        if not headlines:
            return {'score': 0.0, 'confidence': 0.0, 'source': 'no_data'}
        
        # Analyze sentiment
        sentiments = []
        for headline in headlines:
            result = self.classifier(headline)[0]
            score = 1 if result['label'] == 'positive' else -1 if result['label'] == 'negative' else 0
            sentiments.append({
                'headline': headline,
                'score': score,
                'confidence': result['score']
            })
        
        # Aggregate
        avg_score = sum(s['score'] for s in sentiments) / len(sentiments)
        avg_confidence = sum(s['confidence'] for s in sentiments) / len(sentiments)
        
        result = {
            'score': avg_score,
            'confidence': avg_confidence,
            'count': len(sentiments),
            'source': 'finbert',
            'details': sentiments
        }
        
        # Cache for 5 minutes
        self.cache.setex(f"sentiment:{symbol}", 300, json.dumps(result))
        
        return result
    
    def _fetch_headlines(self, symbol: str, limit: int) -> List[str]:
        """Fetch recent headlines from multiple sources."""
        headlines = []
        
        try:
            # CryptoPanic API
            url = f"{self.news_sources['cryptopanic']}?currencies={symbol}&kind=news"
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                data = response.json()
                headlines.extend([post['title'] for post in data['results'][:limit]])
        except Exception as e:
            print(f"Error fetching from CryptoPanic: {e}")
        
        return headlines[:limit]
```

**Testing**:
```python
# fks_ai/tests/test_sentiment.py
import pytest
from src.sentiment.analyzer import SentimentAnalyzer

def test_sentiment_positive():
    analyzer = SentimentAnalyzer()
    result = analyzer.classifier("Bitcoin surges to new all-time high")[0]
    assert result['label'] == 'positive'
    assert result['score'] > 0.7

def test_sentiment_negative():
    analyzer = SentimentAnalyzer()
    result = analyzer.classifier("Market crashes amid regulatory fears")[0]
    assert result['label'] == 'negative'
    assert result['score'] > 0.7

def test_sentiment_caching():
    analyzer = SentimentAnalyzer()
    # First call
    result1 = analyzer.get_sentiment_from_news("BTC")
    # Second call (should hit cache)
    result2 = analyzer.get_sentiment_from_news("BTC")
    assert result1 == result2
```

**Validation Gate**: Test on historical news, achieve F1 score >0.85

#### Task 6.1.3: ASMBTR Integration (Day 5)

**Hybrid Strategy**:
```python
# fks_app/src/strategies/asmbtr_with_sentiment.py
from fks_ai.src.sentiment.analyzer import SentimentAnalyzer

class ASMBTRWithSentiment:
    def __init__(self, asmbtr_model, sentiment_weight=0.3):
        self.asmbtr = asmbtr_model
        self.sentiment = SentimentAnalyzer()
        self.sentiment_weight = sentiment_weight  # 0.2-0.3 recommended
    
    def generate_signal(self, symbol: str, market_data: dict) -> dict:
        """
        Generate trading signal combining ASMBTR technical + sentiment.
        Returns signal from -1 (sell) to 1 (buy).
        """
        # Technical signal from ASMBTR
        technical_signal = self.asmbtr.predict(market_data)  # -1 to 1
        
        # Sentiment signal
        sentiment_result = self.sentiment.get_sentiment_from_news(symbol)
        sentiment_signal = sentiment_result['score']  # -1 to 1
        sentiment_conf = sentiment_result['confidence']
        
        # Weighted combination
        final_signal = (
            (1 - self.sentiment_weight) * technical_signal +
            self.sentiment_weight * sentiment_signal * sentiment_conf
        )
        
        return {
            'signal': final_signal,
            'technical': technical_signal,
            'sentiment': sentiment_signal,
            'sentiment_confidence': sentiment_conf,
            'action': 'BUY' if final_signal > 0.3 else 'SELL' if final_signal < -0.3 else 'HOLD'
        }
```

**Backtesting**:
```python
# fks_app/tests/test_asmbtr_sentiment.py
import pytest
from src.strategies.asmbtr_with_sentiment import ASMBTRWithSentiment

def test_hybrid_strategy_backtest():
    """Test on 2024 BTC/ETH data, target +15-20% improvement."""
    strategy = ASMBTRWithSentiment(asmbtr_model, sentiment_weight=0.25)
    
    # Load historical data
    data = load_2024_crypto_data(['BTC', 'ETH'])
    
    # Run backtest
    results = backtest(strategy, data)
    
    # Assertions
    assert results['total_return'] > 0.15  # +15% minimum
    assert results['sharpe_ratio'] > 1.0
    assert results['max_drawdown'] < 0.20  # <20%
```

**Target**: +15-20% return improvement in backtests

---

### Phase 6.2: Multi-Agent Collaborative System (Week 2)

Implement 4-agent system with debate mechanism for consensus-based trading decisions.

#### Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Strategy Reasoner                         │
│                    (Coordinator)                             │
│                                                              │
│  Aggregates votes, enforces thresholds, makes final decision │
└────────┬─────────────────────────────────────────┬──────────┘
         │                                         │
    ┌────▼────────┐  ┌──────────────┐  ┌─────────▼──────┐
    │  Technical  │  │  Sentiment   │  │  Risk Manager  │
    │   Analyst   │  │   Analyst    │  │                │
    │             │  │              │  │  Portfolio     │
    │ ASMBTR +    │  │ FinBERT +    │  │  Exposure      │
    │ Indicators  │  │ News API     │  │  Metrics       │
    └─────────────┘  └──────────────┘  └────────────────┘
```

#### Task 6.2.1: Agent Base Class (Days 1-2)

```python
# fks_ai/src/agents/base.py
from abc import ABC, abstractmethod
from typing import Dict, Tuple
from dataclasses import dataclass

@dataclass
class AgentVote:
    agent_name: str
    vote: str  # 'BUY', 'SELL', 'HOLD'
    confidence: float  # 0.0-1.0
    reason: str
    metadata: Dict = None

class TradingAgent(ABC):
    def __init__(self, name: str):
        self.name = name
    
    @abstractmethod
    def vote(self, market_state: Dict) -> AgentVote:
        """
        Analyze market state and return vote with confidence.
        
        Args:
            market_state: Dict containing price, volume, indicators, news, etc.
        
        Returns:
            AgentVote with action, confidence, and reasoning
        """
        pass
```

#### Task 6.2.2: Technical Analyst Agent (Day 3)

```python
# fks_ai/src/agents/technical_analyst.py
from .base import TradingAgent, AgentVote
import openai

class TechnicalAnalystAgent(TradingAgent):
    def __init__(self, asmbtr_model):
        super().__init__("TechnicalAnalyst")
        self.asmbtr = asmbtr_model
        openai.api_key = os.getenv("OPENAI_API_KEY")
    
    def vote(self, market_state: Dict) -> AgentVote:
        # Get ASMBTR technical signal
        technical_signal = self.asmbtr.predict(market_state)
        
        # Generate LLM reasoning
        prompt = f"""
        You are a Technical Analyst. Review this market data:
        
        Symbol: {market_state['symbol']}
        Price: ${market_state['price']}
        RSI: {market_state['rsi']}
        MACD: {market_state['macd']}
        Volume: {market_state['volume']}
        Technical Signal: {technical_signal} (-1=sell, 1=buy)
        
        Based on technical indicators, provide:
        1. Vote: BUY, SELL, or HOLD
        2. Confidence: 0.0-1.0
        3. Reason: Brief explanation
        
        Format: {{"vote": "BUY", "confidence": 0.85, "reason": "..."}}
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3  # Low temperature for consistency
        )
        
        result = json.loads(response.choices[0].message.content)
        
        return AgentVote(
            agent_name=self.name,
            vote=result['vote'],
            confidence=result['confidence'],
            reason=result['reason'],
            metadata={'technical_signal': technical_signal}
        )
```

#### Task 6.2.3: Sentiment Analyst Agent (Day 3)

```python
# fks_ai/src/agents/sentiment_analyst.py
from .base import TradingAgent, AgentVote
from fks_ai.src.sentiment.analyzer import SentimentAnalyzer

class SentimentAnalystAgent(TradingAgent):
    def __init__(self):
        super().__init__("SentimentAnalyst")
        self.sentiment = SentimentAnalyzer()
    
    def vote(self, market_state: Dict) -> AgentVote:
        symbol = market_state['symbol']
        
        # Get sentiment from news
        sentiment_result = self.sentiment.get_sentiment_from_news(symbol)
        score = sentiment_result['score']  # -1 to 1
        
        # Determine vote
        if score > 0.3:
            vote = 'BUY'
        elif score < -0.3:
            vote = 'SELL'
        else:
            vote = 'HOLD'
        
        # Market regime detection
        news_count = sentiment_result['count']
        regime = 'high_activity' if news_count > 10 else 'normal'
        
        return AgentVote(
            agent_name=self.name,
            vote=vote,
            confidence=sentiment_result['confidence'],
            reason=f"Sentiment score {score:.2f} from {news_count} news items. Market regime: {regime}",
            metadata={'sentiment_score': score, 'regime': regime}
        )
```

#### Task 6.2.4: Risk Manager Agent (Day 4)

```python
# fks_ai/src/agents/risk_manager.py
from .base import TradingAgent, AgentVote
from prometheus_api_client import PrometheusConnect

class RiskManagerAgent(TradingAgent):
    def __init__(self, prometheus_url='http://prometheus:9090'):
        super().__init__("RiskManager")
        self.prom = PrometheusConnect(url=prometheus_url)
        self.max_portfolio_exposure = 0.25  # 25% per position
        self.max_drawdown_threshold = 0.10  # 10%
    
    def vote(self, market_state: Dict) -> AgentVote:
        # Get current portfolio metrics from Prometheus
        exposure = self._get_current_exposure()
        drawdown = self._get_current_drawdown()
        
        # Risk assessment
        if drawdown > self.max_drawdown_threshold:
            return AgentVote(
                agent_name=self.name,
                vote='HOLD',  # Pause trading
                confidence=0.95,
                reason=f"Drawdown {drawdown:.1%} exceeds {self.max_drawdown_threshold:.1%} limit",
                metadata={'exposure': exposure, 'drawdown': drawdown}
            )
        
        if exposure > self.max_portfolio_exposure:
            return AgentVote(
                agent_name=self.name,
                vote='HOLD',  # Don't add more risk
                confidence=0.90,
                reason=f"Portfolio exposure {exposure:.1%} exceeds {self.max_portfolio_exposure:.1%} limit",
                metadata={'exposure': exposure, 'drawdown': drawdown}
            )
        
        # Low risk, allow trading
        return AgentVote(
            agent_name=self.name,
            vote='NEUTRAL',  # Don't influence trade direction
            confidence=0.50,
            reason="Risk metrics within acceptable limits",
            metadata={'exposure': exposure, 'drawdown': drawdown}
        )
    
    def _get_current_exposure(self) -> float:
        """Query Prometheus for current portfolio exposure."""
        query = 'fks_portfolio_exposure_ratio'
        result = self.prom.custom_query(query=query)
        return float(result[0]['value'][1]) if result else 0.0
    
    def _get_current_drawdown(self) -> float:
        """Query Prometheus for current drawdown."""
        query = 'fks_portfolio_drawdown'
        result = self.prom.custom_query(query=query)
        return float(result[0]['value'][1]) if result else 0.0
```

#### Task 6.2.5: Strategy Reasoner Coordinator (Day 5)

```python
# fks_ai/src/agents/coordinator.py
import openai
import json
from datetime import datetime
from typing import List
from .base import AgentVote

class StrategyReasoner:
    def __init__(self, agents: List, decision_threshold=0.6):
        self.agents = agents
        self.threshold = decision_threshold
        openai.api_key = os.getenv("OPENAI_API_KEY")
    
    def make_decision(self, market_state: dict) -> dict:
        """
        Coordinate multi-agent debate and make final trading decision.
        
        Returns:
            Dict with action, confidence, and detailed reasoning
        """
        # Collect votes from all agents
        votes = []
        for agent in self.agents:
            vote = agent.vote(market_state)
            votes.append(vote)
        
        # Calculate weighted consensus
        buy_strength = sum(v.confidence for v in votes if v.vote == 'BUY')
        sell_strength = sum(v.confidence for v in votes if v.vote == 'SELL')
        total_conf = sum(v.confidence for v in votes if v.vote != 'NEUTRAL')
        
        net_strength = buy_strength - sell_strength
        decision_confidence = abs(net_strength) / total_conf if total_conf > 0 else 0.5
        
        # Determine action based on threshold
        if decision_confidence < self.threshold:
            action = 'HOLD'
        else:
            action = 'BUY' if net_strength > 0 else 'SELL'
        
        # LLM reasoning for audit trail
        reasoning = self._generate_reasoning(votes, action, decision_confidence)
        
        # Log decision
        decision = {
            'timestamp': datetime.utcnow().isoformat(),
            'symbol': market_state['symbol'],
            'action': action,
            'confidence': decision_confidence,
            'reasoning': reasoning,
            'votes': [{'agent': v.agent_name, 'vote': v.vote, 'conf': v.confidence, 'reason': v.reason} for v in votes],
            'net_strength': net_strength
        }
        
        self._log_decision(decision)
        
        return decision
    
    def _generate_reasoning(self, votes: List[AgentVote], action: str, confidence: float) -> str:
        """Use LLM to generate human-readable reasoning."""
        prompt = f"""
        You are a Strategy Reasoner coordinating multiple trading agents. Review their votes:
        
        {json.dumps([{'agent': v.agent_name, 'vote': v.vote, 'confidence': v.confidence, 'reason': v.reason} for v in votes], indent=2)}
        
        Final decision: {action} (confidence: {confidence:.2f})
        
        Provide a brief explanation (2-3 sentences) of why this decision was made.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5
        )
        
        return response.choices[0].message.content.strip()
    
    def _log_decision(self, decision: dict):
        """Log decision to JSONL file for audit trail."""
        with open('/logs/ai/agent_decisions.jsonl', 'a') as f:
            json.dump(decision, f)
            f.write('\n')
```

**Target**: 30-40% reduction in false signals, +0.5 Sharpe ratio

---

### Phase 6.3: Reflective Learning Mechanism (Week 3)

Enable agents to learn from past trading mistakes and successes.

#### Task 6.3.1: Trade Performance Database (Days 1-2)

**SQL Schema**:
```sql
-- fks_main/sql/trade_performance.sql
CREATE TABLE IF NOT EXISTS trade_history (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    action VARCHAR(10) NOT NULL,  -- 'BUY', 'SELL', 'HOLD'
    entry_price DECIMAL(18, 8),
    exit_price DECIMAL(18, 8),
    quantity DECIMAL(18, 8),
    returns DECIMAL(10, 6),  -- Percentage return
    duration_minutes INT,
    
    -- Agent decisions
    agent_votes JSONB,
    final_confidence DECIMAL(5, 4),
    reasoning TEXT,
    
    -- Metadata
    market_conditions JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_trade_history_timestamp ON trade_history(timestamp);
CREATE INDEX idx_trade_history_symbol ON trade_history(symbol);
CREATE INDEX idx_trade_history_returns ON trade_history(returns);

-- View for losing trades
CREATE VIEW losing_trades AS
SELECT * FROM trade_history
WHERE returns < -0.02  -- Losses > 2%
ORDER BY timestamp DESC;
```

**CRUD Operations**:
```python
# fks_ai/src/reflection/trade_store.py
import psycopg2
from typing import List, Dict
import json

class TradeStore:
    def __init__(self, db_url='postgresql://trading_user:password@db:5432/trading_db'):
        self.conn = psycopg2.connect(db_url)
    
    def save_trade(self, trade: Dict):
        """Save completed trade to database."""
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO trade_history (
                    timestamp, symbol, action, entry_price, exit_price, quantity,
                    returns, duration_minutes, agent_votes, final_confidence, reasoning, market_conditions
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                trade['timestamp'], trade['symbol'], trade['action'],
                trade['entry_price'], trade['exit_price'], trade['quantity'],
                trade['returns'], trade['duration_minutes'],
                json.dumps(trade['agent_votes']), trade['final_confidence'],
                trade['reasoning'], json.dumps(trade['market_conditions'])
            ))
            self.conn.commit()
    
    def get_losing_trades(self, limit=20) -> List[Dict]:
        """Retrieve recent losing trades for reflection."""
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT * FROM losing_trades
                LIMIT %s
            """, (limit,))
            
            columns = [desc[0] for desc in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]
```

#### Task 6.3.2: Reflection Agent (Days 3-4)

```python
# fks_ai/src/reflection/reflection_agent.py
import openai
from .trade_store import TradeStore
from chromadb import Client as ChromaClient
import chromadb

class ReflectionAgent:
    def __init__(self):
        self.store = TradeStore()
        self.chroma = chromadb.PersistentClient(path="/data/chromadb")
        self.collection = self.chroma.get_or_create_collection("trade_insights")
        openai.api_key = os.getenv("OPENAI_API_KEY")
    
    def analyze_losing_trades(self, period_days=7):
        """
        Analyze recent losing trades and generate insights.
        """
        # Get losing trades
        losing_trades = self.store.get_losing_trades(limit=20)
        
        if not losing_trades:
            return "No significant losing trades in period"
        
        # Generate reflection for each trade
        insights = []
        for trade in losing_trades:
            insight = self._reflect_on_trade(trade)
            insights.append(insight)
            
            # Store in vector DB for RAG retrieval
            self.collection.add(
                documents=[insight['summary']],
                metadatas=[{'trade_id': trade['id'], 'symbol': trade['symbol']}],
                ids=[f"trade_{trade['id']}"]
            )
        
        # Generate overall recommendations
        recommendations = self._generate_recommendations(insights)
        
        return {
            'period_days': period_days,
            'losing_trades_count': len(losing_trades),
            'insights': insights,
            'recommendations': recommendations
        }
    
    def _reflect_on_trade(self, trade: Dict) -> Dict:
        """Use LLM to analyze why a trade failed."""
        prompt = f"""
        You are a Trading Performance Analyst. Review this losing trade:
        
        Symbol: {trade['symbol']}
        Action: {trade['action']}
        Entry: ${trade['entry_price']}
        Exit: ${trade['exit_price']}
        Returns: {trade['returns']:.2%}
        Duration: {trade['duration_minutes']} minutes
        
        Agent Votes: {json.dumps(trade['agent_votes'], indent=2)}
        Reasoning: {trade['reasoning']}
        Market Conditions: {json.dumps(trade['market_conditions'], indent=2)}
        
        Analyze:
        1. Why did this trade fail?
        2. What warning signs were missed?
        3. What should be adjusted (stop-loss, confidence threshold, etc.)?
        
        Format: {{"issue": "...", "warning_signs": "...", "adjustment": "..."}}
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[{"role": "user", "content": prompt}]
        )
        
        result = json.loads(response.choices[0].message.content)
        
        return {
            'trade_id': trade['id'],
            'symbol': trade['symbol'],
            'issue': result['issue'],
            'warning_signs': result['warning_signs'],
            'adjustment': result['adjustment'],
            'summary': f"{trade['symbol']}: {result['issue']}. {result['adjustment']}"
        }
    
    def _generate_recommendations(self, insights: List[Dict]) -> str:
        """Generate overall strategy recommendations."""
        prompt = f"""
        Based on analysis of {len(insights)} losing trades, summarize:
        
        {json.dumps([i['summary'] for i in insights], indent=2)}
        
        Provide 3-5 actionable recommendations to improve trading performance.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[{"role": "user", "content": prompt}]
        )
        
        return response.choices[0].message.content.strip()
```

**Celery Task** (scheduled weekly):
```python
# fks_app/src/tasks/reflection.py
from celery import shared_task
from fks_ai.src.reflection.reflection_agent import ReflectionAgent

@shared_task
def weekly_reflection():
    """Run weekly reflection on trading performance."""
    agent = ReflectionAgent()
    report = agent.analyze_losing_trades(period_days=7)
    
    # Save report
    with open(f'/reports/reflection_{datetime.now().date()}.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    # Send notification (Slack, email, etc.)
    # ...
    
    return report
```

#### Task 6.3.3: Feedback Loop (Day 5)

**Auto-adjust strategy parameters**:
```python
# fks_app/src/strategies/adaptive_asmbtr.py
from fks_ai.src.reflection.reflection_agent import ReflectionAgent

class AdaptiveASMBTR:
    def __init__(self, base_strategy):
        self.base = base_strategy
        self.reflection = ReflectionAgent()
        self.adjustments = {}
    
    def apply_reflective_learning(self):
        """Query insights from reflection agent and adjust parameters."""
        # Search for relevant insights
        results = self.reflection.collection.query(
            query_texts=["stop loss adjustment", "confidence threshold"],
            n_results=5
        )
        
        # Parse recommendations
        for doc in results['documents'][0]:
            if 'tighten stop-loss' in doc.lower():
                self.adjustments['stop_loss_pct'] = max(
                    self.base.stop_loss_pct * 0.9,  # Tighten by 10%
                    0.02  # Minimum 2%
                )
            
            if 'increase confidence threshold' in doc.lower():
                self.adjustments['min_confidence'] = min(
                    self.base.min_confidence + 0.05,
                    0.80  # Maximum 80%
                )
        
        return self.adjustments
```

**Target**: +10-15% performance improvement over 30-day window

---

### Phase 6.4: Risk Mitigation & Safeguards (Week 4)

Implement validation layers to prevent LLM hallucinations and ensure data quality.

#### Task 6.4.1: LLM Output Validation (Days 1-2)

```python
# fks_ai/src/validation/llm_validator.py
from pydantic import BaseModel, Field, validator
from typing import Literal

class AgentDecision(BaseModel):
    vote: Literal['BUY', 'SELL', 'HOLD']
    confidence: float = Field(ge=0.0, le=1.0)
    reason: str = Field(min_length=10, max_length=500)
    
    @validator('reason')
    def reason_not_empty(cls, v):
        if not v or v.strip() == '':
            raise ValueError('Reason cannot be empty')
        return v

def validate_llm_output(raw_output: str) -> AgentDecision:
    """
    Validate and parse LLM output.
    Raises ValidationError if output is malformed.
    """
    try:
        data = json.loads(raw_output)
        decision = AgentDecision(**data)
        return decision
    except (json.JSONDecodeError, ValidationError) as e:
        # Log invalid output
        with open('/logs/ai/invalid_decisions.jsonl', 'a') as f:
            json.dump({
                'timestamp': datetime.utcnow().isoformat(),
                'raw_output': raw_output,
                'error': str(e)
            }, f)
            f.write('\n')
        
        # Return safe default
        return AgentDecision(vote='HOLD', confidence=0.5, reason='LLM output validation failed')
```

#### Task 6.4.2: Data Quality Monitoring (Day 3)

```python
# fks_data/src/quality/monitor.py
from prometheus_client import Gauge, Counter
import numpy as np

data_quality_score = Gauge('fks_data_quality_score', 'Data quality score 0-1')
stale_data_count = Counter('fks_stale_data_total', 'Count of stale data rejections')
anomaly_count = Counter('fks_data_anomaly_total', 'Count of detected anomalies')

class DataQualityMonitor:
    def __init__(self, max_staleness_seconds=300):
        self.max_staleness = max_staleness_seconds
    
    def validate_market_data(self, data: Dict) -> bool:
        """
        Validate market data quality before trading.
        Returns False if data should be rejected.
        """
        # Freshness check
        age_seconds = (datetime.utcnow() - data['timestamp']).total_seconds()
        if age_seconds > self.max_staleness:
            stale_data_count.inc()
            return False
        
        # Anomaly detection (z-score)
        if 'price_change_pct' in data:
            z_score = abs(data['price_change_pct'] - data['avg_change']) / data['std_change']
            if z_score > 3:
                anomaly_count.inc()
                return False
        
        # Update quality score
        quality = 1.0 - (age_seconds / self.max_staleness)
        data_quality_score.set(quality)
        
        return True
```

#### Task 6.4.3: Cost Optimization (Days 4-5)

**Tiered LLM Usage**:
```python
# fks_ai/src/llm/optimizer.py
class LLMOptimizer:
    def __init__(self):
        self.costs = {
            'gpt-4-turbo': 0.01,  # $0.01 per call (approx)
            'gpt-3.5-turbo': 0.002,
            'gemini-1.5-flash': 0.0  # Free tier
        }
        self.daily_budget = 10.0  # $10/day
        self.spent_today = 0.0
    
    def select_model(self, task_complexity: str) -> str:
        """Select appropriate model based on task and budget."""
        if task_complexity == 'critical' and self.spent_today < self.daily_budget * 0.8:
            self.spent_today += self.costs['gpt-4-turbo']
            return 'gpt-4-turbo'
        elif self.spent_today < self.daily_budget:
            self.spent_today += self.costs['gpt-3.5-turbo']
            return 'gpt-3.5-turbo'
        else:
            return 'gemini-1.5-flash'  # Fallback to free tier
```

**Target**: Reduce API costs by 60-70% vs full GPT-4 usage

---

## 📊 Performance Metrics

### Target Benchmarks

| Metric | Baseline (ASMBTR) | Target (AI-Enhanced) | Research Evidence |
|--------|------------------|---------------------|-------------------|
| Net Returns | ~7-10% | +20-30% | FinGPT benchmarks |
| Sharpe Ratio | ~1.0-1.5 | +0.5-1.0 | TradingGPT paper |
| Max Drawdown | ~15-20% | <10% | Alpha Arena |
| False Signals | Baseline | -30-40% | LMT paper |
| Decision Latency | N/A | <3s | Target |
| Cost per Trade | N/A | <$0.02 | Target |

### Monitoring Dashboard

```yaml
# fks_main/monitoring/prometheus/ai_metrics.yml
groups:
  - name: ai_agents
    interval: 30s
    rules:
      - record: fks_ai_agent_confidence_avg
        expr: avg(fks_agent_confidence)
      
      - alert: LowAgentConfidence
        expr: fks_ai_agent_confidence_avg < 0.5
        for: 5m
        annotations:
          summary: "Agent confidence below 50% for 5 minutes"
      
      - alert: HighLLMCost
        expr: rate(fks_llm_cost_usd[1h]) > 0.50
        annotations:
          summary: "LLM costs exceeding $0.50/hour"
```

## 🚧 Risk Mitigation

### Hallucination Prevention

```python
# Hard price/volatility guards
def validate_trade_signal(signal: dict) -> bool:
    """Prevent absurd LLM recommendations."""
    # Reject if suggesting trade during extreme volatility
    if signal['price_change_1h'] > 0.50:  # >50% move in 1 hour
        return False
    
    # Reject if position size too large
    if signal['position_size'] > 0.25:  # >25% of portfolio
        return False
    
    return True
```

### Circuit Breakers

```python
# Pause trading if data sources failing
def check_circuit_breaker() -> bool:
    failed_sources = prometheus_query('fks_data_source_failures')
    if failed_sources > 0.10:  # >10% failure rate
        return False  # Halt trading
    return True
```

## 🔗 References

### Research Papers

- **FinGPT**: Open-source financial LLMs (F1 0.88) - https://github.com/AI4Finance-Foundation/FinGPT
- **CryptoTrade**: Reflective LLM agent (2.38% ETH) - https://github.com/Xtra-Computing/CryptoTrade
- **TradingAgents**: Multi-agent framework - https://github.com/TauricResearch/TradingAgents
- **Alpha Arena**: Real-world benchmarks (+39.9%) - https://www.chaincatcher.com/en/article/2213902

### FKS Integration

- [Core Architecture](./01-core-architecture.md) - K8s deployment
- [Docker Strategy](./02-docker-strategy.md) - Build workflows
- [Portfolio Rebalancing](./06-portfolio-rebalancing.md) - RL optimization
- [CVaR Risk Management](./07-cvar-risk-management.md) - Safe RL

## 🎯 Next Steps

1. ✅ Install transformers and FinBERT model
2. ✅ Implement sentiment analyzer with caching
3. ✅ Create 4-agent system with debate mechanism
4. ✅ Build reflection agent with ChromaDB
5. ✅ Add validation layers and circuit breakers
6. ⏸️ Run 1000 simulated trades for validation
7. ⏸️ Deploy to fks_ai service in K8s cluster

**Ready to start implementation?** Begin with Phase 6.1.1 (LLM Infrastructure Setup).
