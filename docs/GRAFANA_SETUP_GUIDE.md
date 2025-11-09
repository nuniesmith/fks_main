# Grafana Dashboard Setup Guide - Path A

**Status**: ✅ Grafana Running on http://localhost:3000  
**Credentials**: admin / fks-grafana-admin-2025

---

## Quick Setup (5 Minutes)

### Step 1: Access Grafana

Port-forward is already running. Open in your browser:
```
http://localhost:3000
```

If needed, restart port-forward:
```bash
kubectl port-forward -n fks-trading svc/grafana 3000:3000
```

### Step 2: Login

- **Username**: `admin`
- **Password**: `fks-grafana-admin-2025`

### Step 3: Add Prometheus Datasource

1. Click the menu (☰) → **Connections** → **Data sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
   - **Access**: `Server (default)`
5. Scroll down and click **Save & test**
6. Should see: ✅ "Successfully queried the Prometheus API"

### Step 4: Import Execution Pipeline Dashboard

**Option A: Via UI**
1. Click menu (☰) → **Dashboards** → **Import**
2. Click **Upload JSON file**
3. Select: `/home/jordan/fks/monitoring/grafana/dashboards/execution_pipeline.json`
4. Select **Prometheus** as datasource
5. Click **Import**

**Option B: Via Command Line**
```bash
# Copy dashboard JSON content
cat /home/jordan/fks/monitoring/grafana/dashboards/execution_pipeline.json

# In Grafana:
# 1. Go to Dashboards → Import
# 2. Paste the JSON
# 3. Click Load → Import
```

---

## Dashboard Panels (16 Total)

### Row 1: Overview
- **Request Rate**: Webhooks per second
- **Success Rate**: % of successful webhooks
- **Active Requests**: Currently processing
- **P95 Latency**: 95th percentile response time

### Row 2: Webhooks
- **Processing Duration**: Histogram of webhook handling time
- **Validation Failures**: Failed payload validations
- **Signature Failures**: HMAC signature mismatches

### Row 3: Orders
- **Execution Duration**: Order placement latency
- **Failure Rate**: % of failed orders
- **Order Size Distribution**: Histogram of order sizes

### Row 4: Security
- **Rate-Limited IPs**: IPs hitting rate limits
- **Circuit Breaker State**: CLOSED/OPEN/HALF_OPEN status
- **Audit Events**: Security-related events

### Row 5: Exchange Health
- **API Latency**: Exchange API response time
- **Error Rate**: Exchange API failures
- **Active Connections**: Connection pool status

---

## Test the Dashboard

Send test webhooks to populate metrics:

```bash
# Send 20 webhooks
for i in {1..20}; do
  curl -X POST http://localhost:8000/webhook/tradingview \
    -H "Content-Type: application/json" \
    -d "{\"symbol\":\"BTCUSDT\",\"side\":\"buy\",\"confidence\":0.$((70 + RANDOM % 30))}"
  echo "Sent webhook $i"
  sleep 1
done
```

After sending webhooks:
1. Go to the **Execution Pipeline** dashboard
2. Set time range to **Last 5 minutes**
3. Click **Refresh** icon (↻)
4. You should see:
   - Request rate graph showing spikes
   - Success rate at ~100%
   - Processing duration < 100ms
   - Order executions tracked

---

## Troubleshooting

### Dashboard shows "No data"
**Solution**: 
- Check time range (top-right corner) - set to "Last 15 minutes"
- Verify Prometheus datasource is working (Settings → Data sources → Test)
- Send test webhooks (see above)
- Check Prometheus targets: http://localhost:9090/targets

### Datasource test fails
**Solution**:
- URL must be `http://prometheus:9090` (internal K8s DNS)
- Access: Server (not Browser)
- Port-forward Prometheus to test: `kubectl port-forward -n fks-trading svc/prometheus 9090:9090`

### Can't login to Grafana
**Solution**:
```bash
# Get password from K8s secret
kubectl get secret fks-secrets -n fks-trading \
  -o jsonpath='{.data.grafana-admin-password}' | base64 -d
```

### Port-forward dies
**Solution**:
```bash
# Check if still running
ps aux | grep "port-forward.*grafana"

# Restart if needed
pkill -f "port-forward.*grafana"
kubectl port-forward -n fks-trading svc/grafana 3000:3000 &
```

---

## Advanced: Custom Panels

### Add Webhook Success Rate Panel
1. Click **Add** → **Visualization**
2. Select **Prometheus** datasource
3. Query:
   ```promql
   rate(webhook_requests_total{status="success"}[5m]) / 
   rate(webhook_requests_total[5m]) * 100
   ```
4. Panel options:
   - **Title**: Webhook Success Rate
   - **Unit**: percent (0-100)
   - **Thresholds**: Red < 95, Yellow 95-99, Green ≥ 99
5. Click **Apply**

### Add Live Webhook Count
1. Add Visualization → Stat
2. Query:
   ```promql
   increase(webhook_requests_total[1m])
   ```
3. Title: Webhooks (Last Minute)
4. Apply

---

## Next Steps After Setup

1. **Customize Time Range**: Set to "Last 30 minutes" for live monitoring
2. **Enable Auto-Refresh**: Click refresh icon → Set to "5s" or "10s"
3. **Create Alerts**: 
   - Dashboard → Panel → Alert → Create alert rule
   - Example: Alert if webhook success rate < 95%
4. **Star Dashboard**: Click ★ to add to favorites
5. **Share Dashboard**: Click Share icon → Copy link

---

## Alternative Dashboards Available

Also available to import:
- `/monitoring/grafana/dashboards/quality_monitoring.json` - Data quality metrics
- `/monitoring/grafana/dashboards/asmbtr.json` - ASMBTR strategy metrics

---

## Quick Reference

**Grafana URL**: http://localhost:3000  
**Login**: admin / fks-grafana-admin-2025  
**Prometheus URL**: http://prometheus:9090 (internal)  
**Dashboard File**: `/home/jordan/fks/monitoring/grafana/dashboards/execution_pipeline.json`

**Port Forwards**:
```bash
kubectl port-forward -n fks-trading svc/grafana 3000:3000 &
kubectl port-forward -n fks-trading svc/prometheus 9090:9090 &
kubectl port-forward -n fks-trading svc/fks-execution 8000:8000 &
```

**Send Test Webhook**:
```bash
curl -X POST http://localhost:8000/webhook/tradingview \
  -H "Content-Type: application/json" \
  -d '{"symbol":"BTCUSDT","side":"buy","confidence":0.85}'
```

---

**Path A Complete**: ✅ Dashboard ready for visualization  
**Next**: Send webhooks and watch metrics flow in real-time!
