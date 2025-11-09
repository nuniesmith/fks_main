# 🎯 Next Steps Roadmap

**Last Updated**: Based on current AI/ML implementation status

## 📊 Priority 1: Critical Integration (This Week)

### 1. Connect fks_training to fks_data Service
**Status**: ⚠️ TODO in code  
**Impact**: HIGH - Blocks end-to-end ML pipeline  
**Effort**: 2-3 days

**Current Issue**: Training script has placeholder for data loading
```python
# TODO: Load from fks_data service or database
raise NotImplementedError("Data loading from service not yet implemented")
```

**Tasks**:
- [ ] Create data client in `fks_training` to call `fks_data` API
- [ ] Implement database query fallback (if using shared DB)
- [ ] Add data caching layer for training efficiency
- [ ] Test with real market data

**Files to Modify**:
- `repo/training/src/domain/ml/training/train.py` - `load_data()` function
- Create: `repo/training/src/infrastructure/data_client.py`

---

### 2. Complete ML API Features
**Status**: ⚠️ TODOs in code  
**Impact**: MEDIUM - Enhances prediction quality  
**Effort**: 1-2 days

**Missing Features**:
- [ ] Confidence intervals calculation (uncertainty quantification)
- [ ] Feature importance extraction from predictions

**Files to Modify**:
- `repo/api/src/routes/v1/ml.py` - `/predict` endpoint

---

## 📊 Priority 2: Advanced Features (Next 2 Weeks)

### 3. Enhanced Backtesting Framework
**Status**: 🟡 Partial  
**Impact**: HIGH - Critical for strategy validation  
**Effort**: 3-5 days

**Tasks**:
- [ ] Integrate Backtrader or Zipline
- [ ] Add realistic transaction costs and slippage
- [ ] Implement walk-forward analysis
- [ ] Add performance metrics (Sharpe, drawdown, win rate)

**Files**:
- `repo/app/src/backtesting/` - Enhance existing framework

---

### 4. Sentiment Integration
**Status**: 🟡 Not Started  
**Impact**: MEDIUM - Improves prediction accuracy  
**Effort**: 2-3 days

**Tasks**:
- [ ] Integrate `fks_ai` news sentiment analysis
- [ ] Combine sentiment scores with price predictions
- [ ] Create hybrid signal generation

**Files**:
- Create: `repo/training/src/domain/ml/strategies/sentiment_strategy.py`
- Modify: `repo/api/src/routes/v1/ml.py` - Add sentiment features

---

### 5. Advanced Model Architectures
**Status**: 🟡 Not Started  
**Impact**: MEDIUM - Better predictions  
**Effort**: 4-5 days

**Tasks**:
- [ ] Implement CNN-LSTM for multi-asset correlation
- [ ] Add Transformer model with attention
- [ ] Create ensemble methods
- [ ] Compare performance vs. baseline LSTM

**Files**:
- Create: `repo/training/src/domain/ml/models/cnn_lstm/`
- Create: `repo/training/src/domain/ml/models/transformer/`
- Create: `repo/training/src/domain/ml/models/ensemble/`

---

## 📊 Priority 3: Quality & Testing (Ongoing)

### 6. Unit Tests for ML Components
**Status**: 🔴 Not Started  
**Impact**: HIGH - Ensures reliability  
**Effort**: 3-4 days

**Tasks**:
- [ ] Test training pipeline
- [ ] Test evaluation scripts
- [ ] Test inference endpoints
- [ ] Test drift detection
- [ ] Test feature engineering

**Target Coverage**: 80%+

---

### 7. Documentation
**Status**: 🔴 Not Started  
**Impact**: MEDIUM - Improves usability  
**Effort**: 2-3 days

**Tasks**:
- [ ] API usage guide
- [ ] Training tutorial
- [ ] Model deployment guide
- [ ] Example notebooks
- [ ] Architecture diagrams

---

## 📊 Priority 4: Production Readiness

### 8. Performance Optimization
**Status**: 🟡 Partial  
**Impact**: MEDIUM - Better user experience  
**Effort**: 2-3 days

**Tasks**:
- [ ] Model quantization for faster inference
- [ ] Batch prediction optimization
- [ ] GPU support for training
- [ ] Caching improvements

---

### 9. Monitoring & Alerting
**Status**: ✅ Basic implementation  
**Impact**: HIGH - Production stability  
**Effort**: 1-2 days

**Tasks**:
- [ ] Set up Prometheus metrics
- [ ] Create Grafana dashboards
- [ ] Add alerting rules
- [ ] Integrate with existing monitoring

---

## 🎯 Recommended Order

1. **Week 1**: Data integration (#1) + API completion (#2)
2. **Week 2**: Backtesting (#3) + Sentiment (#4)
3. **Week 3**: Advanced models (#5) + Testing (#6)
4. **Week 4**: Documentation (#7) + Optimization (#8)

---

## 📝 Quick Wins (Can Do Anytime)

- Add confidence intervals to predictions (1-2 hours)
- Create example training notebook (2-3 hours)
- Add feature importance to predictions (1-2 hours)
- Write API usage examples (1-2 hours)

---

## 🚀 Current Status Summary

✅ **Completed**:
- MLflow integration (tracking, registry, deployment)
- LSTM models with technical indicators
- Feature engineering pipeline
- ML inference API with caching
- Reinforcement Learning environment
- Ethical AI tools (SHAP, bias detection)
- Model evaluation & monitoring
- Automated retraining (Celery)

⚠️ **In Progress / TODO**:
- Data service integration
- Confidence intervals
- Feature importance extraction
- Advanced model architectures
- Backtesting enhancements
- Sentiment integration
- Unit tests
- Documentation

---

## 💡 Next Immediate Action

**Start with**: Connect `fks_training` to `fks_data` service

This unblocks the entire ML pipeline and allows you to:
- Train models on real data
- Test the full workflow
- Validate all components end-to-end

Would you like me to start implementing the data integration?

