"""
Tests for security middleware (rate limiting, circuit breakers, etc.).
"""

import pytest
import asyncio
from datetime import datetime

from src.services.execution.security import (
    RateLimiter,
    CircuitBreaker,
    IPWhitelist,
    AuditLogger,
    RateLimitConfig,
    CircuitBreakerConfig,
    CircuitState,
    create_rate_limiter,
    create_circuit_breaker,
    create_ip_whitelist,
    create_audit_logger,
)


class TestRateLimiter:
    """Test RateLimiter functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.config = RateLimitConfig(max_requests=5, window_seconds=1, burst_allowance=2)
        self.limiter = RateLimiter(self.config)

    @pytest.mark.asyncio
    async def test_allow_within_limit(self):
        """Test allowing requests within limit."""
        for i in range(5):
            allowed = await self.limiter.check_rate_limit("user1")
            assert allowed is True

    @pytest.mark.asyncio
    async def test_allow_with_burst(self):
        """Test burst allowance."""
        # 5 normal + 2 burst = 7 total
        for i in range(7):
            allowed = await self.limiter.check_rate_limit("user1")
            assert allowed is True

    @pytest.mark.asyncio
    async def test_block_over_limit(self):
        """Test blocking requests over limit."""
        # Use up limit + burst
        for i in range(7):
            await self.limiter.check_rate_limit("user1")

        # 8th request should be blocked
        allowed = await self.limiter.check_rate_limit("user1")
        assert allowed is False

    @pytest.mark.asyncio
    async def test_window_reset(self):
        """Test rate limit window reset."""
        # Use up limit
        for i in range(7):
            await self.limiter.check_rate_limit("user1")

        # Wait for window to expire
        await asyncio.sleep(1.1)

        # Should allow again
        allowed = await self.limiter.check_rate_limit("user1")
        assert allowed is True

    @pytest.mark.asyncio
    async def test_separate_identifiers(self):
        """Test separate limits per identifier."""
        # user1 uses up limit
        for i in range(7):
            await self.limiter.check_rate_limit("user1")

        # user2 should still be allowed
        allowed = await self.limiter.check_rate_limit("user2")
        assert allowed is True

    @pytest.mark.asyncio
    async def test_get_stats(self):
        """Test rate limit statistics."""
        await self.limiter.check_rate_limit("user1")
        await self.limiter.check_rate_limit("user1")

        stats = await self.limiter.get_stats("user1")
        assert stats["requests"] == 2
        assert stats["limit"] == 5
        assert stats["remaining"] == 5  # 5 + 2 burst - 2 used

    @pytest.mark.asyncio
    async def test_reset_identifier(self):
        """Test resetting specific identifier."""
        for i in range(7):
            await self.limiter.check_rate_limit("user1")

        self.limiter.reset("user1")
        allowed = await self.limiter.check_rate_limit("user1")
        assert allowed is True

    @pytest.mark.asyncio
    async def test_reset_all(self):
        """Test resetting all identifiers."""
        for i in range(7):
            await self.limiter.check_rate_limit("user1")
            await self.limiter.check_rate_limit("user2")

        self.limiter.reset()
        assert await self.limiter.check_rate_limit("user1") is True
        assert await self.limiter.check_rate_limit("user2") is True


class TestCircuitBreaker:
    """Test CircuitBreaker functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.config = CircuitBreakerConfig(
            failure_threshold=3, timeout_seconds=1, success_threshold=2
        )
        self.breaker = CircuitBreaker("test", self.config)

    @pytest.mark.asyncio
    async def test_initial_state_closed(self):
        """Test initial state is CLOSED."""
        assert self.breaker.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_success_keeps_closed(self):
        """Test successful calls keep circuit CLOSED."""

        async def success_func():
            return "ok"

        for i in range(5):
            result = await self.breaker.call(success_func)
            assert result == "ok"
            assert self.breaker.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_failures_open_circuit(self):
        """Test failures open circuit."""

        async def fail_func():
            raise Exception("Test failure")

        # Fail threshold times
        for i in range(3):
            with pytest.raises(Exception, match="Test failure"):
                await self.breaker.call(fail_func)

        # Circuit should be OPEN
        assert self.breaker.state == CircuitState.OPEN

    @pytest.mark.asyncio
    async def test_open_circuit_blocks_requests(self):
        """Test OPEN circuit blocks requests."""
        # Open circuit
        async def fail_func():
            raise Exception("Fail")

        for i in range(3):
            with pytest.raises(Exception):
                await self.breaker.call(fail_func)

        # Try to call - should be blocked
        async def any_func():
            return "ok"

        with pytest.raises(Exception, match="Circuit breaker.*is OPEN"):
            await self.breaker.call(any_func)

    @pytest.mark.asyncio
    async def test_half_open_after_timeout(self):
        """Test transition to HALF_OPEN after timeout."""
        # Open circuit
        async def fail_func():
            raise Exception("Fail")

        for i in range(3):
            with pytest.raises(Exception):
                await self.breaker.call(fail_func)

        assert self.breaker.state == CircuitState.OPEN

        # Wait for timeout
        await asyncio.sleep(1.1)

        # Try to call - should transition to HALF_OPEN
        async def success_func():
            return "ok"

        result = await self.breaker.call(success_func)
        assert result == "ok"
        # State depends on success count, but shouldn't be OPEN
        assert self.breaker.state != CircuitState.OPEN

    @pytest.mark.asyncio
    async def test_half_open_closes_on_success(self):
        """Test HALF_OPEN → CLOSED on success."""
        # Open circuit
        async def fail_func():
            raise Exception("Fail")

        for i in range(3):
            with pytest.raises(Exception):
                await self.breaker.call(fail_func)

        # Wait for timeout
        await asyncio.sleep(1.1)

        # Success threshold times
        async def success_func():
            return "ok"

        for i in range(2):
            await self.breaker.call(success_func)

        # Should be CLOSED
        assert self.breaker.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_half_open_reopens_on_failure(self):
        """Test HALF_OPEN → OPEN on failure."""
        # Open circuit
        async def fail_func():
            raise Exception("Fail")

        for i in range(3):
            with pytest.raises(Exception):
                await self.breaker.call(fail_func)

        # Wait for timeout
        await asyncio.sleep(1.1)

        # Fail again in HALF_OPEN
        with pytest.raises(Exception):
            await self.breaker.call(fail_func)

        assert self.breaker.state == CircuitState.OPEN

    @pytest.mark.asyncio
    async def test_get_stats(self):
        """Test circuit breaker statistics."""
        async def fail_func():
            raise Exception("Fail")

        with pytest.raises(Exception):
            await self.breaker.call(fail_func)

        stats = await self.breaker.get_stats()
        assert stats["name"] == "test"
        assert stats["state"] == "closed"
        assert stats["failure_count"] == 1
        assert stats["threshold"] == 3

    @pytest.mark.asyncio
    async def test_manual_reset(self):
        """Test manual circuit reset."""
        # Open circuit
        async def fail_func():
            raise Exception("Fail")

        for i in range(3):
            with pytest.raises(Exception):
                await self.breaker.call(fail_func)

        assert self.breaker.state == CircuitState.OPEN

        # Manual reset
        await self.breaker.reset()
        assert self.breaker.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_state_change_callback(self):
        """Test state change callback."""
        transitions = []

        def callback(old, new):
            transitions.append((old, new))

        breaker = CircuitBreaker("test", self.config, on_state_change=callback)

        async def fail_func():
            raise Exception("Fail")

        # Open circuit
        for i in range(3):
            with pytest.raises(Exception):
                await breaker.call(fail_func)

        # Should have CLOSED → OPEN transition
        assert (CircuitState.CLOSED, CircuitState.OPEN) in transitions


class TestIPWhitelist:
    """Test IPWhitelist functionality."""

    def test_no_whitelist_allows_all(self):
        """Test no whitelist allows all IPs."""
        whitelist = IPWhitelist()
        assert whitelist.is_allowed("192.168.1.1") is True
        assert whitelist.is_allowed("10.0.0.1") is True

    def test_exact_match_allowed(self):
        """Test exact IP match."""
        whitelist = IPWhitelist(["192.168.1.1", "10.0.0.1"])
        assert whitelist.is_allowed("192.168.1.1") is True
        assert whitelist.is_allowed("10.0.0.1") is True

    def test_not_in_whitelist_blocked(self):
        """Test blocking non-whitelisted IP."""
        whitelist = IPWhitelist(["192.168.1.1"])
        assert whitelist.is_allowed("192.168.1.2") is False
        assert whitelist.is_allowed("10.0.0.1") is False

    def test_cidr_range_allowed(self):
        """Test CIDR range matching (simplified)."""
        whitelist = IPWhitelist(["192.168.1.0/24"])
        # Simplified CIDR check - matches prefix
        assert whitelist.is_allowed("192.168.1.100") is True

    def test_add_ip(self):
        """Test adding IP to whitelist."""
        whitelist = IPWhitelist(["192.168.1.1"])
        assert whitelist.is_allowed("10.0.0.1") is False

        whitelist.add_ip("10.0.0.1")
        assert whitelist.is_allowed("10.0.0.1") is True

    def test_remove_ip(self):
        """Test removing IP from whitelist."""
        whitelist = IPWhitelist(["192.168.1.1", "10.0.0.1"])
        assert whitelist.is_allowed("10.0.0.1") is True

        whitelist.remove_ip("10.0.0.1")
        assert whitelist.is_allowed("10.0.0.1") is False


class TestAuditLogger:
    """Test AuditLogger functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.logger = AuditLogger(max_entries=100)

    @pytest.mark.asyncio
    async def test_log_success(self):
        """Test logging successful action."""
        await self.logger.log(
            action="webhook_request",
            identifier="192.168.1.1",
            success=True,
            details={"symbol": "BTC/USDT"},
        )

        entries = await self.logger.get_recent(count=1)
        assert len(entries) == 1
        assert entries[0].action == "webhook_request"
        assert entries[0].success is True

    @pytest.mark.asyncio
    async def test_log_failure(self):
        """Test logging failed action."""
        await self.logger.log(
            action="auth_failed",
            identifier="192.168.1.1",
            success=False,
            error="Invalid API key",
        )

        entries = await self.logger.get_recent(count=1)
        assert len(entries) == 1
        assert entries[0].success is False
        assert entries[0].error == "Invalid API key"

    @pytest.mark.asyncio
    async def test_get_recent(self):
        """Test retrieving recent entries."""
        for i in range(10):
            await self.logger.log(
                action="test", identifier=f"user{i}", success=True
            )

        entries = await self.logger.get_recent(count=5)
        assert len(entries) == 5

    @pytest.mark.asyncio
    async def test_get_by_identifier(self):
        """Test filtering by identifier."""
        await self.logger.log(action="test", identifier="user1", success=True)
        await self.logger.log(action="test", identifier="user2", success=True)
        await self.logger.log(action="test", identifier="user1", success=True)

        entries = await self.logger.get_by_identifier("user1")
        assert len(entries) == 2
        assert all(e.identifier == "user1" for e in entries)

    @pytest.mark.asyncio
    async def test_max_entries_limit(self):
        """Test max entries limit."""
        logger = AuditLogger(max_entries=5)

        # Log 10 entries
        for i in range(10):
            await logger.log(action="test", identifier=f"user{i}", success=True)

        # Should only keep last 5
        entries = await logger.get_recent(count=100)
        assert len(entries) == 5


class TestFactoryFunctions:
    """Test factory functions."""

    def test_create_rate_limiter(self):
        """Test rate limiter factory."""
        limiter = create_rate_limiter(RateLimitConfig(max_requests=10))
        assert limiter.config.max_requests == 10

    def test_create_circuit_breaker(self):
        """Test circuit breaker factory."""
        breaker = create_circuit_breaker("test", CircuitBreakerConfig(failure_threshold=5))
        assert breaker.name == "test"
        assert breaker.config.failure_threshold == 5

    def test_create_ip_whitelist(self):
        """Test IP whitelist factory."""
        whitelist = create_ip_whitelist(["192.168.1.1"])
        assert whitelist.is_allowed("192.168.1.1") is True

    def test_create_audit_logger(self):
        """Test audit logger factory."""
        logger = create_audit_logger(max_entries=50)
        assert logger.max_entries == 50
