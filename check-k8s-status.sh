#!/usr/bin/env bash
# Quick K8s status check for FKS Trading Platform

NAMESPACE="fks-trading"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      FKS K8s Status Check • fkstrading.xyz               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Count pods by status
echo "📊 Pod Status Summary:"
TOTAL=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
RUNNING=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
CRASH=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "CrashLoopBackOff" || echo 0)
PENDING=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Pending" || echo 0)
COMPLETED=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Completed" || echo 0)

echo "  Total Pods:       $TOTAL"
echo "  ✓ Running:        $RUNNING"
echo "  ✗ CrashLoopBackOff: $CRASH"
echo "  ⏸ Pending:        $PENDING"
echo "  ✓ Completed:      $COMPLETED"
echo ""

# List services by status
echo "🎯 Service Status:"
echo ""
echo "✅ HEALTHY SERVICES:"
kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null | \
  jq -r '.items[] | select(.status.phase == "Running" and 
    (.status.containerStatuses[]? | select(.ready == true))) |
    .metadata.labels.app // .metadata.name' | \
  grep "^fks-" | sed 's/^fks-//' | sort -u | sed 's/^/  • /'

echo ""
echo "❌ FAILING SERVICES:"
kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null | \
  jq -r '.items[] | select(.status.phase != "Running" or 
    (.status.containerStatuses[]? | select(.ready == false))) |
    (.metadata.labels.app // .metadata.name) + " (" + .status.phase + ")"' | \
  grep "^fks-" | sed 's/^fks-//' | sort -u | sed 's/^/  • /'

echo ""
echo "📋 Core Services Check:"
CORE_SERVICES=("api" "app" "data" "execution" "portfolio" "web" "ai" "training")
for svc in "${CORE_SERVICES[@]}"; do
  STATUS=$(kubectl get pods -n "$NAMESPACE" -l "app=fks-$svc" -o json 2>/dev/null | \
    jq -r '.items[0].status.phase // "Missing"')
  READY=$(kubectl get pods -n "$NAMESPACE" -l "app=fks-$svc" -o json 2>/dev/null | \
    jq -r '.items[0].status.containerStatuses[0].ready // false')
  
  if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ]; then
    echo "  ✓ $svc"
  elif [ "$STATUS" = "Missing" ]; then
    echo "  ⚠ $svc (no deployment)"
  else
    echo "  ✗ $svc ($STATUS)"
  fi
done

echo ""
echo "🔗 Quick Actions:"
echo "  • View detailed status:  kubectl get pods -n fks-trading -o wide"
echo "  • Check logs:            kubectl logs -n fks-trading <pod-name>"
echo "  • Fix failing services:  ./fix-k8s-services.sh"
echo "  • Open dashboard:        ./k8s/access-dashboard.sh"
echo ""
