# FKS Risk Management System Documentation

## Overview

The FKS Risk Management System provides comprehensive risk controls to protect trading capital and ensure compliance with risk limits. It enforces position limits, margin requirements, daily loss limits, and implements circuit breakers to automatically halt trading when risk thresholds are exceeded.

**Critical Principle**: Risk management is enforced at multiple layers—pre-trade validation, real-time monitoring, and post-trade reconciliation—to prevent catastrophic losses.

## Table of Contents

1. [Position Limits](#position-limits)
2. [Margin Requirements](#margin-requirements)
3. [Stop-Loss Mechanisms](#stop-loss-mechanisms)
4. [Daily Limits](#daily-limits)
5. [Risk Metrics](#risk-metrics)
6. [Circuit Breakers](#circuit-breakers)
7. [Risk Validation Pipeline](#risk-validation-pipeline)
8. [Configuration](#configuration)

---

## Position Limits

Position limits restrict the size and number of positions to prevent over-concentration and excessive risk exposure.

### Per-Account Position Limits

**Maximum Position Size**: Limit the value of a single position relative to account balance.

```python
class AccountPositionLimits:
    def __init__(
        self,
        account_id: int,
        max_position_pct: float = 0.10,  # 10% of account per position
        max_position_value: Optional[float] = None  # Absolute limit in base currency
    ):
        self.account_id = account_id
        self.max_position_pct = max_position_pct
        self.max_position_value = max_position_value
    
    async def validate_position(self, symbol: str, quantity: float, price: float) -> tuple[bool, str]:
        """Validate if position size is within limits"""
        account = await get_account(self.account_id)
        balance = account.current_balance
        
        position_value = quantity * price
        
        # Check percentage limit
        position_pct = position_value / balance if balance > 0 else 0
        if position_pct > self.max_position_pct:
            return False, f"Position {position_pct:.1%} exceeds max {self.max_position_pct:.1%}"
        
        # Check absolute limit
        if self.max_position_value and position_value > self.max_position_value:
            return False, f"Position value ${position_value:,.2f} exceeds max ${self.max_position_value:,.2f}"
        
        return True, "OK"
```

**Example Configuration**:
```python
# Conservative account: 5% max per position
limits = AccountPositionLimits(account_id=1, max_position_pct=0.05)

# Aggressive account: 10% max per position
limits = AccountPositionLimits(account_id=2, max_position_pct=0.10)

# Absolute limit: $10,000 max per position
limits = AccountPositionLimits(account_id=3, max_position_value=10000.0)
```

### Per-Symbol Position Limits

**Maximum Exposure per Symbol**: Limit total exposure (long + short) for a single symbol.

```python
class SymbolPositionLimits:
    def __init__(
        self,
        symbol: str,
        max_exposure_pct: float = 0.20,  # 20% of account per symbol
        max_quantity: Optional[float] = None  # Absolute quantity limit
    ):
        self.symbol = symbol
        self.max_exposure_pct = max_exposure_pct
        self.max_quantity = max_quantity
    
    async def validate_symbol_exposure(
        self,
        account_id: int,
        new_quantity: float,
        price: float
    ) -> tuple[bool, str]:
        """Validate total symbol exposure"""
        account = await get_account(account_id)
        current_positions = await get_positions(account_id, symbol=self.symbol)
        
        # Calculate current exposure
        current_exposure = sum(
            abs(pos.quantity * pos.current_price) for pos in current_positions
        )
        
        # Calculate new exposure
        new_exposure = abs(new_quantity * price)
        total_exposure = current_exposure + new_exposure
        
        # Check percentage limit
        exposure_pct = total_exposure / account.current_balance
        if exposure_pct > self.max_exposure_pct:
            return False, (
                f"Symbol {self.symbol} exposure {exposure_pct:.1%} "
                f"exceeds max {self.max_exposure_pct:.1%}"
            )
        
        # Check quantity limit
        total_quantity = sum(abs(pos.quantity) for pos in current_positions) + abs(new_quantity)
        if self.max_quantity and total_quantity > self.max_quantity:
            return False, (
                f"Symbol {self.symbol} quantity {total_quantity} "
                f"exceeds max {self.max_quantity}"
            )
        
        return True, "OK"
```

### Portfolio-Level Position Limits

**Maximum Total Exposure**: Limit total portfolio exposure across all positions.

```python
class PortfolioLimits:
    def __init__(
        self,
        max_total_exposure_pct: float = 0.50,  # 50% of account total
        max_open_positions: int = 10,  # Maximum number of open positions
        max_correlation_exposure: float = 0.30  # 30% max in correlated assets
    ):
        self.max_total_exposure_pct = max_total_exposure_pct
        self.max_open_positions = max_open_positions
        self.max_correlation_exposure = max_correlation_exposure
    
    async def validate_portfolio(
        self,
        account_id: int,
        new_position: Dict[str, Any]
    ) -> tuple[bool, str]:
        """Validate portfolio-level limits"""
        account = await get_account(account_id)
        all_positions = await get_all_positions(account_id)
        
        # Check total exposure
        total_exposure = sum(
            abs(pos.quantity * pos.current_price) for pos in all_positions
        )
        new_exposure = abs(new_position['quantity'] * new_position['price'])
        total_exposure += new_exposure
        
        exposure_pct = total_exposure / account.current_balance
        if exposure_pct > self.max_total_exposure_pct:
            return False, (
                f"Total portfolio exposure {exposure_pct:.1%} "
                f"exceeds max {self.max_total_exposure_pct:.1%}"
            )
        
        # Check number of positions
        open_count = len([p for p in all_positions if p.status == 'open'])
        if open_count >= self.max_open_positions:
            return False, (
                f"Maximum {self.max_open_positions} open positions reached "
                f"(current: {open_count})"
            )
        
        # Check correlation exposure (e.g., BTC + ETH should not exceed 30%)
        symbol = new_position['symbol']
        correlated_symbols = get_correlated_symbols(symbol)  # e.g., BTC -> [ETH, SOL]
        
        correlated_exposure = sum(
            abs(pos.quantity * pos.current_price)
            for pos in all_positions
            if pos.symbol in correlated_symbols
        )
        correlated_exposure += new_exposure
        
        correlation_pct = correlated_exposure / account.current_balance
        if correlation_pct > self.max_correlation_exposure:
            return False, (
                f"Correlated assets exposure {correlation_pct:.1%} "
                f"exceeds max {self.max_correlation_exposure:.1%}"
            )
        
        return True, "OK"
```

### Position Limit Configuration

**Database Schema**:
```sql
CREATE TABLE position_limits (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(id),
    symbol VARCHAR(20),  -- NULL for account-level limits
    limit_type VARCHAR(50) NOT NULL,  -- 'per_position', 'per_symbol', 'portfolio'
    max_value_pct DECIMAL(5, 4),  -- Percentage of balance
    max_value_absolute DECIMAL(20, 8),  -- Absolute value
    max_quantity DECIMAL(20, 8),  -- For quantity-based limits
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_position_limits_account ON position_limits(account_id);
CREATE INDEX idx_position_limits_symbol ON position_limits(symbol);
```

**Default Limits**:
```python
DEFAULT_LIMITS = {
    "per_position": {
        "max_position_pct": 0.10,  # 10% per position
        "max_position_value": None  # No absolute limit
    },
    "per_symbol": {
        "max_exposure_pct": 0.20,  # 20% per symbol
        "max_quantity": None
    },
    "portfolio": {
        "max_total_exposure_pct": 0.50,  # 50% total
        "max_open_positions": 10,
        "max_correlation_exposure": 0.30  # 30% in correlated assets
    }
}
```

---

## Margin Requirements

Margin requirements ensure sufficient capital is available to cover potential losses, especially for leveraged positions.

### Initial Margin

**Definition**: Minimum capital required to open a position.

```python
class MarginCalculator:
    def __init__(
        self,
        initial_margin_pct: float = 0.10,  # 10% initial margin
        maintenance_margin_pct: float = 0.05,  # 5% maintenance margin
        leverage: float = 1.0  # 1x = no leverage, 10x = 10x leverage
    ):
        self.initial_margin_pct = initial_margin_pct
        self.maintenance_margin_pct = maintenance_margin_pct
        self.leverage = leverage
    
    def calculate_initial_margin(
        self,
        position_value: float,
        leverage: Optional[float] = None
    ) -> float:
        """
        Calculate initial margin required.
        
        Formula:
            Initial Margin = Position Value / Leverage
        
        Args:
            position_value: Total value of position
            leverage: Leverage multiplier (uses instance default if None)
        
        Returns:
            Required initial margin
        """
        leverage = leverage or self.leverage
        if leverage <= 0:
            raise ValueError("Leverage must be positive")
        
        return position_value / leverage
    
    def calculate_maintenance_margin(
        self,
        position_value: float,
        current_price: float,
        entry_price: float
    ) -> float:
        """
        Calculate maintenance margin required.
        
        Maintenance margin increases as position moves against you.
        
        Formula:
            Maintenance Margin = Position Value × Maintenance Margin %
        
        Args:
            position_value: Current position value
            current_price: Current market price
            entry_price: Entry price
        
        Returns:
            Required maintenance margin
        """
        return position_value * self.maintenance_margin_pct
```

### Margin Call and Liquidation

**Margin Call**: Warning when margin falls below maintenance margin.

**Liquidation**: Automatic position closure when margin is insufficient.

```python
class MarginMonitor:
    def __init__(
        self,
        liquidation_threshold: float = 0.03,  # 3% margin = liquidation
        margin_call_threshold: float = 0.05  # 5% margin = margin call
    ):
        self.liquidation_threshold = liquidation_threshold
        self.margin_call_threshold = margin_call_threshold
    
    async def check_margin_status(
        self,
        account_id: int,
        position_id: int
    ) -> Dict[str, Any]:
        """Check margin status for a position"""
        position = await get_position(position_id)
        account = await get_account(account_id)
        
        # Calculate available margin
        total_margin_used = sum(
            self.calculate_initial_margin(
                pos.quantity * pos.current_price,
                pos.leverage
            )
            for pos in await get_all_positions(account_id)
        )
        
        available_margin = account.current_balance - total_margin_used
        margin_ratio = available_margin / account.current_balance if account.current_balance > 0 else 0
        
        # Determine status
        if margin_ratio < self.liquidation_threshold:
            status = "LIQUIDATION"
            action = await self.liquidate_position(position_id)
        elif margin_ratio < self.margin_call_threshold:
            status = "MARGIN_CALL"
            action = await self.send_margin_call_alert(account_id, position_id)
        else:
            status = "OK"
            action = None
        
        return {
            "status": status,
            "margin_ratio": margin_ratio,
            "available_margin": available_margin,
            "total_margin_used": total_margin_used,
            "action": action
        }
    
    async def liquidate_position(self, position_id: int):
        """Liquidate position due to insufficient margin"""
        position = await get_position(position_id)
        
        # Close position at market price
        order = {
            "symbol": position.symbol,
            "side": "sell" if position.position_type == "LONG" else "buy",
            "order_type": "market",
            "quantity": abs(position.quantity),
            "reason": "margin_liquidation"
        }
        
        result = await execute_order(order)
        
        # Log liquidation
        await log_liquidation_event(position_id, result)
        
        # Alert operations
        await alert_ops(
            f"Position {position_id} liquidated due to insufficient margin",
            severity="critical"
        )
        
        return result
```

### Leverage Limits

**Maximum Leverage**: Restrict leverage to prevent excessive risk.

```python
class LeverageLimits:
    def __init__(
        self,
        max_leverage: float = 10.0,  # 10x max leverage
        symbol_leverage_limits: Dict[str, float] = None
    ):
        self.max_leverage = max_leverage
        self.symbol_leverage_limits = symbol_leverage_limits or {}
    
    def get_max_leverage(self, symbol: str) -> float:
        """Get maximum allowed leverage for symbol"""
        return self.symbol_leverage_limits.get(symbol, self.max_leverage)
    
    def validate_leverage(
        self,
        symbol: str,
        requested_leverage: float
    ) -> tuple[bool, str]:
        """Validate requested leverage"""
        max_allowed = self.get_max_leverage(symbol)
        
        if requested_leverage > max_allowed:
            return False, (
                f"Leverage {requested_leverage}x exceeds max {max_allowed}x "
                f"for {symbol}"
            )
        
        if requested_leverage < 1.0:
            return False, "Leverage must be >= 1.0"
        
        return True, "OK"
```

---

## Stop-Loss Mechanisms

Stop-loss orders automatically close positions when losses reach predefined thresholds.

### ATR-Based Stop-Loss

**Description**: Stop-loss distance based on Average True Range (ATR) to account for volatility.

```python
class ATRStopLoss:
    def __init__(
        self,
        atr_multiplier: float = 2.0,  # 2x ATR for stop distance
        atr_period: int = 14  # 14-period ATR
    ):
        self.atr_multiplier = atr_multiplier
        self.atr_period = atr_period
    
    def calculate_stop_loss(
        self,
        entry_price: float,
        side: str,  # 'buy' or 'sell'
        atr_value: float
    ) -> float:
        """
        Calculate stop-loss price based on ATR.
        
        Args:
            entry_price: Entry price
            side: 'buy' (long) or 'sell' (short)
            atr_value: Current ATR value
        
        Returns:
            Stop-loss price
        """
        stop_distance = atr_value * self.atr_multiplier
        
        if side == "buy":  # Long position
            return entry_price - stop_distance
        else:  # Short position
            return entry_price + stop_distance
    
    async def update_stop_loss(
        self,
        position_id: int,
        current_price: float
    ):
        """Update stop-loss based on current ATR"""
        position = await get_position(position_id)
        atr = await calculate_atr(position.symbol, self.atr_period)
        
        new_stop = self.calculate_stop_loss(
            position.entry_price,
            "buy" if position.position_type == "LONG" else "sell",
            atr
        )
        
        # Only move stop in favorable direction (trailing stop)
        if position.position_type == "LONG":
            new_stop = max(new_stop, position.stop_loss)  # Only move up
        else:
            new_stop = min(new_stop, position.stop_loss)  # Only move down
        
        await update_position_stop_loss(position_id, new_stop)
```

### Percentage-Based Stop-Loss

**Description**: Fixed percentage stop-loss from entry price.

```python
class PercentageStopLoss:
    def __init__(self, stop_loss_pct: float = 0.02):  # 2% stop
        self.stop_loss_pct = stop_loss_pct
    
    def calculate_stop_loss(
        self,
        entry_price: float,
        side: str
    ) -> float:
        """Calculate stop-loss as percentage of entry price"""
        if side == "buy":  # Long
            return entry_price * (1 - self.stop_loss_pct)
        else:  # Short
            return entry_price * (1 + self.stop_loss_pct)
```

### Trailing Stop-Loss

**Description**: Stop-loss that moves with favorable price movement.

```python
class TrailingStopLoss:
    def __init__(
        self,
        trail_distance_pct: float = 0.015,  # 1.5% trail distance
        trail_distance_atr: Optional[float] = None  # Or use ATR-based
    ):
        self.trail_distance_pct = trail_distance_pct
        self.trail_distance_atr = trail_distance_atr
    
    async def update_trailing_stop(
        self,
        position_id: int,
        current_price: float
    ):
        """Update trailing stop-loss"""
        position = await get_position(position_id)
        
        if position.position_type == "LONG":
            # Calculate new stop (current price - trail distance)
            if self.trail_distance_atr:
                atr = await calculate_atr(position.symbol, 14)
                new_stop = current_price - (atr * self.trail_distance_atr)
            else:
                new_stop = current_price * (1 - self.trail_distance_pct)
            
            # Only move stop up (never down)
            if new_stop > position.stop_loss:
                await update_position_stop_loss(position_id, new_stop)
        
        else:  # SHORT
            # Calculate new stop (current price + trail distance)
            if self.trail_distance_atr:
                atr = await calculate_atr(position.symbol, 14)
                new_stop = current_price + (atr * self.trail_distance_atr)
            else:
                new_stop = current_price * (1 + self.trail_distance_pct)
            
            # Only move stop down (never up)
            if new_stop < position.stop_loss or position.stop_loss is None:
                await update_position_stop_loss(position_id, new_stop)
```

### Stop-Loss Enforcement

**Real-Time Monitoring**: Continuously monitor positions and trigger stop-loss orders.

```python
class StopLossMonitor:
    def __init__(self, check_interval: float = 1.0):  # Check every 1 second
        self.check_interval = check_interval
    
    async def monitor_positions(self):
        """Continuously monitor all open positions for stop-loss triggers"""
        while True:
            try:
                open_positions = await get_open_positions()
                
                for position in open_positions:
                    await self.check_stop_loss(position)
                
                await asyncio.sleep(self.check_interval)
            
            except Exception as e:
                logger.error(f"Stop-loss monitoring error: {e}")
                await asyncio.sleep(self.check_interval)
    
    async def check_stop_loss(self, position: Position):
        """Check if stop-loss should be triggered"""
        current_price = await get_current_price(position.symbol)
        
        if not position.stop_loss:
            return
        
        should_trigger = False
        
        if position.position_type == "LONG":
            # Long: trigger if price drops to stop-loss
            if current_price <= position.stop_loss:
                should_trigger = True
        else:  # SHORT
            # Short: trigger if price rises to stop-loss
            if current_price >= position.stop_loss:
                should_trigger = True
        
        if should_trigger:
            await self.trigger_stop_loss(position)
    
    async def trigger_stop_loss(self, position: Position):
        """Trigger stop-loss order"""
        logger.warning(
            f"Stop-loss triggered for position {position.id}: "
            f"{position.symbol} @ {position.stop_loss}"
        )
        
        # Close position
        order = {
            "symbol": position.symbol,
            "side": "sell" if position.position_type == "LONG" else "buy",
            "order_type": "market",
            "quantity": abs(position.quantity),
            "stop_loss_triggered": True,
            "trigger_price": position.stop_loss
        }
        
        result = await execute_order(order)
        
        # Log stop-loss event
        await log_stop_loss_event(position.id, result)
        
        # Send alert
        await send_alert(
            f"Stop-loss triggered: {position.symbol}",
            severity="warning"
        )
```

---

## Daily Limits

Daily limits prevent excessive trading and protect against catastrophic daily losses.

### Daily Loss Limits

**Hard Stop**: Automatically halt trading when daily loss exceeds threshold.

```python
class DailyLossLimits:
    def __init__(
        self,
        daily_loss_hard_limit_pct: float = 0.02,  # 2% hard stop
        daily_loss_soft_limit_pct: float = 0.015,  # 1.5% soft limit (reduce risk)
        account_id: int = None
    ):
        self.daily_loss_hard_limit_pct = daily_loss_hard_limit_pct
        self.daily_loss_soft_limit_pct = daily_loss_soft_limit_pct
        self.account_id = account_id
    
    async def check_daily_loss(self, account_id: int) -> Dict[str, Any]:
        """Check if daily loss limits are exceeded"""
        account = await get_account(account_id)
        
        # Calculate today's P&L
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_trades = await get_trades(
            account_id=account_id,
            start_time=today_start
        )
        
        daily_pnl = sum(trade.realized_pnl for trade in today_trades if trade.realized_pnl)
        daily_pnl_pct = daily_pnl / account.initial_balance if account.initial_balance > 0 else 0
        
        # Check limits
        status = "OK"
        action = None
        
        if daily_pnl_pct <= -self.daily_loss_hard_limit_pct:
            status = "HARD_LIMIT_EXCEEDED"
            action = await self.halt_trading(account_id, "Daily loss hard limit exceeded")
        
        elif daily_pnl_pct <= -self.daily_loss_soft_limit_pct:
            status = "SOFT_LIMIT_EXCEEDED"
            action = await self.reduce_risk(account_id, "Daily loss soft limit exceeded")
        
        return {
            "status": status,
            "daily_pnl": daily_pnl,
            "daily_pnl_pct": daily_pnl_pct,
            "hard_limit": -self.daily_loss_hard_limit_pct,
            "soft_limit": -self.daily_loss_soft_limit_pct,
            "action": action
        }
    
    async def halt_trading(self, account_id: int, reason: str):
        """Halt all trading for account"""
        await update_account_status(account_id, "trading_halted", reason)
        
        # Cancel all open orders
        open_orders = await get_open_orders(account_id)
        for order in open_orders:
            await cancel_order(order.id)
        
        # Alert
        await send_alert(
            f"Trading halted for account {account_id}: {reason}",
            severity="critical"
        )
        
        return {"action": "halted", "reason": reason}
    
    async def reduce_risk(self, account_id: int, reason: str):
        """Reduce position sizes and risk"""
        # Reduce max position size by 50%
        await update_account_risk_params(account_id, {
            "max_position_pct": 0.05,  # Reduce from 10% to 5%
            "max_risk_per_trade": 0.005  # Reduce from 1% to 0.5%
        })
        
        await send_alert(
            f"Risk reduced for account {account_id}: {reason}",
            severity="warning"
        )
        
        return {"action": "risk_reduced", "reason": reason}
```

### Daily Trade Count Limits

**Maximum Trades per Day**: Limit number of trades to prevent overtrading.

```python
class DailyTradeLimits:
    def __init__(
        self,
        max_trades_per_day: int = 6,
        max_trades_per_symbol: int = 3
    ):
        self.max_trades_per_day = max_trades_per_day
        self.max_trades_per_symbol = max_trades_per_symbol
    
    async def check_trade_count(
        self,
        account_id: int,
        symbol: str
    ) -> tuple[bool, str]:
        """Check if trade count limits allow new trade"""
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Count today's trades
        today_trades = await get_trades(
            account_id=account_id,
            start_time=today_start
        )
        
        total_trades = len(today_trades)
        symbol_trades = len([t for t in today_trades if t.symbol == symbol])
        
        # Check limits
        if total_trades >= self.max_trades_per_day:
            return False, (
                f"Maximum {self.max_trades_per_day} trades per day reached "
                f"(current: {total_trades})"
            )
        
        if symbol_trades >= self.max_trades_per_symbol:
            return False, (
                f"Maximum {self.max_trades_per_symbol} trades per day for {symbol} "
                f"reached (current: {symbol_trades})"
            )
        
        return True, "OK"
```

### Consecutive Loss Limits

**Stop After Consecutive Losses**: Halt trading after multiple consecutive losses.

```python
class ConsecutiveLossLimits:
    def __init__(self, max_consecutive_losses: int = 3):
        self.max_consecutive_losses = max_consecutive_losses
    
    async def check_consecutive_losses(
        self,
        account_id: int
    ) -> tuple[bool, str]:
        """Check if consecutive loss limit is reached"""
        recent_trades = await get_recent_trades(account_id, limit=10)
        
        consecutive_losses = 0
        for trade in reversed(recent_trades):  # Check from most recent
            if trade.realized_pnl and trade.realized_pnl < 0:
                consecutive_losses += 1
            else:
                break  # Stop counting on first win
        
        if consecutive_losses >= self.max_consecutive_losses:
            return False, (
                f"{consecutive_losses} consecutive losses reached. "
                f"Maximum allowed: {self.max_consecutive_losses}"
            )
        
        return True, "OK"
```

---

## Risk Metrics

Real-time calculation of risk metrics to assess portfolio risk.

### Value at Risk (VaR)

**Definition**: Maximum expected loss over a time horizon at a given confidence level.

```python
import numpy as np
from scipy import stats

class ValueAtRisk:
    def __init__(
        self,
        confidence_level: float = 0.95,  # 95% confidence
        time_horizon_days: int = 1  # 1-day VaR
    ):
        self.confidence_level = confidence_level
        self.time_horizon_days = time_horizon_days
    
    def calculate_historical_var(
        self,
        returns: np.ndarray,
        portfolio_value: float
    ) -> float:
        """
        Calculate VaR using historical simulation.
        
        Args:
            returns: Historical returns array
            portfolio_value: Current portfolio value
        
        Returns:
            VaR in absolute terms
        """
        # Sort returns
        sorted_returns = np.sort(returns)
        
        # Find percentile
        percentile = (1 - self.confidence_level) * 100
        var_percentile = np.percentile(sorted_returns, percentile)
        
        # Convert to absolute VaR
        var_absolute = abs(var_percentile * portfolio_value)
        
        return var_absolute
    
    def calculate_parametric_var(
        self,
        portfolio_value: float,
        portfolio_std: float
    ) -> float:
        """
        Calculate VaR using parametric method (assumes normal distribution).
        
        Formula:
            VaR = Portfolio Value × Z-score × Portfolio Std Dev × sqrt(time_horizon)
        
        Args:
            portfolio_value: Current portfolio value
            portfolio_std: Portfolio standard deviation
        
        Returns:
            VaR in absolute terms
        """
        z_score = stats.norm.ppf(1 - self.confidence_level)
        time_factor = np.sqrt(self.time_horizon_days)
        
        var = portfolio_value * abs(z_score) * portfolio_std * time_factor
        
        return var
    
    async def calculate_portfolio_var(
        self,
        account_id: int
    ) -> Dict[str, float]:
        """Calculate VaR for entire portfolio"""
        positions = await get_all_positions(account_id)
        account = await get_account(account_id)
        
        # Get historical returns for each position
        portfolio_returns = []
        for position in positions:
            symbol_returns = await get_historical_returns(
                position.symbol,
                days=30
            )
            # Weight by position value
            position_value = position.quantity * position.current_price
            weight = position_value / account.current_balance
            weighted_returns = symbol_returns * weight
            portfolio_returns.append(weighted_returns)
        
        # Combine returns
        if portfolio_returns:
            combined_returns = np.sum(portfolio_returns, axis=0)
        else:
            combined_returns = np.array([])
        
        # Calculate VaR
        if len(combined_returns) > 0:
            historical_var = self.calculate_historical_var(
                combined_returns,
                account.current_balance
            )
            parametric_var = self.calculate_parametric_var(
                account.current_balance,
                np.std(combined_returns)
            )
        else:
            historical_var = 0.0
            parametric_var = 0.0
        
        return {
            "historical_var": historical_var,
            "parametric_var": parametric_var,
            "var_pct": historical_var / account.current_balance if account.current_balance > 0 else 0
        }
```

### Conditional Value at Risk (CVaR)

**Definition**: Expected loss given that loss exceeds VaR (tail risk).

```python
class ConditionalVaR:
    def calculate_cvar(
        self,
        returns: np.ndarray,
        portfolio_value: float,
        var_value: float
    ) -> float:
        """
        Calculate CVaR (Expected Shortfall).
        
        CVaR = Average of losses that exceed VaR
        
        Args:
            returns: Historical returns
            portfolio_value: Portfolio value
            var_value: Pre-calculated VaR value
        
        Returns:
            CVaR in absolute terms
        """
        # Convert VaR to return percentile
        var_return = var_value / portfolio_value
        
        # Find returns below VaR threshold
        tail_returns = returns[returns <= -abs(var_return)]
        
        if len(tail_returns) == 0:
            return var_value  # No tail, use VaR
        
        # Calculate average of tail
        cvar_return = np.mean(tail_returns)
        cvar_absolute = abs(cvar_return * portfolio_value)
        
        return cvar_absolute
```

### Maximum Drawdown

**Definition**: Largest peak-to-trough decline in portfolio value.

```python
class MaximumDrawdown:
    def calculate_max_drawdown(
        self,
        equity_curve: np.ndarray
    ) -> Dict[str, float]:
        """
        Calculate maximum drawdown.
        
        Args:
            equity_curve: Array of portfolio values over time
        
        Returns:
            Dict with max_drawdown (absolute), max_drawdown_pct, and duration
        """
        # Calculate running maximum
        running_max = np.maximum.accumulate(equity_curve)
        
        # Calculate drawdown
        drawdown = equity_curve - running_max
        drawdown_pct = drawdown / running_max
        
        # Find maximum drawdown
        max_drawdown_idx = np.argmin(drawdown)
        max_drawdown = abs(drawdown[max_drawdown_idx])
        max_drawdown_pct = abs(drawdown_pct[max_drawdown_idx])
        
        # Calculate duration (days from peak to recovery)
        peak_idx = np.argmax(equity_curve[:max_drawdown_idx + 1])
        recovery_idx = None
        for i in range(max_drawdown_idx, len(equity_curve)):
            if equity_curve[i] >= equity_curve[peak_idx]:
                recovery_idx = i
                break
        
        duration = (recovery_idx - peak_idx) if recovery_idx else None
        
        return {
            "max_drawdown": max_drawdown,
            "max_drawdown_pct": max_drawdown_pct,
            "duration_days": duration
        }
```

### Sharpe Ratio

**Definition**: Risk-adjusted return measure.

```python
class SharpeRatio:
    def calculate_sharpe_ratio(
        self,
        returns: np.ndarray,
        risk_free_rate: float = 0.02  # 2% annual risk-free rate
    ) -> float:
        """
        Calculate Sharpe ratio.
        
        Formula:
            Sharpe = (Mean Return - Risk-Free Rate) / Std Dev of Returns
        
        Args:
            returns: Portfolio returns
            risk_free_rate: Annual risk-free rate (default 2%)
        
        Returns:
            Sharpe ratio
        """
        if len(returns) == 0 or np.std(returns) == 0:
            return 0.0
        
        # Convert to annual if returns are daily
        mean_return = np.mean(returns) * 252  # Annualize
        std_return = np.std(returns) * np.sqrt(252)  # Annualize
        
        sharpe = (mean_return - risk_free_rate) / std_return if std_return > 0 else 0.0
        
        return sharpe
```

---

## Circuit Breakers

Circuit breakers automatically halt trading when risk thresholds are exceeded or system anomalies are detected.

### Trading Circuit Breaker

**Purpose**: Halt all trading when risk limits are exceeded.

```python
class TradingCircuitBreaker:
    def __init__(
        self,
        daily_loss_threshold: float = 0.02,  # 2% daily loss
        max_drawdown_threshold: float = 0.10,  # 10% max drawdown
        consecutive_loss_threshold: int = 5,  # 5 consecutive losses
        var_threshold: float = 0.05  # 5% VaR
    ):
        self.daily_loss_threshold = daily_loss_threshold
        self.max_drawdown_threshold = max_drawdown_threshold
        self.consecutive_loss_threshold = consecutive_loss_threshold
        self.var_threshold = var_threshold
        self.is_open = False
        self.open_reason = None
        self.open_time = None
    
    async def check_risk_limits(self, account_id: int) -> Dict[str, Any]:
        """Check all risk limits and open circuit if needed"""
        account = await get_account(account_id)
        
        # Check daily loss
        daily_loss = await calculate_daily_loss(account_id)
        if daily_loss <= -self.daily_loss_threshold:
            await self.open_circuit(account_id, "Daily loss threshold exceeded")
            return {"status": "OPEN", "reason": "daily_loss"}
        
        # Check max drawdown
        equity_curve = await get_equity_curve(account_id, days=30)
        max_dd = MaximumDrawdown().calculate_max_drawdown(equity_curve)
        if max_dd["max_drawdown_pct"] >= self.max_drawdown_threshold:
            await self.open_circuit(account_id, "Maximum drawdown threshold exceeded")
            return {"status": "OPEN", "reason": "max_drawdown"}
        
        # Check consecutive losses
        consecutive_losses = await count_consecutive_losses(account_id)
        if consecutive_losses >= self.consecutive_loss_threshold:
            await self.open_circuit(account_id, "Consecutive loss threshold exceeded")
            return {"status": "OPEN", "reason": "consecutive_losses"}
        
        # Check VaR
        var_result = await ValueAtRisk().calculate_portfolio_var(account_id)
        if var_result["var_pct"] >= self.var_threshold:
            await self.open_circuit(account_id, "VaR threshold exceeded")
            return {"status": "OPEN", "reason": "var_threshold"}
        
        return {"status": "CLOSED"}
    
    async def open_circuit(self, account_id: int, reason: str):
        """Open circuit breaker (halt trading)"""
        self.is_open = True
        self.open_reason = reason
        self.open_time = datetime.utcnow()
        
        # Halt trading
        await halt_trading(account_id, reason)
        
        # Cancel all open orders
        open_orders = await get_open_orders(account_id)
        for order in open_orders:
            await cancel_order(order.id)
        
        # Alert
        await send_alert(
            f"Circuit breaker opened for account {account_id}: {reason}",
            severity="critical"
        )
        
        logger.critical(f"Trading circuit breaker opened: {reason}")
    
    async def close_circuit(self, account_id: int):
        """Close circuit breaker (resume trading)"""
        self.is_open = False
        self.open_reason = None
        self.open_time = None
        
        await resume_trading(account_id)
        
        await send_alert(
            f"Circuit breaker closed for account {account_id}",
            severity="info"
        )
```

### Exchange Circuit Breaker

**Purpose**: Halt trading with specific exchange when it's experiencing issues.

```python
class ExchangeCircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,  # 5 failures
        timeout_seconds: int = 60  # 60 second timeout
    ):
        self.failure_threshold = failure_threshold
        self.timeout_seconds = timeout_seconds
        self.exchange_states: Dict[str, Dict] = {}
    
    async def check_exchange_health(self, exchange: str) -> bool:
        """Check if exchange is healthy"""
        state = self.exchange_states.get(exchange, {
            "failures": 0,
            "last_failure": None,
            "is_open": False
        })
        
        # Check if circuit should be closed (timeout elapsed)
        if state["is_open"] and state["last_failure"]:
            elapsed = (datetime.utcnow() - state["last_failure"]).total_seconds()
            if elapsed >= self.timeout_seconds:
                state["is_open"] = False
                state["failures"] = 0
                logger.info(f"Exchange circuit breaker closed for {exchange}")
        
        return not state["is_open"]
    
    def record_exchange_failure(self, exchange: str):
        """Record exchange failure"""
        state = self.exchange_states.get(exchange, {
            "failures": 0,
            "last_failure": None,
            "is_open": False
        })
        
        state["failures"] += 1
        state["last_failure"] = datetime.utcnow()
        
        if state["failures"] >= self.failure_threshold:
            state["is_open"] = True
            logger.warning(
                f"Exchange circuit breaker opened for {exchange} "
                f"after {state['failures']} failures"
            )
        
        self.exchange_states[exchange] = state
    
    def record_exchange_success(self, exchange: str):
        """Record exchange success"""
        state = self.exchange_states.get(exchange, {
            "failures": 0,
            "last_failure": None,
            "is_open": False
        })
        
        if state["is_open"]:
            # In half-open state, success closes circuit
            state["is_open"] = False
            state["failures"] = 0
            logger.info(f"Exchange circuit breaker closed for {exchange}")
        else:
            # Reset failure count on success
            state["failures"] = max(0, state["failures"] - 1)
        
        self.exchange_states[exchange] = state
```

---

## Risk Validation Pipeline

Complete risk validation before order execution.

```python
class RiskValidator:
    def __init__(self, account_id: int):
        self.account_id = account_id
        self.position_limits = AccountPositionLimits(account_id)
        self.portfolio_limits = PortfolioLimits()
        self.daily_limits = DailyLossLimits(account_id=account_id)
        self.trade_limits = DailyTradeLimits()
        self.loss_limits = ConsecutiveLossLimits()
        self.circuit_breaker = TradingCircuitBreaker()
    
    async def validate_order(self, order: Dict[str, Any]) -> Dict[str, Any]:
        """
        Complete risk validation before order execution.
        
        Returns:
            Dict with 'approved' (bool) and 'reasons' (list of strings)
        """
        account = await get_account(self.account_id)
        symbol = order['symbol']
        quantity = order['quantity']
        price = order.get('price') or await get_current_price(symbol)
        
        validation_results = []
        
        # 1. Check circuit breaker
        circuit_status = await self.circuit_breaker.check_risk_limits(self.account_id)
        if circuit_status["status"] == "OPEN":
            return {
                "approved": False,
                "reasons": [f"Circuit breaker open: {circuit_status.get('reason')}"]
            }
        
        # 2. Check daily loss limits
        daily_loss_check = await self.daily_limits.check_daily_loss(self.account_id)
        if daily_loss_check["status"] != "OK":
            return {
                "approved": False,
                "reasons": [f"Daily loss limit: {daily_loss_check['status']}"]
            }
        
        # 3. Check trade count limits
        trade_count_ok, trade_count_reason = await self.trade_limits.check_trade_count(
            self.account_id, symbol
        )
        if not trade_count_ok:
            return {"approved": False, "reasons": [trade_count_reason]}
        
        # 4. Check consecutive losses
        consecutive_ok, consecutive_reason = await self.loss_limits.check_consecutive_losses(
            self.account_id
        )
        if not consecutive_ok:
            return {"approved": False, "reasons": [consecutive_reason]}
        
        # 5. Check position limits
        position_ok, position_reason = await self.position_limits.validate_position(
            symbol, quantity, price
        )
        if not position_ok:
            validation_results.append(position_reason)
        
        # 6. Check symbol exposure
        symbol_ok, symbol_reason = await SymbolPositionLimits(symbol).validate_symbol_exposure(
            self.account_id, quantity, price
        )
        if not symbol_ok:
            validation_results.append(symbol_reason)
        
        # 7. Check portfolio limits
        portfolio_ok, portfolio_reason = await self.portfolio_limits.validate_portfolio(
            self.account_id, order
        )
        if not portfolio_ok:
            validation_results.append(portfolio_reason)
        
        # 8. Check margin requirements
        margin_ok, margin_reason = await self.check_margin(order)
        if not margin_ok:
            validation_results.append(margin_reason)
        
        if validation_results:
            return {
                "approved": False,
                "reasons": validation_results
            }
        
        return {"approved": True, "reasons": []}
    
    async def check_margin(self, order: Dict[str, Any]) -> tuple[bool, str]:
        """Check if sufficient margin is available"""
        account = await get_account(self.account_id)
        position_value = order['quantity'] * order.get('price', 0)
        
        # Calculate required margin
        leverage = order.get('leverage', 1.0)
        required_margin = position_value / leverage
        
        # Check available margin
        total_margin_used = await calculate_total_margin_used(self.account_id)
        available_margin = account.current_balance - total_margin_used
        
        if available_margin < required_margin:
            return False, (
                f"Insufficient margin: required ${required_margin:,.2f}, "
                f"available ${available_margin:,.2f}"
            )
        
        return True, "OK"
```

---

## Configuration

### Risk Management Configuration Schema

```sql
CREATE TABLE risk_config (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(id),
    config_type VARCHAR(50) NOT NULL,  -- 'position_limits', 'daily_limits', etc.
    config_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Default Configuration

```python
DEFAULT_RISK_CONFIG = {
    "position_limits": {
        "max_position_pct": 0.10,  # 10% per position
        "max_symbol_exposure_pct": 0.20,  # 20% per symbol
        "max_portfolio_exposure_pct": 0.50  # 50% total
    },
    "daily_limits": {
        "daily_loss_hard_limit_pct": 0.02,  # 2% hard stop
        "daily_loss_soft_limit_pct": 0.015,  # 1.5% soft limit
        "max_trades_per_day": 6,
        "max_trades_per_symbol": 3,
        "max_consecutive_losses": 3
    },
    "stop_loss": {
        "atr_multiplier": 2.0,
        "default_stop_pct": 0.02,  # 2% default
        "trail_distance_pct": 0.015  # 1.5% trail
    },
    "margin": {
        "initial_margin_pct": 0.10,  # 10% initial
        "maintenance_margin_pct": 0.05,  # 5% maintenance
        "max_leverage": 10.0,
        "liquidation_threshold": 0.03  # 3% = liquidation
    },
    "circuit_breaker": {
        "daily_loss_threshold": 0.02,
        "max_drawdown_threshold": 0.10,
        "consecutive_loss_threshold": 5,
        "var_threshold": 0.05
    }
}
```

---

## References

- [Risk Management in Algorithmic Trading](https://www.investopedia.com/articles/trading/09/risk-management.asp)
- [Value at Risk (VaR) Calculation Methods](https://www.investopedia.com/terms/v/var.asp)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Position Sizing Strategies](https://www.investopedia.com/articles/trading/09/position-sizing.asp)

