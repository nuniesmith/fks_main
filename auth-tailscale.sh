#!/bin/bash
# Quick script to authenticate Tailscale connector in Kubernetes

set -e

echo "🔐 Tailscale Authentication Helper"
echo "===================================="
echo ""

# Check if auth key is provided as argument
if [ -z "$1" ]; then
    echo "❌ Error: Tailscale auth key not provided"
    echo ""
    echo "Usage: $0 <tskey-auth-xxxxx>"
    echo ""
    echo "Get your auth key from: https://login.tailscale.com/admin/settings/keys"
    echo "  1. Click 'Generate auth key'"
    echo "  2. Settings: Reusable, Tags: tag:k8s"
    echo "  3. Copy the key (starts with 'tskey-auth-...')"
    echo ""
    echo "Example:"
    echo "  $0 tskey-auth-xxxxx-xxxxxxxxxxxxxxxxx"
    echo ""
    exit 1
fi

AUTH_KEY="$1"

# Validate key format
if [[ ! "$AUTH_KEY" =~ ^tskey-auth- ]]; then
    echo "⚠️  Warning: Key doesn't start with 'tskey-auth-'"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📝 Updating Tailscale auth secret..."
kubectl create secret generic tailscale-auth \
  --namespace=fks-trading \
  --from-literal=TS_AUTHKEY="$AUTH_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Secret updated successfully"
else
    echo "❌ Failed to update secret"
    exit 1
fi

echo ""
echo "🔄 Restarting Tailscale connector pod..."
kubectl delete pod -n fks-trading tailscale-connector-0 2>/dev/null || \
kubectl delete pod -n fks-trading -l app=tailscale-connector 2>/dev/null || true

echo "⏳ Waiting for pod to restart..."
sleep 5

echo ""
echo "📊 Pod status:"
kubectl get pods -n fks-trading -l app=tailscale-connector

echo ""
echo "📋 View logs (Ctrl+C to exit):"
echo "  kubectl logs -n fks-trading tailscale-connector-0 -f"
echo ""
echo "✅ Authentication complete!"
echo ""
echo "🔍 Verify connection (from local machine with Tailscale):"
echo "  tailscale status | grep fks-trading"

