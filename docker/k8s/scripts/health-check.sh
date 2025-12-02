#!/bin/bash
# Comprehensive Health Check for FKS Kubernetes Environment
# Checks all services, pods, and provides diagnostics

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="fks-trading"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}FKS Kubernetes Health Check${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check namespace
echo -e "${BLUE}Checking namespace...${NC}"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo -e "${GREEN}✓ Namespace exists${NC}"
else
  echo -e "${RED}✗ Namespace not found${NC}"
  exit 1
fi

# Get all pods
echo ""
echo -e "${BLUE}Pod Status Summary:${NC}"
kubectl get pods -n "$NAMESPACE" -o wide | head -1
kubectl get pods -n "$NAMESPACE" | grep -v "Completed" | tail -n +2 | while read line; do
  if echo "$line" | grep -q "Running"; then
    echo -e "${GREEN}$line${NC}"
  elif echo "$line" | grep -q "CrashLoopBackOff\|Error\|ImagePullBackOff\|ErrImagePull"; then
    echo -e "${RED}$line${NC}"
  elif echo "$line" | grep -q "Pending\|ContainerCreating"; then
    echo -e "${YELLOW}$line${NC}"
  else
    echo "$line"
  fi
done

# Count statuses
RUNNING=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
FAILED=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -cE "CrashLoopBackOff|Error|ImagePullBackOff" || echo "0")
PENDING=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -cE "Pending|ContainerCreating" || echo "0")

echo ""
echo -e "${BLUE}Summary:${NC}"
echo -e "  ${GREEN}Running: $RUNNING${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo -e "  ${YELLOW}Pending: $PENDING${NC}"

# Check each service
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Service Health Checks${NC}"
echo -e "${CYAN}========================================${NC}"

SERVICES=(
  "fks-web:8000"
  "fks-api:8001"
  "fks-app:8002"
  "fks-data:8003"
  "fks-execution:8004"
  "fks-meta:8005"
  "fks-ninja:8006"
  "fks-ai:8007"
  "fks-analyze:8008"
  "fks-auth:8009"
  "fks-main:8010"
  "fks-training:8011"
  "fks-portfolio:8012"
  "fks-monitor:8013"
)

for service_info in "${SERVICES[@]}"; do
  IFS=':' read -r service port <<< "$service_info"
  echo ""
  echo -e "${BLUE}Checking $service (port $port)...${NC}"
  
  # Check if deployment exists
  if ! kubectl get deployment "$service" -n "$NAMESPACE" &> /dev/null; then
    echo -e "  ${YELLOW}⚠ Deployment not found${NC}"
    continue
  fi
  
  # Check pod status
  POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
  RESTARTS=$(kubectl get pods -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
  
  if [ "$POD_STATUS" = "Running" ]; then
    echo -e "  ${GREEN}✓ Pod is Running${NC}"
    if [ "$RESTARTS" != "0" ] && [ "$RESTARTS" != "NotFound" ]; then
      echo -e "  ${YELLOW}  ⚠ Restarts: $RESTARTS${NC}"
    fi
    
    # Test health endpoint
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
      if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:$port/health &> /dev/null; then
        echo -e "  ${GREEN}✓ Health endpoint responding${NC}"
      else
        echo -e "  ${YELLOW}  ⚠ Health endpoint not responding${NC}"
      fi
    fi
  elif [ "$POD_STATUS" = "CrashLoopBackOff" ] || [ "$POD_STATUS" = "Error" ]; then
    echo -e "  ${RED}✗ Pod is $POD_STATUS${NC}"
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
      echo -e "  ${YELLOW}  Last log line:${NC}"
      kubectl logs -n "$NAMESPACE" "$POD_NAME" --tail=1 2>&1 | sed 's/^/    /' || echo "    (no logs)"
    fi
  elif [ "$POD_STATUS" = "Pending" ] || [ "$POD_STATUS" = "ContainerCreating" ]; then
    echo -e "  ${YELLOW}⚠ Pod is $POD_STATUS${NC}"
  else
    echo -e "  ${YELLOW}⚠ Pod status: $POD_STATUS${NC}"
  fi
done

# Check infrastructure
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Infrastructure Health${NC}"
echo -e "${CYAN}========================================${NC}"

# PostgreSQL
echo ""
echo -e "${BLUE}PostgreSQL:${NC}"
if kubectl get statefulset postgres -n "$NAMESPACE" &> /dev/null; then
  PG_READY=$(kubectl get statefulset postgres -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  PG_REPLICAS=$(kubectl get statefulset postgres -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
  if [ "$PG_READY" = "$PG_REPLICAS" ] && [ "$PG_READY" != "0" ]; then
    echo -e "  ${GREEN}✓ PostgreSQL is ready ($PG_READY/$PG_REPLICAS)${NC}"
  else
    echo -e "  ${YELLOW}⚠ PostgreSQL not ready ($PG_READY/$PG_REPLICAS)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠ PostgreSQL not found${NC}"
fi

# Redis
echo ""
echo -e "${BLUE}Redis:${NC}"
if kubectl get deployment redis -n "$NAMESPACE" &> /dev/null; then
  REDIS_READY=$(kubectl get deployment redis -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  REDIS_REPLICAS=$(kubectl get deployment redis -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
  if [ "$REDIS_READY" = "$REDIS_REPLICAS" ] && [ "$REDIS_READY" != "0" ]; then
    echo -e "  ${GREEN}✓ Redis is ready ($REDIS_READY/$REDIS_REPLICAS)${NC}"
  else
    echo -e "  ${YELLOW}⚠ Redis not ready ($REDIS_READY/$REDIS_REPLICAS)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠ Redis not found${NC}"
fi

# Check portfolio service specifically (signal integration)
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Portfolio Service (Signal Integration)${NC}"
echo -e "${CYAN}========================================${NC}"

PORTFOLIO_POD=$(kubectl get pods -n "$NAMESPACE" -l app=fks-portfolio -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PORTFOLIO_POD" ]; then
  echo -e "${BLUE}Pod: $PORTFOLIO_POD${NC}"
  
  # Check volume mounts
  echo -e "${BLUE}Checking volume mounts...${NC}"
  if kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- ls /app/signals &> /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Signals directory mounted${NC}"
    SIGNAL_COUNT=$(kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- find /app/signals -name "*.json" 2>/dev/null | wc -l)
    echo -e "  ${GREEN}  Found $SIGNAL_COUNT signal file(s)${NC}"
  else
    echo -e "  ${RED}✗ Signals directory not accessible${NC}"
  fi
  
  # Check environment variables
  echo -e "${BLUE}Checking environment variables...${NC}"
  if kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- env 2>/dev/null | grep -q "SIGNALS_DIR"; then
    SIGNALS_DIR=$(kubectl exec -n "$NAMESPACE" "$PORTFOLIO_POD" -- env 2>/dev/null | grep SIGNALS_DIR | cut -d= -f2)
    echo -e "  ${GREEN}✓ SIGNALS_DIR=$SIGNALS_DIR${NC}"
  else
    echo -e "  ${RED}✗ SIGNALS_DIR not set${NC}"
  fi
else
  echo -e "${RED}✗ Portfolio pod not found${NC}"
fi

# Check web service connection to portfolio
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Web Service (Portfolio Connection)${NC}"
echo -e "${CYAN}========================================${NC}"

WEB_POD=$(kubectl get pods -n "$NAMESPACE" -l app=fks-web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$WEB_POD" ]; then
  echo -e "${BLUE}Pod: $WEB_POD${NC}"
  
  # Check environment variables
  echo -e "${BLUE}Checking environment variables...${NC}"
  if kubectl exec -n "$NAMESPACE" "$WEB_POD" -- env 2>/dev/null | grep -q "FKS_PORTFOLIO_URL"; then
    PORTFOLIO_URL=$(kubectl exec -n "$NAMESPACE" "$WEB_POD" -- env 2>/dev/null | grep FKS_PORTFOLIO_URL | cut -d= -f2)
    echo -e "  ${GREEN}✓ FKS_PORTFOLIO_URL=$PORTFOLIO_URL${NC}"
  else
    echo -e "  ${RED}✗ FKS_PORTFOLIO_URL not set${NC}"
  fi
  
  # Test connectivity
  echo -e "${BLUE}Testing connectivity to portfolio...${NC}"
  if kubectl exec -n "$NAMESPACE" "$WEB_POD" -- curl -s http://fks-portfolio:8012/health &> /dev/null; then
    echo -e "  ${GREEN}✓ Can connect to portfolio service${NC}"
  else
    echo -e "  ${YELLOW}  ⚠ Cannot connect to portfolio service${NC}"
  fi
else
  echo -e "${RED}✗ Web pod not found${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Health Check Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${GREEN}✓ Running: $RUNNING pods${NC}"
if [ "$FAILED" != "0" ]; then
  echo -e "${RED}✗ Failed: $FAILED pods${NC}"
  echo ""
  echo -e "${YELLOW}Failed pods:${NC}"
  kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "CrashLoopBackOff|Error|ImagePullBackOff" | awk '{print "  - " $1 " (" $3 ")"}'
fi
if [ "$PENDING" != "0" ]; then
  echo -e "${YELLOW}⚠ Pending: $PENDING pods${NC}"
fi

echo ""
echo -e "${BLUE}For detailed logs of failed pods, run:${NC}"
echo "  kubectl logs -n $NAMESPACE <pod-name>"
echo ""
echo -e "${BLUE}For pod events, run:${NC}"
echo "  kubectl describe pod -n $NAMESPACE <pod-name>"

