"""
Tests for CCXTPlugin - ExecutionPlugin implementation for CCXT.

Tests cover:
- Plugin initialization
- Order execution with confidence filtering
- Market data fetching
- Balance queries
- Health checks
- Order management
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from src.services.execution.exchanges.ccxt_plugin import CCXTPlugin, create_ccxt_plugin


@pytest.fixture
def mock_manager():
    """Mock ExchangeManager."""
    manager = AsyncMock()
    manager.init_exchange = AsyncMock()
    manager.fetch_ticker = AsyncMock()
    manager.fetch_balance = AsyncMock()
    manager.place_order = AsyncMock()
    manager.cancel_order = AsyncMock()
    manager.fetch_order = AsyncMock()
    return manager


class TestPluginInitialization:
    """Test plugin initialization."""
    
    @pytest.mark.asyncio
    async def test_init_success(self, mock_manager):
        """Test successful plugin initialization."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            result = await plugin.init()
            
            assert result is True
            assert plugin._initialized is True
            mock_manager.init_exchange.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_init_with_credentials(self, mock_manager):
        """Test initialization with API credentials."""
        config = {
            'api_key': 'test_key',
            'api_secret': 'test_secret',
            'testnet': True
        }
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance', config)
            await plugin.init()
            
            call_args = mock_manager.init_exchange.call_args
            assert call_args[1]['credentials']['api_key'] == 'test_key'
            assert call_args[1]['testnet'] is True
    
    @pytest.mark.asyncio
    async def test_init_failure(self, mock_manager):
        """Test handling of initialization failure."""
        mock_manager.init_exchange.side_effect = Exception("Connection failed")
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            result = await plugin.init()
            
            assert result is False
            assert plugin._initialized is False
    
    def test_create_plugin_convenience_function(self):
        """Test create_ccxt_plugin convenience function."""
        plugin = create_ccxt_plugin('binance', api_key='xxx', testnet=True)
        
        assert isinstance(plugin, CCXTPlugin)
        assert plugin.exchange_id == 'binance'
        assert plugin.config['api_key'] == 'xxx'
        assert plugin.config['testnet'] is True


class TestOrderExecution:
    """Test order execution with confidence filtering."""
    
    @pytest.mark.asyncio
    async def test_execute_market_order(self, mock_manager):
        """Test executing a market order."""
        mock_result = {
            'id': '12345',
            'symbol': 'BTC/USDT',
            'filled': 0.1,
            'average': 67500.0,
            'timestamp': 1699113600000
        }
        mock_manager.place_order.return_value = mock_result
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1,
                'confidence': 0.8
            }
            
            result = await plugin.execute_order(order)
            
            assert result['success'] is True
            assert result['order_id'] == '12345'
            assert result['filled_quantity'] == 0.1
            assert result['average_price'] == 67500.0
    
    @pytest.mark.asyncio
    async def test_execute_limit_order_with_tp_sl(self, mock_manager):
        """Test executing a limit order with TP/SL."""
        mock_result = {
            'id': '12346',
            'symbol': 'BTC/USDT',
            'filled': 0,
            'average': 0,
            'timestamp': 1699113600000
        }
        mock_manager.place_order.return_value = mock_result
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'limit',
                'quantity': 0.1,
                'price': 67000.0,
                'stop_loss': 66000.0,
                'take_profit': 69000.0,
                'confidence': 0.9
            }
            
            result = await plugin.execute_order(order)
            
            assert result['success'] is True
            mock_manager.place_order.assert_called_once_with(
                'binance',
                symbol='BTC/USDT',
                side='buy',
                order_type='limit',
                amount=0.1,
                price=67000.0,
                stop_loss=66000.0,
                take_profit=69000.0,
                params={}
            )
    
    @pytest.mark.asyncio
    async def test_confidence_filter_reject(self, mock_manager):
        """Test that low confidence orders are rejected."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance', {'min_confidence': 0.7})
            await plugin.init()
            
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1,
                'confidence': 0.5  # Below threshold
            }
            
            result = await plugin.execute_order(order)
            
            assert result['success'] is False
            assert 'below threshold' in result['error']
            assert result['order_id'] is None
    
    @pytest.mark.asyncio
    async def test_confidence_filter_default(self, mock_manager):
        """Test default confidence threshold (0.6)."""
        mock_result = {'id': '12347', 'filled': 0.1, 'average': 67500.0, 'timestamp': 0}
        mock_manager.place_order.return_value = mock_result
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')  # No explicit min_confidence
            await plugin.init()
            
            # Should accept 0.6
            order1 = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1,
                'confidence': 0.6
            }
            result1 = await plugin.execute_order(order1)
            assert result1['success'] is True
            
            # Should reject 0.5
            order2 = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1,
                'confidence': 0.5
            }
            result2 = await plugin.execute_order(order2)
            assert result2['success'] is False
    
    @pytest.mark.asyncio
    async def test_execute_order_not_initialized(self, mock_manager):
        """Test executing order before initialization."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            # Don't call init()
            
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1
            }
            
            result = await plugin.execute_order(order)
            
            assert result['success'] is False
            assert 'not initialized' in result['error']
    
    @pytest.mark.asyncio
    async def test_execute_order_exception(self, mock_manager):
        """Test handling of order execution exception."""
        mock_manager.place_order.side_effect = Exception("API error")
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            order = {
                'symbol': 'BTC/USDT',
                'side': 'buy',
                'order_type': 'market',
                'quantity': 0.1
            }
            
            result = await plugin.execute_order(order)
            
            assert result['success'] is False
            assert 'API error' in result['error']


class TestMarketData:
    """Test market data fetching."""
    
    @pytest.mark.asyncio
    async def test_fetch_data(self, mock_manager):
        """Test fetching market data."""
        mock_ticker = {
            'symbol': 'BTC/USDT',
            'bid': 67500.0,
            'ask': 67505.0,
            'last': 67502.5,
            'volume': 12345.67,
            'timestamp': 1699113600000
        }
        mock_manager.fetch_ticker.return_value = mock_ticker
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            data = await plugin.fetch_data('BTC/USDT')
            
            assert data['bid'] == 67500.0
            assert data['ask'] == 67505.0
            assert data['last'] == 67502.5
            assert data['volume'] == 12345.67
            mock_manager.fetch_ticker.assert_called_once_with('binance', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_data_custom_exchange(self, mock_manager):
        """Test fetching data from custom exchange."""
        mock_ticker = {'bid': 67500.0, 'ask': 67505.0, 'last': 67502.5, 'volume': 0, 'timestamp': 0}
        mock_manager.fetch_ticker.return_value = mock_ticker
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            await plugin.fetch_data('BTC/USDT', exchange_id='coinbase')
            
            mock_manager.fetch_ticker.assert_called_once_with('coinbase', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_data_not_initialized(self, mock_manager):
        """Test fetching data before initialization."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            
            with pytest.raises(RuntimeError, match="not initialized"):
                await plugin.fetch_data('BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_balance(self, mock_manager):
        """Test fetching account balance."""
        mock_balance = {
            'BTC': {'free': 0.5, 'used': 0.1, 'total': 0.6},
            'USDT': {'free': 10000, 'used': 0, 'total': 10000}
        }
        mock_manager.fetch_balance.return_value = mock_balance
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            balance = await plugin.fetch_balance()
            
            assert 'BTC' in balance
            assert 'USDT' in balance
            assert balance['BTC']['total'] == 0.6


class TestOrderManagement:
    """Test order management operations."""
    
    @pytest.mark.asyncio
    async def test_cancel_order(self, mock_manager):
        """Test order cancellation."""
        mock_manager.cancel_order.return_value = True
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            result = await plugin.cancel_order('12345', 'BTC/USDT')
            
            assert result is True
            mock_manager.cancel_order.assert_called_once_with('binance', '12345', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_order(self, mock_manager):
        """Test fetching order details."""
        mock_order = {
            'id': '12345',
            'status': 'open',
            'filled': 0,
            'remaining': 0.1
        }
        mock_manager.fetch_order.return_value = mock_order
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            order = await plugin.fetch_order('12345', 'BTC/USDT')
            
            assert order['id'] == '12345'
            assert order['status'] == 'open'


class TestPluginUtilities:
    """Test plugin utility methods."""
    
    def test_name(self):
        """Test plugin name."""
        plugin = CCXTPlugin('binance')
        assert plugin.name() == 'ccxt:binance'
        
        plugin2 = CCXTPlugin('coinbase')
        assert plugin2.name() == 'ccxt:coinbase'
    
    @pytest.mark.asyncio
    async def test_health_check_success(self, mock_manager):
        """Test successful health check."""
        mock_manager.fetch_ticker.return_value = {'bid': 67500.0, 'ask': 67505.0, 'last': 67502.5}
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            is_healthy = await plugin.health_check()
            
            assert is_healthy is True
            mock_manager.fetch_ticker.assert_called_once_with('binance', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_health_check_failure(self, mock_manager):
        """Test failed health check."""
        mock_manager.fetch_ticker.side_effect = Exception("API error")
        
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            is_healthy = await plugin.health_check()
            
            assert is_healthy is False
    
    @pytest.mark.asyncio
    async def test_health_check_not_initialized(self, mock_manager):
        """Test health check before initialization."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            
            is_healthy = await plugin.health_check()
            
            assert is_healthy is False
    
    @pytest.mark.asyncio
    async def test_close(self, mock_manager):
        """Test plugin close."""
        with patch('src.services.execution.exchanges.ccxt_plugin.get_exchange_manager', return_value=mock_manager):
            plugin = CCXTPlugin('binance')
            await plugin.init()
            
            assert plugin._initialized is True
            
            await plugin.close()
            
            assert plugin._initialized is False
