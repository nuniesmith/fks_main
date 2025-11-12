# FKS Ninja Service Configuration

**Date**: 2025-11-12  
**Status**: ✅ **UPDATED**  
**Purpose**: Configure fks_ninja as a Python/Rust API service for NinjaTrader8 communication

---

## 🎯 Service Overview

### fks_ninja - NinjaTrader8 Bridge Service

**Purpose**: Python/Rust API service that communicates with NinjaTrader8 running on Windows desktop.

**Architecture**:
- **FKS Platform**: fks_ninja service (Python/Rust) running in Kubernetes
- **NinjaTrader8**: C# strategy running on Windows desktop (separate machine)
- **Communication**: TCP sockets (port 8080) between FKS platform and NinjaTrader8

**Key Points**:
- ✅ **Not a C# service** - fks_ninja is a Python/Rust API service
- ✅ **Runs in Kubernetes** - Part of the FKS platform
- ✅ **Communicates with NinjaTrader8** - Sends signals via TCP sockets
- ✅ **NinjaTrader8 runs separately** - C# indicators/strategies run on Windows desktop
- ✅ **Simple API** - Receives signals from fks_execution, sends to NinjaTrader8

---

## 🔧 Configuration

### Service Configuration

```yaml
fks_ninja:
  enabled: true
  name: fks-ninja
  replicaCount: 2
  port: 8006
  image: nuniesmith/fks:ninja-latest
```

### Environment Variables

```yaml
env:
  # NinjaTrader8 connection
  - name: NINJATRADER_HOST
    value: "100.80.141.117"  # Tailscale IP of Windows desktop
  - name: NINJATRADER_PORT
    value: "8080"  # Port that NinjaTrader8 strategy listens on
  - name: NINJATRADER_TIMEOUT
    value: "5"  # Connection timeout in seconds
  
  # Service configuration
  - name: SERVICE_NAME
    value: "fks_ninja"
  - name: SERVICE_PORT
    value: "8006"
  
  # Integration
  - name: EXECUTION_SERVICE_URL
    value: "http://fks-execution:8004"
  - name: DATA_SERVICE_URL
    value: "http://fks-data:8003"
```

---

## 📡 API Endpoints

### Signal Endpoints

- `POST /api/v1/signals/send` - Send signal to NinjaTrader8
- `POST /api/v1/signals/batch` - Send multiple signals
- `GET /api/v1/signals/status` - Get signal status
- `GET /api/v1/connection/test` - Test connection to NinjaTrader8

### Health Endpoints

- `GET /health` - Service health
- `GET /ready` - Readiness (checks NinjaTrader8 connection)

---

## 🔌 Communication Protocol

### Signal Format

```json
{
  "action": "buy",
  "instrument": "ES 03-25",
  "price": 4500.25,
  "tp_points": 20,
  "sl_points": 10
}
```

### Communication Flow

```
fks_execution → fks_ninja (API) → NinjaTrader8 (TCP Socket)
                     ↓
                (Signal Queue)
                     ↓
            (TCP Socket:8080)
                     ↓
         NinjaTrader8 Strategy
         (C# - runs on Windows)
```

---

## 🚀 Deployment

### Prerequisites

1. **NinjaTrader8 Running**: NinjaTrader8 must be running on Windows desktop
2. **FKS Strategy Installed**: FKS_AsyncStrategy must be installed in NinjaTrader8
3. **Strategy Listening**: Strategy must be listening on port 8080
4. **Network Access**: Kubernetes cluster must be able to reach Windows desktop (via Tailscale)

### Deployment Steps

1. **Deploy fks_ninja service**:
   ```bash
   cd repo/main
   ./run.sh
   # Choose option 8 (Kubernetes Start)
   ```

2. **Verify service is running**:
   ```bash
   kubectl get pods -n fks-trading -l app=fks-ninja
   ```

3. **Test connection to NinjaTrader8**:
   ```bash
   kubectl exec -n fks-trading deployment/fks-ninja -- curl http://localhost:8006/api/v1/connection/test
   ```

---

## 🔍 Verification

### Check Service Status

```bash
# Check pods
kubectl get pods -n fks-trading -l app=fks-ninja

# Check service
kubectl get svc -n fks-trading -l app=fks-ninja

# Check logs
kubectl logs -n fks-trading -l app=fks-ninja -f
```

### Test Connection

```bash
# Test connection to NinjaTrader8
curl -X GET http://localhost:8006/api/v1/connection/test

# Send test signal
curl -X POST http://localhost:8006/api/v1/signals/send \
  -H "Content-Type: application/json" \
  -d '{
    "action": "buy",
    "instrument": "ES 03-25",
    "price": 4500.25,
    "tp_points": 20,
    "sl_points": 10
  }'
```

---

## 🔧 Troubleshooting

### Connection Issues

**Problem**: Cannot connect to NinjaTrader8

**Solutions**:
1. Verify NinjaTrader8 is running
2. Verify FKS_AsyncStrategy is enabled and listening on port 8080
3. Check firewall rules (port 8080 must be open)
4. Verify Tailscale IP is correct (100.80.141.117)
5. Test connection from Kubernetes pod:
   ```bash
   kubectl exec -n fks-trading deployment/fks-ninja -- nc -zv 100.80.141.117 8080
   ```

### Signal Not Received

**Problem**: Signals sent but not received by NinjaTrader8

**Solutions**:
1. Check NinjaTrader8 output window for errors
2. Verify signal format matches expected format
3. Check network connectivity
4. Verify strategy is enabled in NinjaTrader8

---

## 📊 Integration with fks_execution

### Execution Flow

```
1. fks_execution receives signal from fks_app
2. fks_execution sends signal to fks_ninja via API
3. fks_ninja sends signal to NinjaTrader8 via TCP socket
4. NinjaTrader8 strategy executes trade
5. fks_ninja logs signal status
```

### API Integration

```python
# fks_execution sends signal to fks_ninja
import httpx

async def send_to_ninja(signal: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://fks-ninja:8006/api/v1/signals/send",
            json=signal
        )
        return response.json()
```

---

## 🎯 Next Steps

### Implementation Tasks

1. **Create fks_ninja service** (Python or Rust):
   - API endpoints for signal sending
   - TCP socket client for NinjaTrader8 communication
   - Signal queue management
   - Connection health checks

2. **Build Docker image**:
   - Python: Use FastAPI
   - Rust: Use Axum (to match fks_main)

3. **Deploy to Kubernetes**:
   - Enable in values.yaml
   - Deploy using Helm
   - Verify connectivity

4. **Test integration**:
   - Test connection to NinjaTrader8
   - Send test signals
   - Verify signals are received

---

## 📚 Related Documentation

- `repo/ninja/signal_sender.py` - Python signal sender implementation
- `repo/ninja/fks-package/FKS_AsyncStrategy.cs` - NinjaTrader8 strategy
- `repo/ninja/README.md` - NinjaTrader8 integration guide

---

## 🎉 Summary

### Service Configuration

- ✅ **fks_ninja**: Python/Rust API service (enabled)
- ✅ **Port**: 8006
- ✅ **Purpose**: Communicate with NinjaTrader8
- ✅ **Communication**: TCP sockets (port 8080)
- ✅ **Integration**: fks_execution → fks_ninja → NinjaTrader8

### Key Changes

1. **Enabled fks_ninja** in values.yaml
2. **Configured as API service** (not C# service)
3. **Added environment variables** for NinjaTrader8 connection
4. **Updated ingress** to include ninja routes
5. **Updated deployment scripts** to enable fks_ninja

### Next Action

Create the fks_ninja service implementation (Python or Rust) to communicate with NinjaTrader8!

---

**Status**: ✅ **CONFIGURATION READY**

**Last Updated**: 2025-11-12

**Next Action**: Create fks_ninja service implementation (Python FastAPI or Rust Axum)!

---

**Happy Trading!** 🚀

