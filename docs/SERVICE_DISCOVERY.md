# FKS Service Discovery and Communication

## Overview

This document describes how FKS services discover and communicate with each other.

## Service Registry

All services are registered in `config/service_registry.json`. This provides:
- Service locations (hosts and ports)
- Health check endpoints
- Dependency mapping

## Communication Patterns

### Direct HTTP Calls

Services communicate via HTTP REST APIs:
```
fks_api -> fks_data: http://fks-data:8003/api/v1/data
```

### Service Discovery

Services can discover each other via:
1. **Environment Variables**: Pre-configured service URLs
2. **Service Registry**: Centralized registry (future)
3. **Kubernetes DNS**: Automatic DNS resolution in K8s

## Circuit Breakers

Circuit breakers prevent cascading failures:
- **Failure Threshold**: 5 consecutive failures
- **Timeout**: 60 seconds
- **Fallback**: Returns default response when open

Configuration: `config/circuit_breakers.json`

## API Gateway

External traffic routes through API gateway:
- Path: `/api/{service}`
- Load balancing
- Rate limiting
- Authentication

## Distributed Tracing

All requests are traced using Jaeger:
- Trace IDs propagated via headers
- 10% sampling rate
- Full request flow visibility

## Best Practices

1. **Always use service names** (not IPs)
2. **Implement circuit breakers** for external calls
3. **Add request timeouts** (default: 5s)
4. **Log trace IDs** for debugging
5. **Use health checks** before making calls

## Service Dependencies


### fks_api
Depends on: fks_data, fks_auth

### fks_app
Depends on: fks_api, fks_data

### fks_execution
Depends on: fks_api, fks_data

### fks_web
Depends on: fks_api

### fks_ai
Depends on: fks_data

### fks_analyze
Depends on: fks_data, fks_ai

### fks_monitor
Depends on: all

### fks_main
Depends on: fks_monitor
