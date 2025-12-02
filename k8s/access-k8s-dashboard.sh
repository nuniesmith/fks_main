#!/bin/bash
# Quick access to Kubernetes Dashboard at k8s.fkstrading.xyz

set -e

echo "=== Kubernetes Dashboard Access ==="
echo ""

# Check if Minikube is running
if ! minikube status &>/dev/null; then
    echo "⚠️  Minikube is not running. Starting..."
    minikube start
fi

# Get token
TOKEN_FILE="$(dirname "$0")/dashboard-token.txt"
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE")
else
    echo "Generating new token..."
    TOKEN=$(kubectl create token admin-user -n kubernetes-dashboard --duration=8760h 2>/dev/null || \
            kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount admin-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode)
fi

echo "🌐 Dashboard URL: https://k8s.fkstrading.xyz"
echo ""
echo "🔑 Access Token (copied to clipboard):"
echo "$TOKEN"
echo ""

# Copy to clipboard if available
if command -v xclip &>/dev/null; then
    echo "$TOKEN" | xclip -selection clipboard
    echo "✅ Token copied to clipboard!"
elif command -v pbcopy &>/dev/null; then
    echo "$TOKEN" | pbcopy
    echo "✅ Token copied to clipboard!"
else
    echo "ℹ️  Install xclip to auto-copy token: sudo apt install xclip"
fi

echo ""
echo "📋 Steps to access:"
echo "  1. Open: https://k8s.fkstrading.xyz"
echo "  2. Choose 'Token' authentication"
echo "  3. Paste the token above"
echo ""

# Open browser if requested
if [ "$1" == "--open" ] || [ "$1" == "-o" ]; then
    echo "🌐 Opening browser..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "https://k8s.fkstrading.xyz" &>/dev/null &
    elif command -v open &>/dev/null; then
        open "https://k8s.fkstrading.xyz"
    fi
fi
