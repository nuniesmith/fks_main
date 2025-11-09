# FKS Database Schema Design Documentation

## Overview

FKS uses **TimescaleDB** (PostgreSQL extension) for efficient time-series data storage. This document outlines the schema design patterns, indexing strategies, data archival policies, and migration procedures.

## Table of Contents

1. [Hypertable Design Patterns](#hypertable-design-patterns)
2. [Indexing Strategy](#indexing-strategy)
3. [Data Retention and Archival](#data-retention-and-archival)
4. [Compression Policies](#compression-policies)
5. [Continuous Aggregates](#continuous-aggregates)
6. [Migration Strategy](#migration-strategy)
7. [Query Optimization Guidelines](#query-optimization-guidelines)

---

## Hypertable Design Patterns

### What is a Hypertable?

TimescaleDB hypertables are PostgreSQL tables automatically partitioned by time. They provide:
- **Automatic partitioning**: Data is split into chunks by time intervals
- **Query optimization**: Queries automatically target relevant chunks
- **Compression**: Old data can be compressed to save space
- **Retention policies**: Automatic deletion of old data

### Current Hypertables

#### 1. `ohlcv_data` - Market Data

**Purpose**: Store OHLCV (Open-High-Low-Close-Volume) candlestick data for all symbols and timeframes.

**Schema**:
```sql
CREATE TABLE ohlcv_data (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    timeframe VARCHAR(10) NOT NULL,  -- 1m, 5m, 15m, 30m, 1h, 4h, 1d, 1w, 1M
    open DECIMAL(20, 8) NOT NULL,
    high DECIMAL(20, 8) NOT NULL,
    low DECIMAL(20, 8) NOT NULL,
    close DECIMAL(20, 8) NOT NULL,
    volume DECIMAL(30, 8) NOT NULL,
    quote_volume DECIMAL(30, 8),
    trades_count INTEGER,
    taker_buy_base_volume DECIMAL(30, 8),
    taker_buy_quote_volume DECIMAL(30, 8),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Hypertable Configuration**:
```sql
SELECT create_hypertable('ohlcv_data', 'time', if_not_exists => TRUE);
```

**Chunk Interval**: Default (7 days). For high-frequency data, consider 1 day chunks.

**Partitioning Strategy**:
- Primary key: `(time, symbol, timeframe)` - composite unique constraint
- Chunks are automatically created based on time intervals
- Each chunk contains data for all symbols/timeframes within the time range

**Retention Policy**:
- **Minute data**: 1 year (then archive to cold storage)
- **Hourly data**: 2 years
- **Daily data**: 10 years (indefinite for analysis)

#### 2. `trades` - Trading History

**Purpose**: Complete trading history with full execution details.

**Schema**:
```sql
CREATE TABLE trades (
    id SERIAL,
    time TIMESTAMPTZ NOT NULL,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    symbol VARCHAR(20) NOT NULL,
    trade_type VARCHAR(10) NOT NULL CHECK (trade_type IN ('BUY', 'SELL')),
    quantity DECIMAL(20, 8) NOT NULL,
    price DECIMAL(20, 8) NOT NULL,
    fee DECIMAL(20, 8),
    realized_pnl DECIMAL(20, 8),
    order_id VARCHAR(100),
    trade_metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Hypertable Configuration**:
```sql
SELECT create_hypertable('trades', 'time', if_not_exists => TRUE);
```

**Chunk Interval**: 7 days (default)

**Retention Policy**: 
- **Active trades**: Indefinite (regulatory requirement: 7 years minimum)
- **Archived trades**: Move to cold storage after 2 years, keep metadata in main DB

#### 3. `balance_history` - Account Balance Snapshots

**Purpose**: Track account balance over time for equity curve analysis.

**Schema**:
```sql
CREATE TABLE balance_history (
    time TIMESTAMPTZ NOT NULL,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    balance DECIMAL(20, 8) NOT NULL,
    equity DECIMAL(20, 8) NOT NULL,
    margin_used DECIMAL(20, 8),
    daily_pnl DECIMAL(20, 8),
    cumulative_pnl DECIMAL(20, 8),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Hypertable Configuration**:
```sql
SELECT create_hypertable('balance_history', 'time', if_not_exists => TRUE);
```

**Chunk Interval**: 30 days

**Retention Policy**: 5 years (then archive)

#### 4. `indicators_cache` - Technical Indicators

**Purpose**: Pre-calculated technical indicators for performance optimization.

**Schema**:
```sql
CREATE TABLE indicators_cache (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    timeframe VARCHAR(10) NOT NULL,
    indicator_name VARCHAR(50) NOT NULL,
    value DECIMAL(20, 8),
    indicator_metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Hypertable Configuration**:
```sql
SELECT create_hypertable('indicators_cache', 'time', if_not_exists => TRUE);
```

**Chunk Interval**: 7 days

**Retention Policy**: Match parent data (e.g., if minute OHLCV is kept for 1 year, keep indicators for 1 year)

---

## Indexing Strategy

### Composite Indexes for Time-Series Queries

#### OHLCV Data Indexes

```sql
-- Unique constraint to prevent duplicates
CREATE UNIQUE INDEX idx_ohlcv_unique 
    ON ohlcv_data (symbol, timeframe, time DESC);

-- Most common query: Get latest data for a symbol
CREATE INDEX idx_ohlcv_symbol_time 
    ON ohlcv_data (symbol, time DESC);

-- Query by timeframe across all symbols
CREATE INDEX idx_ohlcv_timeframe 
    ON ohlcv_data (timeframe, time DESC);
```

**Query Patterns**:
1. `SELECT * FROM ohlcv_data WHERE symbol = 'BTCUSDT' AND timeframe = '1h' ORDER BY time DESC LIMIT 100;`
   - Uses: `idx_ohlcv_symbol_time` (covers symbol, time)
   
2. `SELECT * FROM ohlcv_data WHERE symbol = 'BTCUSDT' AND timeframe = '1h' AND time >= '2024-01-01';`
   - Uses: `idx_ohlcv_symbol_time` (covers symbol, time range)

3. `SELECT * FROM ohlcv_data WHERE timeframe = '1d' AND time >= '2024-01-01' ORDER BY time DESC;`
   - Uses: `idx_ohlcv_timeframe` (covers timeframe, time)

#### Trades Indexes

```sql
-- Query trades by account and time
CREATE INDEX idx_trades_account_time 
    ON trades (account_id, time DESC);

-- Query trades by symbol and time
CREATE INDEX idx_trades_symbol_time 
    ON trades (symbol, time DESC);

-- Lookup by exchange order ID
CREATE INDEX idx_trades_order_id 
    ON trades (order_id);
```

**Query Patterns**:
1. `SELECT * FROM trades WHERE account_id = 1 ORDER BY time DESC LIMIT 50;`
   - Uses: `idx_trades_account_time`

2. `SELECT * FROM trades WHERE symbol = 'BTCUSDT' AND time >= '2024-01-01';`
   - Uses: `idx_trades_symbol_time`

#### Balance History Indexes

```sql
-- Query balance history by account
CREATE INDEX idx_balance_account_time 
    ON balance_history (account_id, time DESC);
```

### Partial Indexes for Filtered Queries

For queries that frequently filter on specific conditions:

```sql
-- Index only open positions
CREATE INDEX idx_positions_open 
    ON positions (account_id, symbol) 
    WHERE status = 'open';

-- Index only active sync statuses
CREATE INDEX idx_sync_status_active 
    ON sync_status (symbol, timeframe) 
    WHERE sync_status IN ('pending', 'syncing');
```

### Index Maintenance

**Monitor Index Usage**:
```sql
-- Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

**Rebuild Unused Indexes**:
```sql
-- Rebuild index if needed
REINDEX INDEX CONCURRENTLY idx_ohlcv_symbol_time;
```

---

## Data Retention and Archival

### Retention Policies

TimescaleDB provides automatic data retention policies:

```sql
-- Delete OHLCV minute data older than 1 year
SELECT add_retention_policy('ohlcv_data', INTERVAL '1 year',
    if_not_exists => TRUE);

-- Delete balance history older than 5 years
SELECT add_retention_policy('balance_history', INTERVAL '5 years',
    if_not_exists => TRUE);
```

**Current Retention Schedule**:

| Table | Data Type | Retention Period | Action |
|-------|-----------|------------------|--------|
| `ohlcv_data` | Minute (1m, 5m) | 1 year | Archive to S3 |
| `ohlcv_data` | Hourly (1h, 4h) | 2 years | Archive to S3 |
| `ohlcv_data` | Daily (1d, 1w, 1M) | 10 years | Keep in DB |
| `trades` | All | 7 years (regulatory) | Archive after 2 years |
| `balance_history` | All | 5 years | Archive to S3 |
| `indicators_cache` | All | Match parent data | Delete when parent deleted |

### Archival Strategy

#### Step 1: Export to S3

```python
# Example: Archive old OHLCV data to S3
import boto3
import pandas as pd
from sqlalchemy import create_engine

def archive_ohlcv_to_s3(symbol: str, timeframe: str, start_date: str, end_date: str):
    """Export OHLCV data to S3 before deletion"""
    engine = create_engine(DATABASE_URL)
    
    query = f"""
    SELECT * FROM ohlcv_data
    WHERE symbol = '{symbol}'
      AND timeframe = '{timeframe}'
      AND time >= '{start_date}'
      AND time < '{end_date}'
    ORDER BY time
    """
    
    df = pd.read_sql(query, engine)
    
    # Upload to S3 as Parquet (compressed)
    s3_path = f"s3://fks-archive/ohlcv/{symbol}/{timeframe}/{start_date}.parquet"
    df.to_parquet(s3_path, compression='snappy', index=False)
    
    return s3_path
```

#### Step 2: Verify Archive

```sql
-- Verify data exists in S3 before deletion
-- (Implement S3 verification in application code)
```

#### Step 3: Delete from Database

```sql
-- Delete archived data (after verification)
DELETE FROM ohlcv_data
WHERE symbol = 'BTCUSDT'
  AND timeframe = '1m'
  AND time < NOW() - INTERVAL '1 year';
```

#### Step 4: Restore from Archive (if needed)

```python
def restore_from_s3(s3_path: str):
    """Restore archived data from S3"""
    import boto3
    import pandas as pd
    
    s3 = boto3.client('s3')
    df = pd.read_parquet(s3_path)
    
    # Insert back into database
    df.to_sql('ohlcv_data', engine, if_exists='append', index=False)
```

### Cold Storage Access

For archived data that's rarely accessed:

1. **S3 Standard-IA** (Infrequent Access): For data accessed < 1x/month
2. **S3 Glacier**: For data accessed < 1x/year
3. **S3 Glacier Deep Archive**: For compliance/regulatory data (7+ years)

---

## Compression Policies

TimescaleDB automatically compresses old data to save space (up to 90% reduction).

### Compression Configuration

```sql
-- Enable compression on ohlcv_data
ALTER TABLE ohlcv_data SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol, timeframe',
    timescaledb.compress_orderby = 'time DESC'
);

-- Compress data older than 7 days
SELECT add_compression_policy('ohlcv_data', INTERVAL '7 days', 
    if_not_exists => TRUE);
```

**Compression Settings Explained**:
- `segmentby`: Group compressed chunks by these columns (symbol, timeframe)
- `orderby`: Sort within compressed chunks (time DESC for recent-first queries)

### Compression Status

```sql
-- Check compression status
SELECT 
    hypertable_name,
    total_chunks,
    number_compressed_chunks,
    before_compression_total_bytes,
    after_compression_total_bytes,
    (before_compression_total_bytes - after_compression_total_bytes)::numeric / 
        before_compression_total_bytes * 100 as compression_ratio_pct
FROM timescaledb_information.compressed_hypertable_stats;
```

### Decompression (if needed)

```sql
-- Decompress specific chunk (rarely needed)
SELECT decompress_chunk('_timescaledb_internal._hyper_1_1_chunk');
```

---

## Continuous Aggregates

Continuous aggregates are materialized views that automatically refresh, pre-computing expensive queries.

### Example: Daily Account Performance

```sql
CREATE MATERIALIZED VIEW daily_account_performance
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    account_id,
    COUNT(*) as trades_count,
    SUM(CASE WHEN realized_pnl > 0 THEN 1 ELSE 0 END) as winning_trades,
    SUM(CASE WHEN realized_pnl < 0 THEN 1 ELSE 0 END) as losing_trades,
    SUM(realized_pnl) as total_pnl,
    AVG(realized_pnl) as avg_pnl,
    MAX(realized_pnl) as best_trade,
    MIN(realized_pnl) as worst_trade,
    SUM(fee) as total_fees
FROM trades
WHERE realized_pnl IS NOT NULL
GROUP BY day, account_id;

-- Auto-refresh policy (refresh every hour, keep last 3 days + 1 hour buffer)
SELECT add_continuous_aggregate_policy('daily_account_performance',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE);
```

### Querying Continuous Aggregates

```sql
-- Fast query using pre-aggregated data
SELECT * FROM daily_account_performance
WHERE account_id = 1
  AND day >= '2024-01-01'
ORDER BY day DESC;
```

### Adding More Continuous Aggregates

**Hourly OHLCV Aggregation** (from minute data):
```sql
CREATE MATERIALIZED VIEW hourly_ohlcv_agg
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS hour,
    symbol,
    timeframe,
    FIRST(open, time) as open,
    MAX(high) as high,
    MIN(low) as low,
    LAST(close, time) as close,
    SUM(volume) as volume
FROM ohlcv_data
WHERE timeframe = '1m'
GROUP BY hour, symbol, timeframe;
```

---

## Migration Strategy

### Zero-Downtime Migrations for Hypertables

#### Adding a Column

```sql
-- Step 1: Add column as nullable
ALTER TABLE ohlcv_data ADD COLUMN new_field DECIMAL(20, 8);

-- Step 2: Backfill data (in batches)
UPDATE ohlcv_data 
SET new_field = calculated_value 
WHERE time >= '2024-01-01' AND time < '2024-01-02';

-- Step 3: Add NOT NULL constraint (if needed) after backfill
ALTER TABLE ohlcv_data ALTER COLUMN new_field SET NOT NULL;
```

#### Changing Column Type

```sql
-- Step 1: Add new column with new type
ALTER TABLE ohlcv_data ADD COLUMN volume_new BIGINT;

-- Step 2: Copy data
UPDATE ohlcv_data SET volume_new = volume::BIGINT;

-- Step 3: Drop old column, rename new
ALTER TABLE ohlcv_data DROP COLUMN volume;
ALTER TABLE ohlcv_data RENAME COLUMN volume_new TO volume;
```

#### Adding Indexes

```sql
-- Use CONCURRENTLY to avoid locking
CREATE INDEX CONCURRENTLY idx_ohlcv_new_index
ON ohlcv_data (symbol, timeframe, time DESC);
```

### Schema Versioning

Track schema changes in migration files:

```
repo/main/sql/migrations/
├── 001_initial_schema.sql
├── 002_add_indicators_cache.sql
├── 003_add_fundamentals_schema.sql
└── 004_add_new_field_to_ohlcv.sql
```

### Rollback Procedures

Always test migrations on staging first. For rollback:

```sql
-- Example: Rollback adding a column
ALTER TABLE ohlcv_data DROP COLUMN IF EXISTS new_field;
```

---

## Query Optimization Guidelines

### Best Practices

1. **Always include time range in WHERE clause**:
   ```sql
   -- ✅ Good: Uses chunk exclusion
   SELECT * FROM ohlcv_data 
   WHERE symbol = 'BTCUSDT' 
     AND timeframe = '1h'
     AND time >= NOW() - INTERVAL '7 days';
   
   -- ❌ Bad: Scans all chunks
   SELECT * FROM ohlcv_data 
   WHERE symbol = 'BTCUSDT';
   ```

2. **Use time_bucket for aggregations**:
   ```sql
   -- ✅ Good: Uses continuous aggregate if available
   SELECT time_bucket('1 day', time) as day, AVG(close)
   FROM ohlcv_data
   WHERE symbol = 'BTCUSDT' AND timeframe = '1h'
   GROUP BY day;
   ```

3. **Limit result sets**:
   ```sql
   -- ✅ Good: Limits data transfer
   SELECT * FROM trades 
   WHERE account_id = 1 
   ORDER BY time DESC 
   LIMIT 100;
   ```

4. **Use appropriate timeframes**:
   ```sql
   -- ✅ Good: Use daily data for long-term analysis
   SELECT * FROM ohlcv_data 
   WHERE timeframe = '1d' AND time >= '2020-01-01';
   
   -- ❌ Bad: Using minute data for years
   SELECT * FROM ohlcv_data 
   WHERE timeframe = '1m' AND time >= '2020-01-01';
   ```

### Query Performance Monitoring

```sql
-- Enable query logging for slow queries
ALTER DATABASE fks_trading SET log_min_duration_statement = 1000; -- Log queries > 1s

-- Check query plans
EXPLAIN ANALYZE
SELECT * FROM ohlcv_data 
WHERE symbol = 'BTCUSDT' 
  AND timeframe = '1h'
  AND time >= NOW() - INTERVAL '30 days';
```

### Connection Pooling

Configure SQLAlchemy connection pool:

```python
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=10,          # Number of connections to maintain
    max_overflow=20,      # Max connections beyond pool_size
    pool_pre_ping=True,   # Verify connections before use
    pool_recycle=3600     # Recycle connections after 1 hour
)
```

---

## Monitoring and Maintenance

### Chunk Management

```sql
-- View all chunks
SELECT * FROM timescaledb_information.chunks
WHERE hypertable_name = 'ohlcv_data'
ORDER BY range_start DESC;

-- View chunk sizes
SELECT 
    chunk_name,
    range_start,
    range_end,
    pg_size_pretty(total_bytes) as size
FROM timescaledb_information.chunks
WHERE hypertable_name = 'ohlcv_data'
ORDER BY range_start DESC;
```

### Compression Monitoring

```sql
-- Monitor compression effectiveness
SELECT 
    hypertable_name,
    number_compressed_chunks,
    before_compression_total_bytes,
    after_compression_total_bytes
FROM timescaledb_information.compressed_hypertable_stats;
```

### Retention Policy Status

```sql
-- View retention policies
SELECT * FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention';
```

---

## References

- [TimescaleDB Documentation](https://docs.timescale.com/)
- [PostgreSQL Indexing Best Practices](https://www.postgresql.org/docs/current/indexes.html)
- [SQLAlchemy Connection Pooling](https://docs.sqlalchemy.org/en/14/core/pooling.html)

