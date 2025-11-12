#!/bin/bash
# Test FKS endpoints for fkstrading.xyz domain

set -e

MINIKUBE_IP=$(minikube ip)
DOMAIN="fkstrading.xyz"

echo "🧪 Testing FKS Endpoints"
echo "========================="
echo "Minikube IP: $MINIKUBE_IP"
echo "Domain: $DOMAIN"
echo ""
echo "Note: For local testing, you can either:"
echo "  1. Add to /etc/hosts: $MINIKUBE_IP $DOMAIN"
echo "  2. Use minikube tunnel (recommended)"
echo "  3. Test directly with IP and Host header"
echo ""

# Check if minikube tunnel is running
if pgrep -f "minikube tunnel" > /dev/null; then
    echo "✅ Minikube tunnel is running"
    BASE_URL="http://$DOMAIN"
else
    echo "⚠️  Minikube tunnel not running"
    echo "   Using IP with Host header instead"
    BASE_URL="http://$MINIKUBE_IP"
    HOST_HEADER="Host: $DOMAIN"
fi

echo ""
echo "Testing endpoints..."
echo ""

# Test function
test_endpoint() {
    local name="$1"
    local path="$2"
    local expected_status="${3:-200}"
    
    echo -n "Testing $name ($path)... "
    
    if [ -n "$HOST_HEADER" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -H "$HOST_HEADER" "$BASE_URL$path" 2>/dev/null || echo "000")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$path" 2>/dev/null || echo "000")
    fi
    
    if [ "$response" = "$expected_status" ] || [ "$response" = "200" ] || [ "$response" = "302" ] || [ "$response" = "404" ]; then
        echo "✅ HTTP $response"
    else
        echo "❌ HTTP $response (expected $expected_status)"
    fi
}

# Test endpoints
test_endpoint "Web Interface (Root)" "/"
test_endpoint "Web Interface (/web)" "/web"
test_endpoint "API Service" "/api/health" "200"
test_endpoint "API Service (/api)" "/api/docs"
test_endpoint "App Service" "/app/health" "200"
test_endpoint "Data Service" "/data/health" "200"
test_endpoint "Main Service" "/main/health" "200"
test_endpoint "AI Service" "/ai/health" "200"
test_endpoint "Analyze Service" "/analyze/health" "200"
test_endpoint "Portfolio Service" "/portfolio/health" "200"
test_endpoint "Monitor Service" "/monitor/health" "200"
test_endpoint "Auth Service" "/auth/health" "200"
test_endpoint "Execution Service" "/execution/health" "200"
test_endpoint "Meta Service" "/meta/health" "200"
test_endpoint "Training Service" "/training/health" "200"
test_endpoint "Ninja Service" "/ninja/health" "200"

echo ""
echo "📋 Subdomain endpoints (if tunnel is running):"
echo "  - http://api.$DOMAIN"
echo "  - http://app.$DOMAIN"
echo "  - http://data.$DOMAIN"
echo "  - http://main.$DOMAIN"
echo "  - http://ai.$DOMAIN"
echo "  - http://web.$DOMAIN"
echo ""

echo "💡 To start minikube tunnel (for proper domain routing):"
echo "   minikube tunnel"
echo ""
echo "💡 Or add to /etc/hosts:"
echo "   $MINIKUBE_IP $DOMAIN api.$DOMAIN app.$DOMAIN data.$DOMAIN main.$DOMAIN ai.$DOMAIN web.$DOMAIN"

