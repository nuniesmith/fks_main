# FKS Historical Data Backfilling Strategy

## Overview

The FKS Historical Data Backfilling System ensures complete, accurate historical market data by efficiently backfilling years of data from multiple providers, detecting and filling gaps, and validating data quality.

**Key Principle**: Historical data must be complete, validated, and efficiently stored to support backtesting, ML training, and analysis.

## Table of Contents

1. [Backfill Pipeline](#backfill-pipeline)
2. [Gap Detection](#gap-detection)
3. [Gap Filling](#gap-filling)
4. [Incremental Updates](#incremental-updates)
5. [Data Validation](#data-validation)
6. [Sync Status Tracking](#sync-status-tracking)
7. [Configuration](#configuration)

---

## Backfill Pipeline

The backfill pipeline efficiently retrieves historical data from multiple providers in parallel.

### Multi-Provider Strategy

**Provider Priority**:
1. **Primary Provider**: Fastest, most reliable (e.g., Binance for crypto)
2. **Secondary Provider**: Backup for gaps (e.g., CoinGecko)
3. **Tertiary Provider**: Validation source (e.g., Polygon)

```python
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import asyncio
import pandas as pd

class BackfillPipeline:
    def __init__(
        self,
        providers: List[DataProvider],
        batch_size_days: int = 30,  # Backfill 30 days at a time
        max_concurrent: int = 5  # Max concurrent requests
    ):
        self.providers = providers
        self.batch_size_days = batch_size_days
        self.max_concurrent = max_concurrent
        self.semaphore = asyncio.Semaphore(max_concurrent)
    
    async def backfill_symbol(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime,
        provider_priority: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Backfill historical data for a symbol.
        
        Args:
            symbol: Trading pair symbol
            timeframe: Data interval (1m, 5m, 1h, 1d)
            start_date: Start date for backfill
            end_date: End date for backfill
            provider_priority: Preferred provider order
        
        Returns:
            Dict with backfill results
        """
        provider_priority = provider_priority or [p.name for p in self.providers]
        
        # Split into batches
        batches = self._create_batches(start_date, end_date)
        
        results = {
            "symbol": symbol,
            "timeframe": timeframe,
            "total_batches": len(batches),
            "successful_batches": 0,
            "failed_batches": 0,
            "total_candles": 0,
            "errors": []
        }
        
        # Process batches with rate limiting
        for batch_start, batch_end in batches:
            async with self.semaphore:
                batch_result = await self._backfill_batch(
                    symbol,
                    timeframe,
                    batch_start,
                    batch_end,
                    provider_priority
                )
                
                if batch_result["success"]:
                    results["successful_batches"] += 1
                    results["total_candles"] += batch_result["candles_count"]
                else:
                    results["failed_batches"] += 1
                    results["errors"].append(batch_result["error"])
                
                # Small delay to respect rate limits
                await asyncio.sleep(0.1)
        
        return results
    
    def _create_batches(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> List[tuple[datetime, datetime]]:
        """Split date range into batches"""
        batches = []
        current = start_date
        
        while current < end_date:
            batch_end = min(current + timedelta(days=self.batch_size_days), end_date)
            batches.append((current, batch_end))
            current = batch_end
        
        return batches
    
    async def _backfill_batch(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime,
        provider_priority: List[str]
    ) -> Dict[str, Any]:
        """Backfill a single batch using provider priority"""
        for provider_name in provider_priority:
            provider = self._get_provider(provider_name)
            if not provider:
                continue
            
            try:
                data = await provider.fetch_historical(
                    symbol=symbol,
                    timeframe=timeframe,
                    start_date=start_date,
                    end_date=end_date
                )
                
                if data is not None and len(data) > 0:
                    # Store data
                    await self._store_data(symbol, timeframe, data)
                    
                    return {
                        "success": True,
                        "provider": provider_name,
                        "candles_count": len(data)
                    }
            
            except Exception as e:
                logger.warning(
                    f"Provider {provider_name} failed for {symbol}: {e}"
                )
                continue
        
        return {
            "success": False,
            "error": f"All providers failed for {symbol} ({start_date} to {end_date})"
        }
    
    def _get_provider(self, name: str) -> Optional[DataProvider]:
        """Get provider by name"""
        for provider in self.providers:
            if provider.name == name:
                return provider
        return None
    
    async def _store_data(
        self,
        symbol: str,
        timeframe: str,
        data: pd.DataFrame
    ):
        """Store backfilled data in database"""
        # Convert to database format
        records = []
        for _, row in data.iterrows():
            records.append({
                "symbol": symbol,
                "timeframe": timeframe,
                "timestamp": row["timestamp"],
                "open": float(row["open"]),
                "high": float(row["high"]),
                "low": float(row["low"]),
                "close": float(row["close"]),
                "volume": float(row.get("volume", 0))
            })
        
        # Bulk insert
        await bulk_insert_ohlcv(records)
```

### Provider-Specific Backfill

**Binance Backfill** (Crypto):
```python
class BinanceBackfillProvider:
    async def fetch_historical(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime
    ) -> Optional[pd.DataFrame]:
        """Fetch historical data from Binance"""
        # Binance limit: 1000 candles per request
        # Calculate number of requests needed
        interval_seconds = self._timeframe_to_seconds(timeframe)
        total_candles = (end_date - start_date).total_seconds() / interval_seconds
        num_requests = int(np.ceil(total_candles / 1000))
        
        all_data = []
        current_start = start_date
        
        for i in range(num_requests):
            # Calculate end for this request
            current_end = min(
                current_start + timedelta(seconds=1000 * interval_seconds),
                end_date
            )
            
            # Fetch data
            klines = await self.exchange.fetch_ohlcv(
                symbol=symbol,
                timeframe=timeframe,
                since=int(current_start.timestamp() * 1000),
                limit=1000
            )
            
            if klines:
                df = pd.DataFrame(klines, columns=["timestamp", "open", "high", "low", "close", "volume"])
                df["timestamp"] = pd.to_datetime(df["timestamp"], unit="ms")
                all_data.append(df)
            
            # Update start for next request
            current_start = current_end
            
            # Rate limit: Binance allows ~1200 requests/5min
            await asyncio.sleep(0.25)  # ~240 requests/min
        
        if all_data:
            return pd.concat(all_data, ignore_index=True)
        return None
```

**Polygon Backfill** (Stocks/ETFs):
```python
class PolygonBackfillProvider:
    async def fetch_historical(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime
    ) -> Optional[pd.DataFrame]:
        """Fetch historical data from Polygon"""
        # Polygon free tier: 5 calls/min, 2 years history
        multiplier, timespan = self._timeframe_to_polygon(timeframe)
        
        url = f"https://api.polygon.io/v2/aggs/ticker/{symbol}/range/{multiplier}/{timespan}/{start_date.strftime('%Y-%m-%d')}/{end_date.strftime('%Y-%m-%d')}"
        
        params = {
            "apiKey": self.api_key,
            "limit": 50000  # Max results per request
        }
        
        response = await self.session.get(url, params=params)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("resultsCount", 0) > 0:
            df = pd.DataFrame(data["results"])
            df["timestamp"] = pd.to_datetime(df["t"], unit="ms")
            df = df.rename(columns={
                "o": "open",
                "h": "high",
                "l": "low",
                "c": "close",
                "v": "volume"
            })
            return df[["timestamp", "open", "high", "low", "close", "volume"]]
        
        return None
```

---

## Gap Detection

Detect missing data periods in historical datasets.

### Gap Detection Algorithm

```python
class GapDetector:
    def __init__(
        self,
        max_gap_minutes: int = 5,  # Max acceptable gap (5 minutes)
        expected_interval_seconds: Optional[int] = None
    ):
        self.max_gap_minutes = max_gap_minutes
        self.expected_interval_seconds = expected_interval_seconds
    
    async def detect_gaps(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[Dict[str, Any]]:
        """
        Detect gaps in historical data.
        
        Returns:
            List of gap dictionaries with start, end, duration
        """
        # Get existing data
        existing_data = await get_ohlcv_data(
            symbol=symbol,
            timeframe=timeframe,
            start_date=start_date,
            end_date=end_date
        )
        
        if existing_data.empty:
            # Entire range is a gap
            return [{
                "start": start_date,
                "end": end_date,
                "duration_minutes": (end_date - start_date).total_seconds() / 60,
                "missing_candles": self._estimate_candles(start_date, end_date, timeframe)
            }]
        
        # Sort by timestamp
        existing_data = existing_data.sort_values("timestamp")
        
        # Determine expected interval
        if self.expected_interval_seconds is None:
            self.expected_interval_seconds = self._detect_interval(existing_data)
        
        gaps = []
        
        # Check for gap at start
        first_timestamp = existing_data["timestamp"].iloc[0]
        if first_timestamp > start_date:
            gap_end = first_timestamp
            gaps.append({
                "start": start_date,
                "end": gap_end,
                "duration_minutes": (gap_end - start_date).total_seconds() / 60,
                "missing_candles": self._estimate_candles(start_date, gap_end, timeframe)
            })
        
        # Check for gaps between data points
        for i in range(len(existing_data) - 1):
            current = existing_data.iloc[i]["timestamp"]
            next_timestamp = existing_data.iloc[i + 1]["timestamp"]
            
            expected_next = current + timedelta(seconds=self.expected_interval_seconds)
            gap_duration = (next_timestamp - expected_next).total_seconds() / 60
            
            if gap_duration > self.max_gap_minutes:
                gaps.append({
                    "start": expected_next,
                    "end": next_timestamp,
                    "duration_minutes": gap_duration,
                    "missing_candles": self._estimate_candles(expected_next, next_timestamp, timeframe)
                })
        
        # Check for gap at end
        last_timestamp = existing_data["timestamp"].iloc[-1]
        if last_timestamp < end_date:
            gap_start = last_timestamp + timedelta(seconds=self.expected_interval_seconds)
            gaps.append({
                "start": gap_start,
                "end": end_date,
                "duration_minutes": (end_date - gap_start).total_seconds() / 60,
                "missing_candles": self._estimate_candles(gap_start, end_date, timeframe)
            })
        
        return gaps
    
    def _detect_interval(self, data: pd.DataFrame) -> int:
        """Detect data interval from timestamps"""
        if len(data) < 2:
            return 60  # Default 1 minute
        
        diffs = data["timestamp"].diff().dropna()
        median_diff = diffs.median()
        
        return int(median_diff.total_seconds())
    
    def _estimate_candles(
        self,
        start: datetime,
        end: datetime,
        timeframe: str
    ) -> int:
        """Estimate number of missing candles"""
        interval_seconds = self._timeframe_to_seconds(timeframe)
        duration_seconds = (end - start).total_seconds()
        return int(duration_seconds / interval_seconds)
    
    def _timeframe_to_seconds(self, timeframe: str) -> int:
        """Convert timeframe string to seconds"""
        timeframe_map = {
            "1m": 60,
            "5m": 300,
            "15m": 900,
            "30m": 1800,
            "1h": 3600,
            "4h": 14400,
            "1d": 86400,
            "1w": 604800
        }
        return timeframe_map.get(timeframe, 60)
```

### Gap Detection Scheduler

```python
from celery import shared_task

@shared_task
async def detect_gaps_task():
    """Periodic task to detect gaps in historical data"""
    detector = GapDetector()
    
    # Get all active symbols
    symbols = await get_active_symbols()
    
    for symbol in symbols:
        for timeframe in ["1m", "5m", "1h", "1d"]:
            # Get sync status
            sync_status = await get_sync_status(symbol, timeframe)
            
            if sync_status and sync_status.oldest_data_time:
                # Check for gaps in existing data
                gaps = await detector.detect_gaps(
                    symbol=symbol,
                    timeframe=timeframe,
                    start_date=sync_status.oldest_data_time,
                    end_date=sync_status.newest_data_time or datetime.utcnow()
                )
                
                if gaps:
                    # Log gaps
                    await log_gaps(symbol, timeframe, gaps)
                    
                    # Queue gap filling
                    for gap in gaps:
                        await queue_gap_fill(symbol, timeframe, gap)
```

---

## Gap Filling

Fill detected gaps using multiple providers.

### Gap Filling Strategy

```python
class GapFiller:
    def __init__(self, providers: List[DataProvider]):
        self.providers = providers
    
    async def fill_gap(
        self,
        symbol: str,
        timeframe: str,
        gap: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Fill a detected gap.
        
        Args:
            symbol: Trading pair symbol
            timeframe: Data interval
            gap: Gap dictionary with start, end, duration
        
        Returns:
            Fill result with success status and candles filled
        """
        start = gap["start"]
        end = gap["end"]
        
        # Try providers in priority order
        for provider in self.providers:
            try:
                data = await provider.fetch_historical(
                    symbol=symbol,
                    timeframe=timeframe,
                    start_date=start,
                    end_date=end
                )
                
                if data is not None and len(data) > 0:
                    # Validate data quality
                    validation = await self._validate_gap_data(data, gap)
                    
                    if validation["valid"]:
                        # Store filled data
                        await self._store_data(symbol, timeframe, data)
                        
                        # Update sync status
                        await self._update_sync_status(symbol, timeframe, data)
                        
                        return {
                            "success": True,
                            "provider": provider.name,
                            "candles_filled": len(data),
                            "expected_candles": gap["missing_candles"],
                            "coverage": len(data) / gap["missing_candles"] if gap["missing_candles"] > 0 else 1.0
                        }
                    else:
                        logger.warning(
                            f"Gap data validation failed for {symbol}: {validation['reason']}"
                        )
            
            except Exception as e:
                logger.error(f"Provider {provider.name} failed to fill gap: {e}")
                continue
        
        return {
            "success": False,
            "error": "All providers failed to fill gap"
        }
    
    async def _validate_gap_data(
        self,
        data: pd.DataFrame,
        gap: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Validate gap fill data quality"""
        # Check data range covers gap
        data_start = data["timestamp"].min()
        data_end = data["timestamp"].max()
        
        if data_start > gap["start"] or data_end < gap["end"]:
            return {
                "valid": False,
                "reason": f"Data range ({data_start} to {data_end}) doesn't cover gap ({gap['start']} to {gap['end']})"
            }
        
        # Check for missing values
        if data[["open", "high", "low", "close"]].isnull().any().any():
            return {
                "valid": False,
                "reason": "Data contains missing OHLC values"
            }
        
        # Check price consistency (high >= low, etc.)
        if (data["high"] < data["low"]).any():
            return {
                "valid": False,
                "reason": "Data contains invalid price relationships"
            }
        
        return {"valid": True}
    
    async def _update_sync_status(
        self,
        symbol: str,
        timeframe: str,
        data: pd.DataFrame
    ):
        """Update sync status after gap fill"""
        sync_status = await get_sync_status(symbol, timeframe)
        
        if sync_status:
            # Update oldest/newest if needed
            data_start = data["timestamp"].min()
            data_end = data["timestamp"].max()
            
            if not sync_status.oldest_data_time or data_start < sync_status.oldest_data_time:
                sync_status.oldest_data_time = data_start
            
            if not sync_status.newest_data_time or data_end > sync_status.newest_data_time:
                sync_status.newest_data_time = data_end
            
            sync_status.total_candles += len(data)
            await sync_status.save()
```

---

## Incremental Updates

Update historical data when corrections are received from providers.

### Incremental Update Handler

```python
class IncrementalUpdateHandler:
    def __init__(self):
        self.update_queue = asyncio.Queue()
    
    async def process_correction(
        self,
        symbol: str,
        timeframe: str,
        correction_data: pd.DataFrame
    ):
        """
        Process data correction from provider.
        
        Corrections typically come from:
        - Exchange data corrections
        - Provider data updates
        - Manual corrections
        """
        # Validate correction data
        validation = await self._validate_correction(correction_data)
        if not validation["valid"]:
            logger.error(f"Invalid correction data: {validation['reason']}")
            return
        
        # Check which records need updating
        existing_data = await get_ohlcv_data(
            symbol=symbol,
            timeframe=timeframe,
            start_date=correction_data["timestamp"].min(),
            end_date=correction_data["timestamp"].max()
        )
        
        if existing_data.empty:
            # No existing data, insert new
            await bulk_insert_ohlcv(correction_data)
        else:
            # Update existing records
            await self._update_existing_records(
                symbol,
                timeframe,
                correction_data,
                existing_data
            )
        
        # Log correction
        await log_data_correction(
            symbol=symbol,
            timeframe=timeframe,
            records_updated=len(correction_data),
            reason="provider_correction"
        )
    
    async def _update_existing_records(
        self,
        symbol: str,
        timeframe: str,
        correction_data: pd.DataFrame,
        existing_data: pd.DataFrame
    ):
        """Update existing records with corrected data"""
        # Merge on timestamp
        merged = existing_data.merge(
            correction_data,
            on="timestamp",
            how="outer",
            suffixes=("_old", "_new")
        )
        
        # Update records where data differs
        for _, row in merged.iterrows():
            if pd.notna(row["open_new"]):
                # Check if values changed
                if (row["open_old"] != row["open_new"] or
                    row["high_old"] != row["high_new"] or
                    row["low_old"] != row["low_new"] or
                    row["close_old"] != row["close_new"]):
                    
                    # Update record
                    await update_ohlcv_record(
                        symbol=symbol,
                        timeframe=timeframe,
                        timestamp=row["timestamp"],
                        open=row["open_new"],
                        high=row["high_new"],
                        low=row["low_new"],
                        close=row["close_new"],
                        volume=row.get("volume_new", row.get("volume_old", 0))
                    )
```

---

## Data Validation

Validate backfilled data against multiple sources.

### Multi-Source Validation

```python
class DataValidator:
    def __init__(self, validation_providers: List[DataProvider]):
        self.validation_providers = validation_providers
    
    async def validate_backfill(
        self,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime,
        tolerance_pct: float = 0.01  # 1% price tolerance
    ) -> Dict[str, Any]:
        """
        Validate backfilled data against validation sources.
        
        Returns:
            Validation report with discrepancies
        """
        # Get stored data
        stored_data = await get_ohlcv_data(
            symbol=symbol,
            timeframe=timeframe,
            start_date=start_date,
            end_date=end_date
        )
        
        if stored_data.empty:
            return {
                "valid": False,
                "reason": "No stored data to validate"
            }
        
        discrepancies = []
        
        # Validate against each provider
        for provider in self.validation_providers:
            try:
                validation_data = await provider.fetch_historical(
                    symbol=symbol,
                    timeframe=timeframe,
                    start_date=start_date,
                    end_date=end_date
                )
                
                if validation_data is None or validation_data.empty:
                    continue
                
                # Compare data
                comparison = self._compare_data(
                    stored_data,
                    validation_data,
                    tolerance_pct
                )
                
                if comparison["discrepancies"]:
                    discrepancies.extend(comparison["discrepancies"])
            
            except Exception as e:
                logger.warning(f"Validation provider {provider.name} failed: {e}")
                continue
        
        # Generate report
        if discrepancies:
            return {
                "valid": False,
                "discrepancies": discrepancies,
                "discrepancy_count": len(discrepancies),
                "total_records": len(stored_data)
            }
        else:
            return {
                "valid": True,
                "total_records": len(stored_data)
            }
    
    def _compare_data(
        self,
        stored: pd.DataFrame,
        validation: pd.DataFrame,
        tolerance_pct: float
    ) -> Dict[str, Any]:
        """Compare stored data with validation data"""
        # Merge on timestamp
        merged = stored.merge(
            validation,
            on="timestamp",
            how="inner",
            suffixes=("_stored", "_validation")
        )
        
        discrepancies = []
        
        for _, row in merged.iterrows():
            # Check price discrepancies
            for price_type in ["open", "high", "low", "close"]:
                stored_price = row[f"{price_type}_stored"]
                validation_price = row[f"{price_type}_validation"]
                
                if pd.notna(stored_price) and pd.notna(validation_price):
                    diff_pct = abs(stored_price - validation_price) / validation_price
                    
                    if diff_pct > tolerance_pct:
                        discrepancies.append({
                            "timestamp": row["timestamp"],
                            "field": price_type,
                            "stored": stored_price,
                            "validation": validation_price,
                            "difference_pct": diff_pct
                        })
        
        return {"discrepancies": discrepancies}
```

---

## Sync Status Tracking

Track synchronization state for each symbol/timeframe.

### Sync Status Model

```python
class SyncStatus:
    """Track data synchronization state"""
    
    def __init__(
        self,
        symbol: str,
        timeframe: str,
        last_sync_time: Optional[datetime] = None,
        oldest_data_time: Optional[datetime] = None,
        newest_data_time: Optional[datetime] = None,
        total_candles: int = 0,
        sync_status: str = "pending"
    ):
        self.symbol = symbol
        self.timeframe = timeframe
        self.last_sync_time = last_sync_time
        self.oldest_data_time = oldest_data_time
        self.newest_data_time = newest_data_time
        self.total_candles = total_candles
        self.sync_status = sync_status  # pending, syncing, completed, error
    
    async def update_after_backfill(
        self,
        data: pd.DataFrame
    ):
        """Update sync status after backfill"""
        if data.empty:
            return
        
        data_start = data["timestamp"].min()
        data_end = data["timestamp"].max()
        
        # Update oldest/newest
        if not self.oldest_data_time or data_start < self.oldest_data_time:
            self.oldest_data_time = data_start
        
        if not self.newest_data_time or data_end > self.newest_data_time:
            self.newest_data_time = data_end
        
        # Update counts
        self.total_candles += len(data)
        self.last_sync_time = datetime.utcnow()
        self.sync_status = "completed"
        
        await self.save()
    
    async def mark_syncing(self):
        """Mark as currently syncing"""
        self.sync_status = "syncing"
        await self.save()
    
    async def mark_error(self, error_message: str):
        """Mark sync as failed"""
        self.sync_status = "error"
        self.error_message = error_message
        await self.save()
```

### Sync Status API

```python
@router.get("/sync-status/{symbol}/{timeframe}")
async def get_sync_status(
    symbol: str,
    timeframe: str
) -> Dict[str, Any]:
    """Get sync status for symbol/timeframe"""
    status = await get_sync_status(symbol, timeframe)
    
    if not status:
        return {
            "symbol": symbol,
            "timeframe": timeframe,
            "status": "not_started"
        }
    
    return {
        "symbol": symbol,
        "timeframe": timeframe,
        "status": status.sync_status,
        "oldest_data": status.oldest_data_time.isoformat() if status.oldest_data_time else None,
        "newest_data": status.newest_data_time.isoformat() if status.newest_data_time else None,
        "total_candles": status.total_candles,
        "last_sync": status.last_sync_time.isoformat() if status.last_sync_time else None
    }
```

---

## Configuration

### Backfill Configuration

```python
BACKFILL_CONFIG = {
    "batch_size_days": 30,
    "max_concurrent_requests": 5,
    "provider_priority": {
        "crypto": ["binance", "coingecko", "polygon"],
        "stocks": ["polygon", "yfinance", "alphavantage"],
        "forex": ["oanda", "polygon"]
    },
    "gap_detection": {
        "max_gap_minutes": 5,
        "check_interval_hours": 24
    },
    "validation": {
        "enabled": True,
        "tolerance_pct": 0.01,
        "validation_providers": ["coingecko", "polygon"]
    }
}
```

---

## References

- [Binance API Documentation](https://binance-docs.github.io/apidocs/spot/en/)
- [Polygon.io API Documentation](https://polygon.io/docs)
- [TimescaleDB Continuous Aggregates](https://docs.timescale.com/timescaledb/latest/how-to-guides/continuous-aggregates/)

