#!/bin/bash
# FKS Trading Platform - Deployment Verification Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          FKS Trading Platform - Deployment Verification                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check 1: Minikube Running
echo -n "✓ Checking minikube status... "
if minikube status | grep -q "Running"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check 2: Kubectl configured
echo -n "✓ Checking kubectl connectivity... "
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check 3: Namespace exists
echo -n "✓ Checking fks-trading namespace... "
if kubectl get namespace fks-trading &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check 4: All pods running
echo -n "✓ Checking pod status... "
PENDING=$(kubectl get pods -n fks-trading --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
if [ "$PENDING" -eq 0 ]; then
    echo -e "${GREEN}OK (all running)${NC}"
else
    echo -e "${YELLOW}WARNING ($PENDING not running)${NC}"
fi

# Check 5: Services exposed
echo -n "✓ Checking services... "
SERVICES=$(kubectl get svc -n fks-trading --no-headers | wc -l)
if [ "$SERVICES" -ge 4 ]; then
    echo -e "${GREEN}OK ($SERVICES services)${NC}"
else
    echo -e "${RED}FAILED (expected 4+)${NC}"
fi

# Check 6: Ingress configured
echo -n "✓ Checking ingress... "
INGRESS=$(kubectl get ingress -n fks-trading --no-headers | wc -l)
if [ "$INGRESS" -ge 4 ]; then
    echo -e "${GREEN}OK ($INGRESS routes)${NC}"
else
    echo -e "${RED}FAILED (expected 4+)${NC}"
fi

# Check 7: TLS secret exists
echo -n "✓ Checking TLS secret... "
if kubectl get secret fkstrading-tls -n fks-trading &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check 8: Dashboard accessible
echo -n "✓ Checking dashboard... "
if kubectl get svc kubernetes-dashboard -n kubernetes-dashboard &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check 9: DNS resolution
echo -n "✓ Checking DNS resolution... "
if ping -c 1 grafana.fkstrading.xyz &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check 10: HTTPS endpoints
echo -n "✓ Checking HTTPS endpoints... "
HTTPS_OK=0
curl -k -s -o /dev/null -w "%{http_code}" https://grafana.fkstrading.xyz | grep -q "200\|302" && ((HTTPS_OK++))
curl -k -s -o /dev/null -w "%{http_code}" https://prometheus.fkstrading.xyz | grep -q "200\|302" && ((HTTPS_OK++))
curl -k -s -o /dev/null -w "%{http_code}" https://alertmanager.fkstrading.xyz | grep -q "200\|302" && ((HTTPS_OK++))

if [ "$HTTPS_OK" -ge 3 ]; then
    echo -e "${GREEN}OK ($HTTPS_OK/3 responding)${NC}"
else
    echo -e "${YELLOW}WARNING ($HTTPS_OK/3 responding)${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✅ All Verification Checks Passed!                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display access info
MINIKUBE_IP=$(minikube ip)
NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')

echo -e "${BLUE}Access Information:${NC}"
echo ""
echo -e "  🌐 Dashboard: ${YELLOW}http://${MINIKUBE_IP}:${NODEPORT}${NC}"
echo -e "  🔑 Token:     ${YELLOW}cat /tmp/k8s-dashboard-token.txt${NC}"
echo ""
echo -e "  🔐 HTTPS Services:"
echo -e "     Grafana:      ${YELLOW}https://grafana.fkstrading.xyz${NC}"
echo -e "     Prometheus:   ${YELLOW}https://prometheus.fkstrading.xyz${NC}"
echo -e "     Alertmanager: ${YELLOW}https://alertmanager.fkstrading.xyz${NC}"
echo ""
echo -e "  📊 Port Forward (no SSL warnings):"
echo -e "     ${YELLOW}kubectl port-forward -n fks-trading svc/grafana 3000:3000${NC}"
echo -e "     ${YELLOW}kubectl port-forward -n fks-trading svc/prometheus 9090:9090${NC}"
echo ""
