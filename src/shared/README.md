# Shared Utilities and Framework

This directory contains shared code and utilities used across multiple FKS microservices.

## Structure

```
src/shared/
├── framework/       # Common framework components
│   ├── cache/      # Caching utilities (Redis, in-memory)
│   ├── config/     # Configuration management
│   ├── exceptions/ # Custom exception classes
│   ├── lifecycle/  # Service lifecycle management
│   ├── logging/    # Structured logging
│   ├── middleware/ # Common middleware (rate limiting, circuit breakers)
│   ├── patterns/   # Design patterns (repository, factory, etc.)
│   └── services/   # Service base classes
├── core/           # Core business logic utilities
│   ├── database/   # Database utilities and helpers
│   ├── market/     # Market data utilities
│   └── signals/    # Signal processing utilities
└── monitor/        # Monitoring and observability
    ├── health/     # Health check utilities
    ├── metrics/    # Prometheus metrics
    └── tracing/    # Distributed tracing
```

## Usage

Services should import from `src/shared` rather than duplicating code:

```python
# Good - import from shared
from src.shared.framework.middleware import RateLimiter
from src.shared.core.database import DatabaseManager

# Bad - duplicating code in service
from src.services/api/src/framework/middleware import RateLimiter
```

## Migration Status

**Phase 1.2.2 Complete** - Centralized shared utilities

### Consolidated Modules

- ✅ `framework/` - 25,488 LOC of shared framework code
- ✅ `core/` - 4,540 LOC of core utilities  
- ✅ `monitor/` - 761 LOC of monitoring code

### Duplicate Locations (to be removed)

The following duplicates should be gradually replaced with imports from `/src/shared`:

- `src/services/api/src/framework/`
- `src/services/data/src/framework/`
- `src/services/app/src/framework/` (if exists)

## Benefits

1. **DRY Principle**: Single source of truth for shared code
2. **Easier Maintenance**: Fix bugs once, benefits all services
3. **Consistent Behavior**: Same middleware/utilities across services
4. **Smaller Services**: Reduced code duplication
5. **Better Testing**: Test shared code once comprehensively

## Next Steps

1. Update service imports to use `/src/shared`
2. Remove duplicate code from individual services
3. Add integration tests for shared utilities
4. Document API contracts for shared modules

---

**Created**: November 4, 2025  
**Phase**: 1.2.2 - Centralize tests and utils
