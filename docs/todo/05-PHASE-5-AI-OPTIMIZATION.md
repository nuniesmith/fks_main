# Phase 5: AI Optimization Layer
## Weeks 6-8 | AI Optimization

**Duration**: 6-8 weeks (part-time)  
**Focus**: Enhance baseline with AI for adaptive intelligence  
**Goal**: AI-enhanced signals outperforming baseline in simulations with explanations

---

## 🎯 Phase Objectives

1. Integrate AI models for signal refinement
2. Implement advanced bias mitigation using AI
3. Create BTC-centric AI rules for long-term optimization
4. Validate AI improvements with backtesting

---

## 📋 Task Breakdown

### Task 5.1: AI Model Integration (Days 1-5)

**Objective**: Use fks_ai agents to refine signals

**Subtasks**:
- [ ] Integrate with fks_ai service:
  ```python
  # portfolio/src/ai/integration.py
  from fks_ai import AgentSystem
  
  class AISignalRefiner:
      def __init__(self):
          self.agents = AgentSystem()
          self.bull_agent = self.agents.get_agent("bull")
          self.bear_agent = self.agents.get_agent("bear")
      
      def refine_signal(self, baseline_signal):
          # Get bull and bear perspectives
          bull_analysis = self.bull_agent.analyze(baseline_signal)
          bear_analysis = self.bear_agent.analyze(baseline_signal)
          
          # Debate and refine
          refined_signal = self.debate_signals(bull_analysis, bear_analysis)
          return refined_signal
  ```
- [ ] Implement signal debate system:
  ```python
  # portfolio/src/ai/debate.py
  def debate_signals(bull_view, bear_view, baseline_signal):
      # Compare confidence levels
      # Adjust entry/TP/SL based on consensus
      # Return refined signal with explanation
  ```
- [ ] Add reinforcement learning for learning from backtests:
  ```python
  # portfolio/src/ai/rl_optimizer.py
  class RLOptimizer:
      def learn_from_backtest(self, backtest_results):
          # Use DDPG or similar RL algorithm
          # Learn optimal entry/TP/SL adjustments
          # Update policy
  ```
- [ ] Create AI signal output format:
  ```json
  {
    "signal": {...},
    "ai_enhancements": {
      "confidence": 0.85,
      "bull_consensus": 0.8,
      "bear_consensus": 0.2,
      "adjustments": {
        "entry": -0.5,
        "take_profit": +1.0,
        "stop_loss": -0.3
      },
      "explanation": "Bull agents strongly favor this signal..."
    }
  }
  ```

**Milestone**: AI system refines baseline signals with explanations

**Files to Create**:
- `portfolio/src/ai/integration.py`
- `portfolio/src/ai/debate.py`
- `portfolio/src/ai/rl_optimizer.py`
- `portfolio/tests/test_ai_integration.py`

**Dependencies**:
- fks_ai service running
- Access to agent system

---

### Task 5.2: Advanced Bias Mitigation (Days 6-8)

**Objective**: Train models on behavioral data to counter biases

**Subtasks**:
- [ ] Create bias detection model:
  ```python
  # portfolio/src/ai/bias_detector.py
  class BiasDetector:
      def detect_bias(self, user_decision, signal):
          # Analyze decision patterns
          # Identify overconfidence, loss aversion, etc.
          # Return bias type and mitigation suggestion
  ```
- [ ] Implement GPT-like prompts for bias countering:
  ```python
  # portfolio/src/ai/bias_prompts.py
  BIAS_PROMPTS = {
      "overconfidence": """
      Based on data, not confidence:
      - Your win rate is {win_rate}%
      - Recent performance: {recent_performance}
      - Recommendation: {recommendation}
      """,
      "loss_aversion": """
      Recent loss detected: {recent_loss}%
      Historical recovery: {recovery_rate}%
      Recommendation: {recommendation}
      """
  }
  ```
- [ ] Add behavioral coaching:
  ```python
  # portfolio/src/ai/coaching.py
  def provide_coaching(user_state, signal):
      if user_state.recent_loss > threshold:
          return "Based on data, not fear, recommend holding current positions"
      elif user_state.override_frequency > threshold:
          return "You've overridden {count} signals. Consider trusting the system more."
  ```

**Milestone**: AI provides bias mitigation suggestions

**Files to Create**:
- `portfolio/src/ai/bias_detector.py`
- `portfolio/src/ai/bias_prompts.py`
- `portfolio/src/ai/coaching.py`

---

### Task 5.3: BTC-Centric AI Rules (Days 9-12)

**Objective**: Prioritize BTC in long-term allocations using AI

**Subtasks**:
- [ ] Implement BTC allocation optimizer:
  ```python
  # portfolio/src/ai/btc_optimizer.py
  class BTCOptimizer:
      def optimize_btc_allocation(self, portfolio, market_state):
          # Use LSTM or similar for BTC price forecast
          btc_forecast = self.forecast_btc_price()
          
          # Adjust allocation to maximize BTC growth
          if btc_forecast.bullish:
              target_btc = 0.60  # Increase BTC allocation
          else:
              target_btc = 0.50  # Maintain minimum
          
          return target_btc
  ```
- [ ] Add predictive models for BTC:
  ```python
  # portfolio/src/ai/btc_predictor.py
  class BTCPredictor:
      def predict_price(self, lookback_days=90, forecast_days=30):
          # Use LSTM model trained on historical BTC data
          # Return price forecast with confidence intervals
  ```
- [ ] Create BTC rebalancing recommendations:
  ```python
  # portfolio/src/ai/btc_rebalancing.py
  def recommend_btc_rebalancing(portfolio, btc_forecast):
      current_btc = portfolio.btc_allocation
      target_btc = btc_optimizer.optimize_btc_allocation(portfolio)
      
      if current_btc < target_btc:
          return {
              "action": "INCREASE_BTC",
              "amount": (target_btc - current_btc) * portfolio.value,
              "rationale": "BTC forecast bullish, increase allocation"
          }
  ```

**Milestone**: AI optimizes BTC allocation based on forecasts

**Files to Create**:
- `portfolio/src/ai/btc_optimizer.py`
- `portfolio/src/ai/btc_predictor.py`
- `portfolio/src/ai/btc_rebalancing.py`
- `portfolio/tests/test_btc_ai.py`

---

### Task 5.4: AI Validation and Comparison (Days 13-14)

**Objective**: Validate AI improvements with backtesting

**Subtasks**:
- [ ] Run comparative backtests:
  ```python
  # portfolio/src/backtesting/ai_comparison.py
  def compare_baseline_vs_ai(start_date, end_date):
      baseline_results = backtest_baseline_signals(start_date, end_date)
      ai_results = backtest_ai_signals(start_date, end_date)
      
      return {
          "baseline": {
              "win_rate": baseline_results.win_rate,
              "sharpe": baseline_results.sharpe,
              "return": baseline_results.total_return
          },
          "ai_enhanced": {
              "win_rate": ai_results.win_rate,
              "sharpe": ai_results.sharpe,
              "return": ai_results.total_return
          },
          "improvement": {
              "win_rate_delta": ai_results.win_rate - baseline_results.win_rate,
              "sharpe_delta": ai_results.sharpe - baseline_results.sharpe
          }
      }
  ```
- [ ] Generate AI performance report:
  - Win rate improvement
  - Sharpe ratio improvement
  - Return improvement
  - Explanation quality metrics
- [ ] Document AI decision explanations:
  - Why AI adjusted entry/TP/SL
  - Confidence levels
  - Agent consensus

**Milestone**: AI-enhanced signals outperform baseline in simulations

**Files to Create**:
- `portfolio/src/backtesting/ai_comparison.py`
- `portfolio/notebooks/ai_validation.ipynb`

---

## ✅ Phase 5 Milestone

**Deliverable**: AI-enhanced signals outperforming baseline in simulations, with explanations for decisions.

**Success Criteria**:
- [ ] AI system refines baseline signals
- [ ] Bias mitigation active and providing suggestions
- [ ] BTC optimization working
- [ ] Backtest shows AI improvements (target: 10-20% better risk-adjusted returns)
- [ ] Explanations provided for all AI decisions

**Command to Run**:
```bash
# Generate AI-enhanced signals
python portfolio/src/cli.py --generate-signals --ai-enhanced

# Compare baseline vs AI
python portfolio/src/cli.py --compare-ai --start 2024-01-01 --end 2024-12-31
```

---

## 🔧 Technical Stack

- **fks_ai**: Existing AI agent system
- **LSTM/Transformer**: Time series forecasting (PyTorch/TensorFlow)
- **Reinforcement Learning**: DDPG or similar (Stable-Baselines3)
- **LLM Integration**: GPT-like models for bias mitigation

---

## 📚 References

- [Multi-period portfolio optimization using deep reinforcement learning](https://www.sciencedirect.com/science/article/pii/S0040162523006297)
- [Reducing emotional bias in investment decisions: the role of GPT-4](https://www.emerald.com/apjba/article/doi/10.1108/APJBA-03-2025-0181/1277501/Reducing-emotional-bias-in-investment-decisions)
- [PyTorch Time Series Tutorial](https://pytorch.org/tutorials/beginner/transformer_tutorial.html)

---

## 🚦 Next Phase

Once Phase 5 is complete, proceed to [06-PHASE-6-DEMO-ITERATION.md](06-PHASE-6-DEMO-ITERATION.md)

---

**Estimated Effort**: 50-60 hours (part-time over 6-8 weeks)

