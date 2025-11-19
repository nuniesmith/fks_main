#!/bin/bash
# Quick access to Kubernetes Dashboard with auto token

TOKEN_FILE="$(dirname "$0")/dashboard-token.txt"
NAMESPACE="kubernetes-dashboard"
PROXY_PORT=8001

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Token file not found. Please run k8s_start again to generate token."
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

# Start proxy if not running
if ! pgrep -f "kubectl proxy" > /dev/null; then
  echo "Starting kubectl proxy..."
  nohup kubectl proxy --port=$PROXY_PORT > /tmp/kubectl-proxy.log 2>&1 &
  sleep 2
fi

DASHBOARD_URL="http://localhost:$PROXY_PORT/api/v1/namespaces/$NAMESPACE/services/https:kubernetes-dashboard:/proxy/#/login?token=$TOKEN"

echo "Dashboard URL: $DASHBOARD_URL"
echo "Token saved in: $TOKEN_FILE"

# Try to open in browser
if command -v xdg-open > /dev/null; then
  xdg-open "$DASHBOARD_URL" 2>/dev/null &
elif command -v open > /dev/null; then
  open "$DASHBOARD_URL" 2>/dev/null &
else
  echo "Please open this URL in your browser:"
  echo "$DASHBOARD_URL"
fi
