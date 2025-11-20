# Development Volume Mounts for Kubernetes

This guide explains how to set up development volume mounts for hot-reloading code changes in your Kubernetes deployments without rebuilding Docker images.

## Overview

Development volume mounts allow you to:
- Edit code locally and see changes immediately in running containers
- Debug without rebuilding Docker images
- Speed up development iteration

## Prerequisites

- Minikube running
- Kubernetes cluster accessible
- Code repository cloned locally

## Quick Start

### 1. Start Development Mounts

```bash
cd repo/main/k8s
./setup-dev-mounts.sh
```

This script will:
- Mount your local code directories into Minikube
- Start background processes to maintain the mounts
- Create mount points at `/mnt/fks-dev/` in the Minikube VM

### 2. Apply Volume Mounts to Deployments

#### Option A: Using the Patch Script (Recommended for existing deployments)

```bash
./patch-web-dev-mounts.sh
```

This patches the existing `fks-web` deployment to include development mounts.

#### Option B: Using Helm with Dev Values

```bash
helm upgrade --install fks-platform ./docker/k8s/charts/fks-platform \
  -n fks-trading --create-namespace \
  -f ./docker/k8s/charts/fks-platform/values-dev.yaml
```

#### Option C: Manual Patch

```bash
kubectl patch deployment fks-web -n fks-trading --patch-file dev-mount-patch.yaml
```

### 3. Verify Mounts

```bash
# Check if mounts are working
kubectl exec -n fks-trading <web-pod-name> -- ls -la /app/src

# Edit a file locally and check if it's reflected in the pod
echo "# Test" >> repo/web/src/config/urls.py
kubectl exec -n fks-trading <web-pod-name> -- tail -1 /app/src/config/urls.py
```

## Stopping Development Mounts

When you're done developing:

```bash
./stop-dev-mounts.sh
```

This stops all background mount processes.

## Configuration

### Mount Paths

The default mount paths are:
- **Web Service**: `/home/jordan/Nextcloud/code/repos/fks/repo/web/src` → `/mnt/fks-dev/web/src` → `/app/src` (container)
- **API Service**: `/home/jordan/Nextcloud/code/repos/fks/repo/api/src` → `/mnt/fks-dev/api/src` → `/app/src` (container)
- **App Service**: `/home/jordan/Nextcloud/code/repos/fks/repo/app/src` → `/mnt/fks-dev/app/src` → `/app/src` (container)

### Customizing Mounts

Edit `values-dev.yaml` to customize mount paths:

```yaml
fks_web:
  devMounts:
    enabled: true
    mounts:
      - name: web-src
        hostPath: /mnt/fks-dev/web/src
        containerPath: /app/src
        readOnly: false
      - name: web-templates
        hostPath: /mnt/fks-dev/web/src/templates
        containerPath: /app/src/templates
        readOnly: false
```

### Adding Mounts for Other Services

To add mounts for other services, update `values-dev.yaml`:

```yaml
fks_api:
  devMounts:
    enabled: true
    mounts:
      - name: api-src
        hostPath: /mnt/fks-dev/api/src
        containerPath: /app/src
        readOnly: false
```

Then update `setup-dev-mounts.sh` to include the new service.

## Troubleshooting

### Mounts Not Working

1. **Check if minikube mount is running:**
   ```bash
   ps aux | grep "minikube mount"
   ```

2. **Verify mount paths exist in Minikube:**
   ```bash
   minikube ssh
   ls -la /mnt/fks-dev/
   ```

3. **Check pod volume mounts:**
   ```bash
   kubectl describe pod <pod-name> -n fks-trading | grep -A 10 "Mounts:"
   ```

### Permission Issues

If you encounter permission issues:

1. **Check file ownership:**
   ```bash
   ls -la repo/web/src/
   ```

2. **Ensure container runs as correct user:**
   The deployment uses `runAsUser: 1000` which should match your local user.

3. **Fix permissions if needed:**
   ```bash
   chown -R 1000:1000 repo/web/src/
   ```

### Changes Not Reflecting

1. **Restart the application process:**
   - For Django: The development server should auto-reload, but you may need to restart gunicorn
   - For other services: May require a pod restart

2. **Force pod restart:**
   ```bash
   kubectl rollout restart deployment/fks-web -n fks-trading
   ```

3. **Check if files are actually mounted:**
   ```bash
   kubectl exec -n fks-trading <pod-name> -- cat /app/src/config/urls.py
   ```

## Production Considerations

⚠️ **Never use development mounts in production!**

- Development mounts are only enabled when `global.environment: development` in Helm values
- The deployment template checks for this before applying hostPath volumes
- In production, use regular Docker images without volume mounts

## Architecture

```
Local Filesystem                    Minikube VM                    Container
─────────────────                  ───────────                    ─────────
/home/jordan/.../repo/web/src  →   /mnt/fks-dev/web/src      →   /app/src
     (minikube mount)                    (hostPath volume)
```

The flow:
1. `minikube mount` creates a mount from host to Minikube VM
2. Kubernetes `hostPath` volume mounts from Minikube VM to container
3. Code changes in local filesystem are immediately available in container

## Notes

- Mounts run as background processes - they persist until stopped
- Multiple services can share the same mount point
- Read-only mounts can be used for shared libraries or configs
- Changes to Python files may require application restart (depends on framework)

