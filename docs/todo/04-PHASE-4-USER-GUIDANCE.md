# Phase 4: User Guidance and Emotion-Free Features
## Weeks 5-6 | User Guidance & Emotion-Free

**Duration**: 5-6 weeks (part-time)  
**Focus**: Ensure system acts as comprehensive advisor, removing biases through structured outputs  
**Goal**: Web interface with guided signals, decision logs, and portfolio tracking

---

## 🎯 Phase Objectives

1. Build decision support module for various market scenarios
2. Integrate manual workflow for signal execution tracking
3. Create portfolio tracking and visualization
4. Implement emotion-free decision logging

---

## 📋 Task Breakdown

### Task 4.1: Decision Support Module (Days 1-3)

**Objective**: Generate options for any market situation

**Subtasks**:
- [ ] Create scenario handler:
  ```python
  # portfolio/src/guidance/scenarios.py
  class ScenarioHandler:
      def handle_market_crash(self, portfolio):
          options = [
              {
                  "action": "HOLD_BTC",
                  "rationale": "BTC serves as hedge during crashes",
                  "risk": "LOW"
              },
              {
                  "action": "HEDGE_WITH_STABLES",
                  "rationale": "Convert 20% to stablecoins",
                  "risk": "MEDIUM"
              },
              {
                  "action": "DIVERSIFY",
                  "rationale": "Add uncorrelated assets",
                  "risk": "MEDIUM"
              }
          ]
          return options
  ```
- [ ] Implement rule-based recommendations:
  ```python
  # portfolio/src/guidance/recommendations.py
  def generate_recommendation(market_state, portfolio_state):
      if market_state.volatility > threshold:
          return "RECOMMEND_LONG_TERM_BTC_HOLD"
      elif market_state.trend == "BULLISH":
          return "RECOMMEND_SWING_POSITIONS"
      else:
          return "RECOMMEND_CASH_POSITION"
  ```
- [ ] Add "what-if" analysis:
  ```python
  # portfolio/src/guidance/whatif.py
  def simulate_scenario(portfolio, action, market_assumptions):
      # Simulate portfolio value under different scenarios
      # Return expected outcomes
  ```

**Milestone**: System generates actionable recommendations for common scenarios

**Files to Create**:
- `portfolio/src/guidance/scenarios.py`
- `portfolio/src/guidance/recommendations.py`
- `portfolio/src/guidance/whatif.py`
- `portfolio/tests/test_guidance.py`

---

### Task 4.2: Manual Workflow Integration (Days 4-7)

**Objective**: Create signals page in fks_web with manual execution tracking

**Subtasks**:
- [ ] Create signals display page:
  ```python
  # fks_web/src/portfolio/views.py
  def signals_page(request):
      signals = signal_engine.scan_assets(assets)
      context = {
          "signals": signals,
          "filtered_count": len([s for s in signals if s.filtered])
      }
      return render(request, "portfolio/signals.html", context)
  ```
- [ ] Add signal action buttons:
  ```html
  <!-- fks_web/src/templates/portfolio/signals.html -->
  {% for signal in signals %}
  <div class="signal-card">
      <h3>{{ signal.asset }}</h3>
      <p>Entry: {{ signal.entry }}, TP: {{ signal.take_profit }}, SL: {{ signal.stop_loss }}</p>
      <button onclick="executeSignal({{ signal.id }})">Execute</button>
      <button onclick="dismissSignal({{ signal.id }})">Dismiss</button>
      <button onclick="modifySignal({{ signal.id }})">Modify</button>
  </div>
  {% endfor %}
  ```
- [ ] Implement execution logging:
  ```python
  # portfolio/src/execution/logger.py
  def log_execution(signal, action, user_override=False):
      execution = {
          "signal_id": signal.id,
          "action": action,  # "EXECUTED", "DISMISSED", "MODIFIED"
          "user_override": user_override,
          "timestamp": datetime.now()
      }
      # Store in database
  ```
- [ ] Track adherence to signals:
  ```python
  # portfolio/src/execution/adherence.py
  def calculate_adherence(user_executions):
      total_signals = len(user_executions)
      executed = len([e for e in user_executions if e.action == "EXECUTED"])
      adherence_rate = executed / total_signals
      
      # Warn if overriding too many signals
      if adherence_rate < 0.7:
          return "WARNING", "Low adherence to signals detected"
      return "OK", None
  ```
- [ ] Add email/Discord alerts (optional):
  ```python
  # portfolio/src/notifications/alerts.py
  def send_signal_alert(signal):
      message = f"New signal: {signal.asset} at {signal.entry}"
      # Send via email or Discord webhook
  ```

**Milestone**: Web interface displays signals with execution tracking

**Files to Create/Modify**:
- `fks_web/src/portfolio/views.py` - Add signals view
- `fks_web/src/templates/portfolio/signals.html` - Signals page
- `portfolio/src/execution/logger.py`
- `portfolio/src/execution/adherence.py`
- `portfolio/src/notifications/alerts.py` (optional)

---

### Task 4.3: Portfolio Tracking (Days 8-10)

**Objective**: Visualize portfolio performance in BTC terms

**Subtasks**:
- [ ] Create portfolio performance tracker:
  ```python
  # portfolio/src/tracking/performance.py
  class PortfolioTracker:
      def track_performance(self, portfolio, start_date, end_date):
          # Calculate daily portfolio value in BTC
          # Calculate returns, drawdowns
          # Generate performance metrics
  ```
- [ ] Build visualization components:
  ```python
  # fks_web/src/portfolio/charts.py
  def generate_portfolio_chart(portfolio_data):
      # Use matplotlib or Chart.js
      # Show portfolio value over time
      # Show allocation pie chart
      # Show performance vs BTC
  ```
- [ ] Display emotion-free metrics:
  - Sharpe ratio
  - Maximum drawdown
  - Win rate
  - Average return
  - BTC allocation percentage
- [ ] Create performance dashboard:
  ```html
  <!-- fks_web/src/templates/portfolio/performance.html -->
  <div class="performance-dashboard">
      <h2>Portfolio Performance</h2>
      <div class="metrics">
          <div class="metric">
              <label>Sharpe Ratio</label>
              <value>{{ sharpe_ratio }}</value>
          </div>
          <div class="metric">
              <label>Max Drawdown</label>
              <value>{{ max_drawdown }}%</value>
          </div>
          <!-- ... more metrics -->
      </div>
      <div class="chart">
          <canvas id="portfolioChart"></canvas>
      </div>
  </div>
  ```

**Milestone**: Portfolio tracking dashboard displays performance metrics

**Files to Create**:
- `portfolio/src/tracking/performance.py`
- `fks_web/src/portfolio/charts.py`
- `fks_web/src/templates/portfolio/performance.html`
- `fks_web/src/static/js/portfolio-charts.js`

---

### Task 4.4: Decision Logging and Review (Days 11-14)

**Objective**: Track all decisions for bias analysis

**Subtasks**:
- [ ] Create decision log database schema:
  ```python
  # portfolio/src/db/models.py
  class DecisionLog(models.Model):
      timestamp = models.DateTimeField()
      signal = models.JSONField()
      action = models.CharField()  # EXECUTED, DISMISSED, MODIFIED
      user_override = models.BooleanField()
      rationale = models.TextField()
      outcome = models.JSONField(null=True)  # Filled after trade closes
  ```
- [ ] Build decision review interface:
  ```python
  # fks_web/src/portfolio/views.py
  def decision_log(request):
      logs = DecisionLog.objects.all().order_by('-timestamp')
      context = {
          "logs": logs,
          "adherence_rate": calculate_adherence(logs)
      }
      return render(request, "portfolio/decision_log.html", context)
  ```
- [ ] Add bias analysis:
  ```python
  # portfolio/src/analysis/bias_analysis.py
  def analyze_bias_patterns(decision_logs):
      # Find patterns like: "always dismissing swing signals"
      # Calculate override frequency by signal type
      # Identify emotional triggers
  ```
- [ ] Generate weekly review report:
  - Signals generated vs executed
  - Override frequency
  - Performance of executed vs dismissed signals
  - Recommendations for improvement

**Milestone**: Decision logging active with review interface

**Files to Create**:
- `portfolio/src/db/models.py` - DecisionLog model
- `fks_web/src/templates/portfolio/decision_log.html`
- `portfolio/src/analysis/bias_analysis.py`

---

## ✅ Phase 4 Milestone

**Deliverable**: Web interface where you input scenarios and receive guided signals, with logs of past decisions.

**Success Criteria**:
- [ ] Signals page displays all generated signals
- [ ] Manual execution tracking works
- [ ] Portfolio performance dashboard functional
- [ ] Decision logs recorded and reviewable
- [ ] Adherence tracking active

**URLs to Access**:
```
http://localhost:8000/portfolio/signals
http://localhost:8000/portfolio/performance
http://localhost:8000/portfolio/decisions
```

---

## 🔧 Technical Stack

- **Django**: Web framework
- **Chart.js/D3.js**: Visualization
- **Matplotlib**: Backend chart generation
- **Database**: PostgreSQL or SQLite

---

## 📚 References

- [Django Forms Documentation](https://docs.djangoproject.com/en/5.1/topics/forms/)
- [Chart.js Documentation](https://www.chartjs.org/)
- [Emotion-Free Trading Strategies](https://www.investopedia.com/articles/trading/08/emotional-trading.asp)

---

## 🚦 Next Phase

Once Phase 4 is complete, proceed to [05-PHASE-5-AI-OPTIMIZATION.md](05-PHASE-5-AI-OPTIMIZATION.md)

---

**Estimated Effort**: 30-40 hours (part-time over 5-6 weeks)

