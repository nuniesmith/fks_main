"""
End-to-end integration tests for the complete execution pipeline.

Tests the full flow from TradingView webhook → CCXT exchange order.
"""

import pytest
import pytest_asyncio
import asyncio
import json
import time
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from src.services.execution.webhooks import create_webhook_handler
from src.services.execution.exchanges import create_ccxt_plugin
from src.services.execution.validation import create_normalizer, create_position_sizer
from src.services.execution.security import (
    create_rate_limiter,
    create_circuit_breaker,
    create_ip_whitelist,
    create_audit_logger,
    RateLimitConfig,
    CircuitBreakerConfig,
)


@pytest_asyncio.fixture
async def execution_plugin():
    """Create CCXT plugin with mocked exchange."""
    # Create mock exchange
    exchange = AsyncMock()
    exchange.id = "binance"
    exchange.has = {"createOrder": True, "fetchTicker": True, "fetchBalance": True}
    
    # Mock successful order creation
    exchange.create_order = AsyncMock(
        return_value={
            "id": "test_order_123",
            "symbol": "BTC/USDT",
            "type": "market",
            "side": "buy",
            "amount": 0.1,
            "filled": 0.1,
            "average": 67000.0,
            "status": "closed",
        }
    )
    
    # Mock ticker fetch
    exchange.fetch_ticker = AsyncMock(
        return_value={
            "symbol": "BTC/USDT",
            "last": 67000.0,
            "bid": 66990.0,
            "ask": 67010.0,
        }
    )
    
    # Mock balance fetch
    exchange.fetch_balance = AsyncMock(
        return_value={
            "USDT": {"free": 10000.0, "used": 0.0, "total": 10000.0},
            "BTC": {"free": 1.0, "used": 0.0, "total": 1.0},
        }
    )
    
    exchange.close = AsyncMock()
    
    # Create plugin with mocked exchange
    with patch("src.services.execution.exchanges.manager.ccxt") as mock_ccxt:
        mock_ccxt.binance = MagicMock(return_value=exchange)
        
        plugin = create_ccxt_plugin("binance", api_key="test", api_secret="test")
        await plugin.init()
        
        yield plugin
        
        await plugin.close()


@pytest.fixture
def security_stack():
    """Create complete security stack."""
    return {
        "rate_limiter": create_rate_limiter(
            RateLimitConfig(max_requests=10, window_seconds=1)
        ),
        "circuit_breaker": create_circuit_breaker(
            "test_exchange",
            CircuitBreakerConfig(failure_threshold=3, timeout_seconds=1),
        ),
        "ip_whitelist": create_ip_whitelist(["192.168.1.1", "10.0.0.0/24"]),
        "audit_logger": create_audit_logger(),
    }


class TestEndToEndPipeline:
    """Test complete execution pipeline end-to-end."""

    @pytest.mark.asyncio
    async def test_complete_webhook_to_order_flow(self, execution_plugin):
        """Test full flow: TradingView webhook → CCXT order."""
        # Create webhook handler
        webhook = create_webhook_handler(
            execution_plugin,
            webhook_secret=None,  # Disable signature verification for testing
            min_confidence=0.6,
        )
        
        # Simulate TradingView alert payload
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        # Process webhook
        result = await webhook.process_webhook(json.dumps(payload))
        
        # Verify success
        assert result["success"] is True
        assert "order_id" in result
        assert result["order_id"] == "test_order_123"
        assert result["filled_quantity"] == 0.1
        assert result["average_price"] == 67000.0

    @pytest.mark.asyncio
    async def test_pipeline_with_symbol_normalization(self, execution_plugin):
        """Test pipeline with symbol normalization (BTC-USDT → BTC/USDT)."""
        webhook = create_webhook_handler(execution_plugin)
        
        # TradingView might send BTC-USDT instead of BTC/USDT
        payload = {
            "symbol": "BTC-USDT",  # Dash separator
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        
        assert result["success"] is True
        # Should be normalized to BTC/USDT internally

    @pytest.mark.asyncio
    async def test_pipeline_with_confidence_filter(self, execution_plugin):
        """Test pipeline rejects low confidence signals."""
        webhook = create_webhook_handler(
            execution_plugin,
            min_confidence=0.7,  # Require 70%
        )
        
        # Low confidence signal
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.5,  # Below threshold
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        
        assert result["success"] is False
        assert ("confidence" in result["message"].lower() or 
                "validation failed" in result["message"].lower())

    @pytest.mark.asyncio
    async def test_pipeline_with_stop_loss_take_profit(self, execution_plugin):
        """Test pipeline with TP/SL orders."""
        webhook = create_webhook_handler(execution_plugin)
        
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "stop_loss": 66000.0,
            "take_profit": 69000.0,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        
        # TP/SL orders may fail if exchange doesn't support them (logged as warnings)
        # Main order should still succeed
        assert result["success"] is True

    @pytest.mark.asyncio
    async def test_pipeline_with_security_stack(self, execution_plugin, security_stack):
        """Test pipeline with complete security middleware."""
        webhook = create_webhook_handler(execution_plugin)
        client_ip = "192.168.1.1"
        
        # Check IP whitelist
        assert security_stack["ip_whitelist"].is_allowed(client_ip) is True
        
        # Check rate limit
        allowed = await security_stack["rate_limiter"].check_rate_limit(client_ip)
        assert allowed is True
        
        # Process webhook with circuit breaker
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        async def execute_with_breaker():
            return await webhook.process_webhook(json.dumps(payload))
        
        result = await security_stack["circuit_breaker"].call(execute_with_breaker)
        
        # Audit log
        await security_stack["audit_logger"].log(
            action="webhook_processed",
            identifier=client_ip,
            success=result["success"],
            details={"order_id": result.get("order_id")},
        )
        
        assert result["success"] is True
        
        # Verify audit log
        logs = await security_stack["audit_logger"].get_recent(1)
        assert len(logs) == 1
        assert logs[0].action == "webhook_processed"
        assert logs[0].success is True

    @pytest.mark.asyncio
    async def test_rate_limit_blocks_excessive_requests(
        self, execution_plugin, security_stack
    ):
        """Test rate limiter blocks excessive requests."""
        webhook = create_webhook_handler(execution_plugin)
        rate_limiter = security_stack["rate_limiter"]
        client_ip = "192.168.1.1"
        
        # security_stack has max_requests=10, burst_allowance=10 (default)
        # So total allowed = 10 + 10 = 20
        for i in range(20):
            allowed = await rate_limiter.check_rate_limit(client_ip)
            assert allowed is True
        
        # 21st request should be blocked
        allowed = await rate_limiter.check_rate_limit(client_ip)
        assert allowed is False

    @pytest.mark.asyncio
    async def test_circuit_breaker_opens_on_failures(self, security_stack):
        """Test circuit breaker opens after failures."""
        breaker = security_stack["circuit_breaker"]
        
        # Simulate failures
        async def failing_operation():
            raise Exception("Exchange error")
        
        # Fail 3 times (threshold)
        for i in range(3):
            with pytest.raises(Exception):
                await breaker.call(failing_operation)
        
        # Circuit should be OPEN
        stats = await breaker.get_stats()
        assert stats["state"] == "open"
        
        # Next call should be blocked
        with pytest.raises(Exception, match="Circuit breaker.*is OPEN"):
            await breaker.call(failing_operation)

    @pytest.mark.asyncio
    async def test_data_normalization_pipeline(self, execution_plugin):
        """Test data normalization throughout pipeline."""
        normalizer = create_normalizer()
        webhook = create_webhook_handler(execution_plugin)
        
        # Test various input formats
        test_cases = [
            ("BTC-USDT", "BTC/USDT"),
            ("BTCUSDT", "BTC/USDT"),
            ("btc_usdt", "BTC/USDT"),
            ("ETH-USDC", "ETH/USDC"),
        ]
        
        for input_symbol, expected_symbol in test_cases:
            normalized = normalizer.normalize_symbol(input_symbol)
            assert normalized == expected_symbol

    @pytest.mark.asyncio
    async def test_position_sizing_integration(self, execution_plugin):
        """Test position sizing with execution pipeline."""
        sizer = create_position_sizer(account_balance=10000.0)
        webhook = create_webhook_handler(execution_plugin)
        
        # Calculate risk-based position size
        entry_price = 67000.0
        stop_loss = 66000.0
        position_size = sizer.calculate_risk_based(entry_price, stop_loss)
        
        # Execute order with calculated size
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": position_size,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        assert result["success"] is True

    @pytest.mark.asyncio
    async def test_performance_latency(self, execution_plugin):
        """Test end-to-end latency is acceptable (<500ms)."""
        webhook = create_webhook_handler(execution_plugin)
        
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        # Measure latency
        start = time.time()
        result = await webhook.process_webhook(json.dumps(payload))
        latency = (time.time() - start) * 1000  # Convert to ms
        
        assert result["success"] is True
        assert latency < 500, f"Latency {latency:.2f}ms exceeds 500ms threshold"

    @pytest.mark.asyncio
    async def test_concurrent_webhooks(self, execution_plugin):
        """Test handling concurrent webhook requests."""
        webhook = create_webhook_handler(execution_plugin)
        
        # Create 5 concurrent webhook requests
        payloads = [
            {
                "symbol": "BTC/USDT",
                "side": "buy",
                "order_type": "market",
                "quantity": 0.01 * (i + 1),
                "confidence": 0.85,
                "timestamp": int(datetime.utcnow().timestamp() * 1000),
            }
            for i in range(5)
        ]
        
        # Execute concurrently
        results = await asyncio.gather(
            *[webhook.process_webhook(json.dumps(p)) for p in payloads]
        )
        
        # All should succeed
        assert all(r["success"] for r in results)
        assert len(results) == 5

    @pytest.mark.asyncio
    async def test_invalid_payload_handling(self, execution_plugin):
        """Test graceful handling of invalid payloads."""
        webhook = create_webhook_handler(execution_plugin)
        
        # Missing required field
        invalid_payload = {
            "side": "buy",
            "quantity": 0.1,
            # Missing 'symbol'
        }
        
        result = await webhook.process_webhook(json.dumps(invalid_payload))
        
        assert result["success"] is False
        assert ("symbol" in result["message"].lower() or
                "validation failed" in result["message"].lower())

    @pytest.mark.asyncio
    async def test_stale_order_rejection(self, execution_plugin):
        """Test rejection of stale orders."""
        webhook = create_webhook_handler(
            execution_plugin,
            stale_timeout=300,  # 5 minutes
        )
        
        # Create stale order (10 minutes old)
        stale_timestamp = int((datetime.utcnow().timestamp() - 600) * 1000)
        
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": stale_timestamp,
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        
        assert result["success"] is False
        assert ("stale" in result["message"].lower() or 
                "validation failed" in result["message"].lower())

    @pytest.mark.asyncio
    async def test_exchange_failure_handling(self, execution_plugin):
        """Test handling of exchange failures."""
        # Get the internal exchange object and mock it to fail
        manager = execution_plugin.manager
        manager.exchanges["binance"].create_order = AsyncMock(
            side_effect=Exception("Exchange unavailable")
        )
        
        webhook = create_webhook_handler(execution_plugin)
        
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await webhook.process_webhook(json.dumps(payload))
        
        assert result["success"] is False
        assert ("error" in result["message"].lower() or 
                "failed" in result["message"].lower())


class TestPipelineComponents:
    """Test individual pipeline components work together."""

    @pytest.mark.asyncio
    async def test_normalizer_with_plugin(self, execution_plugin):
        """Test normalizer output works with plugin."""
        normalizer = create_normalizer()
        
        # Normalize order
        raw_order = {
            "symbol": "BTC-USDT",
            "quantity": "0.1",
            "price": "67000.123456789",
        }
        
        normalized = normalizer.normalize_order(raw_order)
        
        # Should work with plugin
        order = {
            **normalized,
            "side": "buy",
            "order_type": "limit",
            "confidence": 0.85,
        }
        
        result = await execution_plugin.execute_order(order)
        assert result["success"] is True

    @pytest.mark.asyncio
    async def test_security_with_webhook(self, execution_plugin, security_stack):
        """Test security stack integrates with webhook handler."""
        webhook = create_webhook_handler(execution_plugin)
        
        # Simulate secure request processing
        client_ip = "192.168.1.1"
        
        # 1. IP whitelist
        if not security_stack["ip_whitelist"].is_allowed(client_ip):
            pytest.fail("IP should be whitelisted")
        
        # 2. Rate limit
        if not await security_stack["rate_limiter"].check_rate_limit(client_ip):
            pytest.fail("Should be within rate limit")
        
        # 3. Process with circuit breaker
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.1,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        result = await security_stack["circuit_breaker"].call(
            webhook.process_webhook, json.dumps(payload)
        )
        
        # 4. Audit
        await security_stack["audit_logger"].log(
            action="test", identifier=client_ip, success=True
        )
        
        assert result["success"] is True


class TestPerformance:
    """Performance and stress tests."""

    @pytest.mark.asyncio
    async def test_throughput(self, execution_plugin):
        """Test system throughput (orders per second)."""
        webhook = create_webhook_handler(execution_plugin)
        
        num_orders = 100
        payload = {
            "symbol": "BTC/USDT",
            "side": "buy",
            "order_type": "market",
            "quantity": 0.01,
            "confidence": 0.85,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        
        start = time.time()
        
        # Process orders
        results = await asyncio.gather(
            *[webhook.process_webhook(json.dumps(payload)) for _ in range(num_orders)]
        )
        
        duration = time.time() - start
        throughput = num_orders / duration
        
        assert all(r["success"] for r in results)
        assert throughput > 50, f"Throughput {throughput:.2f} orders/s below 50/s target"

    @pytest.mark.asyncio
    async def test_memory_usage_under_load(self, execution_plugin, security_stack):
        """Test memory doesn't grow excessively under load."""
        webhook = create_webhook_handler(execution_plugin)
        audit_logger = security_stack["audit_logger"]
        
        # Process many requests
        for i in range(1000):
            payload = {
                "symbol": "BTC/USDT",
                "side": "buy",
                "order_type": "market",
                "quantity": 0.01,
                "confidence": 0.85,
                "timestamp": int(datetime.utcnow().timestamp() * 1000),
            }
            
            result = await webhook.process_webhook(json.dumps(payload))
            await audit_logger.log(
                action="test", identifier=f"user{i}", success=True
            )
        
        # Audit logger should have bounded memory (max_entries)
        logs = await audit_logger.get_recent(10000)
        assert len(logs) <= audit_logger.max_entries
