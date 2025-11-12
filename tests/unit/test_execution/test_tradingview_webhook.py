"""
Tests for TradingView Webhook Handler

Tests cover:
- Signature verification
- Payload validation
- Confidence filtering
- Risk checks (quantity, value, symbol whitelist)
- Order execution
- Stale order rejection
- Error handling
"""

import pytest
import json
import hmac
import hashlib
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime

from src.services.execution.webhooks.tradingview import (
    TradingViewWebhook,
    create_webhook_handler,
    ValidationError,
    SignatureError
)


@pytest.fixture
def mock_plugin():
    """Mock CCXTPlugin."""
    plugin = AsyncMock()
    plugin.name = MagicMock(return_value="ccxt:binance")  # Regular method, not async
    plugin.execute_order = AsyncMock()
    return plugin


@pytest.fixture
def webhook_secret():
    """Test webhook secret."""
    return "test_secret_key_12345"


@pytest.fixture
def valid_payload():
    """Valid webhook payload."""
    return {
        'symbol': 'BTC/USDT',
        'side': 'buy',
        'order_type': 'market',
        'quantity': 0.1,
        'confidence': 0.85,
        'timestamp': int(datetime.utcnow().timestamp() * 1000)
    }


def sign_payload(payload: str, secret: str) -> str:
    """Generate HMAC signature for payload."""
    return hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()


class TestSignatureVerification:
    """Test webhook signature verification."""
    
    def test_verify_signature_valid(self, mock_plugin, webhook_secret):
        """Test valid signature verification."""
        handler = TradingViewWebhook(mock_plugin, webhook_secret)
        payload = '{"symbol": "BTC/USDT"}'
        signature = sign_payload(payload, webhook_secret)
        
        result = handler.verify_signature(payload, signature)
        assert result is True
    
    def test_verify_signature_invalid(self, mock_plugin, webhook_secret):
        """Test invalid signature rejection."""
        handler = TradingViewWebhook(mock_plugin, webhook_secret)
        payload = '{"symbol": "BTC/USDT"}'
        signature = "invalid_signature"
        
        with pytest.raises(SignatureError, match="Invalid webhook signature"):
            handler.verify_signature(payload, signature)
    
    def test_verify_signature_missing(self, mock_plugin, webhook_secret):
        """Test missing signature rejection."""
        handler = TradingViewWebhook(mock_plugin, webhook_secret, {'require_signature': True})
        payload = '{"symbol": "BTC/USDT"}'
        
        with pytest.raises(SignatureError, match="Signature missing"):
            handler.verify_signature(payload, None)
    
    def test_verify_signature_not_required(self, mock_plugin):
        """Test signature not required when secret not set."""
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        payload = '{"symbol": "BTC/USDT"}'
        
        result = handler.verify_signature(payload, None)
        assert result is True


class TestPayloadValidation:
    """Test webhook payload validation."""
    
    def test_validate_valid_payload(self, mock_plugin, valid_payload):
        """Test valid payload passes validation."""
        handler = TradingViewWebhook(mock_plugin)
        handler.validate_payload(valid_payload)  # Should not raise
    
    def test_validate_missing_required_field(self, mock_plugin):
        """Test rejection of payload missing required fields."""
        handler = TradingViewWebhook(mock_plugin)
        
        incomplete_payload = {
            'symbol': 'BTC/USDT',
            'side': 'buy',
            # Missing order_type and quantity
        }
        
        with pytest.raises(ValidationError, match="Missing required field"):
            handler.validate_payload(incomplete_payload)
    
    def test_validate_invalid_side(self, mock_plugin, valid_payload):
        """Test rejection of invalid side."""
        handler = TradingViewWebhook(mock_plugin)
        valid_payload['side'] = 'invalid'
        
        with pytest.raises(ValidationError, match="Invalid side"):
            handler.validate_payload(valid_payload)
    
    def test_validate_invalid_order_type(self, mock_plugin, valid_payload):
        """Test rejection of invalid order type."""
        handler = TradingViewWebhook(mock_plugin)
        valid_payload['order_type'] = 'invalid'
        
        with pytest.raises(ValidationError, match="Invalid order_type"):
            handler.validate_payload(valid_payload)
    
    def test_validate_negative_quantity(self, mock_plugin, valid_payload):
        """Test rejection of negative quantity."""
        handler = TradingViewWebhook(mock_plugin)
        valid_payload['quantity'] = -0.5
        
        with pytest.raises(ValidationError, match="Invalid quantity"):
            handler.validate_payload(valid_payload)
    
    def test_validate_limit_order_without_price(self, mock_plugin, valid_payload):
        """Test rejection of limit order without price."""
        handler = TradingViewWebhook(mock_plugin)
        valid_payload['order_type'] = 'limit'
        # No price field
        
        with pytest.raises(ValidationError, match="require 'price'"):
            handler.validate_payload(valid_payload)


class TestConfidenceFiltering:
    """Test confidence threshold filtering."""
    
    def test_validate_confidence_above_threshold(self, mock_plugin, valid_payload):
        """Test payload with sufficient confidence passes."""
        handler = TradingViewWebhook(mock_plugin, config={'min_confidence': 0.7})
        valid_payload['confidence'] = 0.85
        
        handler.validate_payload(valid_payload)  # Should not raise
    
    def test_validate_confidence_below_threshold(self, mock_plugin, valid_payload):
        """Test payload with low confidence rejected."""
        handler = TradingViewWebhook(mock_plugin, config={'min_confidence': 0.7})
        valid_payload['confidence'] = 0.5
        
        with pytest.raises(ValidationError, match="below threshold"):
            handler.validate_payload(valid_payload)
    
    def test_validate_confidence_default_threshold(self, mock_plugin, valid_payload):
        """Test default confidence threshold (0.6)."""
        handler = TradingViewWebhook(mock_plugin)
        
        # Should accept 0.6
        valid_payload['confidence'] = 0.6
        handler.validate_payload(valid_payload)
        
        # Should reject 0.5
        valid_payload['confidence'] = 0.5
        with pytest.raises(ValidationError, match="below threshold"):
            handler.validate_payload(valid_payload)
    
    def test_validate_confidence_out_of_range(self, mock_plugin, valid_payload):
        """Test confidence must be 0-1."""
        handler = TradingViewWebhook(mock_plugin)
        
        valid_payload['confidence'] = 1.5
        with pytest.raises(ValidationError, match="must be 0-1"):
            handler.validate_payload(valid_payload)


class TestRiskChecks:
    """Test risk management checks."""
    
    def test_validate_max_quantity(self, mock_plugin, valid_payload):
        """Test maximum quantity limit."""
        handler = TradingViewWebhook(mock_plugin, config={'max_quantity': 0.5})
        valid_payload['quantity'] = 1.0
        
        with pytest.raises(ValidationError, match="exceeds max"):
            handler.validate_payload(valid_payload)
    
    def test_validate_symbol_whitelist_allowed(self, mock_plugin, valid_payload):
        """Test symbol whitelist allows valid symbols."""
        handler = TradingViewWebhook(
            mock_plugin,
            config={'symbol_whitelist': ['BTC/USDT', 'ETH/USDT']}
        )
        valid_payload['symbol'] = 'BTC/USDT'
        
        handler.validate_payload(valid_payload)  # Should not raise
    
    def test_validate_symbol_whitelist_blocked(self, mock_plugin, valid_payload):
        """Test symbol whitelist blocks invalid symbols."""
        handler = TradingViewWebhook(
            mock_plugin,
            config={'symbol_whitelist': ['BTC/USDT', 'ETH/USDT']}
        )
        valid_payload['symbol'] = 'DOGE/USDT'
        
        with pytest.raises(ValidationError, match="not in whitelist"):
            handler.validate_payload(valid_payload)
    
    def test_validate_max_order_value(self, mock_plugin, valid_payload):
        """Test maximum order value limit."""
        handler = TradingViewWebhook(mock_plugin, config={'max_order_value': 5000.0})
        valid_payload['price'] = 67000.0
        valid_payload['quantity'] = 0.1  # 67000 * 0.1 = 6700 > 5000
        
        with pytest.raises(ValidationError, match="exceeds max"):
            handler.validate_payload(valid_payload)
    
    def test_validate_stale_order(self, mock_plugin, valid_payload):
        """Test stale order rejection."""
        handler = TradingViewWebhook(mock_plugin, config={'stale_timeout': 60})
        # Order from 2 minutes ago
        valid_payload['timestamp'] = int((datetime.utcnow().timestamp() - 120) * 1000)
        
        with pytest.raises(ValidationError, match="too old"):
            handler.validate_payload(valid_payload)
    
    def test_validate_future_timestamp(self, mock_plugin, valid_payload):
        """Test future timestamp rejection."""
        handler = TradingViewWebhook(mock_plugin)
        # Order from 2 minutes in the future
        valid_payload['timestamp'] = int((datetime.utcnow().timestamp() + 120) * 1000)
        
        with pytest.raises(ValidationError, match="in the future"):
            handler.validate_payload(valid_payload)


class TestWebhookProcessing:
    """Test webhook processing end-to-end."""
    
    @pytest.mark.asyncio
    async def test_process_webhook_success(self, mock_plugin, valid_payload):
        """Test successful webhook processing."""
        mock_plugin.execute_order.return_value = {
            'success': True,
            'order_id': '12345',
            'filled_quantity': 0.1,
            'average_price': 67500.0
        }
        
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        payload_str = json.dumps(valid_payload)
        
        result = await handler.process_webhook(payload_str)
        
        assert result['success'] is True
        assert result['order_id'] == '12345'
        assert 'message' in result
        mock_plugin.execute_order.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_process_webhook_with_signature(self, mock_plugin, valid_payload, webhook_secret):
        """Test webhook processing with signature verification."""
        mock_plugin.execute_order.return_value = {
            'success': True,
            'order_id': '12346',
            'filled_quantity': 0.1,
            'average_price': 67500.0
        }
        
        handler = TradingViewWebhook(mock_plugin, webhook_secret)
        payload_str = json.dumps(valid_payload)
        signature = sign_payload(payload_str, webhook_secret)
        
        result = await handler.process_webhook(payload_str, signature)
        
        assert result['success'] is True
    
    @pytest.mark.asyncio
    async def test_process_webhook_invalid_signature(self, mock_plugin, valid_payload, webhook_secret):
        """Test webhook rejection with invalid signature."""
        handler = TradingViewWebhook(mock_plugin, webhook_secret)
        payload_str = json.dumps(valid_payload)
        
        result = await handler.process_webhook(payload_str, "invalid_sig")
        
        assert result['success'] is False
        assert 'Signature verification failed' in result['message']
    
    @pytest.mark.asyncio
    async def test_process_webhook_invalid_json(self, mock_plugin):
        """Test webhook rejection with invalid JSON."""
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        
        result = await handler.process_webhook("not valid json")
        
        assert result['success'] is False
        assert 'Invalid JSON' in result['error']
    
    @pytest.mark.asyncio
    async def test_process_webhook_validation_failure(self, mock_plugin):
        """Test webhook rejection on validation failure."""
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        invalid_payload = {'symbol': 'BTC/USDT'}  # Missing required fields
        
        result = await handler.process_webhook(json.dumps(invalid_payload))
        
        assert result['success'] is False
        assert 'Validation failed' in result['message']
    
    @pytest.mark.asyncio
    async def test_process_webhook_execution_failure(self, mock_plugin, valid_payload):
        """Test handling of order execution failure."""
        mock_plugin.execute_order.return_value = {
            'success': False,
            'error': 'Insufficient balance'
        }
        
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        
        result = await handler.process_webhook(json.dumps(valid_payload))
        
        assert result['success'] is False
        assert 'Insufficient balance' in result['error']
    
    @pytest.mark.asyncio
    async def test_process_webhook_with_optional_fields(self, mock_plugin, valid_payload):
        """Test webhook with optional fields (price, SL, TP)."""
        mock_plugin.execute_order.return_value = {
            'success': True,
            'order_id': '12347',
            'filled_quantity': 0,
            'average_price': 0
        }
        
        handler = TradingViewWebhook(mock_plugin, None, {'require_signature': False})
        valid_payload['order_type'] = 'limit'
        valid_payload['price'] = 67000.0
        valid_payload['stop_loss'] = 66000.0
        valid_payload['take_profit'] = 69000.0
        valid_payload['exchange'] = 'coinbase'
        
        result = await handler.process_webhook(json.dumps(valid_payload))
        
        assert result['success'] is True
        
        # Verify order dict passed to plugin
        call_args = mock_plugin.execute_order.call_args[0][0]
        assert call_args['price'] == 67000.0
        assert call_args['stop_loss'] == 66000.0
        assert call_args['take_profit'] == 69000.0
        assert call_args['exchange'] == 'coinbase'


class TestUtilityMethods:
    """Test utility methods."""
    
    def test_create_webhook_handler(self, mock_plugin):
        """Test create_webhook_handler convenience function."""
        handler = create_webhook_handler(
            mock_plugin,
            webhook_secret='secret',
            min_confidence=0.7,
            max_quantity=1.0
        )
        
        assert isinstance(handler, TradingViewWebhook)
        assert handler.webhook_secret == 'secret'
        assert handler.min_confidence == 0.7
        assert handler.max_quantity == 1.0
    
    def test_get_stats(self, mock_plugin):
        """Test get_stats returns configuration."""
        handler = TradingViewWebhook(
            mock_plugin,
            webhook_secret='secret',
            config={
                'min_confidence': 0.75,
                'max_quantity': 2.0,
                'symbol_whitelist': ['BTC/USDT', 'ETH/USDT']
            }
        )
        
        stats = handler.get_stats()
        
        assert stats['min_confidence'] == 0.75
        assert stats['max_quantity'] == 2.0
        assert 'BTC/USDT' in stats['symbol_whitelist']
        assert stats['require_signature'] is True
        assert stats['plugin'] == 'ccxt:binance'
