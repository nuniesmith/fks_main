#!/bin/bash
# Quick access to Kubernetes Dashboard
# This script opens the dashboard with the token automatically

TOKEN_FILE="$(dirname "$0")/dashboard-token.txt"
NAMESPACE="kubernetes-dashboard"

# Suppress GTK warnings
export NO_AT_BRIDGE=1

echo "=========================================="
echo "Kubernetes Dashboard Access"
echo "=========================================="
echo ""

# Get token
if [ -f "$TOKEN_FILE" ]; then
  TOKEN=$(cat "$TOKEN_FILE")
  echo "✓ Token loaded from file"
else
  echo "Generating new token..."
  TOKEN=$(kubectl -n "$NAMESPACE" create token admin-user --duration=8760h 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    echo "$TOKEN" > "$TOKEN_FILE"
    echo "✓ Token generated and saved"
  else
    echo "✗ Failed to generate token"
    echo "Run manually: kubectl -n $NAMESPACE create token admin-user --duration=8760h"
    exit 1
  fi
fi

# Method 1: Use port-forward (more reliable)
echo "Setting up port-forward..."
# Kill existing port-forwards
pkill -f "kubectl port-forward.*kubernetes-dashboard" 2>/dev/null || true
sleep 1

# Start port-forward in background
kubectl port-forward -n "$NAMESPACE" svc/kubernetes-dashboard 8443:80 > /tmp/dashboard-portforward.log 2>&1 &
PF_PID=$!
sleep 3

# Check if port-forward is working
if kill -0 $PF_PID 2>/dev/null; then
  echo "✓ Port-forward started (PID: $PF_PID)"
  DASHBOARD_URL="http://localhost:8443/#/login?token=$TOKEN"
  PORT_FORWARD_METHOD=true
else
  echo "⚠ Port-forward failed, trying kubectl proxy method..."
  PORT_FORWARD_METHOD=false
  
  # Fallback to proxy method
  if ! pgrep -f "kubectl proxy" > /dev/null; then
    echo "Starting kubectl proxy..."
    kubectl proxy > /dev/null 2>&1 &
    sleep 3
    echo "✓ Proxy started"
  else
    echo "✓ Proxy already running"
  fi
  
  # Try HTTP service endpoint instead of HTTPS
  DASHBOARD_URL="http://localhost:8001/api/v1/namespaces/$NAMESPACE/services/http:kubernetes-dashboard:/proxy/#/login?token=$TOKEN"
fi

echo ""
echo "=========================================="
echo "Dashboard Access Methods"
echo "=========================================="
echo ""
echo "Method 1: Direct URL (copy and paste into browser):"
echo "$DASHBOARD_URL"
echo ""
if [ "$PORT_FORWARD_METHOD" = "true" ]; then
  echo "Method 2: Port-forward (already active):"
  echo "  kubectl port-forward -n $NAMESPACE svc/kubernetes-dashboard 8443:80"
  echo ""
  echo "Method 3: Via kubectl proxy (alternative):"
  echo "  1. kubectl proxy"
  echo "  2. Visit: http://localhost:8001/api/v1/namespaces/$NAMESPACE/services/http:kubernetes-dashboard:/proxy/"
  echo "  3. Select 'Token' authentication"
  echo "  4. Paste token from: $TOKEN_FILE"
else
  echo "Method 2: Via port-forward (recommended):"
  echo "  kubectl port-forward -n $NAMESPACE svc/kubernetes-dashboard 8443:80"
  echo "  Then visit: http://localhost:8443/#/login?token=<token>"
  echo ""
  echo "Method 3: Via minikube service:"
  minikube service kubernetes-dashboard -n "$NAMESPACE" --url 2>/dev/null | head -1 | sed 's/^/  /' || echo "  (minikube service not available)"
fi
echo ""

# Try to open browser (suppress GTK warnings)
if command -v xdg-open > /dev/null; then
  echo "Attempting to open browser..."
  NO_AT_BRIDGE=1 xdg-open "$DASHBOARD_URL" 2>/dev/null &
  echo "✓ Browser launch attempted"
elif command -v open > /dev/null; then
  echo "Attempting to open browser..."
  open "$DASHBOARD_URL" 2>/dev/null &
  echo "✓ Browser launch attempted"
else
  echo "Please copy the URL above and open it in your browser"
fi

echo ""
echo "=========================================="
echo "Token (first 50 chars):"
echo "$(echo "$TOKEN" | head -c 50)..."
echo "=========================================="
echo ""
echo "If browser doesn't open, copy the URL above and paste it into your browser."
