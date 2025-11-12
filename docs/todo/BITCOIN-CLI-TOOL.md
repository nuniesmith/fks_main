# Bitcoin Signal CLI Tool

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Command-line tool for generating, displaying, and managing Bitcoin signals for daily manual trading

---

## 📋 Overview

The Bitcoin Signal CLI Tool (`bitcoin-signal-cli.py`) provides a simple command-line interface for:
- Generating Bitcoin trading signals
- Displaying signals with detailed information
- Approving or rejecting signals
- Interactive mode for daily trading workflow
- Saving approved/rejected signals to files

---

## 🚀 Installation

### Prerequisites
- Python 3.7 or higher
- `requests` library
- Docker services running (`fks_data`, `fks_app`)

### Install Dependencies
```bash
pip install requests
```

---

## 📖 Usage

### Basic Usage

**Generate a signal:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT
```

**Generate with detailed information:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed
```

**Generate with specific category:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --category swing
```

**Generate with AI enhancement:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --use-ai
```

**Generate with specific strategy:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --strategy rsi
```

**Output as JSON:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --json
```

### Interactive Mode

**Start interactive mode:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

**Interactive mode workflow:**
1. Generate signal
2. Display signal with detailed information
3. Choose action:
   - `a` - Approve signal (saves to file)
   - `r` - Reject signal (logs rejection)
   - `n` - Generate new signal
   - `q` - Quit

### Auto-Approve/Reject

**Auto-approve signal:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
```

**Auto-reject signal:**
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --reject
```

---

## 📊 Signal Output

### Basic Signal Display
```
Symbol: BTCUSDT
Signal: BUY
Category: swing
Entry Price: $103,149.40
Take Profit: $106,759.63 (3.50%)
Stop Loss: $101,086.41 (-2.00%)
Confidence: 50.93%
Rationale: RSI oversold (29.54 < 30.0) - Buy signal
Timestamp: 2025-11-12T04:54:36.533017
```

### Detailed Signal Display
```
Symbol: BTCUSDT
Signal: BUY
Category: swing
Entry Price: $103,149.40
Take Profit: $106,759.63 (3.50%)
Stop Loss: $101,086.41 (-2.00%)
Confidence: 50.93%
Rationale: RSI oversold (29.54 < 30.0) - Buy signal
Timestamp: 2025-11-12T04:54:36.533017

Position Sizing:
  Position Size: 75.00% of portfolio
  Position Size: $7,500.00 USD
  Position Size: 0.072738 units
  Risk Amount: $150.00 (1.50% risk)
  Risk/Reward: 1.75

Indicators:
  RSI: 29.54

AI Enhanced: No
```

---

## 📁 File Output

### Approved Signals
Approved signals are saved to: `approved_signals_YYYYMMDD.json`

**Example:**
```json
[
  {
    "symbol": "BTCUSDT",
    "side": "BUY",
    "order_type": "MARKET",
    "quantity": 0.072738,
    "price": 103149.4,
    "stop_loss": 101086.41,
    "take_profit": 106759.63,
    "signal_id": "BTCUSDT_swing_1739265276",
    "category": "swing",
    "confidence": 0.5093,
    "strategy": "fks_app_pipeline",
    "timestamp": "2025-11-12T04:54:36.533017",
    "status": "approved"
  }
]
```

### Rejected Signals
Rejected signals are saved to: `rejected_signals_YYYYMMDD.json`

**Example:**
```json
[
  {
    "signal_id": "BTCUSDT_swing_1739265276",
    "symbol": "BTCUSDT",
    "category": "swing",
    "signal_type": "BUY",
    "entry_price": 103149.4,
    "confidence": 0.5093,
    "reason": "Manual rejection",
    "timestamp": "2025-11-12T04:54:36.533017",
    "status": "rejected"
  }
]
```

---

## 🔧 Command-Line Options

```
positional arguments:
  symbol                Trading symbol (default: BTCUSDT)

optional arguments:
  -h, --help            Show help message
  --category {scalp,swing,long_term}
                        Trade category (default: swing)
  --strategy STRATEGY   Strategy (rsi, macd, ema_scalp, ema_swing, asmbtr)
  --use-ai              Use AI enhancement
  --detailed            Show detailed signal information
  --approve             Approve signal automatically
  --reject              Reject signal automatically
  --interactive, -i     Interactive mode
  --json                Output as JSON
```

---

## 📝 Daily Workflow

### Morning Routine

1. **Generate Signal:**
   ```bash
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed
   ```

2. **Review Signal:**
   - Check entry price, take profit, stop loss
   - Review confidence and rationale
   - Check indicators (RSI, MACD, etc.)
   - Review position sizing

3. **Approve or Reject:**
   ```bash
   # Interactive mode
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
   
   # Or auto-approve
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
   ```

4. **Execute Trade:**
   - Use approved signal file to execute trade manually
   - Or send to execution service (if available)

### End of Day Review

1. **Review Approved Signals:**
   ```bash
   cat approved_signals_YYYYMMDD.json
   ```

2. **Review Rejected Signals:**
   ```bash
   cat rejected_signals_YYYYMMDD.json
   ```

3. **Analyze Performance:**
   - Compare signals to actual market movements
   - Review confidence vs. actual outcomes
   - Adjust strategy if needed

---

## 🔗 Integration

### Execution Service Integration
If `fks_execution` service is available, the CLI tool will attempt to send approved signals directly to the execution service. If the service is not available, signals are saved to a file for manual execution.

### Dashboard Integration
The CLI tool can be used alongside the dashboard for signal generation and approval. The dashboard provides a web interface, while the CLI tool provides a command-line interface.

---

## 🐛 Troubleshooting

### Error: ModuleNotFoundError: No module named 'requests'
**Solution:**
```bash
pip install requests
```

### Error: Failed to connect to signal service
**Solution:**
1. Check if `fks_app` service is running:
   ```bash
   docker ps | grep fks_app
   ```

2. Check service health:
   ```bash
   curl http://localhost:8002/health
   ```

3. Start services if needed:
   ```bash
   cd repo/app && docker-compose up -d
   ```

### Error: No signal generated
**Solution:**
1. Check if `fks_data` service is running:
   ```bash
   docker ps | grep fks_data
   ```

2. Check data service:
   ```bash
   curl http://localhost:8003/api/v1/data/price?symbol=BTCUSDT
   ```

3. Check signal service logs:
   ```bash
   docker logs fks_app
   ```

---

## 📚 Examples

### Example 1: Generate and Display Signal
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed
```

### Example 2: Interactive Mode
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
```

### Example 3: Auto-Approve Signal
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --approve
```

### Example 4: Generate with AI Enhancement
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --use-ai --detailed
```

### Example 5: Generate with Specific Strategy
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --strategy rsi --detailed
```

### Example 6: Output as JSON
```bash
python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --json > signal.json
```

---

## ✅ Success Criteria

### Minimum Viable Tool
- ✅ Generate signals via CLI
- ✅ Display signals with detailed information
- ✅ Approve/reject signals
- ✅ Save approved/rejected signals to files
- ✅ Interactive mode for daily workflow

### Production Ready
- ✅ Error handling
- ✅ Color-coded output
- ✅ JSON output support
- ✅ Integration with execution service
- ✅ File-based signal storage

---

## 🎯 Next Steps

1. **Install Dependencies:**
   ```bash
   pip install requests
   ```

2. **Test CLI Tool:**
   ```bash
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --detailed
   ```

3. **Use Interactive Mode:**
   ```bash
   python repo/main/scripts/bitcoin-signal-cli.py BTCUSDT --interactive
   ```

4. **Integrate into Daily Workflow:**
   - Add to morning routine
   - Use for signal generation and approval
   - Review approved/rejected signals at end of day

---

**Status**: ✅ **READY TO USE**

**Next Action**: Install dependencies and test the CLI tool

---

**Last Updated**: 2025-11-12

