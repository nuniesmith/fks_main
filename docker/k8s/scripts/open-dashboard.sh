#!/bin/bash
# Open Kubernetes Dashboard

set -e

NAMESPACE="kubernetes-dashboard"
TOKEN_FILE="$(cd "$(dirname "$0")/.." && pwd)/dashboard-token.txt"

echo "🔐 Opening Kubernetes Dashboard..."

# Get or generate token
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE")
    echo "✅ Using saved token from $TOKEN_FILE"
else
    echo "Generating new token..."
    TOKEN=$(kubectl -n "$NAMESPACE" create token admin-user --duration=8760h 2>/dev/null || \
            kubectl -n "$NAMESPACE" get secret admin-user-secret -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)
    
    if [ -z "$TOKEN" ]; then
        echo "❌ Failed to get token"
        exit 1
    fi
    
    echo "$TOKEN" > "$TOKEN_FILE"
    echo "✅ Token saved to $TOKEN_FILE"
fi

# Start kubectl proxy if not running
if ! pgrep -f "kubectl proxy" > /dev/null; then
    echo "Starting kubectl proxy..."
    kubectl proxy > /dev/null 2>&1 &
    sleep 2
    echo "✅ Proxy started"
fi

# Dashboard URL
DASHBOARD_URL="http://localhost:8001/api/v1/namespaces/$NAMESPACE/services/https:kubernetes-dashboard:/proxy/#/login?token=$TOKEN"

echo ""
echo "📊 Dashboard URL:"
echo "   $DASHBOARD_URL"
echo ""
echo "🔑 Token (first 50 chars): $(echo "$TOKEN" | head -c 50)..."
echo ""

# Try to open in browser
if command -v xdg-open > /dev/null; then
    echo "Opening in browser..."
    xdg-open "$DASHBOARD_URL" 2>/dev/null &
elif command -v open > /dev/null; then
    echo "Opening in browser..."
    open "$DASHBOARD_URL" 2>/dev/null &
else
    echo "Please open the URL above in your browser"
fi

echo ""
echo "💡 To stop the proxy: pkill -f 'kubectl proxy'"

