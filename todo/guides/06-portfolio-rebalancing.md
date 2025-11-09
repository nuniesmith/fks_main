# AI-Driven Portfolio Rebalancing via Reinforcement Learning

**Status**: Research & Planning Phase  
**Priority**: Advanced Feature (Future Implementation)  
**Estimated Timeline**: 4-6 weeks for MVP

## 🎯 Overview

Integration of reinforcement learning (RL) frameworks for dynamic, constraint-aware portfolio rebalancing in FKS trading platform. Research shows 15-30% improvement in risk-adjusted returns vs static strategies.

### Key Benefits

- **Risk-Adjusted Returns**: +15-30% vs 60/40 static allocations
- **Constraint Enforcement**: Primal-dual networks manage VaR/liquidity limits
- **Client Behavior Modeling**: Stackelberg RL predicts realistic execution rates
- **Reduced Violations**: <0.09 constraint residuals in simulations
- **Volatility Reduction**: -21% in benchmarks

## 📚 Research Foundation

### Core Framework: Primal-Dual Neural Networks

**Paper**: "AI-Driven Personalized Portfolio Rebalancing Using Reinforcement Learning" (Shenggang Li, 2025)

**Key Components**:

1. **Actor Network (ϕθ)**: Proposes portfolio adjustments
2. **Critic-λ Network (ψϕ)**: Enforces constraints via Lagrange multipliers
3. **Critic-y Network (χφ)**: Models client compliance behavior
4. **Augmented Lagrangian**: Balances objectives with penalties

### Mathematical Foundation

**Augmented Lagrangian**:

```
L(x, λ, ρ) = f(x) + λᵀ g(x) + (ρ/2) ‖g(x)‖²
```

Where:

- `f(x)`: Objective (e.g., portfolio return)
- `g(x) ≤ 0`: Constraints (VaR, liquidity, tax limits)
- `λ ≥ 0`: Lagrange multipliers (shadow prices)
- `ρ > 0`: Penalty weight (adaptive)

**Actor Gradient** (primal descent):

```
∇_θ L = -∇_r + ∇_λ g + ρ ∇(g²)
```

**Critic-λ Gradient** (dual ascent):

```
∇_ϕ L = ∇ g
```

### CVaR Risk Extensions

**Conditional Value at Risk (CVaR)**: Expected loss in tail beyond confidence threshold α.

**Formula**:

```
CVaR_α(L) = (1/(1-α)) ∫_α^1 VaR_p(L) dp = E[L | L ≥ VaR_α(L)]
```

**Properties**:

- Coherent risk measure (subadditive, monotonic)
- Focuses on tail severity vs VaR threshold
- Enables safe RL with constraint violations <10%

**Research Impact**:

- 10-20% drawdown reduction
- Higher Sharpe ratios (+0.5-1.0)
- Robust in volatile crypto markets

## 🏗️ FKS Implementation Plan

### Phase 1: Infrastructure Setup (Week 1-2)

**Task 1.1: Data Pipeline Enhancement**

```python
# fks_data/src/portfolio/rebalancer.py
import pandas as pd
import torch
import torch.nn as nn

class PortfolioDataPipeline:
    """Prepare data for RL training"""
    def __init__(self, horizons={'short': 60, 'mid': 1440*7, 'long': 1440*30}):
        self.horizons = horizons
        self.buffers = {k: pd.DataFrame() for k in horizons}
    
    def update(self, new_data: pd.DataFrame):
        """Update rolling buffers with market data"""
        for horizon, size in self.horizons.items():
            self.buffers[horizon] = pd.concat([self.buffers[horizon], new_data]).tail(size)
    
    def get_state(self, symbol: str) -> dict:
        """Extract state features for RL agent"""
        return {
            'prices': self.buffers['short'][[symbol]].values,
            'volumes': self.buffers['short']['volume'].values,
            'indicators': self._compute_indicators(symbol)
        }
    
    def _compute_indicators(self, symbol: str):
        """Compute technical indicators (RSI, MACD, etc.)"""
        # Integration with existing ASMBTR indicators
        pass
```

**Task 1.2: PostgreSQL Schema Extension**

```sql
-- Add to fks_main/sql/portfolio_tracking.sql
CREATE TABLE portfolio_states (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    position DECIMAL(18, 8),
    value DECIMAL(18, 2),
    returns DECIMAL(10, 6),
    risk_metrics JSONB  -- VaR, CVaR, volatility
);

CREATE TABLE rebalance_decisions (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    agent_type VARCHAR(50),  -- 'actor', 'critic_lambda', 'critic_y'
    action JSONB,  -- Portfolio adjustments
    confidence DECIMAL(5, 4),
    constraints_satisfied BOOLEAN,
    metadata JSONB
);

CREATE INDEX idx_portfolio_timestamp ON portfolio_states(timestamp);
CREATE INDEX idx_rebalance_timestamp ON rebalance_decisions(timestamp);
```

### Phase 2: Neural Network Implementation (Week 3-4)

**Task 2.1: Actor Network**

```python
# fks_ai/src/rl/portfolio_actor.py
import torch.nn as nn

class PortfolioActor(nn.Module):
    """Proposes portfolio adjustments"""
    def __init__(self, state_dim=128, action_dim=10, hidden_dim=256):
        super().__init__()
        self.lstm = nn.LSTM(state_dim, hidden_dim, num_layers=2, batch_first=True)
        self.fc = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(hidden_dim // 2, action_dim),
            nn.Tanh()  # Actions in [-1, 1] for position adjustments
        )
    
    def forward(self, state):
        """state: [batch, seq_len, features]"""
        lstm_out, _ = self.lstm(state)
        return self.fc(lstm_out[:, -1, :])  # Use last hidden state
```

**Task 2.2: Critic-λ Network (Constraint Enforcement)**

```python
# fks_ai/src/rl/critic_lambda.py
class CriticLambda(nn.Module):
    """Enforces portfolio constraints via Lagrange multipliers"""
    def __init__(self, state_dim=128, action_dim=10, num_constraints=3):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim + action_dim, 256),
            nn.ReLU(),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, num_constraints),
            nn.Softplus()  # Ensure λ ≥ 0
        )
    
    def forward(self, state, action):
        """Returns multipliers for [VaR, liquidity, tax] constraints"""
        x = torch.cat([state, action], dim=-1)
        return self.net(x)
```

**Task 2.3: Critic-y Network (Client Behavior)**

```python
# fks_ai/src/rl/critic_y.py
class CriticY(nn.Module):
    """Predicts client execution compliance"""
    def __init__(self, state_dim=128, action_dim=10):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim + action_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 1),
            nn.Sigmoid()  # Execution rate q ∈ [0, 1]
        )
    
    def forward(self, state, action):
        """Returns predicted execution rate"""
        x = torch.cat([state, action], dim=-1)
        return self.net(x).squeeze(-1)
```

### Phase 3: Training Pipeline (Week 5-6)

**Task 3.1: Primal-Dual Training Loop**

```python
# fks_ai/src/rl/trainer.py
import torch.optim as optim

class PrimalDualTrainer:
    def __init__(self, actor, critic_lambda, critic_y, lr=3e-4):
        self.actor = actor
        self.critic_lambda = critic_lambda
        self.critic_y = critic_y
        
        self.opt_actor = optim.Adam(actor.parameters(), lr=lr)
        self.opt_lambda = optim.Adam(critic_lambda.parameters(), lr=lr)
        self.opt_y = optim.Adam(critic_y.parameters(), lr=lr)
        
        self.rho = 1.0  # Adaptive penalty weight
    
    def train_step(self, state, action, reward, constraints):
        """Single training iteration"""
        # Forward pass
        lambda_vals = self.critic_lambda(state, action)
        q_vals = self.critic_y(state, action)
        
        # Compute losses
        constraint_violations = torch.relu(constraints)  # max(g(x), 0)
        
        # Actor loss (primal descent)
        actor_loss = -reward.mean() + \
                     (lambda_vals * constraint_violations).sum(dim=-1).mean() + \
                     (self.rho / 2) * (constraint_violations ** 2).sum(dim=-1).mean()
        
        # Critic-λ loss (dual ascent)
        lambda_loss = -(lambda_vals * constraint_violations).sum(dim=-1).mean() + \
                      1e-6 * (lambda_vals ** 2).sum(dim=-1).mean()  # L2 regularization
        
        # Critic-y loss (behavior prediction)
        y_loss = nn.MSELoss()(q_vals, q_observed)  # q_observed from logs
        
        # Update networks
        self.opt_actor.zero_grad()
        actor_loss.backward()
        self.opt_actor.step()
        
        self.opt_lambda.zero_grad()
        lambda_loss.backward()
        self.opt_lambda.step()
        
        self.opt_y.zero_grad()
        y_loss.backward()
        self.opt_y.step()
        
        # Adaptive penalty
        if constraint_violations.mean() > 0.01:
            self.rho *= 1.05  # Increase penalty if violations persist
        
        return {
            'actor_loss': actor_loss.item(),
            'lambda_loss': lambda_loss.item(),
            'y_loss': y_loss.item(),
            'constraint_violations': constraint_violations.mean().item()
        }
```

**Task 3.2: CVaR Integration**

```python
# fks_ai/src/rl/cvar_loss.py
def compute_cvar_loss(returns, alpha=0.95):
    """Compute CVaR for risk-sensitive training"""
    sorted_returns, _ = torch.sort(returns)
    tail_idx = int(len(returns) * alpha)
    var = sorted_returns[tail_idx]
    cvar = sorted_returns[tail_idx:].mean()
    return cvar, var

class CVaRPrimalDualTrainer(PrimalDualTrainer):
    """Extended trainer with CVaR constraints"""
    def train_step(self, state, action, returns, constraints):
        cvar, var = compute_cvar_loss(returns, alpha=0.95)
        
        # Add CVaR to constraints
        cvar_constraint = torch.relu(cvar - self.cvar_threshold)  # CVaR ≤ threshold
        constraints = torch.cat([constraints, cvar_constraint.unsqueeze(-1)], dim=-1)
        
        return super().train_step(state, action, returns.mean(), constraints)
```

### Phase 4: Integration with ASMBTR (Week 7-8)

**Task 4.1: Hybrid Strategy**

```python
# fks_app/src/strategies/hybrid_asmbtr_rl.py
from fks_ai.src.rl.portfolio_actor import PortfolioActor

class HybridASMBTRRL:
    """Combine ASMBTR technical analysis with RL rebalancing"""
    def __init__(self, asmbtr_model, rl_actor):
        self.asmbtr = asmbtr_model
        self.rl_actor = rl_actor
        self.alpha = 0.5  # Weight for hybrid decision
    
    def get_action(self, state):
        # ASMBTR technical signal
        asmbtr_signal = self.asmbtr.predict(state)  # -1 to 1
        
        # RL portfolio adjustment
        rl_adjustment = self.rl_actor(state).detach().numpy()
        
        # Hybrid decision
        final_action = self.alpha * asmbtr_signal + (1 - self.alpha) * rl_adjustment
        
        return {
            'action': final_action,
            'asmbtr_signal': asmbtr_signal,
            'rl_adjustment': rl_adjustment,
            'confidence': self._compute_confidence(asmbtr_signal, rl_adjustment)
        }
    
    def _compute_confidence(self, asmbtr, rl):
        """High confidence when signals agree"""
        agreement = 1 - abs(asmbtr - rl) / 2
        return agreement
```

## 📊 Performance Metrics

### Target Benchmarks (Based on Research)

| Metric | Current (ASMBTR) | Target (RL-Enhanced) | Research Baseline |
|--------|------------------|---------------------|-------------------|
| Net Worth Growth | ~7-10% | +10-20% | +13.4% (paper) |
| Sharpe Ratio | ~1.0-1.5 | +0.5-1.0 | ~2.0 (paper) |
| Max Drawdown | ~15-20% | <10% | <8% (LMT) |
| Volatility | Baseline | -15-25% | -21% (paper) |
| Constraint Violations | ~10-20% | <5% | <0.09 (paper) |

### Monitoring Integration

```python
# fks_main/monitoring/prometheus/rl_metrics.py
from prometheus_client import Gauge, Counter

# Portfolio metrics
portfolio_value = Gauge('fks_portfolio_value', 'Current portfolio value USD')
portfolio_returns = Gauge('fks_portfolio_returns', 'Portfolio returns %')
portfolio_sharpe = Gauge('fks_portfolio_sharpe', 'Sharpe ratio')

# RL agent metrics
agent_confidence = Gauge('fks_rl_agent_confidence', 'Agent confidence score')
constraint_violations = Counter('fks_rl_constraint_violations', 'Constraint violation count')
lambda_values = Gauge('fks_rl_lambda_values', 'Lagrange multiplier values', ['constraint_type'])
cvar_current = Gauge('fks_rl_cvar', 'Current CVaR value')
```

## 🚧 Risks & Mitigations

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Overfitting | High | High | Walk-forward validation, rolling windows |
| Hallucinations (LLM) | Medium | High | Ground truth validation, hard price guards |
| Compute Load | Medium | Medium | Offload to Gemini API, optimize batch sizes |
| Non-stationarity | High | Medium | Adaptive ρ, periodic retraining |
| Latency | Low | Medium | Async inference, caching |

### Financial Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Market Regime Change | High | High | Multi-agent debate, circuit breakers |
| Fat Tails | Medium | High | CVaR constraints, dynamic VaR limits |
| Liquidity Crunch | Low | High | Liquidity constraints in Critic-λ |
| Slippage | Medium | Medium | Execution quality tracking |

## 🎯 Success Criteria

### Minimum Viable Product (MVP)

- [ ] Actor/Critic-λ/Critic-y networks implemented
- [ ] Training pipeline with synthetic data
- [ ] Backtests on 2023-24 AAPL/GOOG/MSFT data
- [ ] Constraint violations <10%
- [ ] Sharpe ratio improvement +0.3 vs baseline

### Production-Ready

- [ ] CVaR integration for tail risk
- [ ] Hybrid ASMBTR-RL strategy
- [ ] Real-time inference <2s per decision
- [ ] Prometheus metrics dashboard
- [ ] 1000 simulated trades validation
- [ ] +20% return improvement in backtests

## 🔗 References

### Primary Papers

1. **Primal-Dual Framework**: "AI-Driven Personalized Portfolio Rebalancing Using Reinforcement Learning" ([Medium](https://medium.com/data-science-collective/ai-driven-personalized-portfolio-rebalancing-using-reinforcement-learning-1a36fce7201f))
2. **CVaR in Safe RL**: "Towards Safe Reinforcement Learning via Constraining Conditional Value at Risk" ([arXiv:2206.04436](https://arxiv.org/abs/2206.04436))
3. **Distributional RL**: "A Distributional Perspective on Reinforcement Learning" ([ICML 2017](https://proceedings.mlr.press/v70/bellemare17a.html))
4. **TradingGPT Multi-Agent**: "Multi-Agent System with Layered Memory" ([arXiv:2309.03736](https://arxiv.org/abs/2309.03736))

### Implementation Resources

- [FinMem: LLM Trading Agent](https://github.com/pipiku915/FinMem-LLM-StockTrading)
- [CryptoRLPM: RL for Crypto](https://arxiv.org/abs/2202.09663)
- [Dynamic Portfolio Rebalancing](https://github.com/cao-q/Dynamic-portfolio-rebalancing-through-RL)

### FKS Integration Points

- `/fks_ai/src/rl/` - RL models
- `/fks_data/src/portfolio/` - Data pipelines
- `/fks_app/src/strategies/` - Hybrid strategies
- `/fks_main/sql/` - Portfolio tracking schema
- `/fks_main/monitoring/` - Prometheus metrics

---

**Next Steps**:

1. Review research papers and reproduce key formulas
2. Prototype Actor/Critic networks with toy data
3. Integrate with existing ASMBTR backtesting framework
4. Run simulations on historical data
5. Deploy to fks_main K8s with monitoring
