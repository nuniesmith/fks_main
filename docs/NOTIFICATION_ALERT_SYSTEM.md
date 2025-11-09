# FKS Notification and Alert System Documentation

## Overview

The FKS Notification and Alert System provides multi-channel alerting for trading events, risk warnings, system errors, and daily reports. It supports Discord, email, SMS, push notifications, and webhooks with user-configurable preferences and alert aggregation to prevent alert fatigue.

**Key Principle**: Users should receive timely, relevant alerts without being overwhelmed. The system prioritizes critical alerts and batches non-critical notifications.

## Table of Contents

1. [Alert Types](#alert-types)
2. [Delivery Channels](#delivery-channels)
3. [Alert Prioritization](#alert-prioritization)
4. [User Preferences](#user-preferences)
5. [Alert Aggregation](#alert-aggregation)
6. [Implementation](#implementation)
7. [Configuration](#configuration)

---

## Alert Types

FKS generates alerts for various trading and system events.

### Trading Alerts

#### 1. Trade Execution Alerts

**Trigger**: When an order is executed (filled).

**Alert Content**:
```json
{
  "type": "trade_execution",
  "severity": "info",
  "account_id": 1,
  "symbol": "BTCUSDT",
  "side": "buy",
  "quantity": 0.01,
  "price": 50000.0,
  "order_id": "order_123",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Message Format**:
```
✅ Trade Executed
Symbol: BTCUSDT
Side: BUY
Quantity: 0.01 BTC
Price: $50,000.00
Order ID: order_123
```

#### 2. Stop-Loss Triggered Alerts

**Trigger**: When a stop-loss order is executed.

**Alert Content**:
```json
{
  "type": "stop_loss_triggered",
  "severity": "warning",
  "account_id": 1,
  "position_id": 456,
  "symbol": "BTCUSDT",
  "realized_pnl": -100.0,
  "trigger_price": 48000.0,
  "timestamp": "2024-01-01T12:05:00Z"
}
```

**Message Format**:
```
🛑 Stop-Loss Triggered
Symbol: BTCUSDT
Loss: -$100.00
Trigger Price: $48,000.00
Position ID: 456
```

#### 3. Take-Profit Triggered Alerts

**Trigger**: When a take-profit order is executed.

**Alert Content**:
```json
{
  "type": "take_profit_triggered",
  "severity": "info",
  "account_id": 1,
  "position_id": 456,
  "symbol": "BTCUSDT",
  "realized_pnl": 200.0,
  "trigger_price": 52000.0,
  "timestamp": "2024-01-01T12:10:00Z"
}
```

**Message Format**:
```
🎯 Take-Profit Triggered
Symbol: BTCUSDT
Profit: +$200.00
Trigger Price: $52,000.00
Position ID: 456
```

#### 4. Order Rejected Alerts

**Trigger**: When an order is rejected by the exchange.

**Alert Content**:
```json
{
  "type": "order_rejected",
  "severity": "warning",
  "account_id": 1,
  "order_id": "order_123",
  "symbol": "BTCUSDT",
  "reason": "INSUFFICIENT_BALANCE",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Risk Management Alerts

#### 5. Daily Loss Limit Alerts

**Trigger**: When daily loss approaches or exceeds limits.

**Alert Content**:
```json
{
  "type": "daily_loss_limit",
  "severity": "critical",
  "account_id": 1,
  "daily_pnl": -200.0,
  "daily_pnl_pct": -0.02,
  "limit_type": "hard",  // "soft" or "hard"
  "timestamp": "2024-01-01T15:00:00Z"
}
```

**Message Format**:
```
⚠️ Daily Loss Limit Exceeded
Daily P&L: -$200.00 (-2.00%)
Limit Type: HARD STOP
Trading has been halted.
```

#### 6. Position Limit Alerts

**Trigger**: When position size approaches limits.

**Alert Content**:
```json
{
  "type": "position_limit_warning",
  "severity": "warning",
  "account_id": 1,
  "symbol": "BTCUSDT",
  "current_exposure_pct": 0.18,
  "max_exposure_pct": 0.20,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 7. Margin Call Alerts

**Trigger**: When margin falls below maintenance margin.

**Alert Content**:
```json
{
  "type": "margin_call",
  "severity": "critical",
  "account_id": 1,
  "margin_ratio": 0.04,
  "required_margin": 1000.0,
  "available_margin": 400.0,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Message Format**:
```
🚨 MARGIN CALL
Margin Ratio: 4%
Required: $1,000.00
Available: $400.00
Please add funds or close positions.
```

#### 8. Circuit Breaker Alerts

**Trigger**: When trading circuit breaker is activated.

**Alert Content**:
```json
{
  "type": "circuit_breaker",
  "severity": "critical",
  "account_id": 1,
  "reason": "daily_loss_threshold",
  "daily_loss_pct": -0.025,
  "trading_halted": true,
  "timestamp": "2024-01-01T15:30:00Z"
}
```

### System Alerts

#### 9. Exchange Connection Failure

**Trigger**: When exchange API connection fails.

**Alert Content**:
```json
{
  "type": "exchange_failure",
  "severity": "critical",
  "exchange": "binance",
  "error": "Connection timeout",
  "retry_count": 3,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 10. Data Quality Alerts

**Trigger**: When data quality checks fail.

**Alert Content**:
```json
{
  "type": "data_quality",
  "severity": "warning",
  "symbol": "BTCUSDT",
  "issue": "stale_data",
  "last_update": "2024-01-01T11:50:00Z",
  "threshold_minutes": 5,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 11. API Rate Limit Alerts

**Trigger**: When API rate limits are approached.

**Alert Content**:
```json
{
  "type": "rate_limit_warning",
  "severity": "warning",
  "provider": "polygon",
  "usage_pct": 0.85,
  "limit": 5,
  "window": "per_minute",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Reporting Alerts

#### 12. Daily Trading Reports

**Trigger**: End of trading day summary.

**Alert Content**:
```json
{
  "type": "daily_report",
  "severity": "info",
  "account_id": 1,
  "date": "2024-01-01",
  "metrics": {
    "total_trades": 5,
    "winning_trades": 3,
    "losing_trades": 2,
    "total_pnl": 150.0,
    "total_pnl_pct": 0.015,
    "sharpe_ratio": 1.2,
    "max_drawdown_pct": 0.01
  },
  "timestamp": "2024-01-01T23:59:59Z"
}
```

**Message Format**:
```
📊 Daily Trading Report - 2024-01-01
Trades: 5 (3W / 2L)
P&L: +$150.00 (+1.50%)
Sharpe Ratio: 1.20
Max Drawdown: 1.00%
```

---

## Delivery Channels

FKS supports multiple notification delivery channels.

### 1. Discord Webhooks

**Use Case**: Real-time alerts for traders, team notifications.

**Implementation**:
```python
import requests
from typing import Dict, Optional

class DiscordNotifier:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url
    
    async def send_alert(
        self,
        alert_type: str,
        severity: str,
        message: str,
        embed_data: Optional[Dict] = None
    ) -> bool:
        """Send alert to Discord webhook"""
        # Color mapping
        color_map = {
            "critical": 15158332,  # Red
            "warning": 16776960,   # Yellow
            "info": 3066993,        # Green
            "success": 3066993      # Green
        }
        
        payload = {
            "content": message,
            "embeds": []
        }
        
        if embed_data:
            embed = {
                "title": embed_data.get("title", alert_type.replace("_", " ").title()),
                "description": embed_data.get("description", ""),
                "color": color_map.get(severity, 8421504),  # Gray default
                "fields": embed_data.get("fields", []),
                "timestamp": embed_data.get("timestamp"),
                "footer": {
                    "text": f"FKS Trading Platform"
                }
            }
            payload["embeds"].append(embed)
        
        try:
            response = requests.post(
                self.webhook_url,
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"Discord notification failed: {e}")
            return False
    
    async def send_trade_alert(self, trade_data: Dict):
        """Send trade execution alert"""
        message = f"✅ Trade Executed: {trade_data['symbol']}"
        embed = {
            "title": "Trade Execution",
            "fields": [
                {"name": "Symbol", "value": trade_data['symbol'], "inline": True},
                {"name": "Side", "value": trade_data['side'].upper(), "inline": True},
                {"name": "Quantity", "value": str(trade_data['quantity']), "inline": True},
                {"name": "Price", "value": f"${trade_data['price']:,.2f}", "inline": True},
                {"name": "Order ID", "value": trade_data['order_id'], "inline": False}
            ],
            "timestamp": trade_data['timestamp']
        }
        return await self.send_alert("trade_execution", "info", message, embed)
```

**Webhook Setup**:
1. Create Discord webhook in server settings
2. Store webhook URL in environment variable: `DISCORD_WEBHOOK_URL`
3. Configure in user profile for personal alerts

### 2. Email Notifications

**Use Case**: Important alerts, daily reports, compliance notifications.

**Implementation**:
```python
from django.core.mail import send_mail
from django.template.loader import render_to_string
from celery import shared_task

class EmailNotifier:
    def __init__(self):
        self.from_email = settings.DEFAULT_FROM_EMAIL
    
    @shared_task
    async def send_email_alert(
        self,
        user_id: int,
        subject: str,
        template: str,
        context: Dict
    ) -> bool:
        """Send email alert"""
        user = await get_user(user_id)
        
        # Check user preferences
        profile = user.profile
        if not profile.email_notifications:
            return False
        
        # Render email template
        html_message = render_to_string(f"emails/{template}.html", context)
        text_message = render_to_string(f"emails/{template}.txt", context)
        
        try:
            send_mail(
                subject=subject,
                message=text_message,
                from_email=self.from_email,
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False
            )
            return True
        except Exception as e:
            logger.error(f"Email notification failed: {e}")
            return False
    
    async def send_daily_report(self, user_id: int, report_data: Dict):
        """Send daily trading report via email"""
        subject = f"Daily Trading Report - {report_data['date']}"
        context = {
            "user": await get_user(user_id),
            "report": report_data,
            "metrics": report_data['metrics']
        }
        return await self.send_email_alert(
            user_id,
            subject,
            "daily_report",
            context
        )
```

**Email Templates**:

`templates/emails/daily_report.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .header { background: #2c3e50; color: white; padding: 20px; }
        .content { padding: 20px; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #ecf0f1; }
        .positive { color: #27ae60; }
        .negative { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Daily Trading Report</h1>
        <p>Date: {{ report.date }}</p>
    </div>
    <div class="content">
        <h2>Performance Summary</h2>
        <div class="metric">
            <strong>Total P&L:</strong>
            <span class="{% if metrics.total_pnl >= 0 %}positive{% else %}negative{% endif %}">
                ${{ metrics.total_pnl|floatformat:2 }}
            </span>
        </div>
        <div class="metric">
            <strong>Trades:</strong> {{ metrics.total_trades }}
        </div>
        <div class="metric">
            <strong>Win Rate:</strong> {{ metrics.win_rate|floatformat:1 }}%
        </div>
    </div>
</body>
</html>
```

### 3. SMS Notifications

**Use Case**: Critical alerts only (stop-loss, margin call, circuit breaker).

**Implementation**:
```python
import boto3
from typing import Optional

class SMSNotifier:
    def __init__(self, aws_region: str = "us-east-1"):
        self.sns_client = boto3.client('sns', region_name=aws_region)
    
    async def send_sms(
        self,
        phone_number: str,
        message: str
    ) -> bool:
        """Send SMS via AWS SNS"""
        try:
            response = self.sns_client.publish(
                PhoneNumber=phone_number,
                Message=message,
                MessageAttributes={
                    'AWS.SNS.SMS.SMSType': {
                        'DataType': 'String',
                        'StringValue': 'Transactional'
                    }
                }
            )
            return response['MessageId'] is not None
        except Exception as e:
            logger.error(f"SMS notification failed: {e}")
            return False
    
    async def send_critical_alert(
        self,
        user_id: int,
        alert_type: str,
        message: str
    ) -> bool:
        """Send critical alert via SMS"""
        user = await get_user(user_id)
        profile = user.profile
        
        # Check if user has SMS enabled and phone number
        if not profile.sms_notifications or not profile.phone_number:
            return False
        
        # Format message (SMS has 160 char limit)
        sms_message = f"FKS Alert: {alert_type}\n{message[:120]}"
        
        return await self.send_sms(profile.phone_number, sms_message)
```

### 4. Push Notifications

**Use Case**: Mobile app notifications for real-time alerts.

**Implementation**:
```python
from firebase_admin import messaging
import firebase_admin

class PushNotifier:
    def __init__(self):
        if not firebase_admin._apps:
            firebase_admin.initialize_app()
    
    async def send_push_notification(
        self,
        user_id: int,
        title: str,
        body: str,
        data: Optional[Dict] = None
    ) -> bool:
        """Send push notification via FCM"""
        user = await get_user(user_id)
        profile = user.profile
        
        # Get user's FCM tokens
        fcm_tokens = await get_user_fcm_tokens(user_id)
        if not fcm_tokens:
            return False
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data or {},
            tokens=fcm_tokens
        )
        
        try:
            response = messaging.send_multicast(message)
            # Remove invalid tokens
            if response.failure_count > 0:
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        await remove_fcm_token(fcm_tokens[idx])
            
            return response.success_count > 0
        except Exception as e:
            logger.error(f"Push notification failed: {e}")
            return False
```

### 5. Webhook Notifications

**Use Case**: Integration with external systems (Zapier, custom bots).

**Implementation**:
```python
import requests
import hmac
import hashlib
import json

class WebhookNotifier:
    def __init__(self, webhook_url: str, secret: Optional[str] = None):
        self.webhook_url = webhook_url
        self.secret = secret
    
    async def send_webhook(
        self,
        payload: Dict,
        event_type: str
    ) -> bool:
        """Send webhook notification"""
        # Add event metadata
        payload['event_type'] = event_type
        payload['timestamp'] = datetime.utcnow().isoformat()
        
        # Sign payload if secret provided
        headers = {'Content-Type': 'application/json'}
        if self.secret:
            signature = self._sign_payload(payload)
            headers['X-FKS-Signature'] = signature
        
        try:
            response = requests.post(
                self.webhook_url,
                json=payload,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"Webhook notification failed: {e}")
            return False
    
    def _sign_payload(self, payload: Dict) -> str:
        """Generate HMAC signature for webhook"""
        payload_str = json.dumps(payload, sort_keys=True)
        signature = hmac.new(
            self.secret.encode(),
            payload_str.encode(),
            hashlib.sha256
        ).hexdigest()
        return signature
```

---

## Alert Prioritization

Alerts are prioritized by severity and routed accordingly.

### Severity Levels

```python
from enum import Enum

class AlertSeverity(Enum):
    CRITICAL = "critical"  # Immediate action required
    WARNING = "warning"   # Attention needed
    INFO = "info"         # Informational
    SUCCESS = "success"   # Positive events
```

### Routing Rules

```python
class AlertRouter:
    def __init__(self):
        self.routing_rules = {
            "critical": {
                "channels": ["discord", "email", "sms", "push"],
                "immediate": True,
                "batch": False
            },
            "warning": {
                "channels": ["discord", "email"],
                "immediate": False,
                "batch": True,
                "batch_window": 300  # 5 minutes
            },
            "info": {
                "channels": ["discord", "email"],
                "immediate": False,
                "batch": True,
                "batch_window": 3600  # 1 hour
            },
            "success": {
                "channels": ["discord"],
                "immediate": False,
                "batch": True,
                "batch_window": 1800  # 30 minutes
            }
        }
    
    async def route_alert(
        self,
        alert: Dict,
        user_id: int
    ):
        """Route alert to appropriate channels based on severity"""
        severity = alert.get("severity", "info")
        rules = self.routing_rules.get(severity, self.routing_rules["info"])
        
        user_preferences = await get_user_notification_preferences(user_id)
        
        # Determine channels based on rules and user preferences
        channels = []
        for channel in rules["channels"]:
            if user_preferences.get(f"{channel}_notifications", True):
                channels.append(channel)
        
        # Send immediately or queue for batching
        if rules["immediate"]:
            await self.send_immediate(alert, user_id, channels)
        else:
            await self.queue_for_batching(alert, user_id, channels, rules["batch_window"])
```

### Alert Inhibition

**Prevent Duplicate Alerts**: Don't send warning if critical is already firing.

```python
class AlertInhibitor:
    def __init__(self):
        self.active_alerts: Dict[str, List[Dict]] = {}  # symbol -> alerts
    
    async def should_send_alert(
        self,
        alert: Dict
    ) -> bool:
        """Check if alert should be sent (not inhibited)"""
        symbol = alert.get("symbol")
        severity = alert.get("severity")
        alert_type = alert.get("type")
        
        if not symbol:
            return True  # Non-symbol alerts always sent
        
        # Check for higher severity alerts
        active_critical = [
            a for a in self.active_alerts.get(symbol, [])
            if a.get("severity") == "critical"
        ]
        
        # Inhibit warning if critical exists
        if severity == "warning" and active_critical:
            # Check if same alert type
            for critical_alert in active_critical:
                if critical_alert.get("type") == alert_type:
                    return False  # Inhibited
        
        # Track active alert
        if symbol not in self.active_alerts:
            self.active_alerts[symbol] = []
        self.active_alerts[symbol].append(alert)
        
        return True
    
    async def clear_alert(self, alert_id: str, symbol: str):
        """Clear alert from active list"""
        if symbol in self.active_alerts:
            self.active_alerts[symbol] = [
                a for a in self.active_alerts[symbol]
                if a.get("id") != alert_id
            ]
```

---

## User Preferences

Users can customize which alerts they receive and via which channels.

### Database Schema

```sql
CREATE TABLE notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    alert_type VARCHAR(50) NOT NULL,  -- 'trade_execution', 'stop_loss', etc.
    channel VARCHAR(20) NOT NULL,  -- 'discord', 'email', 'sms', 'push'
    enabled BOOLEAN DEFAULT true,
    severity_filter VARCHAR(20),  -- 'critical_only', 'warning_and_above', 'all'
    frequency_limit INTEGER,  -- Max alerts per hour for this type
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, alert_type, channel)
);

CREATE INDEX idx_notification_prefs_user ON notification_preferences(user_id);
```

### User Preference Model

```python
class NotificationPreference(models.Model):
    """User notification preferences"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    alert_type = models.CharField(max_length=50)
    channel = models.CharField(max_length=20)
    enabled = models.BooleanField(default=True)
    severity_filter = models.CharField(
        max_length=20,
        choices=[
            ("critical_only", "Critical Only"),
            ("warning_and_above", "Warning and Above"),
            ("all", "All Alerts")
        ],
        default="all"
    )
    frequency_limit = models.IntegerField(null=True)  # Max per hour
    
    class Meta:
        unique_together = [['user', 'alert_type', 'channel']]
    
    def should_send(self, alert_severity: str) -> bool:
        """Check if alert should be sent based on preferences"""
        if not self.enabled:
            return False
        
        severity_order = {"critical": 3, "warning": 2, "info": 1, "success": 0}
        
        if self.severity_filter == "critical_only":
            return alert_severity == "critical"
        elif self.severity_filter == "warning_and_above":
            return severity_order.get(alert_severity, 0) >= 2
        else:  # all
            return True
```

### Preference Management API

```python
@router.post("/notifications/preferences")
async def update_preferences(
    request: Request,
    preferences: List[Dict],
    user: User = Depends(get_current_user)
):
    """Update user notification preferences"""
    for pref_data in preferences:
        NotificationPreference.objects.update_or_create(
            user=user,
            alert_type=pref_data['alert_type'],
            channel=pref_data['channel'],
            defaults={
                'enabled': pref_data.get('enabled', True),
                'severity_filter': pref_data.get('severity_filter', 'all'),
                'frequency_limit': pref_data.get('frequency_limit')
            }
        )
    
    return {"success": True}

@router.get("/notifications/preferences")
async def get_preferences(
    user: User = Depends(get_current_user)
):
    """Get user notification preferences"""
    preferences = NotificationPreference.objects.filter(user=user)
    return {
        "preferences": [
            {
                "alert_type": p.alert_type,
                "channel": p.channel,
                "enabled": p.enabled,
                "severity_filter": p.severity_filter,
                "frequency_limit": p.frequency_limit
            }
            for p in preferences
        ]
    }
```

---

## Alert Aggregation

Prevent alert fatigue by batching and rate limiting.

### Batching Strategy

```python
from collections import defaultdict
from datetime import datetime, timedelta

class AlertBatcher:
    def __init__(self, batch_window: int = 300):  # 5 minutes
        self.batch_window = batch_window
        self.batches: Dict[str, List[Dict]] = defaultdict(list)
        self.last_sent: Dict[str, datetime] = {}
    
    async def add_alert(
        self,
        alert: Dict,
        user_id: int,
        channel: str
    ):
        """Add alert to batch"""
        batch_key = f"{user_id}:{channel}:{alert['type']}"
        
        self.batches[batch_key].append(alert)
        
        # Check if should send batch
        last_sent_time = self.last_sent.get(batch_key)
        now = datetime.utcnow()
        
        if not last_sent_time or (now - last_sent_time).total_seconds() >= self.batch_window:
            await self.send_batch(batch_key, user_id, channel)
    
    async def send_batch(
        self,
        batch_key: str,
        user_id: int,
        channel: str
    ):
        """Send batched alerts"""
        alerts = self.batches[batch_key]
        if not alerts:
            return
        
        # Group by type
        grouped = defaultdict(list)
        for alert in alerts:
            grouped[alert['type']].append(alert)
        
        # Create summary message
        summary = self.create_summary(grouped)
        
        # Send via appropriate channel
        notifier = get_notifier(channel)
        await notifier.send_batch(user_id, summary, alerts)
        
        # Clear batch
        self.batches[batch_key] = []
        self.last_sent[batch_key] = datetime.utcnow()
    
    def create_summary(self, grouped_alerts: Dict) -> str:
        """Create summary message from batched alerts"""
        lines = ["📊 **Alert Summary**\n"]
        
        for alert_type, alerts in grouped_alerts.items():
            count = len(alerts)
            alert_type_name = alert_type.replace("_", " ").title()
            lines.append(f"**{alert_type_name}**: {count} alert(s)")
        
        return "\n".join(lines)
```

### Rate Limiting

```python
from collections import deque
import time

class AlertRateLimiter:
    def __init__(
        self,
        max_alerts_per_hour: int = 100,
        max_alerts_per_minute: int = 10
    ):
        self.max_per_hour = max_alerts_per_hour
        self.max_per_minute = max_alerts_per_minute
        self.user_alerts: Dict[int, deque] = {}  # user_id -> timestamps
    
    def can_send_alert(self, user_id: int) -> bool:
        """Check if alert can be sent (rate limit not exceeded)"""
        now = time.time()
        
        if user_id not in self.user_alerts:
            self.user_alerts[user_id] = deque()
        
        alerts = self.user_alerts[user_id]
        
        # Remove old alerts (older than 1 hour)
        while alerts and alerts[0] < now - 3600:
            alerts.popleft()
        
        # Check hourly limit
        if len(alerts) >= self.max_per_hour:
            return False
        
        # Check minute limit (last 60 seconds)
        recent_alerts = [a for a in alerts if a > now - 60]
        if len(recent_alerts) >= self.max_per_minute:
            return False
        
        # Record alert
        alerts.append(now)
        return True
```

---

## Implementation

### Notification Service

**Centralized Notification Service**:

```python
from celery import shared_task
from typing import List, Dict, Optional

class NotificationService:
    def __init__(self):
        self.discord = DiscordNotifier(os.getenv("DISCORD_WEBHOOK_URL"))
        self.email = EmailNotifier()
        self.sms = SMSNotifier()
        self.push = PushNotifier()
        self.webhook = None  # User-specific webhooks
        self.router = AlertRouter()
        self.batcher = AlertBatcher()
        self.rate_limiter = AlertRateLimiter()
        self.inhibitor = AlertInhibitor()
    
    @shared_task
    async def send_notification(
        self,
        user_id: int,
        alert_type: str,
        severity: str,
        message: str,
        data: Optional[Dict] = None
    ):
        """Send notification via all enabled channels"""
        alert = {
            "id": str(uuid.uuid4()),
            "type": alert_type,
            "severity": severity,
            "message": message,
            "data": data or {},
            "timestamp": datetime.utcnow().isoformat(),
            "user_id": user_id
        }
        
        # Check inhibition
        if not await self.inhibitor.should_send_alert(alert):
            logger.info(f"Alert {alert['id']} inhibited")
            return
        
        # Check rate limits
        if not self.rate_limiter.can_send_alert(user_id):
            logger.warning(f"Rate limit exceeded for user {user_id}")
            return
        
        # Get user preferences
        user_prefs = await get_user_notification_preferences(user_id)
        
        # Route to channels
        channels = await self.router.route_alert(alert, user_id)
        
        # Send via each channel
        for channel in channels:
            preference = user_prefs.get(f"{alert_type}:{channel}")
            
            if preference and preference.should_send(severity):
                if preference.frequency_limit:
                    # Check frequency limit
                    recent_count = await count_recent_alerts(
                        user_id, alert_type, channel, hours=1
                    )
                    if recent_count >= preference.frequency_limit:
                        continue  # Skip this channel
                
                # Send notification
                await self._send_via_channel(channel, user_id, alert)
    
    async def _send_via_channel(
        self,
        channel: str,
        user_id: int,
        alert: Dict
    ):
        """Send alert via specific channel"""
        if channel == "discord":
            user = await get_user(user_id)
            webhook_url = user.profile.discord_webhook
            if webhook_url:
                notifier = DiscordNotifier(webhook_url)
                await notifier.send_alert(
                    alert['type'],
                    alert['severity'],
                    alert['message'],
                    alert.get('embed_data')
                )
        
        elif channel == "email":
            await self.email.send_email_alert(
                user_id,
                f"FKS Alert: {alert['type']}",
                f"alerts/{alert['type']}",
                alert['data']
            )
        
        elif channel == "sms":
            await self.sms.send_critical_alert(
                user_id,
                alert['type'],
                alert['message']
            )
        
        elif channel == "push":
            await self.push.send_push_notification(
                user_id,
                alert['type'].replace("_", " ").title(),
                alert['message'],
                alert['data']
            )
        
        elif channel == "webhook":
            user = await get_user(user_id)
            webhook_url = user.profile.webhook_url
            if webhook_url:
                notifier = WebhookNotifier(webhook_url)
                await notifier.send_webhook(alert['data'], alert['type'])
```

### Integration with Trading Events

```python
# In order execution service
async def on_order_filled(order_id: str, execution_result: Dict):
    """Send notification when order is filled"""
    await NotificationService.send_notification.delay(
        user_id=execution_result['account_id'],
        alert_type="trade_execution",
        severity="info",
        message=f"Trade executed: {execution_result['symbol']}",
        data={
            "order_id": order_id,
            "symbol": execution_result['symbol'],
            "side": execution_result['side'],
            "quantity": execution_result['filled_quantity'],
            "price": execution_result['average_price']
        }
    )

# In risk management service
async def on_stop_loss_triggered(position_id: int, pnl: float):
    """Send notification when stop-loss triggers"""
    position = await get_position(position_id)
    
    await NotificationService.send_notification.delay(
        user_id=position.account_id,
        alert_type="stop_loss_triggered",
        severity="warning",
        message=f"Stop-loss triggered: {position.symbol}",
        data={
            "position_id": position_id,
            "symbol": position.symbol,
            "realized_pnl": pnl,
            "trigger_price": position.stop_loss
        }
    )

# In daily report task
@shared_task
async def send_daily_reports():
    """Send daily reports to all users"""
    users = await get_all_active_users()
    
    for user in users:
        report = await generate_daily_report(user.id)
        
        await NotificationService.send_notification.delay(
            user_id=user.id,
            alert_type="daily_report",
            severity="info",
            message=f"Daily Trading Report - {report['date']}",
            data=report
        )
```

---

## Configuration

### Alert Configuration Schema

```sql
CREATE TABLE alert_config (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL UNIQUE,
    default_severity VARCHAR(20) NOT NULL,
    default_channels JSONB NOT NULL,  -- ['discord', 'email']
    batch_enabled BOOLEAN DEFAULT true,
    batch_window_seconds INTEGER DEFAULT 300,
    rate_limit_per_hour INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Default Alert Configuration

```python
DEFAULT_ALERT_CONFIG = {
    "trade_execution": {
        "default_severity": "info",
        "default_channels": ["discord"],
        "batch_enabled": True,
        "batch_window_seconds": 300
    },
    "stop_loss_triggered": {
        "default_severity": "warning",
        "default_channels": ["discord", "email"],
        "batch_enabled": False,
        "rate_limit_per_hour": 50
    },
    "daily_loss_limit": {
        "default_severity": "critical",
        "default_channels": ["discord", "email", "sms", "push"],
        "batch_enabled": False,
        "rate_limit_per_hour": 10
    },
    "circuit_breaker": {
        "default_severity": "critical",
        "default_channels": ["discord", "email", "sms", "push"],
        "batch_enabled": False
    },
    "daily_report": {
        "default_severity": "info",
        "default_channels": ["email"],
        "batch_enabled": False
    }
}
```

---

## References

- [Discord Webhook API](https://discord.com/developers/docs/resources/webhook)
- [AWS SNS SMS](https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Prometheus Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)

