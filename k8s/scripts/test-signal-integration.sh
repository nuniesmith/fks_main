#!/bin/bash
# Test Signal Integration in Kubernetes
# This script validates the Kubernetes deployment configuration for signal integration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="fks-trading"

echo -e "${BLUE}=== Testing Signal Integration in Kubernetes ===${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

# Check if cluster is accessible
echo -e "${BLUE}Checking Kubernetes cluster...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}⚠ Kubernetes cluster is not accessible${NC}"
    echo "Please start your cluster (minikube start, docker desktop, etc.)"
    exit 1
fi
echo -e "${GREEN}✓ Cluster accessible${NC}"

# Check namespace
echo -e "${BLUE}Checking namespace...${NC}"
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${YELLOW}⚠ Namespace $NAMESPACE does not exist${NC}"
    echo "Creating namespace..."
    kubectl create namespace "$NAMESPACE"
fi
echo -e "${GREEN}✓ Namespace exists${NC}"

# Validate manifests
echo -e "${BLUE}Validating manifests...${NC}"

# Check portfolio deployment
if ! kubectl apply --dry-run=client -f "$K8S_DIR/manifests/missing-services.yaml" &> /dev/null; then
    echo -e "${RED}✗ Portfolio service manifest validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Portfolio service manifest valid${NC}"

# Check web service
if ! kubectl apply --dry-run=client -f "$K8S_DIR/manifests/all-services.yaml" &> /dev/null; then
    echo -e "${RED}✗ Web service manifest validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Web service manifest valid${NC}"

# Check signals volume
if [ -f "$K8S_DIR/manifests/signals-volume.yaml" ]; then
    if ! kubectl apply --dry-run=client -f "$K8S_DIR/manifests/signals-volume.yaml" &> /dev/null; then
        echo -e "${YELLOW}⚠ Signals volume manifest validation failed (optional)${NC}"
    else
        echo -e "${GREEN}✓ Signals volume manifest valid${NC}"
    fi
fi

# Check if services are deployed
echo -e "${BLUE}Checking deployed services...${NC}"

# Portfolio service
if kubectl get deployment fks-portfolio -n "$NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}✓ Portfolio service deployed${NC}"
    
    # Check environment variables
    echo -e "${BLUE}  Checking environment variables...${NC}"
    if kubectl get deployment fks-portfolio -n "$NAMESPACE" -o yaml | grep -q "SIGNALS_DIR"; then
        echo -e "${GREEN}    ✓ SIGNALS_DIR configured${NC}"
    else
        echo -e "${YELLOW}    ⚠ SIGNALS_DIR not found (may need to apply updates)${NC}"
    fi
    
    # Check volume mounts
    if kubectl get deployment fks-portfolio -n "$NAMESPACE" -o yaml | grep -q "signals"; then
        echo -e "${GREEN}    ✓ Signals volume mount configured${NC}"
    else
        echo -e "${YELLOW}    ⚠ Signals volume mount not found (may need to apply updates)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Portfolio service not deployed${NC}"
fi

# Web service
if kubectl get deployment fks-web -n "$NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}✓ Web service deployed${NC}"
    
    # Check environment variables
    echo -e "${BLUE}  Checking environment variables...${NC}"
    if kubectl get deployment fks-web -n "$NAMESPACE" -o yaml | grep -q "FKS_PORTFOLIO_URL"; then
        echo -e "${GREEN}    ✓ FKS_PORTFOLIO_URL configured${NC}"
    else
        echo -e "${YELLOW}    ⚠ FKS_PORTFOLIO_URL not found (may need to apply updates)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Web service not deployed${NC}"
fi

# Test pod connectivity (if pods are running)
echo -e "${BLUE}Testing pod connectivity...${NC}"

PORTFOLIO_POD=$(kubectl get pods -n "$NAMESPACE" -l app=fks-portfolio -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PORTFOLIO_POD" ]; then
    echo -e "${GREEN}✓ Portfolio pod found: $PORTFOLIO_POD${NC}"
    
    # Check if signals directory is mounted
    if kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- ls /app/signals &> /dev/null; then
        echo -e "${GREEN}  ✓ Signals directory mounted${NC}"
        
        # Check if signal files exist
        SIGNAL_COUNT=$(kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- find /app/signals -name "*.json" 2>/dev/null | wc -l)
        if [ "$SIGNAL_COUNT" -gt 0 ]; then
            echo -e "${GREEN}  ✓ Found $SIGNAL_COUNT signal file(s)${NC}"
        else
            echo -e "${YELLOW}  ⚠ No signal files found${NC}"
        fi
    else
        echo -e "${RED}  ✗ Signals directory not accessible${NC}"
    fi
    
    # Test health endpoint
    if kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- curl -s http://localhost:8012/health &> /dev/null; then
        echo -e "${GREEN}  ✓ Health endpoint responding${NC}"
    else
        echo -e "${YELLOW}  ⚠ Health endpoint not responding${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Portfolio pod not running${NC}"
fi

WEB_POD=$(kubectl get pods -n "$NAMESPACE" -l app=fks-web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$WEB_POD" ]; then
    echo -e "${GREEN}✓ Web pod found: $WEB_POD${NC}"
    
    # Test connectivity to portfolio service
    if kubectl exec -n "$NAMESPACE" "$WEB_POD" -- curl -s http://fks-portfolio:8012/health &> /dev/null; then
        echo -e "${GREEN}  ✓ Can connect to portfolio service${NC}"
    else
        echo -e "${YELLOW}  ⚠ Cannot connect to portfolio service${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Web pod not running${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo ""
echo "To apply the updates:"
echo "  kubectl apply -f $K8S_DIR/manifests/missing-services.yaml"
echo "  kubectl apply -f $K8S_DIR/manifests/all-services.yaml"
echo ""
echo "To test after deployment:"
echo "  kubectl port-forward -n $NAMESPACE svc/fks-portfolio 8012:8012"
echo "  curl http://localhost:8012/api/signals/from-files?date=20251112"
echo ""
echo -e "${GREEN}✓ Validation complete!${NC}"

