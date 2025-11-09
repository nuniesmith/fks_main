"""
Tests for ExchangeManager - CCXT integration.

Tests cover:
- Exchange initialization (testnet/mainnet)
- Market data fetching
- Order placement with TP/SL
- Balance queries
- Error handling

Uses proper mocking to avoid real API calls.
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from src.services.execution.exchanges.manager import ExchangeManager


@pytest.fixture
def manager():
    """Fresh ExchangeManager instance."""
    return ExchangeManager()


@pytest.fixture
def mock_exchange():
    """Mock CCXT exchange with common methods."""
    exchange = AsyncMock()
    exchange.load_markets = AsyncMock()
    exchange.fetch_ticker = AsyncMock()
    exchange.fetch_balance = AsyncMock()
    exchange.create_order = AsyncMock()
    exchange.cancel_order = AsyncMock()
    exchange.fetch_order = AsyncMock()
    exchange.close = AsyncMock()
    exchange.has = {
        'createStopLossOrder': True,
        'createTakeProfitOrder': True
    }
    return exchange


class TestExchangeInitialization:
    """Test exchange connection initialization."""
    
    @pytest.mark.asyncio
    async def test_init_exchange_success(self, manager, mock_exchange):
        """Test successful exchange initialization."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance', testnet=False)
            
            assert 'binance' in manager.exchanges
            mock_exchange.load_markets.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_init_exchange_with_credentials(self, manager, mock_exchange):
        """Test initialization with API credentials."""
        credentials = {
            'api_key': 'test_key',
            'api_secret': 'test_secret'
        }
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance', credentials=credentials)
            
            # Verify credentials were passed to constructor
            call_args = mock_ccxt.binance.call_args[0][0]
            assert call_args['apiKey'] == 'test_key'
            assert call_args['secret'] == 'test_secret'
    
    @pytest.mark.asyncio
    async def test_init_exchange_testnet(self, manager, mock_exchange):
        """Test testnet initialization."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance', testnet=True)
            
            # Verify testnet URLs were set
            call_args = mock_ccxt.binance.call_args[0][0]
            assert 'urls' in call_args or 'options' in call_args
    
    @pytest.mark.asyncio
    async def test_init_exchange_failure(self, manager):
        """Test handling of initialization failure."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(side_effect=Exception("Connection failed"))
            with pytest.raises(Exception, match="Connection failed"):
                await manager.init_exchange('binance')


class TestMarketData:
    """Test market data fetching."""
    
    @pytest.mark.asyncio
    async def test_fetch_ticker(self, manager, mock_exchange):
        """Test fetching ticker data."""
        mock_ticker = {
            'symbol': 'BTC/USDT',
            'bid': 67500.0,
            'ask': 67505.0,
            'last': 67502.5,
            'baseVolume': 12345.67,
            'timestamp': 1699113600000,
            'high': 68000.0,
            'low': 67000.0,
            'change': 500.0,
            'percentage': 0.74
        }
        mock_exchange.fetch_ticker.return_value = mock_ticker
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.fetch_ticker('binance', 'BTC/USDT')
            
            assert result['symbol'] == 'BTC/USDT'
            assert result['bid'] == 67500.0
            assert result['ask'] == 67505.0
            assert result['last'] == 67502.5
            assert result['volume'] == 12345.67
            mock_exchange.fetch_ticker.assert_called_once_with('BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_ticker_uninitialized_exchange(self, manager):
        """Test fetching ticker from uninitialized exchange."""
        with pytest.raises(ValueError, match="not initialized"):
            await manager.fetch_ticker('binance', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_fetch_balance(self, manager, mock_exchange):
        """Test fetching account balance."""
        mock_balance = {
            'total': {'BTC': 0.5, 'USDT': 10000, 'ETH': 0},
            'free': {'BTC': 0.4, 'USDT': 10000, 'ETH': 0},
            'used': {'BTC': 0.1, 'USDT': 0, 'ETH': 0}
        }
        mock_exchange.fetch_balance.return_value = mock_balance
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.fetch_balance('binance')
            
            # Should only return non-zero balances
            assert 'BTC' in result
            assert 'USDT' in result
            assert 'ETH' not in result  # Zero balance excluded
            
            assert result['BTC']['total'] == 0.5
            assert result['BTC']['free'] == 0.4
            assert result['BTC']['used'] == 0.1


class TestOrderPlacement:
    """Test order placement with TP/SL."""
    
    @pytest.mark.asyncio
    async def test_place_market_order(self, manager, mock_exchange):
        """Test placing a market order."""
        mock_order = {
            'id': '12345',
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'type': 'market',
            'status': 'closed',
            'filled': 0.1,
            'average': 67500.0,
            'timestamp': 1699113600000
        }
        mock_exchange.create_order.return_value = mock_order
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.place_order(
                'binance',
                'BTC/USDT',
                'buy',
                'market',
                0.1
            )
            
            assert result['id'] == '12345'
            assert result['symbol'] == 'BTC/USDT'
            assert result['filled'] == 0.1
            mock_exchange.create_order.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_place_limit_order(self, manager, mock_exchange):
        """Test placing a limit order."""
        mock_order = {
            'id': '12346',
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'type': 'limit',
            'status': 'open',
            'filled': 0,
            'price': 67000.0,
            'timestamp': 1699113600000
        }
        mock_exchange.create_order.return_value = mock_order
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.place_order(
                'binance',
                'BTC/USDT',
                'buy',
                'limit',
                0.1,
                price=67000.0
            )
            
            assert result['type'] == 'limit'
            assert result['status'] == 'open'
    
    @pytest.mark.asyncio
    async def test_place_order_with_stop_loss(self, manager, mock_exchange):
        """Test placing order with stop-loss."""
        main_order = {
            'id': '12347',
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'type': 'market',
            'status': 'closed',
            'filled': 0.1,
            'average': 67500.0,
            'timestamp': 1699113600000
        }
        sl_order = {
            'id': '12348',
            'symbol': 'BTC/USDT',
            'side': 'sell',
            'type': 'stop_loss_limit',
            'status': 'open'
        }
        mock_exchange.create_order.side_effect = [main_order, sl_order]
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.place_order(
                'binance',
                'BTC/USDT',
                'buy',
                'market',
                0.1,
                stop_loss=66000.0
            )
            
            # Should have called create_order twice (main + SL)
            assert mock_exchange.create_order.call_count == 2
            assert result['id'] == '12347'
    
    @pytest.mark.asyncio
    async def test_place_order_with_take_profit(self, manager, mock_exchange):
        """Test placing order with take-profit."""
        main_order = {
            'id': '12349',
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'type': 'market',
            'status': 'closed',
            'filled': 0.1,
            'average': 67500.0,
            'timestamp': 1699113600000
        }
        tp_order = {
            'id': '12350',
            'symbol': 'BTC/USDT',
            'side': 'sell',
            'type': 'take_profit_limit',
            'status': 'open'
        }
        mock_exchange.create_order.side_effect = [main_order, tp_order]
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.place_order(
                'binance',
                'BTC/USDT',
                'buy',
                'market',
                0.1,
                take_profit=69000.0
            )
            
            # Should have called create_order twice (main + TP)
            assert mock_exchange.create_order.call_count == 2
    
    @pytest.mark.asyncio
    async def test_place_limit_order_without_price(self, manager, mock_exchange):
        """Test that limit orders require price."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            
            with pytest.raises(ValueError, match="Price required"):
                await manager.place_order(
                    'binance',
                    'BTC/USDT',
                    'buy',
                    'limit',
                    0.1
                )


class TestOrderManagement:
    """Test order management operations."""
    
    @pytest.mark.asyncio
    async def test_cancel_order(self, manager, mock_exchange):
        """Test order cancellation."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.cancel_order('binance', '12345', 'BTC/USDT')
            
            assert result is True
            mock_exchange.cancel_order.assert_called_once_with('12345', 'BTC/USDT')
    
    @pytest.mark.asyncio
    async def test_cancel_order_failure(self, manager, mock_exchange):
        """Test handling of cancel failure."""
        mock_exchange.cancel_order.side_effect = Exception("Order not found")
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.cancel_order('binance', '12345', 'BTC/USDT')
            
            assert result is False
    
    @pytest.mark.asyncio
    async def test_fetch_order(self, manager, mock_exchange):
        """Test fetching order details."""
        mock_order = {
            'id': '12345',
            'symbol': 'BTC/USDT',
            'side': 'buy',
            'type': 'limit',
            'status': 'open',
            'filled': 0,
            'remaining': 0.1,
            'price': 67000.0,
            'timestamp': 1699113600000
        }
        mock_exchange.fetch_order.return_value = mock_order
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            result = await manager.fetch_order('binance', '12345', 'BTC/USDT')
            
            assert result['id'] == '12345'
            assert result['status'] == 'open'
            assert result['remaining'] == 0.1


class TestUtilityMethods:
    """Test utility and management methods."""
    
    def test_list_exchanges(self, manager):
        """Test listing all CCXT exchanges."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.exchanges = ['binance', 'coinbase', 'kraken']
            exchanges = manager.list_exchanges()
            
            assert isinstance(exchanges, list)
            assert 'binance' in exchanges
            assert 'coinbase' in exchanges
    
    @pytest.mark.asyncio
    async def test_get_initialized_exchanges(self, manager, mock_exchange):
        """Test listing initialized exchanges."""
        mock_exchange2 = AsyncMock()
        mock_exchange2.load_markets = AsyncMock()
        
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            mock_ccxt.coinbase = Mock(return_value=mock_exchange2)
            
            await manager.init_exchange('binance')
            await manager.init_exchange('coinbase')
            
            initialized = manager.get_initialized_exchanges()
            assert 'binance' in initialized
            assert 'coinbase' in initialized
            assert len(initialized) == 2
    
    @pytest.mark.asyncio
    async def test_close_all(self, manager, mock_exchange):
        """Test closing all exchange connections."""
        with patch('src.services.execution.exchanges.manager.ccxt') as mock_ccxt:
            mock_ccxt.binance = Mock(return_value=mock_exchange)
            await manager.init_exchange('binance')
            await manager.close_all()
            
            assert len(manager.exchanges) == 0
            mock_exchange.close.assert_called_once()


class TestSingletonPattern:
    """Test the singleton pattern for ExchangeManager."""
    
    def test_get_exchange_manager_singleton(self):
        """Test that get_exchange_manager returns same instance."""
        from src.services.execution.exchanges import get_exchange_manager
        
        manager1 = get_exchange_manager()
        manager2 = get_exchange_manager()
        
        assert manager1 is manager2
