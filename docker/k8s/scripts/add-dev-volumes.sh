#!/bin/bash
# Add development volumes to FKS service deployments for live code changes

set -e

NAMESPACE="${1:-fks-trading}"
REPO_PATH="${2:-/mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo}"

echo "Adding development volumes to FKS services..."
echo "Namespace: $NAMESPACE"
echo "Source path: $REPO_PATH"

SERVICES=("ai" "analyze" "api" "app" "data" "monitor" "portfolio" "training" "web" "ninja")

for service in "${SERVICES[@]}"; do
    DEPLOYMENT_NAME="fks-$service"
    
    # Check if deployment exists
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
        DEPLOYMENT_NAME="$service"
        if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
            echo "⚠️  Deployment not found: $service (tried: fks-$service, $service)"
            continue
        fi
    fi
    
    echo "Processing: $DEPLOYMENT_NAME"
    
    # Get current deployment
    kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o json > /tmp/deployment.json
    
    # Add volume mount to container
    # For Python services, mount source code
    if [[ " ai analyze api app data monitor portfolio training web ninja " =~ " $service " ]]; then
        SERVICE_SRC_PATH="$REPO_PATH/$service/src"
        
        # Add volume mount using kubectl patch
        kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p="[
            {
                \"op\": \"add\",
                \"path\": \"/spec/template/spec/containers/0/volumeMounts\",
                \"value\": [
                    {
                        \"name\": \"source-code\",
                        \"mountPath\": \"/app/src\",
                        \"readOnly\": false
                    }
                ]
            },
            {
                \"op\": \"add\",
                \"path\": \"/spec/template/spec/volumes\",
                \"value\": [
                    {
                        \"name\": \"source-code\",
                        \"hostPath\": {
                            \"path\": \"$SERVICE_SRC_PATH\",
                            \"type\": \"DirectoryOrCreate\"
                        }
                    }
                ]
            }
        ]" || echo "  ⚠️  Failed to patch $DEPLOYMENT_NAME (may already have volumes)"
        
        # Add dev config env vars
        kubectl set env deployment/"$DEPLOYMENT_NAME" \
            -n "$NAMESPACE" \
            --from=configmap/fks-dev-config || true
    fi
    
    echo "  ✅ Updated $DEPLOYMENT_NAME with development volumes"
done

echo ""
echo "✅ Development volumes added to all services"
echo "Note: Services will need to be restarted to pick up volume changes"

