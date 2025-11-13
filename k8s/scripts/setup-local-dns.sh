#!/bin/bash
# Setup local DNS for fkstrading.xyz domain (adds to /etc/hosts)

set -e

MINIKUBE_IP=$(minikube ip)
HOSTS_FILE="/etc/hosts"
DOMAIN="fkstrading.xyz"

echo "🔧 Setting up local DNS for $DOMAIN"
echo "Minikube IP: $MINIKUBE_IP"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script needs to be run with sudo"
    echo "   sudo bash $0"
    exit 1
fi

# Backup hosts file
cp "$HOSTS_FILE" "$HOSTS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup created: $HOSTS_FILE.backup.*"

# Remove existing entries
sed -i "/fkstrading\.xyz/d" "$HOSTS_FILE"
echo "✅ Removed existing fkstrading.xyz entries"

# Add new entries
cat >> "$HOSTS_FILE" << EOF

# FKS Trading Platform - Minikube Local Development
$MINIKUBE_IP $DOMAIN
$MINIKUBE_IP api.$DOMAIN
$MINIKUBE_IP app.$DOMAIN
$MINIKUBE_IP data.$DOMAIN
$MINIKUBE_IP main.$DOMAIN
$MINIKUBE_IP ai.$DOMAIN
$MINIKUBE_IP web.$DOMAIN
$MINIKUBE_IP ninja.$DOMAIN
$MINIKUBE_IP analyze.$DOMAIN
$MINIKUBE_IP portfolio.$DOMAIN
$MINIKUBE_IP monitor.$DOMAIN
$MINIKUBE_IP execution.$DOMAIN
$MINIKUBE_IP auth.$DOMAIN
$MINIKUBE_IP meta.$DOMAIN
$MINIKUBE_IP training.$DOMAIN
$MINIKUBE_IP dashboard.$DOMAIN
$MINIKUBE_IP grafana.$DOMAIN
$MINIKUBE_IP prometheus.$DOMAIN
EOF

echo "✅ Added DNS entries to $HOSTS_FILE"
echo ""
echo "📋 Added domains:"
echo "  - $DOMAIN"
echo "  - api.$DOMAIN"
echo "  - app.$DOMAIN"
echo "  - data.$DOMAIN"
echo "  - main.$DOMAIN"
echo "  - ai.$DOMAIN"
echo "  - web.$DOMAIN"
echo "  - (and more...)"
echo ""
echo "🧪 Test with:"
echo "   curl http://$DOMAIN"
echo "   curl http://api.$DOMAIN/health"

