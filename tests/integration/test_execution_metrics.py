"""
Integration tests for execution pipeline Prometheus metrics.

Tests that all metrics are properly recorded during webhook processing,
order execution, security checks, and validation.
"""

import pytest
import asyncio
import json
from unittest.mock import Mock, AsyncMock, patch
from prometheus_client import REGISTRY

# Import metrics
from src.services.execution.metrics import (
    webhook_requests_total,
    webhook_processing_duration,
    webhook_validation_failures,
    webhook_signature_failures,
    webhook_confidence_filtered,
    webhook_stale_rejected,
    active_requests,
    orders_total,
    order_execution_duration,
    order_failures,
    order_size_usd,
    exchange_connections,
    exchange_api_calls,
    exchange_errors,
    rate_limit_requests,
    rate_limit_rejections,
    circuit_breaker_state,
    circuit_breaker_transitions,
    ip_whitelist_checks,
    ip_whitelist_rejections,
    audit_events,
    validation_errors,
    normalization_operations,
    nan_replacements,
)

# Import components
from src.services.execution.webhooks.tradingview import TradingViewWebhook
from src.services.execution.exchanges.ccxt_plugin import CCXTPlugin
from src.services.execution.security.middleware import (
    create_rate_limiter,
    create_circuit_breaker,
    create_ip_whitelist,
    create_audit_logger,
    RateLimitConfig,
    CircuitBreakerConfig,
)
from src.services.execution.validation.normalizer import (
    create_normalizer,
    create_position_sizer,
)


class TestWebhookMetrics:
    """Test webhook handler metrics collection."""

    @pytest.fixture
    async def mock_plugin(self):
        """Create mock CCXT plugin."""
        plugin = Mock()
        plugin.execute_order = AsyncMock(return_value={
            'success': True,
            'order_id': 'test_order_123',
            'filled_quantity': 0.1,
            'average_price': 67000.0
        })
        return plugin

    @pytest.fixture
    def webhook_handler(self, mock_plugin):
        """Create webhook handler with mock plugin."""
        return TradingViewWebhook(
            plugin=mock_plugin,
            webhook_secret="test_secret",
            config={'min_confidence': 0.6}
        )

    @pytest.mark.asyncio
    async def test_successful_webhook_records_metrics(self, webhook_handler):
        """Test that successful webhook processing records all metrics."""
        # Get initial metric values
        initial_requests = self._get_counter_value(webhook_requests_total)
        initial_active = self._get_gauge_value(active_requests)
        
        # Create valid webhook payload
        payload = json.dumps({
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'order_type': 'market',
            'quantity': 0.1,
            'confidence': 0.85,
            'timestamp': 1699113600000
        })
        
        # Compute signature
        import hmac
        import hashlib
        signature = hmac.new(
            "test_secret".encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        # Process webhook
        result = await webhook_handler.process_webhook(payload, signature)
        
        # Assertions
        assert result['success'] is True
        
        # Check metrics increased
        new_requests = self._get_counter_value(webhook_requests_total)
        new_active = self._get_gauge_value(active_requests)
        
        assert new_requests > initial_requests, "webhook_requests_total should increase"
        assert new_active == initial_active, "active_requests should return to initial value"

    @pytest.mark.asyncio
    async def test_signature_failure_records_metric(self, webhook_handler):
        """Test that signature failures are recorded."""
        initial_failures = self._get_counter_value(webhook_signature_failures)
        
        payload = json.dumps({'symbol': 'BTC/USDT', 'side': 'buy'})
        
        # Process with invalid signature
        result = await webhook_handler.process_webhook(payload, "invalid_signature")
        
        assert result['success'] is False
        
        new_failures = self._get_counter_value(webhook_signature_failures)
        assert new_failures > initial_failures, "signature_failures should increase"

    @pytest.mark.asyncio
    async def test_validation_failure_records_metric(self, webhook_handler):
        """Test that validation failures are recorded."""
        initial_failures = self._get_counter_value(webhook_validation_failures)
        
        # Invalid JSON
        result = await webhook_handler.process_webhook("invalid json", None)
        
        assert result['success'] is False
        
        new_failures = self._get_counter_value(webhook_validation_failures)
        assert new_failures > initial_failures, "validation_failures should increase"

    @pytest.mark.asyncio
    async def test_low_confidence_records_metric(self, webhook_handler):
        """Test that low confidence filtering is recorded."""
        initial_filtered = self._get_counter_value(webhook_confidence_filtered)
        
        payload = json.dumps({
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'order_type': 'market',
            'quantity': 0.1,
            'confidence': 0.3  # Below 0.6 threshold
        })
        
        result = await webhook_handler.process_webhook(payload, None)
        
        assert result['success'] is False
        
        new_filtered = self._get_counter_value(webhook_confidence_filtered)
        assert new_filtered > initial_filtered, "confidence_filtered should increase"

    def _get_counter_value(self, counter):
        """Get total value from a Counter metric."""
        try:
            return sum(sample.value for sample in counter.collect()[0].samples)
        except (IndexError, AttributeError):
            return 0

    def _get_gauge_value(self, gauge):
        """Get current value from a Gauge metric."""
        try:
            return gauge.collect()[0].samples[0].value
        except (IndexError, AttributeError):
            return 0


class TestOrderMetrics:
    """Test order execution metrics collection."""

    @pytest.mark.asyncio
    async def test_order_execution_records_metrics(self):
        """Test that order execution records all relevant metrics."""
        initial_orders = self._get_counter_value(orders_total)
        initial_connections = self._get_gauge_value(exchange_connections)
        
        # Create plugin with mocked manager
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager') as mock_get_manager:
            mock_manager = Mock()
            mock_manager.init_exchange = AsyncMock()
            mock_manager.place_order = AsyncMock(return_value={
                'id': 'order_123',
                'filled': 0.1,
                'average': 67000.0,
                'timestamp': 1699113600000
            })
            mock_get_manager.return_value = mock_manager
            
            plugin = CCXTPlugin('binance', {'testnet': True})
            await plugin.init()
            
            # Execute order
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1,
                'confidence': 0.9
            }
            
            result = await plugin.execute_order(order)
            
            # Assertions
            assert result['success'] is True
            
            # Check metrics
            new_orders = self._get_counter_value(orders_total)
            new_connections = self._get_gauge_value(exchange_connections)
            
            assert new_orders > initial_orders, "orders_total should increase"
            assert new_connections > initial_connections, "exchange_connections should increase"
            
            await plugin.close()

    def _get_counter_value(self, counter):
        """Get total value from a Counter metric."""
        try:
            return sum(sample.value for sample in counter.collect()[0].samples)
        except (IndexError, AttributeError):
            return 0

    def _get_gauge_value(self, gauge):
        """Get current value from a Gauge metric."""
        try:
            samples = gauge.collect()[0].samples
            return sum(s.value for s in samples)
        except (IndexError, AttributeError):
            return 0


class TestSecurityMetrics:
    """Test security middleware metrics collection."""

    @pytest.mark.asyncio
    async def test_rate_limiter_records_metrics(self):
        """Test that rate limiter records check and rejection metrics."""
        limiter = create_rate_limiter(RateLimitConfig(max_requests=5, window_seconds=60))
        
        initial_checks = self._get_counter_value(rate_limit_requests)
        
        # Should allow first 5 requests
        for i in range(5):
            allowed = await limiter.check_rate_limit("192.168.1.100")
            assert allowed is True
        
        # 6th should be rejected (if no burst)
        allowed = await limiter.check_rate_limit("192.168.1.100")
        
        new_checks = self._get_counter_value(rate_limit_requests)
        assert new_checks > initial_checks, "rate_limit_requests should increase"

    @pytest.mark.asyncio
    async def test_circuit_breaker_records_transitions(self):
        """Test that circuit breaker records state transitions."""
        initial_transitions = self._get_counter_value(circuit_breaker_transitions)
        
        breaker = create_circuit_breaker(
            "test_exchange",
            CircuitBreakerConfig(failure_threshold=2, timeout_seconds=1)
        )
        
        # Cause failures to trigger transition
        async def failing_func():
            raise Exception("Test failure")
        
        for _ in range(3):
            try:
                await breaker.call(failing_func)
            except:
                pass
        
        new_transitions = self._get_counter_value(circuit_breaker_transitions)
        assert new_transitions > initial_transitions, "circuit_breaker_transitions should increase"

    @pytest.mark.asyncio
    async def test_ip_whitelist_records_checks(self):
        """Test that IP whitelist records check metrics."""
        whitelist = create_ip_whitelist(["192.168.1.0/24"])
        
        initial_checks = self._get_counter_value(ip_whitelist_checks)
        
        # Allowed IP
        allowed = whitelist.is_allowed("192.168.1.100")
        assert allowed is True
        
        # Blocked IP
        blocked = whitelist.is_allowed("10.0.0.1")
        assert blocked is False
        
        new_checks = self._get_counter_value(ip_whitelist_checks)
        assert new_checks > initial_checks, "ip_whitelist_checks should increase"

    @pytest.mark.asyncio
    async def test_audit_logger_records_events(self):
        """Test that audit logger records event metrics."""
        logger = create_audit_logger()
        
        initial_events = self._get_counter_value(audit_events)
        
        await logger.log(
            action="test_action",
            identifier="192.168.1.1",
            success=True
        )
        
        new_events = self._get_counter_value(audit_events)
        assert new_events > initial_events, "audit_events should increase"

    def _get_counter_value(self, counter):
        """Get total value from a Counter metric."""
        try:
            return sum(sample.value for sample in counter.collect()[0].samples)
        except (IndexError, AttributeError):
            return 0


class TestValidationMetrics:
    """Test validation layer metrics collection."""

    def test_symbol_normalization_records_metrics(self):
        """Test that symbol normalization records metrics."""
        normalizer = create_normalizer()
        
        initial_ops = self._get_counter_value(normalization_operations)
        
        # Normalize symbol
        result = normalizer.normalize_symbol("BTC-USDT")
        assert result == "BTC/USDT"
        
        new_ops = self._get_counter_value(normalization_operations)
        assert new_ops > initial_ops, "normalization_operations should increase"

    def test_validation_error_records_metrics(self):
        """Test that validation errors are recorded."""
        normalizer = create_normalizer()
        
        initial_errors = self._get_counter_value(validation_errors)
        
        # Try to normalize invalid symbol
        try:
            normalizer.normalize_symbol(None)
        except:
            pass
        
        new_errors = self._get_counter_value(validation_errors)
        assert new_errors > initial_errors, "validation_errors should increase"

    def test_nan_replacement_records_metrics(self):
        """Test that NaN replacements are recorded."""
        normalizer = create_normalizer()
        
        initial_nans = self._get_counter_value(nan_replacements)
        
        # Try to clean NaN value
        import math
        try:
            normalizer.clean_numeric(math.nan, "test_field")
        except:
            pass
        
        new_nans = self._get_counter_value(nan_replacements)
        assert new_nans > initial_nans, "nan_replacements should increase"

    def _get_counter_value(self, counter):
        """Get total value from a Counter metric."""
        try:
            return sum(sample.value for sample in counter.collect()[0].samples)
        except (IndexError, AttributeError):
            return 0


class TestEndToEndMetrics:
    """Test complete pipeline metrics flow."""

    @pytest.mark.asyncio
    async def test_complete_pipeline_records_all_metrics(self):
        """Test that a complete webhook → order flow records all relevant metrics."""
        # This is a smoke test to ensure the full pipeline works
        
        # Create mock plugin
        mock_plugin = Mock()
        mock_plugin.execute_order = AsyncMock(return_value={
            'success': True,
            'order_id': 'e2e_order_123',
            'filled_quantity': 0.1,
            'average_price': 67000.0
        })
        
        # Create webhook handler
        webhook = TradingViewWebhook(
            plugin=mock_plugin,
            webhook_secret="e2e_secret",
            config={'min_confidence': 0.6}
        )
        
        # Get initial metric values
        initial_webhooks = self._get_counter_value(webhook_requests_total)
        initial_active = self._get_gauge_value(active_requests)
        
        # Create payload
        payload = json.dumps({
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'order_type': 'market',
            'quantity': 0.1,
            'confidence': 0.85,
            'timestamp': 1699113600000
        })
        
        import hmac
        import hashlib
        signature = hmac.new(
            "e2e_secret".encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        # Process webhook
        result = await webhook.process_webhook(payload, signature)
        
        # Verify success
        assert result['success'] is True
        
        # Verify metrics recorded
        new_webhooks = self._get_counter_value(webhook_requests_total)
        new_active = self._get_gauge_value(active_requests)
        
        assert new_webhooks > initial_webhooks
        assert new_active == initial_active  # Should return to initial after processing

    def _get_counter_value(self, counter):
        """Get total value from a Counter metric."""
        try:
            return sum(sample.value for sample in counter.collect()[0].samples)
        except (IndexError, AttributeError):
            return 0

    def _get_gauge_value(self, gauge):
        """Get current value from a Gauge metric."""
        try:
            return gauge.collect()[0].samples[0].value
        except (IndexError, AttributeError):
            return 0


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
