# FKS Service Port Layout

**Last Updated**: 2025-01-15  
**Script**: `services/main/run.sh`

## Port Assignment Summary

| Port | Service | Type | Description |
|------|---------|------|-------------|
| 8000 | web | Python | Django web UI |
| 8001 | api | Python | API Gateway (FastAPI) |
| 8002 | app | Python | Trading logic & signals |
| 8003 | data | Python | Central data service (single source of truth) |
| 8004 | execution | Rust | Order execution engine |
| 8005 | meta | Rust | MetaTrader 5 bridge |
| 8006 | ninja | Python | NinjaTrader 8 bridge |
| 8007 | ai | Python | AI/ML inference (GPU) |
| 8008 | analyze | Python | Codebase analysis & auto-improvement |
| 8009 | auth | Rust | Rust-based auth (JWT/RBAC) |
| 8010 | main | Rust | fks_main – Rust orchestrator |
| 8011 | training | Python | GPU batch training |
| 8012 | portfolio | Python | BTC-centric portfolio optimization |
| 8013 | monitor | Python | Prometheus + Grafana metrics aggregation |
| 8014 | crypto | Python | Crypto signal generation and analysis |
| 8015 | futures | Python | Futures trading service (CME Group futures contracts) |
| 8016 | stocks | Python | Stocks trading service (equity market analysis) |
| 8020 | data_ingestion | Python | Data ingestion service (stock, futures, news) |
| 8021 | feature_engineering | Python | Feature engineering service (112+ features) |

## Service Categories

### CPU Core Services
- api, app, data, execution, portfolio, web
- crypto, futures, stocks
- data_ingestion, feature_engineering

### GPU Services
- ai, training

### Execution Plugins
- meta, ninja

### Infrastructure Services
- analyze, auth, monitor, nginx, tailscale

### Orchestrator
- main

## Port Ranges

- **8000-8013**: Core services and infrastructure
- **8014-8016**: Asset-specific trading services (crypto, futures, stocks)
- **8020-8021**: Data processing services (ingestion, feature engineering)

## Notes

- All services use `/health` endpoint for health checks
- Ports are defined in `get_service_health_url()` function
- Service arrays are defined at the top of `run.sh`:
  - `CPU_CORE_SERVICES`
  - `PYTHON_SERVICES`
  - `ALL_SERVICES`
