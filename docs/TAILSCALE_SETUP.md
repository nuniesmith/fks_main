# Tailscale + Kubernetes Setup Guide
## Stable IP for FKS Trading Platform

**Last Updated**: November 3, 2025  
**Purpose**: Provide stable Tailscale IP for DNS automation

---

## 🎯 Overview

This setup provides a **stable Tailscale IP** for your Kubernetes cluster, enabling:
- **Static IP addressing** without cloud LoadBalancer costs
- **Automatic DNS updates** via GitHub Actions
- **Secure access** through Tailscale's zero-trust network
- **Global reachability** from anywhere on your Tailnet

### Architecture

```
Internet (fkstrading.xyz)
    ↓ (DNS: A record → Tailscale IP)
Tailscale Network (100.x.x.x)
    ↓
Tailscale Connector Pod
    ↓
NGINX Ingress Controller
    ↓
FKS Services (fks-main, fks-api, etc.)
```

---

## 📋 Prerequisites

### 1. Tailscale Account

Create account at: https://login.tailscale.com/

### 2. Create Auth Key

1. Go to: https://login.tailscale.com/admin/settings/keys
2. Click **Generate auth key**
3. Settings:
   - ✅ **Reusable**
   - ✅ **Ephemeral** (optional - auto-cleanup on disconnect)
   - **Tags**: `tag:k8s`
   - **Expiration**: Never (or your preference)
4. Copy the key (starts with `tskey-auth-...`)

### 3. Create OAuth Client (for GitHub Actions)

1. Go to: https://login.tailscale.com/admin/settings/oauth
2. Click **Generate OAuth client**
3. Settings:
   - **Name**: `GitHub Actions DNS Updater`
   - **Scopes**: 
     - ✅ `devices:read`
     - ✅ `network:read`
4. Copy **Client ID** and **Client Secret**

---

## 🚀 Installation

### Step 1: Install Tailscale Operator

```bash
# Apply official Tailscale Kubernetes operator
kubectl apply -f https://github.com/tailscale/tailscale/raw/main/cmd/k8s-operator/deploy/manifests/operator.yaml

# Verify operator is running
kubectl get pods -n tailscale -l app=operator

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# operator-xxxx-xxxx          1/1     Running   0          30s
```

### Step 2: Create Tailscale Auth Secret

```bash
# Replace with your actual auth key
export TAILSCALE_AUTH_KEY="tskey-auth-xxxxx-xxxxxxxxx"

# Create secret in fks-trading namespace
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY="$TAILSCALE_AUTH_KEY"

# Verify secret
kubectl get secret tailscale-auth -n fks-trading
```

### Step 3: Deploy Tailscale Connector

```bash
# Update DEST_IP in k8s/tailscale-operator.yaml if needed
# For minikube: 192.168.49.2
# For production: your LoadBalancer IP

kubectl apply -f k8s/tailscale-operator.yaml

# Check connector status
kubectl get pods -n fks-trading -l app=tailscale-connector

# View logs
kubectl logs -n fks-trading -l app=tailscale-connector -f
```

### Step 4: Verify Tailscale Connection

```bash
# From your local machine (with Tailscale installed):
tailscale status

# You should see:
# fks-trading-k8s    100.x.x.x    linux   -
```

**Get the Tailscale IP**:
```bash
tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]'

# Example output: 100.64.123.45
```

### Step 5: Test Direct Access

```bash
# Get Tailscale IP
TS_IP=$(tailscale status --json | jq -r '.Peer[] | select(.HostName=="fks-trading-k8s") | .TailscaleIPs[0]')

# Test HTTP access via Tailscale
curl http://$TS_IP/health/

# Test specific service
curl http://$TS_IP:8000/health/  # fks-main
curl http://$TS_IP:8004/health   # fks-execution
```

---

## 🤖 GitHub Actions DNS Automation

### Step 1: Configure GitHub Secrets

Go to: `https://github.com/nuniesmith/fks/settings/secrets/actions`

Add these secrets:

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `TS_OAUTH_CLIENT_ID` | OAuth Client ID | https://login.tailscale.com/admin/settings/oauth |
| `TS_OAUTH_SECRET` | OAuth Client Secret | Same as above |
| `CLOUDFLARE_API_TOKEN` | API Token | https://dash.cloudflare.com/profile/api-tokens |
| `CLOUDFLARE_ZONE_ID` | Zone ID | Cloudflare Dashboard → fkstrading.xyz → Overview |

### Step 2: Create Cloudflare API Token

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **Create Token**
3. Use template: **Edit zone DNS**
4. Settings:
   - **Permissions**: Zone → DNS → Edit
   - **Zone Resources**: Include → Specific zone → fkstrading.xyz
5. Click **Continue to summary** → **Create Token**
6. Copy token (starts with `...`)

### Step 3: Enable GitHub Actions

```bash
# Workflow file already created at:
# .github/workflows/update-dns.yml

# Commit and push to trigger
git add .github/workflows/update-dns.yml
git commit -m "Add Tailscale DNS automation"
git push origin main
```

### Step 4: Manual Trigger (Test)

1. Go to: `https://github.com/nuniesmith/fks/actions`
2. Select **Update DNS with Tailscale IP**
3. Click **Run workflow** → **Run workflow**
4. Monitor progress

---

## ✅ Verification

### 1. Check Tailscale Status

```bash
# Local machine
tailscale status | grep fks-trading

# Inside Kubernetes
kubectl exec -n fks-trading -it deployment/tailscale-connector -- tailscale status
```

### 2. Verify DNS Records

```bash
# Check all domains
for domain in fkstrading.xyz api.fkstrading.xyz app.fkstrading.xyz; do
  echo "$domain: $(dig +short $domain)"
done

# Should all show your Tailscale IP (100.x.x.x)
```

### 3. Test HTTPS Access

```bash
# Main service
curl https://fkstrading.xyz/health/

# API
curl https://api.fkstrading.xyz/health/

# Execution
curl https://execution.fkstrading.xyz/health
```

---

## 🔧 Troubleshooting

### Tailscale Connector Not Connecting

```bash
# Check logs
kubectl logs -n fks-trading -l app=tailscale-connector

# Common issues:
# - Invalid auth key → recreate secret
# - Permissions → verify ServiceAccount/Role
# - Network → check NET_ADMIN capability
```

### Auth Key Expired

```bash
# Create new auth key (see Prerequisites)
# Update secret
kubectl delete secret tailscale-auth -n fks-trading
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY="tskey-auth-NEW-KEY"

# Restart connector
kubectl rollout restart deployment/tailscale-connector -n fks-trading
```

### DNS Not Updating

```bash
# Check GitHub Actions logs
# https://github.com/nuniesmith/fks/actions

# Manually trigger workflow
gh workflow run update-dns.yml

# Verify Cloudflare API token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_CLOUDFLARE_API_TOKEN"
```

### Can't Access via Tailscale IP

```bash
# Verify Ingress is exposed
kubectl get svc -n fks-trading fks-tailscale-ingress

# Check NGINX Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test direct pod access
kubectl port-forward -n fks-trading svc/fks-main 8000:8000
curl http://localhost:8000/health/
```

---

## 🔐 Security Considerations

### ACL Configuration

Add to your Tailscale ACL (https://login.tailscale.com/admin/acls):

```json
{
  "tagOwners": {
    "tag:k8s": ["autogroup:admin"],
    "tag:ci": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:members"],
      "dst": ["tag:k8s:80,443,8000-8010"]
    },
    {
      "action": "accept",
      "src": ["tag:ci"],
      "dst": ["tag:k8s:*"]
    }
  ]
}
```

### Network Policies

```yaml
# Already configured in k8s/charts/fks-platform/templates/network-policy.yaml
# Allows traffic from Tailscale connector to all services
```

---

## 📊 Monitoring

### Tailscale Metrics

```bash
# Check connection status
kubectl exec -n fks-trading deployment/tailscale-connector -- \
  tailscale status --json | jq '.Self'

# View latency
kubectl exec -n fks-trading deployment/tailscale-connector -- \
  tailscale ping fks-trading-k8s
```

### DNS Update History

View in GitHub Actions: https://github.com/nuniesmith/fks/actions/workflows/update-dns.yml

---

## 🚀 Next Steps

1. ✅ Install Tailscale operator
2. ✅ Deploy connector to K8s
3. ✅ Configure GitHub secrets
4. ✅ Test DNS automation
5. ⏳ **Enable HTTPS** (cert-manager + Let's Encrypt)
6. ⏳ **Monitor** DNS updates
7. ⏳ **Scale** to production

---

## 📚 Resources

- [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator)
- [Tailscale GitHub Action](https://github.com/tailscale/github-action)
- [Cloudflare API Docs](https://developers.cloudflare.com/api/)
- [FKS Domain Setup](DOMAIN_SETUP_GUIDE.md)

---

**Automatic Updates**: DNS updates run hourly via GitHub Actions  
**Manual Trigger**: https://github.com/nuniesmith/fks/actions/workflows/update-dns.yml
