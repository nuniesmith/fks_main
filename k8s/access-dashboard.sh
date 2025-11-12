#!/bin/bash
# Quick access to Kubernetes Dashboard
# This script opens the dashboard with the token automatically

TOKEN_FILE="$(dirname "$0")/dashboard-token.txt"
NAMESPACE="kubernetes-dashboard"

if [ -f "$TOKEN_FILE" ]; then
  TOKEN=$(cat "$TOKEN_FILE")
  echo "Opening dashboard with token..."
  # Start proxy in background if not running
  if ! pgrep -f "kubectl proxy" > /dev/null; then
    echo "Starting kubectl proxy..."
    kubectl proxy > /dev/null 2>&1 &
    sleep 2
  fi
  # Open dashboard with token
  DASHBOARD_URL="http://localhost:8001/api/v1/namespaces/$NAMESPACE/services/https:kubernetes-dashboard:/proxy/#/login?token=$TOKEN"
  echo "Dashboard URL: $DASHBOARD_URL"
  if command -v xdg-open > /dev/null; then
    xdg-open "$DASHBOARD_URL"
  elif command -v open > /dev/null; then
    open "$DASHBOARD_URL"
  else
    echo "Please open this URL in your browser:"
    echo "$DASHBOARD_URL"
  fi
else
  echo "Token file not found. Generating token..."
  TOKEN=$(kubectl -n "$NAMESPACE" create token admin-user --duration=8760h 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    echo "$TOKEN" > "$TOKEN_FILE"
    echo "Token saved. Run this script again to open dashboard."
  else
    echo "Failed to generate token. Run manually:"
    echo "  kubectl -n $NAMESPACE create token admin-user --duration=8760h"
  fi
fi
