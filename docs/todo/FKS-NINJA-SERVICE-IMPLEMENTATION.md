# FKS Ninja Service - Implementation Plan

**Date**: 2025-11-12  
**Status**: 📋 **IMPLEMENTATION NEEDED**  
**Purpose**: Create Python FastAPI service for fks_ninja to communicate with NinjaTrader8

---

## 🎯 Overview

The `fks_ninja` service should be a **Python FastAPI service** that:
1. Receives signals from `fks_execution` via REST API
2. Sends signals to NinjaTrader8 via TCP sockets (port 8080)
3. Provides health checks and monitoring
4. Manages signal queue and retry logic

**Key Points**:
- ✅ **Not a C# service** - Python/Rust API service running in Kubernetes
- ✅ **NinjaTrader8 runs separately** - C# strategy runs on Windows desktop
- ✅ **Communication**: TCP sockets (port 8080) between FKS platform and NinjaTrader8
- ✅ **Simple API**: Receives signals from fks_execution, sends to NinjaTrader8

---

## 🏗️ Architecture

### Service Architecture

```
fks_execution → fks_ninja (FastAPI) → NinjaTrader8 (TCP Socket)
     ↓                ↓                        ↓
  Signal API    Signal Queue          C# Strategy
                TCP Client            (Windows Desktop)
```

### Communication Flow

1. **Signal Reception**: fks_execution sends signal to fks_ninja API
2. **Signal Validation**: fks_ninja validates signal format
3. **Signal Queue**: Signal added to queue (Redis)
4. **Signal Transmission**: fks_ninja sends signal to NinjaTrader8 via TCP socket
5. **Signal Confirmation**: fks_ninja receives confirmation from NinjaTrader8
6. **Signal Logging**: Signal status logged to database

---

## 📁 Service Structure

### Recommended Location

```
repo/ninja/
├── src/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes.py        # API routes
│   │   └── models.py        # Pydantic models
│   ├── ninja/
│   │   ├── __init__.py
│   │   ├── client.py        # TCP socket client
│   │   └── signal.py        # Signal handling
│   ├── config.py            # Configuration
│   └── health.py            # Health checks
├── tests/
│   └── test_ninja.py
├── Dockerfile
├── requirements.txt
├── docker-compose.yml
└── README.md
```

---

## 🔧 Implementation

### Step 1: Create FastAPI Application

**File**: `repo/ninja/src/main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router
from .config import settings

app = FastAPI(
    title="FKS Ninja Service",
    description="NinjaTrader8 Bridge Service",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api/v1")

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "fks_ninja"}

@app.get("/ready")
async def ready():
    # Check connection to NinjaTrader8
    from .ninja.client import NT8Client
    client = NT8Client()
    is_ready = await client.test_connection()
    return {"status": "ready" if is_ready else "not_ready", "ninja_connected": is_ready}
```

### Step 2: Create TCP Socket Client

**File**: `repo/ninja/src/ninja/client.py`

```python
import socket
import json
import asyncio
from typing import Dict, Optional
from ..config import settings

class NT8Client:
    """TCP socket client for NinjaTrader8 communication"""
    
    def __init__(self, host: str = None, port: int = None):
        self.host = host or settings.NINJATRADER_HOST
        self.port = port or settings.NINJATRADER_PORT
        self.timeout = settings.NINJATRADER_TIMEOUT
    
    async def send_signal(self, signal: dict) -> bool:
        """Send signal to NinjaTrader8 via TCP socket"""
        try:
            # Validate signal
            required_keys = ['action', 'instrument', 'price', 'tp_points', 'sl_points']
            if not all(key in signal for key in required_keys):
                raise ValueError(f"Missing required keys: {required_keys}")
            
            # Create socket connection
            loop = asyncio.get_event_loop()
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(self.host, self.port),
                timeout=self.timeout
            )
            
            # Send JSON payload
            payload = json.dumps(signal).encode('utf-8')
            writer.write(payload)
            await writer.drain()
            
            # Close connection
            writer.close()
            await writer.wait_closed()
            
            return True
            
        except asyncio.TimeoutError:
            raise ConnectionError(f"Connection timeout to {self.host}:{self.port}")
        except ConnectionRefusedError:
            raise ConnectionError(f"Connection refused to {self.host}:{self.port}")
        except Exception as e:
            raise ConnectionError(f"Failed to send signal: {e}")
    
    async def test_connection(self) -> bool:
        """Test connection to NinjaTrader8"""
        try:
            loop = asyncio.get_event_loop()
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(self.host, self.port),
                timeout=self.timeout
            )
            writer.close()
            await writer.wait_closed()
            return True
        except Exception:
            return False
```

### Step 3: Create API Routes

**File**: `repo/ninja/src/api/routes.py`

```python
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from ..ninja.client import NT8Client

router = APIRouter()

class SignalRequest(BaseModel):
    action: str  # "buy", "sell", "long", "short"
    instrument: str  # "ES 03-25", "NQ 03-25"
    price: float
    tp_points: int
    sl_points: int

class SignalResponse(BaseModel):
    success: bool
    message: str
    signal_id: Optional[str] = None

@router.post("/signals/send", response_model=SignalResponse)
async def send_signal(signal: SignalRequest):
    """Send signal to NinjaTrader8"""
    try:
        client = NT8Client()
        signal_dict = signal.dict()
        success = await client.send_signal(signal_dict)
        
        if success:
            return SignalResponse(
                success=True,
                message="Signal sent successfully",
                signal_id=f"{signal.instrument}_{signal.action}_{signal.price}"
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to send signal")
            
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/connection/test")
async def test_connection():
    """Test connection to NinjaTrader8"""
    try:
        client = NT8Client()
        is_connected = await client.test_connection()
        return {
            "connected": is_connected,
            "host": client.host,
            "port": client.port
        }
    except Exception as e:
        return {
            "connected": False,
            "error": str(e)
        }
```

### Step 4: Create Configuration

**File**: `repo/ninja/src/config.py`

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Service configuration
    SERVICE_NAME: str = "fks_ninja"
    SERVICE_PORT: int = 8006
    
    # NinjaTrader8 connection
    NINJATRADER_HOST: str = "100.80.141.117"
    NINJATRADER_PORT: int = 8080
    NINJATRADER_TIMEOUT: int = 5
    
    # Execution service
    EXECUTION_SERVICE_URL: str = "http://fks-execution:8004"
    
    # Data service
    DATA_SERVICE_URL: str = "http://fks-data:8003"
    
    # Database
    POSTGRES_HOST: str = "fks-platform-postgresql"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "fks_db"
    POSTGRES_USER: str = "fks_user"
    POSTGRES_PASSWORD: str = ""
    
    # Redis
    REDIS_HOST: str = "fks-platform-redis-master"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: str = ""
    
    class Config:
        env_file = ".env"

settings = Settings()
```

---

## 🚀 Deployment

### Step 1: Create Dockerfile

**File**: `repo/ninja/Dockerfile`

```dockerfile
FROM nuniesmith/fks:docker

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/

# Expose port
EXPOSE 8006

# Run application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8006"]
```

### Step 2: Create requirements.txt

**File**: `repo/ninja/requirements.txt`

```txt
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.0.0
pydantic-settings>=2.0.0
httpx>=0.25.0
redis>=5.0.0
psycopg2-binary>=2.9.0
```

### Step 3: Build and Push Docker Image

```bash
cd repo/ninja
docker build -t nuniesmith/fks:ninja-latest .
docker push nuniesmith/fks:ninja-latest
```

---

## 📊 API Endpoints

### Signal Endpoints

- `POST /api/v1/signals/send` - Send signal to NinjaTrader8
- `GET /api/v1/connection/test` - Test connection to NinjaTrader8

### Health Endpoints

- `GET /health` - Service health
- `GET /ready` - Readiness (checks NinjaTrader8 connection)

---

## 🔌 Signal Format

### Request Format

```json
{
  "action": "buy",
  "instrument": "ES 03-25",
  "price": 4500.25,
  "tp_points": 20,
  "sl_points": 10
}
```

### Response Format

```json
{
  "success": true,
  "message": "Signal sent successfully",
  "signal_id": "ES_03-25_buy_4500.25"
}
```

---

## 🔍 Testing

### Test Connection

```bash
curl -X GET http://localhost:8006/api/v1/connection/test
```

### Send Signal

```bash
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

## 🎯 Next Steps

1. **Create service implementation** in `repo/ninja/src/`
2. **Build Docker image** and push to Docker Hub
3. **Deploy to Kubernetes** using updated values.yaml
4. **Test integration** with NinjaTrader8
5. **Verify signals** are received by NinjaTrader8

---

**Status**: 📋 **IMPLEMENTATION NEEDED**

**Last Updated**: 2025-11-12

**Next Action**: Create fks_ninja service implementation in `repo/ninja/src/`!

---

**Happy Trading!** 🚀

