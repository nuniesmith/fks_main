# CVaR Risk Management for Safe Reinforcement Learning

**Status**: Research Phase  
**Priority**: Advanced Feature (Future Implementation)  
**Estimated Timeline**: 4-6 weeks for MVP

## 🎯 Overview

Integration of Conditional Value at Risk (CVaR) constraints into reinforcement learning agents for portfolio management. Enables **safe RL** with tail risk control, reducing maximum drawdown by 10-20% while maintaining returns.

### Key Benefits

- **Tail Risk Control**: Focus on worst-case scenarios beyond VaR threshold
- **Safe RL**: Constraint violations <10% vs 30-50% in unconstrained RL
- **Higher Sharpe Ratios**: +0.5-1.0 improvement with risk-adjusted optimization
- **Coherent Risk Measure**: Subadditive, monotonic, translation invariant
- **Regulatory Compliance**: Basel III standards support CVaR for capital requirements

## 📐 Mathematical Foundation

### Value at Risk (VaR)

**Definition**: Maximum loss at confidence level α over time horizon T.

**Formula**:
```
VaR_α(L) = inf{x ∈ ℝ : P(L ≤ x) ≥ α}
```

Where:
- `L`: Loss distribution
- `α`: Confidence level (e.g., 0.95 for 95%)
- `P`: Probability measure

**Example**: VaR₀.₉₅ = $10,000 means "95% confident losses won't exceed $10k"

**Limitations**:
- Non-subadditive (portfolio VaR ≠ sum of component VaRs)
- Ignores severity of tail losses beyond threshold
- Not a coherent risk measure

### Conditional Value at Risk (CVaR)

**Definition**: Expected loss in the tail beyond VaR threshold.

**Formula**:
```
CVaR_α(L) = (1/(1-α)) ∫_α^1 VaR_p(L) dp = E[L | L ≥ VaR_α(L)]
```

**Alternative (optimization form)**:
```
CVaR_α(L) = min_η {η + (1/(1-α)) E[(L - η)⁺]}
```

Where:
- `η`: Auxiliary variable (VaR estimate)
- `(x)⁺ = max(x, 0)`: Positive part operator

**Example**: If VaR₀.₉₅ = $10k and CVaR₀.₉₅ = $15k:
- "In worst 5% of scenarios, average loss is $15k"
- Captures tail severity, not just threshold

**Properties (Coherent Risk Measure)**:
1. **Subadditivity**: `CVaR(L₁ + L₂) ≤ CVaR(L₁) + CVaR(L₂)` (diversification works)
2. **Monotonicity**: `L₁ ≤ L₂ ⇒ CVaR(L₁) ≤ CVaR(L₂)`
3. **Positive homogeneity**: `CVaR(λL) = λ CVaR(L)` for λ > 0
4. **Translation invariance**: `CVaR(L + c) = CVaR(L) + c`

### CVaR in Trading Context

**Portfolio Loss Distribution**:
```
L(x, r) = -xᵀr
```

Where:
- `x`: Portfolio weights (sums to 1)
- `r`: Asset returns (random vector)

**CVaR Constraint**:
```
CVaR_α(L(x, r)) ≤ C
```

Limit expected tail loss to threshold C (e.g., 10% of portfolio value).

## 🧠 Safe RL with CVaR Constraints

### Problem Formulation

**Standard RL Objective**:
```
max_π E[∑_t γᵗ r_t]
```

**CVaR-Constrained RL**:
```
max_π CVaR_α(∑_t γᵗ r_t)  subject to  CVaR_β(c_t) ≤ d  ∀t
```

Where:
- `π`: Policy (trading strategy)
- `γ`: Discount factor (0.99)
- `r_t`: Reward at time t
- `c_t`: Constraint value (e.g., drawdown, volatility)
- `α, β`: CVaR confidence levels (typically 0.9-0.95)
- `d`: Constraint threshold

### Distributional RL Approach

**C51 (Categorical DQN)**:
```python
# Represent value distribution with atoms
Z = {z_i : i = 1,...,N}  # N=51 atoms
p(z_i | s, a) = softmax(θ(s, a))_i

# Bellman update
T Z(s, a) ≈ R + γZ(s', a*)

# CVaR calculation
CVaR_α(Z) = (1/(1-α)) ∑_{i: z_i ≥ VaR_α} p(z_i) z_i
```

**IQN (Implicit Quantile Networks)**:
```python
# Parameterize quantile function
Z_τ(s, a; θ) = f(s, a, τ; θ)  # τ ∈ [0, 1]

# CVaR via quantile integration
CVaR_α(s, a) = (1/(1-α)) ∫_α^1 Z_τ(s, a) dτ
```

**QR-DQN (Quantile Regression DQN)**:
```python
# Fixed quantile levels
τ_i = (2i - 1) / (2N)  # Midpoint quantiles

# Learn quantiles directly
Q_τ(s, a) = Z_τ(s, a)

# CVaR from upper quantiles
CVaR_α(s, a) = (1/|I|) ∑_{i ∈ I} Q_τ_i(s, a)
where I = {i : τ_i > α}
```

### Safe RL Algorithms

#### CPPO (CVaR-Proximal Policy Optimization)

**Modified PPO Objective**:
```python
L^CPPO(θ) = E_t[min(
    r_t(θ) Â_t,
    clip(r_t(θ), 1-ε, 1+ε) Â_t
)] - λ CVaR_α(returns)

where:
r_t(θ) = π_θ(a_t|s_t) / π_old(a_t|s_t)  # Importance ratio
Â_t = advantage estimate
λ = CVaR penalty weight
```

**Implementation**:
```python
# fks_ai/src/rl/safe_ppo.py
import torch
import torch.nn as nn
from torch.distributions import Categorical

class CVARPPO:
    def __init__(self, policy, alpha=0.95, lambda_cvar=0.1):
        self.policy = policy
        self.alpha = alpha
        self.lambda_cvar = lambda_cvar
        self.optimizer = torch.optim.Adam(policy.parameters(), lr=3e-4)
    
    def compute_cvar(self, returns, alpha):
        """Compute CVaR from return samples."""
        sorted_returns, _ = torch.sort(returns)
        tail_idx = int(len(returns) * alpha)
        cvar = sorted_returns[tail_idx:].mean()
        return cvar
    
    def update(self, states, actions, old_probs, returns, advantages):
        """Single PPO update with CVaR penalty."""
        # Compute action probabilities
        logits = self.policy(states)
        dist = Categorical(logits=logits)
        new_probs = dist.log_prob(actions).exp()
        
        # Importance ratio
        ratio = new_probs / old_probs
        
        # Clipped surrogate loss
        surr1 = ratio * advantages
        surr2 = torch.clamp(ratio, 0.8, 1.2) * advantages
        policy_loss = -torch.min(surr1, surr2).mean()
        
        # CVaR penalty (minimize CVaR of negative returns)
        cvar_loss = self.compute_cvar(-returns, self.alpha)
        
        # Total loss
        loss = policy_loss + self.lambda_cvar * cvar_loss
        
        # Update
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()
        
        return {
            'policy_loss': policy_loss.item(),
            'cvar_loss': cvar_loss.item(),
            'total_loss': loss.item()
        }
```

#### TRC (Trust Region CVaR)

**Constrained Optimization**:
```python
max_π  CVaR_α(J^π)
subject to:
    D_KL(π || π_old) ≤ δ  (trust region)
    CVaR_β(c^π) ≤ d  (risk constraint)
```

**Lagrangian Formulation**:
```python
L(π, λ) = CVaR_α(J^π) - λ (CVaR_β(c^π) - d)
```

**Implementation**:
```python
# fks_ai/src/rl/trc.py
class TrustRegionCVaR:
    def __init__(self, policy, alpha=0.95, delta_kl=0.01):
        self.policy = policy
        self.alpha = alpha
        self.delta_kl = delta_kl
        self.lambda_dual = 1.0  # Lagrange multiplier
    
    def kl_divergence(self, old_probs, new_probs):
        """KL divergence for trust region."""
        return (old_probs * (old_probs.log() - new_probs.log())).sum(dim=-1).mean()
    
    def update(self, states, actions, returns, constraints):
        """TRC update with constraint satisfaction."""
        # Get old policy
        with torch.no_grad():
            old_logits = self.policy(states)
            old_probs = torch.softmax(old_logits, dim=-1)
        
        # Optimize objective with trust region
        for _ in range(10):  # Inner optimization loop
            logits = self.policy(states)
            new_probs = torch.softmax(logits, dim=-1)
            
            # CVaR objective
            cvar_obj = self.compute_cvar(returns, self.alpha)
            
            # CVaR constraint
            cvar_constraint = self.compute_cvar(constraints, 0.95)
            
            # Trust region constraint
            kl = self.kl_divergence(old_probs, new_probs)
            
            # Lagrangian loss
            loss = -cvar_obj + self.lambda_dual * (cvar_constraint - 0.1)
            loss += 1000 * torch.clamp(kl - self.delta_kl, min=0)  # Hard KL penalty
            
            # Update policy
            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()
        
        # Update dual variable (gradient ascent on constraints)
        with torch.no_grad():
            if cvar_constraint > 0.1:
                self.lambda_dual *= 1.1
            else:
                self.lambda_dual *= 0.9
```

## 🔬 Integration with FKS Portfolio Rebalancing

### Augmented Primal-Dual Framework

**Original Augmented Lagrangian** (from [06-portfolio-rebalancing.md](./06-portfolio-rebalancing.md)):
```
L(x, λ, ρ) = f(x) + λᵀ g(x) + (ρ/2) ‖g(x)‖²
```

**CVaR-Extended Formulation**:
```
L(x, λ, ρ) = -E[R(x)] + λᵀ [g(x), CVaR_α(L(x)) - C] + (ρ/2) ‖constraints‖²
```

Where:
- `R(x)`: Portfolio returns
- `g(x)`: Standard constraints (liquidity, tax, etc.)
- `CVaR_α(L(x)) - C`: CVaR constraint on portfolio loss
- `C`: CVaR threshold (e.g., 10% of portfolio value)

### Network Modifications

**Critic-λ Network Extended**:
```python
# fks_ai/src/rl/critic_lambda_cvar.py
class CriticLambdaCVaR(nn.Module):
    """
    Enforces portfolio constraints including CVaR.
    """
    def __init__(self, state_dim=128, action_dim=10, num_constraints=4):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim + action_dim, 256),
            nn.ReLU(),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, num_constraints),  # [VaR, liquidity, tax, CVaR]
            nn.Softplus()  # Ensure λ ≥ 0
        )
    
    def forward(self, state, action):
        """Returns multipliers for all constraints including CVaR."""
        x = torch.cat([state, action], dim=-1)
        return self.net(x)
```

**CVaR Computation Module**:
```python
# fks_ai/src/rl/cvar_utils.py
import torch

def compute_cvar_loss(returns: torch.Tensor, alpha: float = 0.95) -> tuple:
    """
    Compute CVaR and VaR from return samples.
    
    Args:
        returns: Tensor of shape [batch_size]
        alpha: Confidence level (0.95 = 95%)
    
    Returns:
        (cvar, var) tuple
    """
    sorted_returns, _ = torch.sort(returns)
    tail_idx = int(len(returns) * alpha)
    
    var = sorted_returns[tail_idx]
    cvar = sorted_returns[tail_idx:].mean()
    
    return cvar, var

def compute_cvar_gradient(returns: torch.Tensor, alpha: float, 
                         threshold: float) -> torch.Tensor:
    """
    Compute gradient for CVaR constraint.
    
    CVaR constraint: CVaR_α(L) ≤ threshold
    Gradient w.r.t. policy parameters via chain rule.
    """
    cvar, var = compute_cvar_loss(returns, alpha)
    
    # Constraint violation (g(x) = CVaR - threshold)
    violation = torch.relu(cvar - threshold)
    
    return violation
```

### Training Integration

```python
# fks_ai/src/rl/trainer_cvar.py
from .critic_lambda_cvar import CriticLambdaCVaR
from .cvar_utils import compute_cvar_loss, compute_cvar_gradient

class CVaRPrimalDualTrainer:
    """
    Extended trainer with CVaR constraints.
    Inherits from PrimalDualTrainer (see 06-portfolio-rebalancing.md).
    """
    def __init__(self, actor, critic_lambda, critic_y, 
                 alpha=0.95, cvar_threshold=0.1, lr=3e-4):
        self.actor = actor
        self.critic_lambda = CriticLambdaCVaR(...)  # Extended critic
        self.critic_y = critic_y
        
        self.alpha = alpha
        self.cvar_threshold = cvar_threshold
        
        self.opt_actor = torch.optim.Adam(actor.parameters(), lr=lr)
        self.opt_lambda = torch.optim.Adam(self.critic_lambda.parameters(), lr=lr)
        self.opt_y = torch.optim.Adam(critic_y.parameters(), lr=lr)
        
        self.rho = 1.0  # Adaptive penalty
    
    def train_step(self, state, action, returns, constraints):
        """
        Single training iteration with CVaR constraints.
        
        Args:
            state: Current portfolio state
            action: Proposed rebalancing action
            returns: Portfolio returns distribution
            constraints: [var, liquidity, tax] constraints
        """
        # Compute CVaR
        cvar, var = compute_cvar_loss(returns, self.alpha)
        cvar_violation = torch.relu(cvar - self.cvar_threshold)
        
        # Append CVaR to constraints
        all_constraints = torch.cat([constraints, cvar_violation.unsqueeze(0)])
        
        # Get Lagrange multipliers (4 constraints now)
        lambda_vals = self.critic_lambda(state, action)
        q_vals = self.critic_y(state, action)
        
        # Compute losses
        constraint_violations = torch.relu(all_constraints)
        
        # Actor loss (primal descent)
        actor_loss = -returns.mean() + \
                     (lambda_vals * constraint_violations).sum(dim=-1).mean() + \
                     (self.rho / 2) * (constraint_violations ** 2).sum(dim=-1).mean()
        
        # Critic-λ loss (dual ascent)
        lambda_loss = -(lambda_vals * constraint_violations).sum(dim=-1).mean() + \
                      1e-6 * (lambda_vals ** 2).sum(dim=-1).mean()
        
        # Critic-y loss (behavior prediction)
        y_loss = nn.MSELoss()(q_vals, q_observed)
        
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
            self.rho *= 1.05
        
        return {
            'actor_loss': actor_loss.item(),
            'lambda_loss': lambda_loss.item(),
            'y_loss': y_loss.item(),
            'cvar': cvar.item(),
            'var': var.item(),
            'cvar_violation': cvar_violation.item(),
            'constraint_violations': constraint_violations.mean().item()
        }
```

## 📊 Backtesting with CVaR Constraints

### Simulation Setup

```python
# fks_training/src/backtest/cvar_backtest.py
import pandas as pd
import numpy as np
from fks_ai.src.rl.trainer_cvar import CVaRPrimalDualTrainer

class CVaRBacktest:
    """
    Backtest trading strategy with CVaR risk management.
    """
    def __init__(self, data: pd.DataFrame, alpha=0.95, cvar_threshold=0.1):
        self.data = data
        self.alpha = alpha
        self.cvar_threshold = cvar_threshold
        self.portfolio_value = 100000  # Initial $100k
        self.trades = []
        self.metrics = {
            'returns': [],
            'cvar': [],
            'var': [],
            'violations': []
        }
    
    def run(self, policy):
        """Run backtest with CVaR constraints."""
        for t in range(len(self.data) - 30):
            # Get rolling 30-day window
            window = self.data.iloc[t:t+30]
            
            # Current state
            state = self._compute_state(window)
            
            # Get action from policy
            action = policy.predict(state)
            
            # Simulate trade
            returns = self._execute_trade(action, window)
            
            # Compute CVaR
            cvar, var = compute_cvar_loss(torch.tensor(returns), self.alpha)
            
            # Check constraint
            violation = cvar > self.cvar_threshold
            
            # Record metrics
            self.metrics['returns'].append(returns.mean())
            self.metrics['cvar'].append(cvar.item())
            self.metrics['var'].append(var.item())
            self.metrics['violations'].append(int(violation))
        
        return self._compute_summary()
    
    def _compute_summary(self):
        """Compute backtest summary statistics."""
        returns = np.array(self.metrics['returns'])
        
        return {
            'total_return': (1 + returns).prod() - 1,
            'sharpe_ratio': returns.mean() / returns.std() * np.sqrt(252),
            'max_drawdown': self._max_drawdown(returns),
            'avg_cvar': np.mean(self.metrics['cvar']),
            'avg_var': np.mean(self.metrics['var']),
            'violation_rate': np.mean(self.metrics['violations'])
        }
    
    def _max_drawdown(self, returns):
        """Compute maximum drawdown."""
        cum_returns = (1 + returns).cumprod()
        running_max = np.maximum.accumulate(cum_returns)
        drawdown = (cum_returns - running_max) / running_max
        return drawdown.min()
```

### Expected Results

| Metric | Baseline (No CVaR) | CVaR-Constrained | Improvement |
|--------|-------------------|------------------|-------------|
| Total Return | 25.0% | 22.5% | -10% (trade-off) |
| Sharpe Ratio | 1.5 | 2.1 | +40% |
| Max Drawdown | -18% | -8% | +56% |
| CVaR (95%) | -12% | -7% | +42% |
| Violation Rate | 15% | 3% | +80% |

**Key Insight**: Slight return sacrifice (-10%) for significant risk reduction (-56% drawdown).

## 🔗 Integration with Existing FKS Components

### Connection to ASMBTR Strategy

```python
# fks_app/src/strategies/asmbtr_cvar.py
from fks_ai.src.rl.cvar_utils import compute_cvar_loss

class ASMBTRWithCVaR:
    """
    ASMBTR strategy with CVaR risk management.
    """
    def __init__(self, asmbtr_model, alpha=0.95, cvar_threshold=0.1):
        self.asmbtr = asmbtr_model
        self.alpha = alpha
        self.cvar_threshold = cvar_threshold
        self.recent_returns = []
    
    def predict(self, state):
        """
        Generate trading signal with CVaR check.
        """
        # Get ASMBTR signal
        signal = self.asmbtr.predict(state)
        
        # If recent returns available, check CVaR
        if len(self.recent_returns) >= 30:
            returns_tensor = torch.tensor(self.recent_returns[-30:])
            cvar, var = compute_cvar_loss(returns_tensor, self.alpha)
            
            # If CVaR violated, reduce position size
            if cvar > self.cvar_threshold:
                signal['amount'] *= 0.5  # Cut position in half
                signal['reason'] = f'CVaR threshold exceeded: {cvar:.3f} > {self.cvar_threshold}'
        
        return signal
    
    def update_returns(self, new_return):
        """Update return history."""
        self.recent_returns.append(new_return)
        if len(self.recent_returns) > 100:
            self.recent_returns.pop(0)
```

### PostgreSQL Schema Extension

```sql
-- Add to fks_main/sql/portfolio_tracking.sql
CREATE TABLE risk_metrics (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    var_95 DECIMAL(10, 6),
    cvar_95 DECIMAL(10, 6),
    var_99 DECIMAL(10, 6),
    cvar_99 DECIMAL(10, 6),
    violation BOOLEAN,
    threshold DECIMAL(10, 6)
);

CREATE INDEX idx_risk_timestamp ON risk_metrics(timestamp);
CREATE INDEX idx_risk_symbol ON risk_metrics(symbol);

-- Query for violations
SELECT symbol, COUNT(*) as violation_count
FROM risk_metrics
WHERE violation = TRUE AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY symbol
ORDER BY violation_count DESC;
```

### Prometheus Metrics

```python
# fks_main/monitoring/prometheus/cvar_metrics.py
from prometheus_client import Gauge, Histogram

# CVaR metrics
cvar_current = Gauge('fks_cvar_current', 'Current CVaR value', ['alpha', 'symbol'])
var_current = Gauge('fks_var_current', 'Current VaR value', ['alpha', 'symbol'])
cvar_violations = Counter('fks_cvar_violations_total', 'CVaR violation count', ['symbol'])
cvar_threshold = Gauge('fks_cvar_threshold', 'CVaR threshold setting', ['alpha'])

# Distribution metrics
return_distribution = Histogram('fks_return_distribution', 'Portfolio return distribution',
                               buckets=[-0.1, -0.05, -0.02, 0, 0.02, 0.05, 0.1, 0.2])
```

## 📈 Performance Monitoring

### Grafana Dashboard Panel

```json
{
  "title": "CVaR Risk Monitoring",
  "panels": [
    {
      "title": "CVaR vs Threshold",
      "targets": [
        {"expr": "fks_cvar_current{alpha='0.95'}"},
        {"expr": "fks_cvar_threshold{alpha='0.95'}"}
      ],
      "type": "graph"
    },
    {
      "title": "CVaR Violations (30d)",
      "targets": [
        {"expr": "sum(rate(fks_cvar_violations_total[30d]))"}
      ],
      "type": "stat"
    },
    {
      "title": "Return Distribution",
      "targets": [
        {"expr": "fks_return_distribution"}
      ],
      "type": "heatmap"
    }
  ]
}
```

## 🔗 References

### Primary Papers

1. **CVaR Constraints in Safe RL**: "Towards Safe Reinforcement Learning via Constraining Conditional Value at Risk" ([arXiv:2206.04436](https://arxiv.org/abs/2206.04436))
2. **Distributional RL**: "A Distributional Perspective on Reinforcement Learning" ([ICML 2017](https://proceedings.mlr.press/v70/bellemare17a.html))
3. **IQN**: "Implicit Quantile Networks for Distributional RL" ([NeurIPS 2018](https://arxiv.org/abs/1806.06923))
4. **QR-DQN**: "Distributional RL with Quantile Regression" ([AAAI 2018](https://arxiv.org/abs/1710.10044))
5. **Portfolio CVaR Optimization**: "Optimization of CVaR" ([Journal of Risk 2000](https://www.pm-research.com/content/iijrisk/3/1/21))

### FKS Integration Points

- [Portfolio Rebalancing](./06-portfolio-rebalancing.md) - Primal-dual framework
- [AI Trading Agents](./04-ai-trading-agents.md) - Multi-agent integration
- [Core Architecture](./01-core-architecture.md) - K8s deployment
- `/fks_ai/src/rl/` - RL models and trainers
- `/fks_training/src/backtest/` - Backtesting framework

## 🎯 Next Steps

1. ✅ Review CVaR mathematical foundations
2. ✅ Prototype CPPO/TRC algorithms with toy data
3. ⏸️ Integrate with existing PrimalDualTrainer
4. ⏸️ Backtest on historical crypto data (2023-24)
5. ⏸️ Deploy to fks_ai service in K8s
6. ⏸️ Set up Grafana CVaR monitoring dashboard
7. ⏸️ Run live paper trading with CVaR constraints

**Estimated Impact**: 10-20% drawdown reduction, +0.5-1.0 Sharpe ratio improvement, <10% constraint violations.
