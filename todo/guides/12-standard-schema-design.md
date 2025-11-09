# Standard Schema Design for FKS Microservices

**Last Updated**: November 7, 2025  
**Purpose**: Unified data schema strategy for multi-service architecture

## 🎯 Overview

Research suggests that a unified schema promotes data consistency and interoperability across microservices, reducing integration errors in fintech projects. It seems likely that adopting JSON Schema as the standard, with modular extensions for service-specific needs, will enhance maintainability while supporting compliance requirements like GDPR and PCI DSS.

**Benefits of Standard Schema**:
- Minimizes data inconsistencies (reduce errors by ~40%)
- Streamlines API integrations (auto-generate clients)
- Facilitates easier scaling
- Aids in regulatory adherence (PCI DSS, GDPR)

---

## 📐 Schema Design Principles

### Core Principles from Research

1. **Consistency**: Field naming conventions (snake_case uniformly)
2. **Readability**: Descriptive English terms over abbreviations
3. **Orthogonality**: Each field serves single purpose
4. **Minimal Nesting**: Limit to 2-3 levels for performance
5. **Extensibility**: Design for future additions without breaking changes
6. **Validation**: Built-in constraints (types, patterns, ranges)

### Current FKS Schema Artifacts

**Existing Schemas** (in `/shared/schema/`):
- `market_bar.schema.json` - OHLCV candlestick data
- `trade_signal.schema.json` - Trading signals
- `fks-health-response.schema.json` - Service health checks
- `portfolio.schema.json` - Portfolio state (if exists)

**Gap Analysis**:
- ❌ No unified base schema for common fields (IDs, timestamps)
- ❌ Missing schemas for: user, order, transaction, audit_log
- ❌ No schema versioning strategy
- ❌ No validation in CI/CD pipelines

---

## 🏗️ Base Schema Components

### Common Fields (All Entities)

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://api.fkstrading.xyz/schemas/common/v1/base.schema.json",
    "title": "FKS Base Schema",
    "description": "Common fields for all FKS entities",
    "type": "object",
    "required": ["id", "created_at"],
    "properties": {
        "id": {
            "type": "string",
            "format": "uuid",
            "description": "Unique identifier (UUID v4)"
        },
        "created_at": {
            "type": "string",
            "format": "date-time",
            "description": "Creation timestamp (ISO 8601 with timezone)",
            "examples": ["2025-11-07T12:00:00Z"]
        },
        "updated_at": {
            "type": "string",
            "format": "date-time",
            "description": "Last update timestamp"
        },
        "version": {
            "type": "integer",
            "minimum": 1,
            "description": "Schema version for compatibility"
        }
    }
}
```

### Timestamp Standards

**Always use ISO 8601 with UTC**:
```json
{
    "timestamp": {
        "type": "string",
        "format": "date-time",
        "pattern": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z$",
        "examples": ["2025-11-07T12:00:00Z", "2025-11-07T12:00:00.123Z"]
    }
}
```

### Status Enums (Semantic States)

```json
{
    "status": {
        "type": "string",
        "enum": ["active", "pending", "completed", "cancelled", "failed"],
        "description": "Entity lifecycle state"
    }
}
```

**Benefits**:
- Avoids magic numbers (0, 1, 2 → unclear meaning)
- Self-documenting in logs
- Easy to validate

---

## 📊 Domain-Specific Schemas

### Market Data Schema

**Extended from Base**:
```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://api.fkstrading.xyz/schemas/market/v1/bar.schema.json",
    "title": "Market Bar (OHLCV)",
    "allOf": [
        { "$ref": "../common/v1/base.schema.json" }
    ],
    "properties": {
        "symbol": {
            "type": "string",
            "pattern": "^[A-Z]{1,10}(/[A-Z]{1,10})?$",
            "description": "Trading pair (e.g., BTCUSD or BTC/USD)",
            "examples": ["BTCUSD", "BTC/USD", "AAPL"]
        },
        "timestamp": {
            "type": "string",
            "format": "date-time",
            "description": "Bar timestamp (open time)"
        },
        "open": {
            "type": "number",
            "minimum": 0,
            "description": "Opening price"
        },
        "high": {
            "type": "number",
            "minimum": 0,
            "description": "Highest price in period"
        },
        "low": {
            "type": "number",
            "minimum": 0,
            "description": "Lowest price in period"
        },
        "close": {
            "type": "number",
            "minimum": 0,
            "description": "Closing price"
        },
        "volume": {
            "type": "number",
            "minimum": 0,
            "description": "Trading volume"
        },
        "timeframe": {
            "type": "string",
            "enum": ["1m", "5m", "15m", "1h", "4h", "1d"],
            "description": "Bar interval"
        }
    },
    "required": ["symbol", "timestamp", "open", "high", "low", "close", "volume", "timeframe"],
    "additionalProperties": false
}
```

### Trade Signal Schema

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://api.fkstrading.xyz/schemas/trading/v1/signal.schema.json",
    "title": "Trade Signal",
    "allOf": [
        { "$ref": "../common/v1/base.schema.json" }
    ],
    "properties": {
        "symbol": {
            "type": "string",
            "pattern": "^[A-Z]{1,10}(/[A-Z]{1,10})?$"
        },
        "action": {
            "type": "string",
            "enum": ["BUY", "SELL", "HOLD"],
            "description": "Trading action"
        },
        "quantity": {
            "type": "number",
            "minimum": 0,
            "exclusiveMinimum": true,
            "description": "Order size (must be > 0)"
        },
        "price": {
            "type": "number",
            "minimum": 0,
            "description": "Target price (null for market orders)"
        },
        "confidence": {
            "type": "number",
            "minimum": 0,
            "maximum": 1,
            "description": "AI confidence score (0-1)"
        },
        "strategy": {
            "type": "string",
            "enum": ["ASMBTR", "SENTIMENT", "MULTI_AGENT", "MANUAL"],
            "description": "Signal source"
        },
        "metadata": {
            "type": "object",
            "properties": {
                "indicators": {
                    "type": "object",
                    "properties": {
                        "rsi": { "type": "number", "minimum": 0, "maximum": 100 },
                        "macd": { "type": "number" },
                        "sentiment_score": { "type": "number", "minimum": -1, "maximum": 1 }
                    }
                },
                "agent_votes": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "agent": { "type": "string" },
                            "vote": { "type": "string", "enum": ["BUY", "SELL", "HOLD"] },
                            "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
                        }
                    }
                }
            },
            "description": "Additional context (indicators, agent votes)"
        }
    },
    "required": ["symbol", "action", "quantity", "confidence", "strategy"]
}
```

### Order Execution Schema

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://api.fkstrading.xyz/schemas/trading/v1/order.schema.json",
    "title": "Order Execution Result",
    "allOf": [
        { "$ref": "../common/v1/base.schema.json" }
    ],
    "properties": {
        "order_id": {
            "type": "string",
            "description": "Exchange-provided order ID"
        },
        "signal_id": {
            "type": "string",
            "format": "uuid",
            "description": "Reference to originating signal"
        },
        "symbol": { "type": "string" },
        "side": {
            "type": "string",
            "enum": ["buy", "sell"]
        },
        "type": {
            "type": "string",
            "enum": ["market", "limit", "stop_loss", "take_profit"]
        },
        "quantity": { "type": "number", "minimum": 0 },
        "filled_quantity": { "type": "number", "minimum": 0 },
        "price": { "type": "number", "minimum": 0 },
        "average_fill_price": { "type": "number", "minimum": 0 },
        "status": {
            "type": "string",
            "enum": ["pending", "open", "filled", "partially_filled", "cancelled", "rejected"]
        },
        "exchange": {
            "type": "string",
            "description": "Exchange name (e.g., binance, coinbase)"
        },
        "fees": {
            "type": "object",
            "properties": {
                "amount": { "type": "number", "minimum": 0 },
                "currency": { "type": "string" }
            }
        },
        "error": {
            "type": "object",
            "properties": {
                "code": { "type": "string" },
                "message": { "type": "string" }
            },
            "description": "Error details if order failed"
        }
    },
    "required": ["order_id", "signal_id", "symbol", "side", "type", "quantity", "status", "exchange"]
}
```

### Health Check Schema

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://api.fkstrading.xyz/schemas/common/v1/health.schema.json",
    "title": "Service Health Response",
    "type": "object",
    "properties": {
        "status": {
            "type": "string",
            "enum": ["healthy", "degraded", "unhealthy"],
            "description": "Overall service health"
        },
        "timestamp": {
            "type": "string",
            "format": "date-time"
        },
        "service": {
            "type": "string",
            "description": "Service name (e.g., fks-api)"
        },
        "version": {
            "type": "string",
            "pattern": "^v\\d+\\.\\d+\\.\\d+$",
            "description": "Semantic version (e.g., v1.2.3)"
        },
        "checks": {
            "type": "object",
            "additionalProperties": {
                "type": "object",
                "properties": {
                    "status": { "type": "string", "enum": ["ok", "error"] },
                    "message": { "type": "string" },
                    "latency_ms": { "type": "number", "minimum": 0 }
                },
                "required": ["status"]
            },
            "description": "Individual dependency checks",
            "examples": [{
                "database": { "status": "ok", "latency_ms": 5 },
                "redis": { "status": "ok", "latency_ms": 2 },
                "external_api": { "status": "error", "message": "Timeout" }
            }]
        }
    },
    "required": ["status", "timestamp", "service", "version"]
}
```

---

## 🔄 Schema Versioning Strategy

### Semantic Versioning for Schemas

**Format**: `/schemas/{domain}/{version}/{entity}.schema.json`

**Example**:
```
/schemas/trading/v1/signal.schema.json  → Version 1
/schemas/trading/v2/signal.schema.json  → Version 2 (breaking change)
```

**Backward Compatibility Rules**:
1. **Minor Changes (v1.1)**: Add optional fields only
2. **Major Changes (v2.0)**: Breaking changes (rename, remove fields)
3. **Deprecation**: Support old version for 6 months

**Version Header in API**:
```http
POST /api/v1/signals
Content-Type: application/json
X-Schema-Version: v1

{
    "symbol": "BTCUSD",
    "action": "BUY"
}
```

### Migration Strategy

**Add Field** (backward compatible):
```json
// v1.0.0
{
    "symbol": "BTCUSD",
    "action": "BUY"
}

// v1.1.0 (add optional field)
{
    "symbol": "BTCUSD",
    "action": "BUY",
    "urgency": "normal"  // New optional field
}
```

**Rename Field** (breaking change):
```json
// v1.0.0
{
    "qty": 0.1
}

// v2.0.0 (breaking: rename qty → quantity)
{
    "quantity": 0.1
}

// Transition: Support both for 6 months
if 'qty' in payload:
    payload['quantity'] = payload.pop('qty')
    warnings.warn("'qty' is deprecated, use 'quantity'", DeprecationWarning)
```

---

## 🛠️ Validation and Tooling

### JSON Schema Validation in Python

```python
# /shared/python/schema_validator.py
import jsonschema
from pathlib import Path
import json

class SchemaValidator:
    def __init__(self, schema_dir: Path):
        self.schema_dir = schema_dir
        self.schemas = {}
    
    def load_schema(self, schema_name: str, version: str = 'v1'):
        """Load schema from file"""
        schema_path = self.schema_dir / version / f"{schema_name}.schema.json"
        with open(schema_path) as f:
            self.schemas[schema_name] = json.load(f)
        return self.schemas[schema_name]
    
    def validate(self, data: dict, schema_name: str):
        """Validate data against schema"""
        schema = self.schemas.get(schema_name) or self.load_schema(schema_name)
        try:
            jsonschema.validate(instance=data, schema=schema)
            return True, None
        except jsonschema.ValidationError as e:
            return False, str(e)

# Usage
validator = SchemaValidator(Path('/shared/schemas/trading'))
signal = {"symbol": "BTCUSD", "action": "BUY", "quantity": 0.1, "confidence": 0.8, "strategy": "ASMBTR"}
valid, error = validator.validate(signal, 'signal')
if not valid:
    raise ValueError(f"Invalid signal: {error}")
```

### FastAPI Integration

```python
# /fks_api/src/routers/trades.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, validator
from datetime import datetime

class TradeSignal(BaseModel):
    """Auto-generated from JSON Schema"""
    id: str = Field(..., regex='^[a-f0-9-]{36}$')
    symbol: str = Field(..., regex='^[A-Z]{1,10}(/[A-Z]{1,10})?$')
    action: str = Field(..., regex='^(BUY|SELL|HOLD)$')
    quantity: float = Field(..., gt=0)
    confidence: float = Field(..., ge=0, le=1)
    strategy: str = Field(..., regex='^(ASMBTR|SENTIMENT|MULTI_AGENT|MANUAL)$')
    created_at: datetime
    
    @validator('symbol')
    def validate_symbol(cls, v):
        if v not in ['BTCUSD', 'ETHUSD', 'AAPL']:  # Whitelist
            raise ValueError(f'Unsupported symbol: {v}')
        return v

app = FastAPI()

@app.post("/api/v1/signals", response_model=TradeSignal)
async def create_signal(signal: TradeSignal):
    # Pydantic auto-validates against schema
    return signal
```

### CI/CD Validation

```yaml
# .github/workflows/validate-schemas.yml
name: Validate Schemas
on:
    push:
        paths:
            - 'shared/schemas/**'
jobs:
    validate:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - name: Install ajv-cli
              run: npm install -g ajv-cli
            - name: Validate all schemas
              run: |
                  for schema in shared/schemas/**/*.schema.json; do
                      echo "Validating $schema"
                      ajv validate -s "$schema" --spec=draft2020
                  done
            - name: Test with sample data
              run: |
                  ajv validate -s shared/schemas/trading/v1/signal.schema.json \
                              -d tests/fixtures/valid_signal.json
```

---

## 📦 Schema Distribution

### NPM Package (for JavaScript/TypeScript)

```json
// package.json
{
    "name": "@fks/schemas",
    "version": "1.0.0",
    "main": "index.js",
    "files": ["schemas/"],
    "scripts": {
        "validate": "ajv validate -s schemas/**/*.schema.json"
    }
}
```

**Usage in fks_web**:
```typescript
import { TradeSignal } from '@fks/schemas/trading/v1/signal.schema.json';
import Ajv from 'ajv';

const ajv = new Ajv();
const validate = ajv.compile(TradeSignal);

const signal = { symbol: 'BTCUSD', action: 'BUY', quantity: 0.1 };
if (!validate(signal)) {
    console.error('Invalid signal:', validate.errors);
}
```

### Python Package

```python
# setup.py
from setuptools import setup

setup(
    name='fks-schemas',
    version='1.0.0',
    packages=['fks_schemas'],
    package_data={'fks_schemas': ['schemas/**/*.json']},
)
```

**Usage**:
```python
from fks_schemas import get_schema

schema = get_schema('trading/v1/signal')
```

---

## 🎯 Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Define base schema with common fields
- [ ] Create schemas for: market_bar, trade_signal, order, health
- [ ] Set up schema validation in fks_api
- [ ] Add CI/CD validation

### Phase 2: Service Integration (Week 3-4)
- [ ] Integrate validators in all services
- [ ] Add schema enforcement to API endpoints
- [ ] Update existing data models to match schemas
- [ ] Generate API clients from schemas

### Phase 3: Versioning (Week 5-6)
- [ ] Implement v1/v2 support in API
- [ ] Add deprecation warnings for old schemas
- [ ] Document migration guides
- [ ] Test backward compatibility

### Phase 4: Advanced Features (Week 7-8)
- [ ] Auto-generate TypeScript types from schemas
- [ ] Create Rust structs from schemas (via schemars)
- [ ] Implement schema registry service
- [ ] Add schema evolution policies

---

## 📚 Key Citations

- [Database Design for Microservices](https://arunangshudas.medium.com/database-design-for-microservices-key-strategies-and-best-practices-d89f1251e27e)
- [JSON Schema for APIs](https://www.thisdot.co/blog/level-up-your-rest-apis-with-json-schema)
- [OpenAPI Best Practices](https://www.echoapi.com/blog/ultimate-guide-to-json-api-design-principles-best-practices-and-schema-standards/)
- [Microservices Data Considerations](https://learn.microsoft.com/en-us/azure/architecture/microservices/design/data-considerations)
- [Sharing Schema Between Microservices](https://stackoverflow.com/questions/25600580/sharing-code-and-schema-between-microservices)
