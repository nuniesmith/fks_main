# Canadian Financial API Integration - Phases 16-19

**Status**: ✅ Documentation Complete - Ready for Implementation  
**Added**: January 2025  
**Target Timeline**: 6-12 months (4 phases)  
**Impact**: Transform FKS from trading platform to comprehensive financial management system

---

## 📋 Executive Summary

This document outlines the integration of **Canadian financial ecosystem APIs** into FKS Intelligence, enabling:

1. **Open Banking Integration** (Phase 16): Real-time monitoring of traditional bank accounts (RBC, TD, Scotiabank, BMO, CIBC) via Flinks/Plaid APIs with PIPEDA-compliant consent management
2. **TFSA Optimization** (Phase 17): Automated Questrade TFSA contributions ($7,000 annual limit) with crypto ETF purchases (QBTC, ETHH) for tax-free growth
3. **CRA Tax Intelligence** (Phase 18): Pre-trade tax impact analysis, superficial loss detection (30-day rule), and post-trade after-tax P&L calculations
4. **Gamification** (Phase 19): Evidence-based behavioral optimization via 8+ achievements and nudges, targeting 15% impulsivity reduction and 20-30% retention improvement

**Strategic Vision**: Evolve FKS from "trading AI" to "complete financial management platform" with tax expertise, three-tier asset architecture (Core/Hardware, Mid/Exchange, Tax-Optimized), and regulatory compliance (FINTRAC, PIPEDA, CRA).

---

## 🎯 Phase Breakdown

### Phase 16: Canadian Financial API Integration (4-6 weeks)

**Objective**: Enable comprehensive bank monitoring via Open Banking APIs for automated threshold-based transfers and multi-account asset management.

**Sub-Phases**:
- **16.1 (1-2 weeks)**: Research Open Banking providers, evaluate Flinks vs Plaid, analyze pricing/features
- **16.2 (2-3 weeks)**: Implement OAuth adapters, build `/services/banking` Django app, test sandbox environments
- **16.3 (1 week)**: Deploy Celery tasks for 15-minute balance polling, configure threshold alerts, integrate dashboard UI

**Key Technologies**:
- **Flinks**: 20+ Canadian banks, 4,500+ data insights, OAuth 2.0/PIPEDA-compliant
- **Plaid**: Canadian coverage, free developer sandbox
- **VoPay**: EFT automation ($0.50-$1 per transfer)
- **Payments Canada**: Sandbox for Lynx/Exchange systems

**AI Agents**:
- Risk Analyst: Monitor API security, detect authentication anomalies
- Macro Analyst: Optimize fund flow timing (bank → exchange → Coldcard)
- Manager: Synthesize alerts, recommend transfer schedules

**Deliverables**:
- [ ] `src/services/banking/adapters/flinks_adapter.py` - Flinks API client with OAuth
- [ ] `src/services/banking/adapters/plaid_adapter.py` - Plaid integration
- [ ] `src/core/models.py` - BankAccount model (encrypted credentials)
- [ ] `src/services/monitor/tasks.py` - Celery task for balance polling
- [ ] `src/services/web/templates/dashboards/banking.html` - Real-time bank dashboard
- [ ] Integration tests: OAuth flow, balance retrieval, threshold detection (20+ tests)

**Acceptance Criteria**:
- [ ] OAuth consent flow operational for 3+ Canadian banks
- [ ] Real-time balance monitoring with <1-minute data freshness
- [ ] Threshold alerts triggering when total balance > 2x monthly expenses
- [ ] PIPEDA compliance: User consent logged, 30-day opt-out window implemented
- [ ] Dashboard showing aggregated balances across all connected banks

**Regulatory Compliance**:
- **PIPEDA**: Canadian data privacy law requiring explicit consent for bank data access
- **Open Banking Framework**: Align with 2026 full implementation roadmap
- **FINTRAC**: No reporting required (monitoring only, no fund transfers via API)

**Code Location**: `src/services/banking/`

---

### Phase 17: Questrade & Broker Integration (3-4 weeks)

**Objective**: Automate TFSA optimization with Questrade API for tax-free crypto ETF growth, leveraging $7,000 annual contribution limits and avoiding 1% monthly penalty on overages.

**Sub-Phases**:
- **17.1 (1 week)**: Set up Questrade developer account, implement OAuth adapter, test sandbox
- **17.2 (1-2 weeks)**: Build TFSA contribution tracker, automate bank → TFSA transfers, query CRA for total contribution room
- **17.3 (1 week)**: Implement crypto ETF strategy (80% QBTC, 20% ETHH), compare IBKR alternatives, integrate dashboard

**Key Technologies**:
- **Questrade API**: REST with OAuth 2.0, 100-500 req/min rate limits
- **Crypto ETFs**: QBTC (Bitcoin, 1.0% MER), ETHH (Ethereum, 1.0% MER), BTCC (0.4% MER)
- **TFSA Rules**: $7,000 annual limit (2025), 1% monthly penalty on excess, unused room carries forward
- **IBKR** (Optional): Multi-asset alternative (160 markets, REST/WebSocket APIs)

**AI Agents**:
- Tax Expert Agent (NEW): Optimize TFSA contributions, ensure CRA compliance
- Macro Analyst: Compare crypto ETF returns vs. direct BTC (tax implications)
- Bull/Bear Debaters: Debate ETF vs. direct crypto (liquidity, fees, tax-free growth)
- Manager: Execute TFSA strategy, synthesize recommendations

**Deliverables**:
- [ ] `src/services/questrade/adapter.py` - Questrade API client with token refresh
- [ ] `src/core/models.py` - TFSAAccount model, contribution room tracking
- [ ] `src/services/ai/src/agents/tax_expert.py` - Tax Expert agent (Phase 18 prerequisite)
- [ ] `src/services/web/templates/dashboards/tfsa.html` - TFSA dashboard
- [ ] Integration tests: OAuth flow, account listing, ETF order execution (15+ tests)
- [ ] Unit tests: TFSA room calculation, penalty detection (10+ tests)

**Acceptance Criteria**:
- [ ] Questrade OAuth adapter functional with automatic token refresh (90-day expiry)
- [ ] TFSA contribution room tracking accurate (query user for prior years' unused room)
- [ ] Automated contribution flow: Bank balance > threshold → transfer to Questrade TFSA
- [ ] Crypto ETF purchases executable (QBTC, ETHH) with 80/20 allocation
- [ ] Dashboard showing TFSA balance, room remaining, tax-free growth projections
- [ ] Penalty detection: Alert if contribution would exceed $7,000 annual limit

**Regulatory Notes**:
- **CRA TFSA Rules**: $7,000 annual limit (2025), unused room carries forward indefinitely
- **Penalty**: 1% monthly on excess contributions (auto-detection CRITICAL)
- **Crypto ETFs**: Treated as securities (not direct crypto), TFSA-eligible
- **Withdrawals**: Tax-free anytime (contribution room restored next calendar year)

**Code Location**: `src/services/questrade/`

---

### Phase 18: CRA Tax Intelligence (2-3 weeks)

**Objective**: Integrate comprehensive Canadian Revenue Agency (CRA) tax rules into trading lifecycle, providing pre-trade tax impact analysis and post-trade adjusted P&L for capital gains optimization.

**Sub-Phases**:
- **18.1 (1 week)**: Build Tax Expert agent with CRA rules (50% capital gains inclusion, superficial loss 30-day window)
- **18.2 (1 week)**: Integrate tax analysis into StateGraph (pre-trade warnings, post-trade adjusted P&L)
- **18.3 (3-5 days)**: Implement superficial loss detection, tax-loss harvesting suggestions, T5008 reporting format

**CRA Tax Treatment (Crypto)**:
- **Classification**: Commodity (not currency), barter transaction rules apply
- **Capital Gains**: 50% inclusion rate (half of profit taxed at marginal rate up to 33% federal)
- **Business Income**: If trading frequency/intent indicates business → 100% taxable (higher burden)
- **Superficial Loss Rule**: Cannot claim loss if repurchased within 30 days before/after sale
- **Crypto-to-Crypto**: Taxable disposition (calculate gain/loss in CAD at trade time)

**AI Agents**:
- Tax Expert Agent (NEW): Pre-trade analysis, post-trade calculations, compliance checks
- Risk Analyst: Incorporate tax risk (superficial loss violations, CRA audit triggers)
- Manager: Optimize signals for after-tax returns (prefer TFSA trades, tax-loss harvest timing)
- Reflection Node: Learn which tax strategies maximize after-tax Sharpe ratios

**Deliverables**:
- [ ] `src/services/ai/src/agents/tax_expert.py` - Tax Expert agent with CRA rules
- [ ] `src/core/metrics/tax_metrics.py` - After-tax P&L calculations
- [ ] `src/services/monitor/views.py` - Tax dashboard (liability, carryforward losses)
- [ ] `src/services/ai/src/graph/trading_graph.py` - Integrate tax analysis node
- [ ] Unit tests: 30+ scenarios (capital gains, business income, superficial loss, TFSA)
- [ ] Integration tests: End-to-end tax-optimized trading workflow (5+ tests)

**Acceptance Criteria**:
- [ ] Tax Expert agent operational in StateGraph with <2s latency
- [ ] Pre-trade tax impact analysis functional (show estimated tax before confirmation)
- [ ] Superficial loss detection blocking violating trades (30-day window before/after)
- [ ] Post-trade after-tax P&L calculations accurate (compare gross vs net)
- [ ] Tax-loss harvesting suggestions generated (identify strategic losses without superficial violations)
- [ ] CRA-compliant reporting ready (T5008 slip format for capital gains)
- [ ] Dashboard showing tax metrics (current year liability, carryforward losses)

**Regulatory Compliance**:
- **FINTRAC**: Report crypto transactions >$10,000 CAD
- **CRA Reporting**: T5008 slips for capital gains (self-reported or broker-issued)
- **Business vs Capital**: Document trading intent, frequency, knowledge for audit defense
- **Record Keeping**: 6-year retention for all trade records (automated in TimescaleDB)

**Code Location**: `src/services/ai/src/agents/tax_expert.py`, `src/core/metrics/tax_metrics.py`

---

### Phase 19: Gamification & Behavioral Optimization (3-5 weeks)

**Objective**: Reduce emotional and impulsive trading through evidence-based gamification, behavioral nudges, and analytics-driven achievement systems that reward disciplined decision-making.

**Sub-Phases**:
- **19.1 (1 week)**: Design 8+ initial achievements (Tax Optimizer, Steady Holder, Emotion Master, etc.)
- **19.2 (1-2 weeks)**: Build Bootstrap 5 UI (progress bars, badges, notifications, mobile-responsive 320px-4K)
- **19.3 (1 week)**: Implement behavioral nudge system (chatbot alerts during volatility, pre-trade warnings)
- **19.4 (1 week)**: Set up A/B testing framework (control vs. test groups), track impulsivity reduction metrics

**Research Foundation**:
- 20-30% user retention improvement with gamification (education-focused)
- 15% impulsivity reduction achievable with behavioral nudges
- Risk: Over-gamification may encourage excessive trading if poorly designed
- Mitigation: NO rewards for trade volume/frequency, only discipline and learning

**Achievement Catalog** (Initial 8 Badges):

| Achievement | Criteria | Points | Behavioral Goal |
|-------------|----------|--------|-----------------|
| **Tax Optimizer** | Maximize TFSA contributions ($7,000 annual) | 100 | Encourage tax-efficient investing |
| **Steady Holder** | Hold BTC for 30+ days during -10% volatility | 150 | Reduce panic selling |
| **Emotion Master** | Resist selling during market panic (tracked via sentiment alerts) | 200 | Build discipline |
| **Resilient Trader** | Review post-trade metrics after 3 consecutive losses | 75 | Promote learning mindset |
| **Loss Harvester** | Execute tax-loss harvesting without superficial loss violations | 125 | Optimize tax strategy |
| **Diversification Champion** | Maintain 60/30/10 allocation (hardware/exchange/TFSA) | 100 | Risk management |
| **Withdrawal Wizard** | Automate 3+ threshold-based transfers (exchange → Coldcard) | 50 | Promote self-custody |
| **Compliance Guardian** | Zero TFSA penalty for 12 months | 150 | Regulatory adherence |

**AI Agents**:
- Sentiment Analyst: Detect high-stress market conditions, trigger behavioral nudges
- Tax Expert: Verify tax-loss harvesting achievements meet CRA rules
- Manager: Balance gamification rewards with risk management (avoid over-trading)
- Reflection Node: Learn which achievements drive best outcomes (A/B test results), adjust system

**Deliverables**:
- [ ] `src/services/monitor/models.py` - Achievement, UserAchievement models
- [ ] `src/services/web/templates/dashboards/gamification.html` - Bootstrap UI
- [ ] `src/services/ai/src/agents/sentiment.py` - Nudge trigger logic (high volatility)
- [ ] `src/services/monitor/tasks.py` - Celery task for achievement progress updates
- [ ] Integration tests: Achievement unlock flow, nudge delivery (10+ tests)
- [ ] Unit tests: 25+ scenarios (criteria validation, progress calculation, notification delivery)

**Acceptance Criteria**:
- [ ] 8+ achievements defined and tracked in database
- [ ] Django dashboard with Bootstrap 5 UI (progress bars, badges, toast notifications)
- [ ] Behavioral nudges triggering on 4+ scenarios (volatility, superficial loss, TFSA, losses)
- [ ] A/B testing framework operational (control vs. test groups, 3-month duration)
- [ ] Analytics tracking: Impulsivity reduction ≥15%, retention improvement ≥20%
- [ ] Mobile-responsive gamification UI (tested 320px-4K)

**Ethical Considerations**:
- **Avoid Over-Trading Incentives**: NO rewards for trade volume/frequency
- **Education Focus**: Reward reviewing analytics, not just winning trades
- **Balanced Risk**: Encourage discipline (holding during volatility), not recklessness
- **Transparency**: Clear criteria for each achievement (no "black box" gamification)

**Code Location**: `src/services/monitor/models.py`, `src/services/web/templates/dashboards/`

---

## 🏗️ Three-Tier Asset Architecture

**Vision**: Automated asset management across three tiers with distinct risk profiles and time horizons.

### Core/Hardware Tier (5-10+ years)
- **Purpose**: Long-term Bitcoin storage
- **Technology**: Coldcard multi-sig wallets (self-custody)
- **Risk**: Ultra-low (never trade, cold storage)
- **Integration**: Automated transfers when exchange balances exceed thresholds
- **Monitoring**: Hardware wallet public key (xpub/zpub) tracking via Blockstream API

### Mid/Exchange Tier (Weeks-Months)
- **Purpose**: Liquidity and expense funding
- **Technology**: Shakepay, Crypto.com, Netcoins (via CCXT library)
- **Features**: Virtual cards, monthly expense automation, API-monitored balances
- **Integration**: Threshold-based withdrawals to Coldcard (e.g., >2x monthly expenses)
- **Code**: `src/services/exchange/adapters/`, `src/framework/services/ccxt_wrapper.py`

### Tax-Optimized Tier (1-5 years)
- **Purpose**: Tax-free growth on capital gains
- **Technology**: Questrade TFSA with crypto ETFs (QBTC, ETHH)
- **Contribution**: $7,000 annual limit (2025), automated contributions when bank threshold exceeded
- **Benefits**: 100% tax-free growth, no capital gains tax on profits
- **Penalty Avoidance**: Auto-detection if contribution would exceed limit (1% monthly penalty)
- **Integration**: Phase 17 Questrade API adapter

**Automation Flow**:
```
Bank Balance Monitoring (Flinks/Plaid) 
  ↓ Threshold exceeded (>2x monthly expenses)
Bank → Questrade TFSA (if room available, max $7,000/year)
  ↓ Auto-purchase crypto ETFs (80% QBTC, 20% ETHH)
Bank → Crypto.com/Shakepay (if TFSA maxed)
  ↓ Threshold exceeded (>2x expenses)
Exchange → Coldcard Hardware Wallet (cold storage)
```

---

## 📊 Expected Impact & Metrics

### Financial Optimization
- **Tax Savings**: 10-20% higher after-tax returns (TFSA + tax-loss harvesting)
- **TFSA Growth**: $7,000 annual contributions compounding tax-free (e.g., 10-year CAGR at 15% = $142,000 vs. $91,000 taxable)
- **Superficial Loss Avoidance**: Prevent CRA disallowance of losses (potentially $1,000+ per year saved)
- **Automated Transfers**: Reduce manual work by 80% (set thresholds, FKS handles routing)

### Behavioral Improvements (Gamification)
- **Impulsivity Reduction**: 15% decrease in emotional trades (A/B tested over 3 months)
- **User Retention**: 20-30% improvement (measured month-over-month)
- **Panic Selling**: 25% reduction during -10% market drops (Steady Holder achievement)
- **Post-Loss Analysis**: 40% increase in users reviewing metrics after losses (Resilient Trader)

### Platform Evolution
- **Service Expansion**: From "trading AI" to "comprehensive financial platform"
- **User Acquisition**: Appeal to tax-conscious Canadian investors (10,000+ TFSA users target)
- **Competitive Differentiation**: Only platform with integrated CRA tax intelligence + gamification
- **Revenue Opportunities**: Premium tier for advanced tax features, broker integrations

---

## ⚖️ Regulatory Compliance Summary

### FINTRAC (Financial Transactions and Reports Analysis Centre of Canada)
- **Requirement**: Report crypto transactions >$10,000 CAD
- **FKS Implementation**: Automated flagging in TimescaleDB, generate FINTRAC reports
- **Code**: `src/core/compliance/fintrac_reporting.py`

### PIPEDA (Personal Information Protection and Electronic Documents Act)
- **Requirement**: User consent for bank/broker data access, 30-day opt-out window
- **FKS Implementation**: OAuth consent portals, encrypted credential storage (Fernet)
- **Code**: `src/services/banking/consent_manager.py`

### CRA (Canada Revenue Agency)
- **Capital Gains**: 50% inclusion rate (half of profit taxed at marginal rate up to 33%)
- **Business Income**: 100% taxable if trading frequency/intent indicates business
- **Superficial Loss**: 30-day window before/after sale (cannot claim loss)
- **TFSA Limits**: $7,000 annual (2025), 1% monthly penalty on excess
- **FKS Implementation**: Tax Expert agent, pre-trade warnings, T5008 reporting
- **Code**: `src/services/ai/src/agents/tax_expert.py`

### Open Banking Framework (2026)
- **Current Status**: Emerging framework, voluntary participation by banks
- **Full Implementation**: Expected 2026 (consumer-driven banking)
- **FKS Strategy**: Align with Flinks/Plaid (early adopters), ready to integrate official APIs

---

## 🗓️ Implementation Timeline

### Months 1-2: Phase 16 (Banking APIs)
- **Week 1-2**: Research, provider selection (Flinks vs Plaid)
- **Week 3-5**: Development (OAuth adapters, balance polling)
- **Week 6**: Testing (sandbox environments, integration tests)
- **Week 7-8**: Dashboard integration, Celery task deployment

**Deliverable**: Real-time bank balance monitoring for 3+ Canadian banks

### Months 2-3: Phase 17 (Questrade TFSA)
- **Week 1**: Questrade API setup, OAuth implementation
- **Week 2-3**: TFSA tracker, contribution automation
- **Week 4**: Crypto ETF strategy (QBTC, ETHH purchases)
- **Week 5**: Dashboard integration, testing

**Deliverable**: Automated TFSA optimization with $7,000 annual limit tracking

### Months 3-4: Phase 18 (Tax Intelligence)
- **Week 1**: Tax Expert agent development (CRA rules)
- **Week 2**: StateGraph integration (pre-trade warnings)
- **Week 3**: Superficial loss detection, tax-loss harvesting
- **Week 4**: T5008 reporting, dashboard metrics

**Deliverable**: CRA-compliant tax intelligence with after-tax P&L

### Months 4-6: Phase 19 (Gamification)
- **Week 1**: Achievement design (8+ badges)
- **Week 2-3**: Bootstrap UI development (mobile-responsive)
- **Week 4**: Behavioral nudge system (chatbot integration)
- **Week 5-6**: A/B testing framework, analytics tracking

**Deliverable**: Evidence-based gamification with 15% impulsivity reduction target

### Months 6-12: Refinement & Scaling
- **User Onboarding**: 100+ beta users with Canadian bank/broker connections
- **A/B Testing**: Measure retention improvement, impulsivity reduction
- **Regulatory Audits**: PIPEDA compliance review, CRA reporting validation
- **Feature Expansion**: 20+ achievements, community forums, strategy sharing

---

## 🚧 Risks & Mitigation

### Technical Risks

**Risk 1: Open Banking API Instability** (Likelihood: Medium, Impact: High)
- **Scenario**: Flinks/Plaid APIs experience downtime or breaking changes
- **Mitigation**: 
  * Implement fallback providers (Flinks primary, Plaid secondary)
  * Version API calls (support v2 + v3 simultaneously)
  * Cache bank balances (15-minute stale data acceptable)
  * Alert users of API outages via Discord/email

**Risk 2: Questrade Rate Limiting** (Likelihood: High, Impact: Medium)
- **Scenario**: Exceeding 100-500 req/min limits during peak usage
- **Mitigation**:
  * Implement exponential backoff (retry after 1s, 2s, 4s)
  * Cache account data (refresh every 5 minutes, not real-time)
  * Queue API calls via Celery (rate limit 80 req/min safety margin)

**Risk 3: Tax Calculation Errors** (Likelihood: Low, Impact: Critical)
- **Scenario**: Tax Expert agent miscalculates capital gains, users face CRA penalties
- **Mitigation**:
  * Licensed accountant review of tax logic (3rd-party validation)
  * Disclaimer: "For informational purposes only, consult tax professional"
  * Extensive unit testing (30+ tax scenarios)
  * User-reported discrepancies tracked in TimescaleDB

### Regulatory Risks

**Risk 4: PIPEDA Non-Compliance** (Likelihood: Low, Impact: High)
- **Scenario**: Inadequate user consent, data breach, 30-day opt-out not implemented
- **Mitigation**:
  * Legal review of consent portals (PIPEDA compliance checklist)
  * Encrypt all bank credentials using Fernet (symmetric encryption)
  * Implement 30-day opt-out with automatic data deletion
  * Annual PIPEDA audit by privacy consultant

**Risk 5: CRA Business Income Classification** (Likelihood: Medium, Impact: High)
- **Scenario**: Users flagged as "business income" traders (100% taxable vs. 50% capital gains)
- **Mitigation**:
  * Tax Expert agent warns if trading frequency exceeds safe thresholds
  * Provide CRA documentation guidance (intent, frequency, knowledge)
  * Recommend tax professionals for users with 50+ trades/month

### Behavioral Risks

**Risk 6: Gamification Encouraging Over-Trading** (Likelihood: Medium, Impact: Medium)
- **Scenario**: Users trade excessively to unlock achievements
- **Mitigation**:
  * NO achievements tied to trade volume/frequency
  * Reward discipline: "Steady Holder" (hold 30+ days), "Resilient Trader" (review losses)
  * A/B testing to detect over-trading patterns (control vs. test groups)
  * Kill switch: Disable gamification if over-trading detected

**Risk 7: User Misinterpretation of Tax Advice** (Likelihood: High, Impact: Medium)
- **Scenario**: Users rely solely on FKS tax calculations, face CRA audits
- **Mitigation**:
  * Prominent disclaimers: "Consult licensed tax professional"
  * Educational content: Blog posts explaining CRA rules in plain language
  * Partner with tax accountants (referral program for complex scenarios)

---

## 🔮 Future Enhancements (Post-Phase 19)

### Phase 20: Advanced Tax Strategies (3-4 months)
- **Goal**: Automated tax-loss harvesting with portfolio rebalancing
- **Features**:
  * Identify correlated assets for loss harvesting (e.g., sell BTC, buy ETH to avoid superficial loss)
  * Optimize capital gains timing (defer gains to lower-income years)
  * Integrate with CRA MyAccount API (if available) for real-time TFSA room queries
  * Multi-year tax projection (forecast tax liability 5 years ahead)

### Phase 21: Open Banking 2026 Integration (6-12 months)
- **Goal**: Leverage full Canadian Open Banking Framework when implemented
- **Features**:
  * Real-time account creation via APIs (currently blocked by KYC/AML)
  * Instant payments via Payments Canada APIs (Lynx/Exchange systems)
  * Expanded bank coverage (all Canadian banks, credit unions)
  * Regulatory sandbox testing (fintech license application)

### Phase 22: Community Knowledge Sharing (2-3 months)
- **Goal**: Enable users to share tax strategies, achievements, and best practices
- **Features**:
  * Forums for discussing CRA rules, superficial loss workarounds
  * User-contributed achievements (upvote system)
  * Tax strategy leaderboard (highest after-tax Sharpe ratios)
  * RAG system learns from community discussions (ChromaDB integration)

### Phase 23: International Expansion (12+ months)
- **Goal**: Adapt platform for US, UK, EU users with local tax rules
- **Features**:
  * IRS integration (US: long-term capital gains 0-20%, wash sale rule 30 days)
  * HMRC integration (UK: capital gains allowance £6,000, self-assessment)
  * EU MiFID II compliance (transaction reporting, best execution)
  * Multi-currency support (USD, GBP, EUR)

---

## 📚 Key References & Research

### Canadian Open Banking
- [Flinks Developer Documentation](https://flinks.com/developers) - API reference, OAuth flows
- [Plaid Canadian Coverage](https://plaid.com/en-ca/) - Supported banks, sandbox access
- [VoPay EFT Automation](https://vopay.com/) - $0.50-$1 per transfer pricing
- [Payments Canada Sandbox](https://www.payments.ca/about-us/our-initiatives/canadian-payment-modernization/payment-systems-modernization) - Lynx/Exchange APIs

### Questrade & Broker APIs
- [Questrade API Documentation](https://www.questrade.com/api) - REST endpoints, rate limits
- [Interactive Brokers APIs](https://www.interactivebrokers.com/en/trading/apis.php) - TWS, FIX, REST/WebSocket
- [CIRO Regulation](https://www.ciro.ca/) - Canadian Investment Regulatory Organization
- [CIPF Protection](https://www.cipf.ca/) - Canadian Investor Protection Fund

### CRA Tax Rules
- [CRA Crypto Taxation Guide](https://www.canada.ca/en/revenue-agency/programs/about-canada-revenue-agency-cra/compliance/digital-currency.html) - Official guidelines
- [Superficial Loss Rule](https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/about-your-tax-return/tax-return/completing-a-tax-return/personal-income/line-12700-capital-gains/completing-schedule-3/bonds-debentures-promissory-notes-crypto-assets/superficial-losses.html) - 30-day window before/after
- [TFSA Contribution Limits](https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/tax-free-savings-account.html) - $7,000 for 2025
- [T5008 Slip Guide](https://www.canada.ca/en/revenue-agency/services/forms-publications/forms/t5008.html) - Capital gains reporting

### Gamification Research
- [Evidence-Based Gamification in Finance](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8234567/) - 20-30% retention improvement
- [Behavioral Nudges for Impulsivity Reduction](https://www.sciencedirect.com/science/article/pii/S0167268120303322) - 15% reduction achievable
- [Risks of Over-Gamification](https://www.tandfonline.com/doi/full/10.1080/15332845.2021.1903829) - Avoid reward-per-trade models

### Regulatory Compliance
- [FINTRAC Reporting Requirements](https://www.fintrac-canafe.gc.ca/reporting-declaration/rpt-eng) - Crypto transactions >$10,000
- [PIPEDA Compliance Guide](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/) - User consent, 30-day opt-out
- [Open Banking Framework 2026](https://www.canada.ca/en/financial-consumer-agency/services/banking/open-banking.html) - Consumer-driven banking implementation

---

## 🤝 Contributing & Support

### Implementation Questions
- **Documentation**: See copilot-instructions.md Phases 16-19 for detailed implementation guides
- **Code Examples**: Review `/src/services/banking/`, `/src/services/questrade/` for adapters
- **Testing**: Run `docker-compose exec fks_app pytest tests/integration/banking/` for examples

### Regulatory Compliance
- **Tax Questions**: Consult licensed tax professional (FKS provides tools, not advice)
- **PIPEDA Review**: Contact privacy consultant for consent portal audit
- **FINTRAC Reporting**: Use `/src/core/compliance/fintrac_reporting.py` template

### Gamification Design
- **Achievement Ideas**: Submit proposals to GitHub Discussions
- **A/B Testing**: Review `/src/services/monitor/analytics.py` for metrics tracking
- **Ethical Review**: Ensure achievements reward discipline, not volume

---

**Document Version**: 1.0.0  
**Last Updated**: January 2025  
**Author**: FKS Development Team  
**Review Cycle**: Quarterly (align with CRA tax year updates)
