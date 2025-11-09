# Tailscale + Kubernetes Integration - Complete Setup

**Created**: November 3, 2025  
**Status**: ✅ Ready to Deploy  
**Next**: Get Tailscale auth key and run setup script

---

## 🎯 What You Get

### Stable Tailscale IP for fkstrading.xyz
- **No LoadBalancer costs** (save $10-30/month)
- **Automatic DNS updates** (hourly via GitHub Actions)
- **Zero-trust security** (WireGuard encrypted)
- **Global access** (from anywhere on your Tailnet)

---

## 📦 Files Created

| File | Size | Purpose |
|------|------|---------|
| `k8s/tailscale-operator.yaml` | 3.3 KB | Tailscale connector deployment |
| `.github/workflows/update-dns.yml` | 4.9 KB | DNS automation workflow |
| `scripts/setup-tailscale.sh` | 2.4 KB | Automated setup script |
| `docs/TAILSCALE_SETUP.md` | 11 KB | Comprehensive guide |
| `docs/TAILSCALE_QUICKSTART.md` | 2.5 KB | Quick reference |
| `docs/TAILSCALE_K8S_SUMMARY.md` | 8.8 KB | This summary |

**Total**: 6 new files, ~33 KB

---

## 🚀 Quick Start (5 Minutes)

### 1. Get Tailscale Auth Key

Go to: https://login.tailscale.com/admin/settings/keys

Create auth key with:
- ✅ **Reusable**: Yes
- ✅ **Tags**: `tag:fks` (matches your existing ACLs)
- ✅ **Expiration**: Never (or your preference)

Copy key: `tskey-auth-xxxxx-xxxxxxxxxxxxxxxxx`

### 2. Deploy to Kubernetes

```bash
# Set your auth key
export TAILSCALE_AUTH_KEY="tskey-auth-xxxxx-xxxxxxxxxxxxxxxxx"

# Run automated setup (installs operator + connector)
./scripts/setup-tailscale.sh
```

**Expected output**:
```
🚀 FKS Trading Platform - Tailscale Setup
📦 Installing Tailscale Kubernetes Operator...
🔐 Creating Tailscale auth secret...
🔧 Configuring Tailscale connector...
🚀 Deploying Tailscale connector...
✅ Tailscale setup complete!
```

### 3. Verify Connection

```bash
# Check from local machine (requires Tailscale installed)
tailscale status | grep fks-trading

# Expected:
# fks-trading-k8s    100.x.x.x    linux   active; relay "xxx"
```

### 4. Get Tailscale IP

```bash
# Extract IP address
tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]'

# Example output: 100.64.123.45
```

### 5. Test Access

```bash
# Get IP
TS_IP=$(tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]')

# Test HTTP
curl http://$TS_IP/health/

# Test execution service
curl http://$TS_IP:8004/health
```

---

## 🤖 GitHub Actions DNS Automation

### Configure Secrets

Go to: https://github.com/nuniesmith/fks/settings/secrets/actions

Add 4 secrets:

| Secret | How to Get |
|--------|------------|
| `TS_OAUTH_CLIENT_ID` | https://login.tailscale.com/admin/settings/oauth → Create OAuth client → Scopes: devices:read, network:read |
| `TS_OAUTH_SECRET` | Same as above (copy secret) |
| `CLOUDFLARE_API_TOKEN` | https://dash.cloudflare.com/profile/api-tokens → Create Token → Template: "Edit zone DNS" → Zone: fkstrading.xyz |
| `CLOUDFLARE_ZONE_ID` | Cloudflare dashboard → fkstrading.xyz → Overview → Zone ID (right sidebar) |

### Enable Workflow

```bash
# Commit and push
git add .github/workflows/update-dns.yml k8s/tailscale-operator.yaml
git commit -m "Add Tailscale integration with DNS automation"
git push origin main

# Workflow will run on:
# - Push to main (any changes to these files)
# - Hourly (cron: '0 * * * *')
# - Manual trigger (Actions tab)
```

### Manual Trigger

1. Go to: https://github.com/nuniesmith/fks/actions
2. Select: **Update DNS with Tailscale IP**
3. Click: **Run workflow** → **Run workflow**
4. Monitor progress (~2-3 minutes)

---

## ✅ What the Workflow Does

1. **Connects** to Tailscale (using OAuth)
2. **Discovers** fks-trading-k8s IP (100.x.x.x)
3. **Updates** 7 DNS A records in Cloudflare:
   - fkstrading.xyz
   - api.fkstrading.xyz
   - app.fkstrading.xyz
   - data.fkstrading.xyz
   - execution.fkstrading.xyz
   - grafana.fkstrading.xyz
   - prometheus.fkstrading.xyz
4. **Verifies** DNS propagation
5. **Tests** HTTPS access

---

## 📊 Architecture

```
User Request (https://fkstrading.xyz)
    ↓
DNS Lookup via Cloudflare
    ↓ (Returns: 100.64.123.45 - Tailscale IP)
Tailscale Network (WireGuard tunnel)
    ↓
Tailscale Connector Pod (K8s fks-trading namespace)
    ↓
NGINX Ingress Controller (port 80/443)
    ↓
FKS Services
    ├─ fks-main (8000)
    ├─ fks-api (8001)
    ├─ fks-app (8002)
    ├─ fks-data (8003)
    ├─ fks-execution (8004)
    ├─ grafana (80)
    └─ prometheus (80)
```

---

## 🔐 Security Features

### Your Existing ACLs (tailscale.json)

Already configured for `tag:fks`:

```json
{
  "tagOwners": {
    "tag:fks": ["autogroup:admin", "group:automation"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:ci"],
      "dst": ["tag:fks:*"]
    },
    {
      "action": "accept",
      "src": ["group:member"],
      "dst": ["tag:fks:8000"]
    }
  ]
}
```

**Perfect!** The connector will inherit these rules.

### Additional Security

- ✅ **NET_ADMIN capability** (required for routing)
- ✅ **Kubernetes RBAC** (ServiceAccount with minimal permissions)
- ✅ **Secret storage** (auth key in K8s secret)
- ✅ **WireGuard encryption** (end-to-end)
- ✅ **Tag-based ACLs** (inherit from tailscale.json)

---

## 📋 Verification Checklist

- [ ] Tailscale auth key created
- [ ] Tailscale operator installed (`kubectl get pods -n tailscale`)
- [ ] Connector pod running (`kubectl get pods -n fks-trading -l app=tailscale-connector`)
- [ ] Connector appears in Tailscale admin console
- [ ] Local `tailscale status` shows fks-trading-k8s
- [ ] HTTP access works via Tailscale IP
- [ ] GitHub secrets configured (4 secrets)
- [ ] DNS workflow runs successfully
- [ ] All 7 domains resolve to Tailscale IP
- [ ] HTTPS works (after cert-manager setup)

---

## 🔍 Monitoring

### Check Connector Status

```bash
# Pod status
kubectl get pods -n fks-trading -l app=tailscale-connector

# Logs (real-time)
kubectl logs -n fks-trading -l app=tailscale-connector -f

# Tailscale connection details
kubectl exec -n fks-trading deployment/tailscale-connector -- tailscale status
```

### Monitor DNS Updates

```bash
# GitHub Actions history
# https://github.com/nuniesmith/fks/actions/workflows/update-dns.yml

# Check current DNS records
dig fkstrading.xyz +short
dig api.fkstrading.xyz +short
dig execution.fkstrading.xyz +short

# Should all return your Tailscale IP (100.x.x.x)
```

---

## 🛠️ Troubleshooting

### Connector Pod Not Starting

```bash
# Check logs
kubectl logs -n fks-trading -l app=tailscale-connector

# Common fixes:
# 1. Invalid auth key → create new key
# 2. Expired key → set expiration to "Never"
# 3. Wrong namespace → verify fks-trading namespace exists

# Re-create secret
kubectl delete secret tailscale-auth -n fks-trading
export TAILSCALE_AUTH_KEY="tskey-auth-NEW-KEY"
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY="$TAILSCALE_AUTH_KEY"

# Restart connector
kubectl rollout restart deployment/tailscale-connector -n fks-trading
```

### Not Showing in `tailscale status`

```bash
# Check Tailscale admin console
# https://login.tailscale.com/admin/machines

# Verify ACLs allow tag:fks (or tag:k8s)
# Update k8s/tailscale-operator.yaml if using different tag

# Check connector logs for auth errors
kubectl logs -n fks-trading -l app=tailscale-connector | grep -i error
```

### DNS Workflow Failing

```bash
# View workflow logs
# https://github.com/nuniesmith/fks/actions

# Verify secrets are set
gh secret list

# Test Cloudflare API manually
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_CLOUDFLARE_API_TOKEN"

# Should return: {"result":{"status":"active"},"success":true}
```

---

## 💡 Benefits Summary

| Feature | Before | After |
|---------|--------|-------|
| **IP Stability** | Changes on restart | Stable 100.x.x.x |
| **Cost** | $10-30/mo LoadBalancer | $0 (Tailscale free) |
| **DNS Updates** | Manual | Automated (hourly) |
| **Security** | Public IP | Zero-trust (Tailnet) |
| **Latency** | Direct | +5-20ms (WireGuard) |
| **Setup Time** | 1-2 hours | 5 minutes |

---

## 📚 Documentation

| File | Purpose |
|------|---------|
| [TAILSCALE_SETUP.md](TAILSCALE_SETUP.md) | Full guide (360+ lines) - Prerequisites, installation, troubleshooting |
| [TAILSCALE_QUICKSTART.md](TAILSCALE_QUICKSTART.md) | Quick reference (5-min setup) |
| [TAILSCALE_K8S_SUMMARY.md](TAILSCALE_K8S_SUMMARY.md) | This file - Overview and verification |
| [DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) | DNS/TLS configuration for fkstrading.xyz |
| [FKSTRADING_XYZ_SETUP.md](FKSTRADING_XYZ_SETUP.md) | Domain-specific setup guide |

---

## 🚀 Next Steps After Setup

1. ✅ **Deploy Tailscale** (run setup script)
2. ✅ **Configure GitHub** (add 4 secrets)
3. ✅ **Test automation** (trigger workflow)
4. ⏳ **Enable HTTPS** (install cert-manager)
5. ⏳ **Monitor** (watch GitHub Actions runs)
6. ⏳ **Scale** (deploy to production cluster)

---

## 🔗 Useful Links

- Tailscale Admin: https://login.tailscale.com/admin
- GitHub Actions: https://github.com/nuniesmith/fks/actions
- Cloudflare Dashboard: https://dash.cloudflare.com
- Kubernetes Dashboard: `minikube dashboard`

---

**Ready to deploy!** 🚀

Get your Tailscale auth key and run:
```bash
export TAILSCALE_AUTH_KEY="tskey-auth-xxxxx"
./scripts/setup-tailscale.sh
```
