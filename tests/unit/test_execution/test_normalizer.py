"""
Tests for data normalization and position sizing.
"""

import math
import pytest
from decimal import Decimal

from src.services.execution.validation import (
    DataNormalizer,
    PositionSizer,
    ValidationError,
    create_normalizer,
    create_position_sizer,
)


class TestDataNormalizer:
    """Test DataNormalizer functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.normalizer = DataNormalizer(
            max_price_deviation=0.1,
            min_quantity=0.0001,
            max_quantity=1000.0,
            price_precision=8,
            quantity_precision=8,
        )

    # Symbol Normalization Tests

    def test_normalize_symbol_already_correct(self):
        """Test normalizing already-correct symbols."""
        assert self.normalizer.normalize_symbol("BTC/USDT") == "BTC/USDT"
        assert self.normalizer.normalize_symbol("eth/usdc") == "ETH/USDC"

    def test_normalize_symbol_dash_separator(self):
        """Test normalizing dash-separated symbols."""
        assert self.normalizer.normalize_symbol("BTC-USDT") == "BTC/USDT"
        assert self.normalizer.normalize_symbol("eth-busd") == "ETH/BUSD"

    def test_normalize_symbol_underscore_separator(self):
        """Test normalizing underscore-separated symbols."""
        assert self.normalizer.normalize_symbol("BTC_USDT") == "BTC/USDT"
        assert self.normalizer.normalize_symbol("eth_usdc") == "ETH/USDC"

    def test_normalize_symbol_no_separator(self):
        """Test normalizing symbols without separators."""
        assert self.normalizer.normalize_symbol("BTCUSDT") == "BTC/USDT"
        assert self.normalizer.normalize_symbol("ETHBUSD") == "ETH/BUSD"
        assert self.normalizer.normalize_symbol("BNBBTC") == "BNB/BTC"

    def test_normalize_symbol_invalid_empty(self):
        """Test normalizing empty/None symbols."""
        with pytest.raises(ValidationError, match="Invalid symbol"):
            self.normalizer.normalize_symbol("")
        with pytest.raises(ValidationError, match="Invalid symbol"):
            self.normalizer.normalize_symbol(None)

    def test_normalize_symbol_invalid_format(self):
        """Test normalizing unparseable symbols."""
        with pytest.raises(ValidationError, match="Cannot normalize symbol"):
            self.normalizer.normalize_symbol("INVALID")
        with pytest.raises(ValidationError, match="Cannot normalize symbol"):
            self.normalizer.normalize_symbol("ABC123")

    # Numeric Cleaning Tests

    def test_clean_numeric_valid_float(self):
        """Test cleaning valid floats."""
        assert self.normalizer.clean_numeric(123.45) == 123.45
        assert self.normalizer.clean_numeric(0.0001) == 0.0001
        assert self.normalizer.clean_numeric(-50.0) == -50.0

    def test_clean_numeric_valid_string(self):
        """Test cleaning numeric strings."""
        assert self.normalizer.clean_numeric("123.45") == 123.45
        assert self.normalizer.clean_numeric("  100  ") == 100.0

    def test_clean_numeric_invalid_none(self):
        """Test cleaning None values."""
        with pytest.raises(ValidationError, match="cannot be None"):
            self.normalizer.clean_numeric(None)

    def test_clean_numeric_invalid_nan(self):
        """Test cleaning NaN values."""
        with pytest.raises(ValidationError, match="is NaN"):
            self.normalizer.clean_numeric(float("nan"))

    def test_clean_numeric_invalid_inf(self):
        """Test cleaning infinite values."""
        with pytest.raises(ValidationError, match="is infinite"):
            self.normalizer.clean_numeric(float("inf"))
        with pytest.raises(ValidationError, match="is infinite"):
            self.normalizer.clean_numeric(float("-inf"))

    def test_clean_numeric_invalid_string(self):
        """Test cleaning non-numeric strings."""
        with pytest.raises(ValidationError, match="Invalid"):
            self.normalizer.clean_numeric("not a number")

    # Precision Rounding Tests

    def test_round_to_precision_normal(self):
        """Test precision rounding."""
        assert self.normalizer.round_to_precision(123.456789, 2) == 123.45
        assert self.normalizer.round_to_precision(0.123456, 4) == 0.1234
        assert self.normalizer.round_to_precision(100.999, 0) == 100.0

    def test_round_to_precision_round_down(self):
        """Test rounding down for safety."""
        # Should round down, not up
        assert self.normalizer.round_to_precision(0.999999, 2) == 0.99
        assert self.normalizer.round_to_precision(123.999, 1) == 123.9

    def test_round_to_precision_invalid(self):
        """Test invalid precision."""
        with pytest.raises(ValidationError, match="Invalid precision"):
            self.normalizer.round_to_precision(123.45, -1)

    # Price Normalization Tests

    def test_normalize_price_valid(self):
        """Test normalizing valid prices."""
        price = self.normalizer.normalize_price(123.456789)
        assert price == 123.45678900  # Rounded to 8 decimals

    def test_normalize_price_negative(self):
        """Test normalizing negative prices."""
        with pytest.raises(ValidationError, match="must be positive"):
            self.normalizer.normalize_price(-100.0)

    def test_normalize_price_zero(self):
        """Test normalizing zero price."""
        with pytest.raises(ValidationError, match="must be positive"):
            self.normalizer.normalize_price(0)

    def test_normalize_price_with_market_price(self):
        """Test price validation against market price."""
        # Within deviation (5%)
        price = self.normalizer.normalize_price(105.0, market_price=100.0)
        assert price == 105.0

    def test_normalize_price_excessive_deviation(self):
        """Test rejecting excessive price deviation."""
        # 15% deviation (max is 10%)
        with pytest.raises(ValidationError, match="deviates.*from market"):
            self.normalizer.normalize_price(115.0, market_price=100.0)

    # Quantity Normalization Tests

    def test_normalize_quantity_valid(self):
        """Test normalizing valid quantities."""
        assert self.normalizer.normalize_quantity(0.5) == 0.5
        assert self.normalizer.normalize_quantity(100) == 100.0

    def test_normalize_quantity_negative(self):
        """Test normalizing negative quantities."""
        with pytest.raises(ValidationError, match="must be positive"):
            self.normalizer.normalize_quantity(-10)

    def test_normalize_quantity_below_minimum(self):
        """Test rejecting quantities below minimum."""
        with pytest.raises(ValidationError, match="below minimum"):
            self.normalizer.normalize_quantity(0.00001)  # min is 0.0001

    def test_normalize_quantity_above_maximum(self):
        """Test rejecting quantities above maximum."""
        with pytest.raises(ValidationError, match="above maximum"):
            self.normalizer.normalize_quantity(1500)  # max is 1000

    # Complete Order Normalization Tests

    def test_normalize_order_minimal(self):
        """Test normalizing minimal order."""
        order = {"symbol": "BTC-USDT", "quantity": 0.1}
        normalized = self.normalizer.normalize_order(order)

        assert normalized["symbol"] == "BTC/USDT"
        assert normalized["quantity"] == 0.1

    def test_normalize_order_complete(self):
        """Test normalizing complete order."""
        order = {
            "symbol": "ETH_USDT",
            "quantity": "0.5",
            "price": "2000.123456789",
            "stop_loss": 1950.0,
            "take_profit": 2100.0,
            "side": "buy",
            "order_type": "limit",
            "confidence": 0.85,
        }

        normalized = self.normalizer.normalize_order(order, market_price=2000.0)

        assert normalized["symbol"] == "ETH/USDT"
        assert normalized["quantity"] == 0.5
        assert normalized["price"] == 2000.12345678  # Rounded to 8 decimals
        assert normalized["stop_loss"] == 1950.0
        assert normalized["take_profit"] == 2100.0
        assert normalized["side"] == "buy"
        assert normalized["order_type"] == "limit"
        assert normalized["confidence"] == 0.85

    def test_normalize_order_missing_symbol(self):
        """Test normalizing order without symbol."""
        with pytest.raises(ValidationError, match="Missing required field: symbol"):
            self.normalizer.normalize_order({"quantity": 0.1})

    def test_normalize_order_missing_quantity(self):
        """Test normalizing order without quantity."""
        with pytest.raises(ValidationError, match="Missing required field: quantity"):
            self.normalizer.normalize_order({"symbol": "BTC/USDT"})


class TestPositionSizer:
    """Test PositionSizer functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.sizer = PositionSizer(
            account_balance=10000.0,
            max_risk_per_trade=0.01,  # 1%
            max_position_size=0.1,  # 10%
        )

    # Initialization Tests

    def test_init_valid(self):
        """Test valid initialization."""
        sizer = PositionSizer(10000.0)
        assert sizer.account_balance == 10000.0
        assert sizer.max_risk_per_trade == 0.01
        assert sizer.max_position_size == 0.1

    def test_init_invalid_balance(self):
        """Test invalid account balance."""
        with pytest.raises(ValueError, match="must be positive"):
            PositionSizer(0)
        with pytest.raises(ValueError, match="must be positive"):
            PositionSizer(-1000)

    def test_init_invalid_risk(self):
        """Test invalid risk parameters."""
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            PositionSizer(10000, max_risk_per_trade=0)
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            PositionSizer(10000, max_risk_per_trade=1.5)

    def test_init_invalid_position_size(self):
        """Test invalid position size."""
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            PositionSizer(10000, max_position_size=0)
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            PositionSizer(10000, max_position_size=2.0)

    # Fixed Percentage Tests

    def test_calculate_fixed_percentage_normal(self):
        """Test fixed percentage calculation."""
        # 5% of $10,000 at $100/unit = 5 units
        size = self.sizer.calculate_fixed_percentage(0.05, 100.0)
        assert size == 5.0

    def test_calculate_fixed_percentage_capped(self):
        """Test fixed percentage capped at max."""
        # 20% requested, but max is 10% → $1,000 at $100/unit = 10 units
        size = self.sizer.calculate_fixed_percentage(0.2, 100.0)
        assert size == 10.0

    def test_calculate_fixed_percentage_invalid(self):
        """Test invalid percentage."""
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            self.sizer.calculate_fixed_percentage(0, 100.0)
        with pytest.raises(ValueError, match="must be between 0 and 1"):
            self.sizer.calculate_fixed_percentage(1.5, 100.0)

    def test_calculate_fixed_percentage_invalid_price(self):
        """Test invalid price."""
        with pytest.raises(ValueError, match="must be positive"):
            self.sizer.calculate_fixed_percentage(0.05, 0)
        with pytest.raises(ValueError, match="must be positive"):
            self.sizer.calculate_fixed_percentage(0.05, -100)

    # Risk-Based Position Sizing Tests

    def test_calculate_risk_based_normal(self):
        """Test risk-based position sizing."""
        # Risk 1% of $10,000 = $100
        # Entry $100, stop $50 → $50 risk per unit
        # Position size = $100 / $50 = 2 units
        # But capped at max 10% = $1000 at $100 = 10 units (not hit)
        # Actually: $100 / $50 = 2, but max is $1000/$100 = 10, so 2 < 10 → returns 2
        # Wait, let me recalculate: 1% of $10k = $100 risk, at $50/unit = 2 units
        # Max position = 10% of $10k at $100/unit = 10 units
        # Since 2 < 10, should return 2... but it's returning 1
        # 
        # Oh! The issue is the max position calculation uses entry_price
        # Max = $1000 / $1000 = 1 unit (this is the cap!)
        # So with entry $1000, max position is only 1 unit
        # Let's use smaller entry price to avoid hitting the cap
        size = self.sizer.calculate_risk_based(entry_price=100.0, stop_loss=50.0)
        assert size == 2.0

    def test_calculate_risk_based_custom_risk(self):
        """Test risk-based sizing with custom risk percentage."""
        # Risk 0.5% of $10,000 = $50
        # Entry $1000, stop $950 → $50 risk per unit
        # Position size = $50 / $50 = 1 unit
        size = self.sizer.calculate_risk_based(
            entry_price=1000.0, stop_loss=950.0, risk_percentage=0.005
        )
        assert size == 1.0

    def test_calculate_risk_based_capped_at_max(self):
        """Test risk-based sizing capped at max position size."""
        # Very tight stop loss → large position, but capped at 10%
        # Max position = 10% of $10,000 at $100/unit = 10 units
        size = self.sizer.calculate_risk_based(entry_price=100.0, stop_loss=99.0)
        assert size == 10.0  # Capped at max

    def test_calculate_risk_based_invalid_prices(self):
        """Test invalid prices."""
        with pytest.raises(ValidationError, match="must be positive"):
            self.sizer.calculate_risk_based(entry_price=0, stop_loss=50)
        with pytest.raises(ValidationError, match="must be positive"):
            self.sizer.calculate_risk_based(entry_price=100, stop_loss=-50)

    def test_calculate_risk_based_stop_equals_entry(self):
        """Test stop loss equal to entry price."""
        with pytest.raises(ValidationError, match="cannot equal entry"):
            self.sizer.calculate_risk_based(entry_price=100.0, stop_loss=100.0)

    # Volatility-Adjusted Position Sizing Tests

    def test_calculate_volatility_adjusted_low_vol(self):
        """Test volatility-adjusted sizing with low volatility."""
        # Low volatility (1%) → larger position
        size = self.sizer.calculate_volatility_adjusted(
            price=100.0, volatility=1.0, base_percentage=0.05
        )
        # 1% vol → 100% adjustment → 5% of $10k at $100 = 5 units
        assert size == 5.0

    def test_calculate_volatility_adjusted_high_vol(self):
        """Test volatility-adjusted sizing with high volatility."""
        # High volatility (5%) → smaller position
        size = self.sizer.calculate_volatility_adjusted(
            price=100.0, volatility=5.0, base_percentage=0.05
        )
        # 5% vol → 20% adjustment → 1% of $10k at $100 = 1 unit
        assert size == 1.0

    def test_calculate_volatility_adjusted_zero_vol(self):
        """Test volatility-adjusted sizing with zero volatility."""
        # Zero volatility → full base percentage
        size = self.sizer.calculate_volatility_adjusted(
            price=100.0, volatility=0.0, base_percentage=0.05
        )
        assert size == 5.0

    def test_calculate_volatility_adjusted_invalid_price(self):
        """Test invalid price."""
        with pytest.raises(ValueError, match="must be positive"):
            self.sizer.calculate_volatility_adjusted(
                price=0, volatility=1.0, base_percentage=0.05
            )

    def test_calculate_volatility_adjusted_invalid_volatility(self):
        """Test invalid volatility."""
        with pytest.raises(ValueError, match="cannot be negative"):
            self.sizer.calculate_volatility_adjusted(
                price=100.0, volatility=-1.0, base_percentage=0.05
            )


class TestFactoryFunctions:
    """Test factory functions."""

    def test_create_normalizer(self):
        """Test normalizer factory."""
        normalizer = create_normalizer(max_price_deviation=0.2)
        assert normalizer.max_price_deviation == 0.2

    def test_create_position_sizer(self):
        """Test position sizer factory."""
        sizer = create_position_sizer(5000.0, max_risk_per_trade=0.02)
        assert sizer.account_balance == 5000.0
        assert sizer.max_risk_per_trade == 0.02
