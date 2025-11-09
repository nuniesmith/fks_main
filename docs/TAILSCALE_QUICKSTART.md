# Tailscale + K8s Quick Start

**Goal**: Get stable Tailscale IP for fkstrading.xyz DNS automation

---

## 🚀 Quick Setup (5 minutes)

### 1. Get Tailscale Auth Key

```bash
# Open: https://login.tailscale.com/admin/settings/keys
# Create auth key with:
# - ✅ Reusable
# - ✅ Tags: tag:fks
# Copy the key (tskey-auth-xxxxx)
```

### 2. Run Setup Script

```bash
# Set auth key
export TAILSCALE_AUTH_KEY="tskey-auth-xxxxx-xxxxxxxxx"

# Run automated setup
./scripts/setup-tailscale.sh
```

### 3. Verify Connection

```bash
# Check Tailscale status (local machine)
tailscale status | grep fks-trading

# Get Tailscale IP
tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]'

# Example output: 100.64.123.45
```

### 4. Configure GitHub Secrets

Go to: https://github.com/nuniesmith/fks/settings/secrets/actions

Add:
- `TS_OAUTH_CLIENT_ID` - from https://login.tailscale.com/admin/settings/oauth
- `TS_OAUTH_SECRET` - same as above
- `CLOUDFLARE_API_TOKEN` - from https://dash.cloudflare.com/profile/api-tokens
- `CLOUDFLARE_ZONE_ID` - from Cloudflare dashboard → fkstrading.xyz

### 5. Test DNS Automation

```bash
# Commit and push workflow
git add .github/workflows/update-dns.yml
git commit -m "Add Tailscale DNS automation"
git push origin main

# Or manually trigger:
# Go to: https://github.com/nuniesmith/fks/actions
# Select "Update DNS with Tailscale IP"
# Click "Run workflow"
```

---

## ✅ What This Does

1. **Installs** Tailscale operator in K8s cluster
2. **Deploys** connector pod with tag:fks
3. **Gets** stable Tailscale IP (100.x.x.x)
4. **Automates** DNS updates hourly via GitHub Actions
5. **Routes** traffic: Internet → Tailscale → NGINX Ingress → Services

---

## 🔍 Verification

```bash
# Check connector pod
kubectl get pods -n fks-trading -l app=tailscale-connector

# View logs
kubectl logs -n fks-trading -l app=tailscale-connector -f

# Test access via Tailscale IP
TS_IP=$(tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]')
curl http://$TS_IP/health/
```

---

## 📚 Full Documentation

See: [docs/TAILSCALE_SETUP.md](docs/TAILSCALE_SETUP.md)

---

## 🛠️ Manual Steps (Alternative)

If you prefer manual setup:

```bash
# 1. Install operator
kubectl apply -f https://github.com/tailscale/tailscale/raw/main/cmd/k8s-operator/deploy/manifests/operator.yaml

# 2. Create secret
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY="tskey-auth-xxxxx"

# 3. Deploy connector
kubectl apply -f k8s/tailscale-operator.yaml

# 4. Verify
kubectl get pods -n fks-trading -l app=tailscale-connector
```

---

**Next**: Configure DNS automation with GitHub Actions (see TAILSCALE_SETUP.md)
