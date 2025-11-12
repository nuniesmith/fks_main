# FKS Quick Reference Guide

**Last Updated**: 2025-01-15  
**Purpose**: Quick reference for common tasks and information

---

## 🚀 Quick Start

### Service Ports

| Service | Port | Health URL |
|---------|------|------------|
| fks_web | 8000 | http://localhost:8000/health |
| fks_api | 8001 | http://localhost:8001/health |
| fks_app | 8002 | http://localhost:8002/health |
| fks_data | 8003 | http://localhost:8003/health |
| fks_execution | 8004 | http://localhost:8004/health |
| fks_meta | 8005 | http://localhost:8005/health |
| fks_ai | 8007 | http://localhost:8007/health |
| fks_analyze | 8008 | http://localhost:8008/health |
| fks_auth | 8009 | http://localhost:8009/health |
| fks_main | 8010 | http://localhost:8010/health |
| fks_training | 8011 | http://localhost:8011/health |
| fks_portfolio | 8012 | http://localhost:8012/health |
| fks_monitor | 8013 | http://localhost:8013/health |

---

## 📡 API Endpoints

### fks_data (Port 8003)
- `GET /api/v1/data/price?symbol=BTCUSDT` - Get price
- `GET /api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h` - Get OHLCV
- `GET /api/v1/data/providers` - List providers
- `POST /webhooks/binance` - Binance webhook

### fks_app (Port 8002)
- `POST /api/v1/signals/generate` - Generate signal
- `GET /api/v1/signals/latest/{symbol}` - Get latest signal
- `GET /api/v1/signals/batch?symbols=BTCUSDT,ETHUSDT` - Batch signals

### fks_ai (Port 8007)
- `POST /ai/analyze` - Multi-agent analysis
- `POST /ai/debate` - Bull/bear debate
- `GET /ai/agents/status` - Agent status

### fks_execution (Port 8004)
- `POST /orders` - Submit order
- `GET /orders/{order_id}` - Get order status

### fks_web (Port 8000)
- `/portfolio/signals/` - Signal dashboard
- `/portfolio/signals/approve/{signal_id}/` - Approve signal
- `/portfolio/signals/reject/{signal_id}/` - Reject signal

---

## 🔧 Common Commands

### Start Services
```bash
# Start data service
cd repo/data && docker-compose up -d

# Start app service
cd repo/app && docker-compose up -d

# Start web service
cd repo/web && docker-compose up -d
```

### Health Checks
```bash
# Check all services
python repo/main/scripts/phase1_verify_health.py

# Check specific service
curl http://localhost:8003/health
```

### Generate Signal
```bash
curl -X POST "http://localhost:8002/api/v1/signals/generate" \
  -H "Content-Type: application/json" \
  -d '{"symbol": "BTCUSDT", "category": "swing", "use_ai": true}'
```

### Get Price Data
```bash
curl "http://localhost:8003/api/v1/data/price?symbol=BTCUSDT"
```

---

## 📊 Trade Categories

| Category | TP % | SL % | Timeframe | Risk |
|----------|------|------|-----------|------|
| Scalp | 0.75% | 0.75% | 1h | High |
| Swing | 3.5% | 2.0% | 1d | Medium |
| Long-term | 15.0% | 10.0% | 1w | Low |

---

## 🔗 Service URLs (Docker)

- fks_data: `http://fks_data:8003`
- fks_app: `http://fks_app:8002`
- fks_ai: `http://fks_ai:8007`
- fks_execution: `http://fks_execution:8004`
- fks_portfolio: `http://fks_portfolio:8012`

---

## 📝 Environment Variables

### fks_data
```bash
REDIS_URL=redis://redis:6379/0
POLYGON_API_KEY=your_key
```

### fks_app
```bash
APP_SERVICE_URL=http://fks_app:8002
AI_SERVICE_URL=http://fks_ai:8007
DATA_SERVICE_URL=http://fks_data:8003
```

### fks_web
```bash
APP_SERVICE_URL=http://fks_app:8002
EXECUTION_SERVICE_URL=http://fks_execution:8004
PORTFOLIO_SERVICE_URL=http://fks_portfolio:8012
```

---

## 🐛 Troubleshooting

### Service Not Starting
1. Check port conflicts: `netstat -an | grep :8003`
2. Check logs: `docker-compose logs`
3. Verify health: `curl http://localhost:8003/health`

### Signal Not Generating
1. Check fks_data is running
2. Verify market data available
3. Check fks_ai is accessible (if using AI)

### Dashboard Not Loading
1. Check fks_web is running
2. Verify authentication
3. Check browser console for errors

---

## 📚 Documentation

- **Project Status**: `PROJECT-STATUS-2025-01-15.md`
- **Next Steps**: `NEXT-STEPS-2025-01-15.md`
- **Phase 2 Summary**: `PHASE-2-COMPLETE-SUMMARY.md`
- **Quick Start**: `QUICK-START-GUIDE.md`

---

**For detailed information, see the full documentation in this directory.**

