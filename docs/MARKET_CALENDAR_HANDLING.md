# FKS Market Calendar and Hours Handling

## Overview

The FKS Market Calendar System handles different market hours, holidays, and trading sessions across multiple asset types (crypto 24/7, stocks 9:30-16:00 EST, futures extended hours) with proper timezone management.

**Key Principle**: All timestamps are stored in UTC, but market hours are defined in their native timezones (e.g., EST for NYSE, UTC for crypto).

## Table of Contents

1. [Market Calendars](#market-calendars)
2. [Holiday Handling](#holiday-handling)
3. [Timezone Management](#timezone-management)
4. [Pre/Post-Market Trading](#prepost-market-trading)
5. [Market Status API](#market-status-api)
6. [Configuration](#configuration)

---

## Market Calendars

Different asset types have different trading hours.

### Market Calendar Types

```python
from enum import Enum
from datetime import datetime, time
from typing import Optional, List
import pytz

class MarketType(Enum):
    CRYPTO = "crypto"  # 24/7 trading
    STOCKS = "stocks"  # Regular hours + extended
    FUTURES = "futures"  # Extended hours
    FOREX = "forex"  # 24/5 trading (Mon-Fri)

class MarketCalendar:
    """Base class for market calendars"""
    
    def __init__(self, market_type: MarketType, timezone: str):
        self.market_type = market_type
        self.timezone = pytz.timezone(timezone)
    
    def is_trading_day(self, date: datetime) -> bool:
        """Check if date is a trading day"""
        raise NotImplementedError
    
    def is_market_open(self, timestamp: datetime) -> bool:
        """Check if market is open at timestamp"""
        raise NotImplementedError
    
    def get_market_hours(self, date: datetime) -> Optional[dict]:
        """Get market hours for a specific date"""
        raise NotImplementedError
```

### Crypto Market Calendar (24/7)

```python
class CryptoMarketCalendar(MarketCalendar):
    """24/7 crypto market calendar"""
    
    def __init__(self):
        super().__init__(MarketType.CRYPTO, "UTC")
    
    def is_trading_day(self, date: datetime) -> bool:
        """Crypto trades every day"""
        return True
    
    def is_market_open(self, timestamp: datetime) -> bool:
        """Crypto is always open"""
        return True
    
    def get_market_hours(self, date: datetime) -> dict:
        """Crypto has no market hours (always open)"""
        return {
            "open": None,  # Always open
            "close": None,
            "is_open": True
        }
```

### Stock Market Calendar (NYSE/NASDAQ)

```python
class StockMarketCalendar(MarketCalendar):
    """NYSE/NASDAQ market calendar"""
    
    def __init__(self, exchange: str = "NYSE"):
        super().__init__(MarketType.STOCKS, "America/New_York")
        self.exchange = exchange
        self.regular_open = time(9, 30)  # 9:30 AM ET
        self.regular_close = time(16, 0)  # 4:00 PM ET
        self.pre_market_open = time(4, 0)  # 4:00 AM ET
        self.after_hours_close = time(20, 0)  # 8:00 PM ET
    
    def is_trading_day(self, date: datetime) -> bool:
        """Check if date is a trading day (not weekend or holiday)"""
        # Convert to ET
        et_date = date.astimezone(self.timezone)
        
        # Weekend check
        if et_date.weekday() >= 5:  # Saturday or Sunday
            return False
        
        # Holiday check
        if self._is_holiday(et_date):
            return False
        
        return True
    
    def is_market_open(self, timestamp: datetime) -> bool:
        """Check if regular market hours"""
        if not self.is_trading_day(timestamp):
            return False
        
        # Convert to ET
        et_time = timestamp.astimezone(self.timezone).time()
        
        return self.regular_open <= et_time <= self.regular_close
    
    def is_pre_market(self, timestamp: datetime) -> bool:
        """Check if pre-market hours"""
        if not self.is_trading_day(timestamp):
            return False
        
        et_time = timestamp.astimezone(self.timezone).time()
        return self.pre_market_open <= et_time < self.regular_open
    
    def is_after_hours(self, timestamp: datetime) -> bool:
        """Check if after-hours"""
        if not self.is_trading_day(timestamp):
            return False
        
        et_time = timestamp.astimezone(self.timezone).time()
        return self.regular_close < et_time <= self.after_hours_close
    
    def get_market_hours(self, date: datetime) -> Optional[dict]:
        """Get market hours for date"""
        if not self.is_trading_day(date):
            return None
        
        et_date = date.astimezone(self.timezone)
        
        return {
            "pre_market_open": datetime.combine(et_date.date(), self.pre_market_open).astimezone(pytz.UTC),
            "market_open": datetime.combine(et_date.date(), self.regular_open).astimezone(pytz.UTC),
            "market_close": datetime.combine(et_date.date(), self.regular_close).astimezone(pytz.UTC),
            "after_hours_close": datetime.combine(et_date.date(), self.after_hours_close).astimezone(pytz.UTC),
            "is_trading_day": True
        }
    
    def _is_holiday(self, date: datetime) -> bool:
        """Check if date is a market holiday"""
        # Use holiday calendar (see Holiday Handling section)
        return date.date() in US_MARKET_HOLIDAYS
```

### Futures Market Calendar

```python
class FuturesMarketCalendar(MarketCalendar):
    """Futures market calendar (extended hours)"""
    
    def __init__(self, exchange: str = "CME"):
        super().__init__(MarketType.FUTURES, "America/Chicago")
        self.exchange = exchange
        # CME futures: Sunday 5:00 PM CT to Friday 4:00 PM CT
        self.week_open = time(17, 0)  # 5:00 PM CT Sunday
        self.week_close = time(16, 0)  # 4:00 PM CT Friday
    
    def is_trading_day(self, date: datetime) -> bool:
        """Futures trade Sunday-Friday"""
        ct_date = date.astimezone(self.timezone)
        weekday = ct_date.weekday()
        
        # Sunday (6) or Monday-Friday (0-4)
        return weekday == 6 or weekday < 5
    
    def is_market_open(self, timestamp: datetime) -> bool:
        """Check if futures market is open"""
        ct_time = timestamp.astimezone(self.timezone)
        weekday = ct_time.weekday()
        time_obj = ct_time.time()
        
        # Sunday: open at 5:00 PM
        if weekday == 6:
            return time_obj >= self.week_open
        
        # Monday-Thursday: always open
        if weekday < 4:
            return True
        
        # Friday: close at 4:00 PM
        if weekday == 4:
            return time_obj < self.week_close
        
        # Saturday: closed
        return False
```

### Forex Market Calendar (24/5)

```python
class ForexMarketCalendar(MarketCalendar):
    """Forex market calendar (24/5, Mon-Fri)"""
    
    def __init__(self):
        super().__init__(MarketType.FOREX, "UTC")
    
    def is_trading_day(self, date: datetime) -> bool:
        """Forex trades Monday-Friday"""
        weekday = date.weekday()
        return weekday < 5  # Monday (0) to Friday (4)
    
    def is_market_open(self, timestamp: datetime) -> bool:
        """Forex is open 24/5"""
        return self.is_trading_day(timestamp)
```

---

## Holiday Handling

Handle market holidays and early closes.

### US Market Holidays

```python
from datetime import date
import holidays

# US market holidays
US_MARKET_HOLIDAYS = {
    # New Year's Day
    date(2024, 1, 1),
    date(2025, 1, 1),
    
    # Martin Luther King Jr. Day (3rd Monday of January)
    date(2024, 1, 15),
    date(2025, 1, 20),
    
    # Presidents' Day (3rd Monday of February)
    date(2024, 2, 19),
    date(2025, 2, 17),
    
    # Good Friday
    date(2024, 3, 29),
    date(2025, 4, 18),
    
    # Memorial Day (last Monday of May)
    date(2024, 5, 27),
    date(2025, 5, 26),
    
    # Juneteenth
    date(2024, 6, 19),
    date(2025, 6, 19),
    
    # Independence Day
    date(2024, 7, 4),
    date(2025, 7, 4),
    
    # Labor Day (1st Monday of September)
    date(2024, 9, 2),
    date(2025, 9, 1),
    
    # Thanksgiving (4th Thursday of November)
    date(2024, 11, 28),
    date(2025, 11, 27),
    
    # Christmas
    date(2024, 12, 25),
    date(2025, 12, 25),
}

# Early closes (market closes at 1:00 PM ET)
EARLY_CLOSE_DATES = {
    date(2024, 7, 3),  # Day before Independence Day
    date(2024, 11, 29),  # Day after Thanksgiving (Black Friday)
    date(2024, 12, 24),  # Christmas Eve
}

class HolidayCalendar:
    """Manage market holidays"""
    
    def __init__(self, country: str = "US"):
        self.country = country
        self.holidays = US_MARKET_HOLIDAYS
        self.early_closes = EARLY_CLOSE_CLOSE_DATES
    
    def is_holiday(self, date: date) -> bool:
        """Check if date is a market holiday"""
        return date in self.holidays
    
    def is_early_close(self, date: date) -> bool:
        """Check if market closes early"""
        return date in self.early_closes
    
    def get_early_close_time(self, date: date) -> Optional[time]:
        """Get early close time for date"""
        if self.is_early_close(date):
            return time(13, 0)  # 1:00 PM ET
        return None
    
    def get_next_trading_day(self, date: date) -> date:
        """Get next trading day after date"""
        next_day = date + timedelta(days=1)
        
        while not self._is_trading_day(next_day):
            next_day += timedelta(days=1)
        
        return next_day
    
    def _is_trading_day(self, date: date) -> bool:
        """Check if date is a trading day"""
        # Weekend
        if date.weekday() >= 5:
            return False
        
        # Holiday
        if self.is_holiday(date):
            return False
        
        return True
```

### Holiday Database

```sql
CREATE TABLE market_holidays (
    id SERIAL PRIMARY KEY,
    exchange VARCHAR(50) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR(100) NOT NULL,
    is_early_close BOOLEAN DEFAULT false,
    early_close_time TIME,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(exchange, holiday_date)
);

CREATE INDEX idx_market_holidays_date ON market_holidays(holiday_date);
CREATE INDEX idx_market_holidays_exchange ON market_holidays(exchange);
```

---

## Timezone Management

All timestamps stored in UTC, converted for display.

### Timezone Utilities

```python
import pytz
from datetime import datetime

class TimezoneManager:
    """Manage timezone conversions"""
    
    UTC = pytz.UTC
    
    # Common timezones
    TIMEZONES = {
        "UTC": pytz.UTC,
        "ET": pytz.timezone("America/New_York"),
        "CT": pytz.timezone("America/Chicago"),
        "PT": pytz.timezone("America/Los_Angeles"),
        "GMT": pytz.timezone("Europe/London"),
        "JST": pytz.timezone("Asia/Tokyo")
    }
    
    @staticmethod
    def to_utc(timestamp: datetime, timezone: str = "ET") -> datetime:
        """Convert timestamp to UTC"""
        if timestamp.tzinfo is None:
            # Assume provided timezone
            tz = TimezoneManager.TIMEZONES.get(timezone, pytz.UTC)
            timestamp = tz.localize(timestamp)
        
        return timestamp.astimezone(pytz.UTC)
    
    @staticmethod
    def from_utc(timestamp: datetime, timezone: str = "ET") -> datetime:
        """Convert UTC timestamp to timezone"""
        if timestamp.tzinfo is None:
            timestamp = pytz.UTC.localize(timestamp)
        
        tz = TimezoneManager.TIMEZONES.get(timezone, pytz.UTC)
        return timestamp.astimezone(tz)
    
    @staticmethod
    def format_for_display(timestamp: datetime, timezone: str = "ET") -> str:
        """Format timestamp for display in user's timezone"""
        local_time = TimezoneManager.from_utc(timestamp, timezone)
        return local_time.strftime("%Y-%m-%d %H:%M:%S %Z")
```

### Database Timestamp Handling

```python
# All database timestamps are stored in UTC
from sqlalchemy import Column, DateTime
from datetime import datetime
import pytz

class BaseModel:
    """Base model with UTC timestamps"""
    
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(pytz.UTC)
    )
    
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(pytz.UTC),
        onupdate=lambda: datetime.now(pytz.UTC)
    )

# When querying, convert to user's timezone
def get_trades_for_user(user_id: int, user_timezone: str = "ET"):
    """Get trades with timestamps in user's timezone"""
    trades = session.query(Trade).filter_by(user_id=user_id).all()
    
    for trade in trades:
        # Convert UTC to user timezone
        trade.timestamp_local = TimezoneManager.from_utc(
            trade.timestamp,
            user_timezone
        )
    
    return trades
```

---

## Pre/Post-Market Trading

Handle pre-market and after-hours trading for stocks.

### Extended Hours Handler

```python
class ExtendedHoursHandler:
    """Handle pre-market and after-hours trading"""
    
    def __init__(self, calendar: StockMarketCalendar):
        self.calendar = calendar
    
    def can_trade_extended_hours(
        self,
        timestamp: datetime,
        order_type: str
    ) -> tuple[bool, str]:
        """
        Check if trading is allowed in extended hours.
        
        Returns:
            (allowed, reason)
        """
        if not self.calendar.is_trading_day(timestamp):
            return False, "Not a trading day"
        
        # Pre-market
        if self.calendar.is_pre_market(timestamp):
            # Some brokers allow limit orders in pre-market
            if order_type == "limit":
                return True, "Pre-market limit orders allowed"
            else:
                return False, "Market orders not allowed in pre-market"
        
        # Regular hours
        if self.calendar.is_market_open(timestamp):
            return True, "Regular market hours"
        
        # After-hours
        if self.calendar.is_after_hours(timestamp):
            # Limit orders typically allowed
            if order_type == "limit":
                return True, "After-hours limit orders allowed"
            else:
                return False, "Market orders not allowed in after-hours"
        
        return False, "Market closed"
    
    def get_next_market_open(self, timestamp: datetime) -> datetime:
        """Get next market open time"""
        et_time = timestamp.astimezone(self.calendar.timezone)
        next_day = et_time.date() + timedelta(days=1)
        
        # Skip weekends and holidays
        while not self.calendar.is_trading_day(
            datetime.combine(next_day, time(9, 30)).replace(tzinfo=self.calendar.timezone)
        ):
            next_day += timedelta(days=1)
        
        # Market opens at 9:30 AM ET
        market_open = datetime.combine(
            next_day,
            self.calendar.regular_open
        ).replace(tzinfo=self.calendar.timezone)
        
        return market_open.astimezone(pytz.UTC)
```

---

## Market Status API

API endpoints for checking market status.

### Market Status Endpoints

```python
from fastapi import APIRouter, Depends
from datetime import datetime

router = APIRouter(prefix="/market-status", tags=["market"])

@router.get("/{symbol}")
async def get_market_status(
    symbol: str,
    timestamp: Optional[datetime] = None
) -> Dict[str, Any]:
    """Get current market status for symbol"""
    if timestamp is None:
        timestamp = datetime.now(pytz.UTC)
    
    # Get asset type
    asset = await get_asset(symbol)
    if not asset:
        raise HTTPException(404, f"Asset {symbol} not found")
    
    # Get appropriate calendar
    calendar = get_calendar_for_asset(asset)
    
    # Check market status
    is_open = calendar.is_market_open(timestamp)
    is_trading_day = calendar.is_trading_day(timestamp)
    
    market_hours = calendar.get_market_hours(timestamp)
    
    return {
        "symbol": symbol,
        "asset_type": asset.category.value,
        "timestamp": timestamp.isoformat(),
        "is_open": is_open,
        "is_trading_day": is_trading_day,
        "market_hours": market_hours,
        "timezone": calendar.timezone.zone
    }

@router.get("/{symbol}/next-open")
async def get_next_market_open(symbol: str) -> Dict[str, Any]:
    """Get next market open time for symbol"""
    asset = await get_asset(symbol)
    if not asset:
        raise HTTPException(404, f"Asset {symbol} not found")
    
    calendar = get_calendar_for_asset(asset)
    next_open = calendar.get_next_market_open(datetime.now(pytz.UTC))
    
    return {
        "symbol": symbol,
        "next_open": next_open.isoformat(),
        "next_open_local": TimezoneManager.format_for_display(next_open, "ET")
    }

def get_calendar_for_asset(asset: Asset) -> MarketCalendar:
    """Get appropriate calendar for asset type"""
    if asset.category == AssetCategory.CRYPTO:
        return CryptoMarketCalendar()
    elif asset.category == AssetCategory.STOCKS:
        return StockMarketCalendar()
    elif asset.category == AssetCategory.FUTURES:
        return FuturesMarketCalendar()
    elif asset.category == AssetCategory.FOREX:
        return ForexMarketCalendar()
    else:
        return CryptoMarketCalendar()  # Default
```

---

## Configuration

### Market Calendar Configuration

```python
MARKET_CALENDAR_CONFIG = {
    "crypto": {
        "type": "24/7",
        "timezone": "UTC",
        "holidays": []
    },
    "stocks": {
        "type": "regular_hours",
        "timezone": "America/New_York",
        "regular_open": "09:30",
        "regular_close": "16:00",
        "pre_market_open": "04:00",
        "after_hours_close": "20:00",
        "holidays": "US_MARKET_HOLIDAYS",
        "early_closes": "EARLY_CLOSE_DATES"
    },
    "futures": {
        "type": "extended",
        "timezone": "America/Chicago",
        "week_open": "17:00",  # Sunday 5 PM CT
        "week_close": "16:00"  # Friday 4 PM CT
    },
    "forex": {
        "type": "24/5",
        "timezone": "UTC",
        "trading_days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
}
```

---

## References

- [pytz Timezone Library](https://pythonhosted.org/pytz/)
- [US Market Holidays](https://www.nyse.com/markets/hours-calendars)
- [CME Trading Hours](https://www.cmegroup.com/trading-hours.html)

