# FKS Currency Conversion and FX Rate Handling

## Overview

The FKS Currency Conversion System handles multi-currency portfolios by managing base currencies (USD, EUR, BTC), fetching and updating foreign exchange rates, calculating P&L in base currency, and tracking currency exposure risk.

**Key Principle**: All portfolio values and P&L are calculated in the user's base currency, with real-time FX rate updates and currency risk tracking.

## Table of Contents

1. [Base Currency Management](#base-currency-management)
2. [FX Rate Updates](#fx-rate-updates)
3. [P&L Calculation](#pl-calculation)
4. [FX Risk Management](#fx-risk-management)
5. [Currency Conversion API](#currency-conversion-api)
6. [Configuration](#configuration)

---

## Base Currency Management

Support multiple base currencies for different accounts and portfolios.

### Account Base Currency

```python
from enum import Enum
from decimal import Decimal
from typing import Optional

class Currency(Enum):
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    JPY = "JPY"
    CAD = "CAD"
    BTC = "BTC"
    ETH = "ETH"
    USDT = "USDT"

class Account:
    """Account with base currency"""
    
    def __init__(
        self,
        account_id: int,
        name: str,
        base_currency: Currency = Currency.USD,
        initial_balance: Decimal = Decimal("0"),
        current_balance: Decimal = Decimal("0")
    ):
        self.account_id = account_id
        self.name = name
        self.base_currency = base_currency
        self.initial_balance = initial_balance
        self.current_balance = current_balance
    
    async def get_balance_in_base(self) -> Decimal:
        """Get current balance in base currency"""
        if self.current_balance_currency == self.base_currency:
            return self.current_balance
        
        # Convert to base currency
        fx_rate = await get_fx_rate(
            from_currency=self.current_balance_currency,
            to_currency=self.base_currency
        )
        
        return self.current_balance * fx_rate
```

### Portfolio Base Currency

```python
class Portfolio:
    """Portfolio with base currency"""
    
    def __init__(
        self,
        portfolio_id: int,
        name: str,
        base_currency: Currency = Currency.USD,
        accounts: List[Account] = None
    ):
        self.portfolio_id = portfolio_id
        self.name = name
        self.base_currency = base_currency
        self.accounts = accounts or []
    
    async def get_total_value(self) -> Decimal:
        """Get total portfolio value in base currency"""
        total = Decimal("0")
        
        for account in self.accounts:
            account_value = await account.get_balance_in_base()
            total += account_value
        
        return total
    
    async def get_positions_value(self) -> Decimal:
        """Get total positions value in base currency"""
        total = Decimal("0")
        
        for account in self.accounts:
            positions = await get_account_positions(account.account_id)
            
            for position in positions:
                # Get position currency
                position_currency = await get_position_currency(position.symbol)
                
                # Calculate position value
                position_value = position.quantity * position.current_price
                
                # Convert to base currency
                if position_currency != self.base_currency:
                    fx_rate = await get_fx_rate(
                        from_currency=position_currency,
                        to_currency=self.base_currency
                    )
                    position_value *= fx_rate
                
                total += position_value
        
        return total
```

---

## FX Rate Updates

Fetch and update foreign exchange rates from multiple providers.

### FX Rate Provider

```python
from datetime import datetime, timedelta
import asyncio
import aiohttp

class FXRateProvider:
    """Base class for FX rate providers"""
    
    def __init__(self, name: str, api_key: Optional[str] = None):
        self.name = name
        self.api_key = api_key
        self.base_url = None
    
    async def get_rate(
        self,
        from_currency: Currency,
        to_currency: Currency
    ) -> Decimal:
        """Get FX rate from provider"""
        raise NotImplementedError
    
    async def get_rates_batch(
        self,
        pairs: List[tuple[Currency, Currency]]
    ) -> Dict[tuple[Currency, Currency], Decimal]:
        """Get multiple FX rates in batch"""
        raise NotImplementedError

class ExchangeRatesAPIProvider(FXRateProvider):
    """Exchange Rates API provider (free tier available)"""
    
    def __init__(self, api_key: str):
        super().__init__("exchangeratesapi", api_key)
        self.base_url = "https://api.exchangerate.host"
    
    async def get_rate(
        self,
        from_currency: Currency,
        to_currency: Currency
    ) -> Decimal:
        """Get FX rate"""
        if from_currency == to_currency:
            return Decimal("1.0")
        
        url = f"{self.base_url}/latest"
        params = {
            "base": from_currency.value,
            "symbols": to_currency.value
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(url, params=params) as response:
                data = await response.json()
                
                if data.get("success", False):
                    rate = Decimal(str(data["rates"][to_currency.value]))
                    return rate
                else:
                    raise Exception(f"Failed to get FX rate: {data.get('error')}")

class CryptoFXProvider(FXRateProvider):
    """Crypto-to-fiat FX rates via exchange APIs"""
    
    def __init__(self, exchange_name: str = "binance"):
        super().__init__(f"crypto_{exchange_name}")
        self.exchange_name = exchange_name
        self.exchange = None
    
    async def initialize(self):
        """Initialize exchange connection"""
        exchange_class = getattr(ccxt, self.exchange_name)
        self.exchange = exchange_class({
            'enableRateLimit': True
        })
        await self.exchange.load_markets()
    
    async def get_rate(
        self,
        from_currency: Currency,
        to_currency: Currency
    ) -> Decimal:
        """Get crypto-to-fiat rate"""
        if from_currency == to_currency:
            return Decimal("1.0")
        
        # Build symbol (e.g., BTC/USDT)
        symbol = f"{from_currency.value}/{to_currency.value}"
        
        if symbol not in self.exchange.markets:
            # Try reverse
            symbol = f"{to_currency.value}/{from_currency.value}"
            if symbol not in self.exchange.markets:
                raise ValueError(f"Symbol {symbol} not available")
            
            # Get reverse rate and invert
            ticker = await self.exchange.fetch_ticker(symbol)
            rate = Decimal(str(ticker['last']))
            return Decimal("1.0") / rate
        
        # Get rate
        ticker = await self.exchange.fetch_ticker(symbol)
        return Decimal(str(ticker['last']))
```

### FX Rate Manager

```python
class FXRateManager:
    """Manage FX rates with caching and updates"""
    
    def __init__(
        self,
        providers: List[FXRateProvider],
        cache_ttl_seconds: int = 300  # 5 minutes
    ):
        self.providers = providers
        self.cache_ttl = cache_ttl_seconds
        self.rate_cache: Dict[tuple[Currency, Currency], tuple[Decimal, datetime]] = {}
        self.provider_priority = [p.name for p in providers]
    
    async def get_rate(
        self,
        from_currency: Currency,
        to_currency: Currency,
        force_refresh: bool = False
    ) -> Decimal:
        """Get FX rate with caching"""
        if from_currency == to_currency:
            return Decimal("1.0")
        
        cache_key = (from_currency, to_currency)
        
        # Check cache
        if not force_refresh and cache_key in self.rate_cache:
            rate, cached_time = self.rate_cache[cache_key]
            if (datetime.utcnow() - cached_time).total_seconds() < self.cache_ttl:
                return rate
        
        # Fetch from provider
        rate = await self._fetch_rate(from_currency, to_currency)
        
        # Cache
        self.rate_cache[cache_key] = (rate, datetime.utcnow())
        
        return rate
    
    async def _fetch_rate(
        self,
        from_currency: Currency,
        to_currency: Currency
    ) -> Decimal:
        """Fetch rate from providers"""
        # Try providers in priority order
        for provider_name in self.provider_priority:
            provider = self._get_provider(provider_name)
            if not provider:
                continue
            
            try:
                # Determine if crypto or fiat
                is_crypto = from_currency in [Currency.BTC, Currency.ETH, Currency.USDT] or \
                          to_currency in [Currency.BTC, Currency.ETH, Currency.USDT]
                
                if is_crypto:
                    # Use crypto provider
                    crypto_provider = self._get_crypto_provider()
                    if crypto_provider:
                        return await crypto_provider.get_rate(from_currency, to_currency)
                else:
                    # Use fiat provider
                    fiat_provider = self._get_fiat_provider()
                    if fiat_provider:
                        return await fiat_provider.get_rate(from_currency, to_currency)
            
            except Exception as e:
                logger.warning(f"Provider {provider_name} failed: {e}")
                continue
        
        raise Exception(f"All providers failed for {from_currency} -> {to_currency}")
    
    def _get_provider(self, name: str) -> Optional[FXRateProvider]:
        """Get provider by name"""
        for provider in self.providers:
            if provider.name == name:
                return provider
        return None
    
    def _get_crypto_provider(self) -> Optional[FXRateProvider]:
        """Get crypto FX provider"""
        for provider in self.providers:
            if isinstance(provider, CryptoFXProvider):
                return provider
        return None
    
    def _get_fiat_provider(self) -> Optional[FXRateProvider]:
        """Get fiat FX provider"""
        for provider in self.providers:
            if isinstance(provider, ExchangeRatesAPIProvider):
                return provider
        return None
    
    async def update_rates(self, pairs: List[tuple[Currency, Currency]]):
        """Update rates for multiple pairs"""
        for from_curr, to_curr in pairs:
            await self.get_rate(from_curr, to_curr, force_refresh=True)
```

### FX Rate Database

```sql
CREATE TABLE fx_rates (
    id SERIAL PRIMARY KEY,
    from_currency VARCHAR(10) NOT NULL,
    to_currency VARCHAR(10) NOT NULL,
    rate DECIMAL(20, 8) NOT NULL,
    provider VARCHAR(50),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(from_currency, to_currency, timestamp)
);

CREATE INDEX idx_fx_rates_currencies ON fx_rates(from_currency, to_currency);
CREATE INDEX idx_fx_rates_timestamp ON fx_rates(timestamp DESC);

-- Get latest rate
CREATE OR REPLACE FUNCTION get_latest_fx_rate(
    p_from_currency VARCHAR,
    p_to_currency VARCHAR
) RETURNS DECIMAL AS $$
    SELECT rate
    FROM fx_rates
    WHERE from_currency = p_from_currency
      AND to_currency = p_to_currency
    ORDER BY timestamp DESC
    LIMIT 1;
$$ LANGUAGE SQL;
```

### FX Rate Update Scheduler

```python
from celery import shared_task

@shared_task
async def update_fx_rates_task():
    """Periodic task to update FX rates"""
    manager = FXRateManager(get_fx_providers())
    
    # Get all currency pairs in use
    pairs = await get_active_currency_pairs()
    
    # Update rates
    await manager.update_rates(pairs)
    
    # Store in database
    for from_curr, to_curr in pairs:
        rate = await manager.get_rate(from_curr, to_curr)
        await store_fx_rate(from_curr, to_curr, rate, "exchangeratesapi")
```

---

## P&L Calculation

Calculate realized and unrealized P&L in base currency.

### Realized P&L

```python
class PnLCalculator:
    """Calculate P&L in base currency"""
    
    def __init__(self, fx_manager: FXRateManager):
        self.fx_manager = fx_manager
    
    async def calculate_realized_pnl(
        self,
        trade: Trade,
        base_currency: Currency
    ) -> Decimal:
        """
        Calculate realized P&L in base currency.
        
        Args:
            trade: Trade object
            base_currency: Base currency for calculation
        
        Returns:
            Realized P&L in base currency
        """
        # Get trade currency (from symbol)
        trade_currency = await get_trade_currency(trade.symbol)
        
        # Calculate P&L in trade currency
        if trade.side == "buy":
            pnl = (trade.exit_price - trade.entry_price) * trade.quantity
        else:  # sell
            pnl = (trade.entry_price - trade.exit_price) * trade.quantity
        
        # Subtract fees
        pnl -= trade.fees
        
        # Convert to base currency
        if trade_currency != base_currency:
            fx_rate = await self.fx_manager.get_rate(
                from_currency=trade_currency,
                to_currency=base_currency
            )
            pnl *= fx_rate
        
        return pnl
    
    async def calculate_unrealized_pnl(
        self,
        position: Position,
        base_currency: Currency,
        current_price: Decimal
    ) -> Decimal:
        """
        Calculate unrealized P&L in base currency.
        
        Args:
            position: Position object
            base_currency: Base currency for calculation
            current_price: Current market price
        
        Returns:
            Unrealized P&L in base currency
        """
        # Get position currency
        position_currency = await get_position_currency(position.symbol)
        
        # Calculate P&L in position currency
        if position.position_type == "LONG":
            pnl = (current_price - position.entry_price) * position.quantity
        else:  # SHORT
            pnl = (position.entry_price - current_price) * position.quantity
        
        # Convert to base currency
        if position_currency != base_currency:
            fx_rate = await self.fx_manager.get_rate(
                from_currency=position_currency,
                to_currency=base_currency
            )
            pnl *= fx_rate
        
        return pnl
    
    async def calculate_portfolio_pnl(
        self,
        portfolio: Portfolio,
        include_unrealized: bool = True
    ) -> Dict[str, Decimal]:
        """
        Calculate total portfolio P&L.
        
        Returns:
            Dict with realized_pnl, unrealized_pnl, total_pnl
        """
        realized_pnl = Decimal("0")
        unrealized_pnl = Decimal("0")
        
        # Calculate realized P&L from closed trades
        for account in portfolio.accounts:
            trades = await get_account_trades(account.account_id, status="closed")
            
            for trade in trades:
                trade_pnl = await self.calculate_realized_pnl(
                    trade,
                    portfolio.base_currency
                )
                realized_pnl += trade_pnl
        
        # Calculate unrealized P&L from open positions
        if include_unrealized:
            for account in portfolio.accounts:
                positions = await get_account_positions(account.account_id)
                
                for position in positions:
                    current_price = await get_current_price(position.symbol)
                    position_pnl = await self.calculate_unrealized_pnl(
                        position,
                        portfolio.base_currency,
                        current_price
                    )
                    unrealized_pnl += position_pnl
        
        total_pnl = realized_pnl + unrealized_pnl
        
        return {
            "realized_pnl": realized_pnl,
            "unrealized_pnl": unrealized_pnl,
            "total_pnl": total_pnl
        }
```

---

## FX Risk Management

Track and manage currency exposure in multi-currency portfolios.

### Currency Exposure Tracker

```python
class CurrencyExposureTracker:
    """Track currency exposure and risk"""
    
    def __init__(self, fx_manager: FXRateManager):
        self.fx_manager = fx_manager
    
    async def calculate_exposure(
        self,
        portfolio: Portfolio
    ) -> Dict[Currency, Decimal]:
        """
        Calculate currency exposure for portfolio.
        
        Returns:
            Dict mapping currency to exposure amount in base currency
        """
        exposure: Dict[Currency, Decimal] = {}
        
        for account in portfolio.accounts:
            # Account balance
            account_currency = account.base_currency
            account_value = await account.get_balance_in_base()
            
            if account_currency not in exposure:
                exposure[account_currency] = Decimal("0")
            exposure[account_currency] += account_value
            
            # Positions
            positions = await get_account_positions(account.account_id)
            
            for position in positions:
                position_currency = await get_position_currency(position.symbol)
                position_value = position.quantity * position.current_price
                
                # Convert to base currency
                if position_currency != portfolio.base_currency:
                    fx_rate = await self.fx_manager.get_rate(
                        from_currency=position_currency,
                        to_currency=portfolio.base_currency
                    )
                    position_value *= fx_rate
                
                if position_currency not in exposure:
                    exposure[position_currency] = Decimal("0")
                exposure[position_currency] += position_value
        
        return exposure
    
    async def calculate_fx_risk(
        self,
        portfolio: Portfolio,
        exposure: Dict[Currency, Decimal]
    ) -> Dict[str, Any]:
        """
        Calculate FX risk metrics.
        
        Returns:
            Dict with risk metrics
        """
        total_value = await portfolio.get_total_value()
        
        # Calculate exposure percentages
        exposure_pct = {
            currency: (value / total_value * 100) if total_value > 0 else 0
            for currency, value in exposure.items()
        }
        
        # Calculate concentration risk (max exposure)
        max_exposure_pct = max(exposure_pct.values()) if exposure_pct else 0
        
        # Calculate currency volatility (if available)
        currency_volatility = {}
        for currency, value in exposure.items():
            if currency != portfolio.base_currency:
                # Get historical volatility
                vol = await get_currency_volatility(currency, portfolio.base_currency)
                currency_volatility[currency] = vol
        
        return {
            "exposure": exposure,
            "exposure_pct": exposure_pct,
            "max_exposure_pct": max_exposure_pct,
            "currency_volatility": currency_volatility,
            "total_value": total_value
        }
    
    async def check_fx_limits(
        self,
        portfolio: Portfolio,
        max_exposure_pct: Decimal = Decimal("50.0")
    ) -> tuple[bool, str]:
        """
        Check if FX exposure exceeds limits.
        
        Returns:
            (within_limits, reason)
        """
        exposure = await self.calculate_exposure(portfolio)
        risk = await self.calculate_fx_risk(portfolio, exposure)
        
        # Check max exposure
        for currency, pct in risk["exposure_pct"].items():
            if currency != portfolio.base_currency and pct > max_exposure_pct:
                return False, (
                    f"Currency exposure {currency.value} ({pct:.1f}%) "
                    f"exceeds limit ({max_exposure_pct}%)"
                )
        
        return True, "OK"
```

---

## Currency Conversion API

API endpoints for currency conversion.

### Conversion Endpoints

```python
from fastapi import APIRouter, HTTPException
from decimal import Decimal

router = APIRouter(prefix="/currency", tags=["currency"])

@router.get("/convert")
async def convert_currency(
    amount: Decimal,
    from_currency: Currency,
    to_currency: Currency
) -> Dict[str, Any]:
    """Convert amount between currencies"""
    if from_currency == to_currency:
        return {
            "amount": float(amount),
            "from_currency": from_currency.value,
            "to_currency": to_currency.value,
            "rate": 1.0,
            "converted_amount": float(amount)
        }
    
    fx_manager = get_fx_manager()
    rate = await fx_manager.get_rate(from_currency, to_currency)
    converted = amount * rate
    
    return {
        "amount": float(amount),
        "from_currency": from_currency.value,
        "to_currency": to_currency.value,
        "rate": float(rate),
        "converted_amount": float(converted)
    }

@router.get("/rates/{from_currency}/{to_currency}")
async def get_fx_rate(
    from_currency: Currency,
    to_currency: Currency
) -> Dict[str, Any]:
    """Get current FX rate"""
    fx_manager = get_fx_manager()
    rate = await fx_manager.get_rate(from_currency, to_currency)
    
    return {
        "from_currency": from_currency.value,
        "to_currency": to_currency.value,
        "rate": float(rate),
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/exposure/{portfolio_id}")
async def get_currency_exposure(
    portfolio_id: int
) -> Dict[str, Any]:
    """Get currency exposure for portfolio"""
    portfolio = await get_portfolio(portfolio_id)
    if not portfolio:
        raise HTTPException(404, "Portfolio not found")
    
    tracker = CurrencyExposureTracker(get_fx_manager())
    exposure = await tracker.calculate_exposure(portfolio)
    risk = await tracker.calculate_fx_risk(portfolio, exposure)
    
    return {
        "portfolio_id": portfolio_id,
        "base_currency": portfolio.base_currency.value,
        "exposure": {k.value: float(v) for k, v in exposure.items()},
        "exposure_pct": {k.value: float(v) for k, v in risk["exposure_pct"].items()},
        "max_exposure_pct": float(risk["max_exposure_pct"]),
        "total_value": float(risk["total_value"])
    }
```

---

## Configuration

### Currency Configuration

```python
CURRENCY_CONFIG = {
    "base_currencies": ["USD", "EUR", "GBP", "BTC"],
    "fx_providers": {
        "fiat": "exchangeratesapi",
        "crypto": "binance"
    },
    "rate_update_interval_minutes": 5,
    "cache_ttl_seconds": 300,
    "fx_risk_limits": {
        "max_exposure_pct": 50.0,  # Max 50% exposure to single currency
        "max_crypto_exposure_pct": 30.0  # Max 30% exposure to crypto
    }
}
```

---

## References

- [Exchange Rates API](https://exchangerate.host/)
- [CCXT Exchange Integration](https://docs.ccxt.com/)
- [Currency Risk Management](https://www.investopedia.com/terms/c/currencyrisk.asp)

