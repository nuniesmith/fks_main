# Tailscale Authentication Guide

## Quick Fix for Tailscale Connector

The Tailscale connector is failing because it needs a valid auth key.

### Step 1: Get Tailscale Auth Key

1. Go to: **https://login.tailscale.com/admin/settings/keys**
2. Click **"Generate auth key"**
3. Configure:
   - ✅ **Reusable**: Yes
   - ✅ **Tags**: `tag:k8s` (optional, matches your ACLs)
   - ✅ **Expiration**: Never (or your preference)
4. **Copy the key** (starts with `tskey-auth-...`)

### Step 2: Update Kubernetes Secret

Run this command (replace `YOUR_KEY_HERE` with your actual key):

```bash
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY='YOUR_KEY_HERE' \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Example:**
```bash
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY='tskey-auth-xxxxx-xxxxxxxxxxxxxxxxx' \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Step 3: Restart Connector Pod

```bash
kubectl delete pod -n fks-trading tailscale-connector-0
```

The pod will automatically restart and authenticate with the new key.

### Step 4: Verify Connection

```bash
# Check pod status
kubectl get pods -n fks-trading -l app=tailscale-connector

# View logs (should show successful authentication)
kubectl logs -n fks-trading tailscale-connector-0 -f

# From your local machine (if Tailscale is installed):
tailscale status | grep fks-trading
```

### Expected Log Output

After restart, you should see:
```
control: RegisterReq: got response; nodeKeyExpired=false, machineAuthorized=true
health(warnable=login-state): ok
```

### Troubleshooting

**If authentication still fails:**
1. Verify the key is correct (no extra spaces, full key copied)
2. Check key hasn't expired in Tailscale admin panel
3. Ensure key has proper permissions (reusable, correct tags)
4. Check logs: `kubectl logs -n fks-trading tailscale-connector-0 --tail=50`

**Alternative: Use Setup Script**

If you prefer automated setup:
```bash
export TAILSCALE_AUTH_KEY='tskey-auth-xxxxx-xxxxxxxxxxxxxxxxx'
cd repo/main
./scripts/setup-tailscale.sh
```

