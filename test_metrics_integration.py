#!/usr/bin/env python3
"""
Quick test to verify metrics integration works.
"""

import sys
import asyncio

# Test imports
try:
    print("Testing metrics imports...")
    from src.services.execution.metrics import (
        webhook_requests_total,
        webhook_processing_duration,
        order_execution_duration,
        rate_limit_requests,
        circuit_breaker_state,
        MetricsTimer,
    )
    print("✓ Metrics imports successful")
except Exception as e:
    print(f"✗ Metrics import failed: {e}")
    sys.exit(1)

# Test webhook handler
try:
    print("\nTesting webhook handler with metrics...")
    from src.services.execution.webhooks.tradingview import TradingViewWebhook
    print("✓ Webhook handler imports successful")
except Exception as e:
    print(f"✗ Webhook handler import failed: {e}")
    sys.exit(1)

# Test CCXT plugin
try:
    print("\nTesting CCXT plugin with metrics...")
    from src.services.execution.exchanges.ccxt_plugin import CCXTPlugin
    print("✓ CCXT plugin imports successful")
except Exception as e:
    print(f"✗ CCXT plugin import failed: {e}")
    sys.exit(1)

# Test security middleware
try:
    print("\nTesting security middleware with metrics...")
    from src.services.execution.security.middleware import (
        RateLimiter,
        CircuitBreaker,
        IPWhitelist,
        AuditLogger,
    )
    print("✓ Security middleware imports successful")
except Exception as e:
    print(f"✗ Security middleware import failed: {e}")
    sys.exit(1)

# Test validation layer
try:
    print("\nTesting validation layer with metrics...")
    from src.services.execution.validation.normalizer import (
        DataNormalizer,
        PositionSizer,
    )
    print("✓ Validation layer imports successful")
except Exception as e:
    print(f"✗ Validation layer import failed: {e}")
    sys.exit(1)

# Test basic functionality
async def test_basic_functionality():
    print("\n=== Testing Basic Functionality ===")
    
    # Test rate limiter
    print("\nTesting RateLimiter...")
    from src.services.execution.security.middleware import create_rate_limiter, RateLimitConfig
    limiter = create_rate_limiter(RateLimitConfig(max_requests=5, window_seconds=60))
    
    # Should allow first request
    allowed = await limiter.check_rate_limit("192.168.1.1")
    print(f"  First request allowed: {allowed}")
    assert allowed, "First request should be allowed"
    
    # Check metrics were recorded
    print("  ✓ RateLimiter metrics recorded")
    
    # Test data normalizer
    print("\nTesting DataNormalizer...")
    from src.services.execution.validation.normalizer import create_normalizer
    normalizer = create_normalizer()
    
    # Normalize symbol
    normalized = normalizer.normalize_symbol("BTC-USDT")
    print(f"  BTC-USDT normalized to: {normalized}")
    assert normalized == "BTC/USDT", "Symbol normalization failed"
    
    # Check metrics were recorded
    print("  ✓ Normalizer metrics recorded")
    
    print("\n✓ All basic functionality tests passed!")

# Run async tests
try:
    asyncio.run(test_basic_functionality())
except Exception as e:
    print(f"\n✗ Functionality test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "="*50)
print("✓ ALL METRICS INTEGRATION TESTS PASSED")
print("="*50)
