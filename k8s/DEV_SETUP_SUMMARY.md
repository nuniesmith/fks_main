# FKS Development Setup Summary

## ✅ Completed Setup

### 1. Kubernetes Environment
- **Namespace**: `fks-trading`
- **Status**: Deployed and running
- **Services**: All 14 FKS services deployed

### 2. Image Auto-Updater
Two mechanisms are in place to automatically update images from Docker Hub:

#### CronJob (Scheduled Updates)
- **Name**: `image-auto-updater`
- **Schedule**: Every 15 minutes (`*/15 * * * *`)
- **Function**: Checks Docker Hub for new images and updates deployments
- **Location**: `k8s/manifests/image-auto-updater.yaml`

#### Deployment (Continuous Updates)
- **Name**: `image-auto-updater-deployment`
- **Mode**: Runs continuously, checks every 15 minutes
- **Function**: Alternative to CronJob for continuous monitoring

**To check status:**
```bash
kubectl get cronjob image-auto-updater -n fks-trading
kubectl get deployment image-auto-updater-deployment -n fks-trading
kubectl logs -n fks-trading -l app=image-updater
```

### 3. Development Volumes (Live Code Changes)
All Python services now have development volumes mounted for live code changes:

**Services with volumes:**
- `fks-ai`
- `fks-analyze`
- `fks-api`
- `fks-app`
- `fks-data`
- `fks-monitor`
- `fks-portfolio`
- `fks-training`
- `fks-web`
- `fks-ninja`

**Volume Configuration:**
- **Mount Path**: `/app/src` (maps to service source code)
- **Source Path**: `/mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo/{service}/src`
- **Type**: `hostPath` (direct file system access)
- **Read/Write**: Read-write enabled for live changes

**Development Environment Variables:**
- `PYTHONUNBUFFERED=1`
- `PYTHONDONTWRITEBYTECODE=1`
- `DEVELOPMENT=true`
- `LIVE_RELOAD=true`

**To add volumes to a service:**
```bash
cd /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo/main
bash k8s/scripts/add-dev-volumes.sh fks-trading /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo
```

### 4. Image Management

**Local Images (Built):**
All services have been built locally and tagged as:
- `nuniesmith/fks:{service}-latest`

**Docker Hub Images:**
The auto-updater pulls from Docker Hub:
- `nuniesmith/fks:{service}-latest`

**To manually sync images:**
```bash
# Using run.sh script
cd /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo/main
./run.sh
# Choose option 12: Sync Images & Update Kubernetes Deployments
```

## 📋 Quick Commands

### Check Service Status
```bash
kubectl get pods -n fks-trading
kubectl get deployments -n fks-trading
kubectl get services -n fks-trading
```

### View Logs
```bash
kubectl logs -n fks-trading -l app=fks-api
kubectl logs -n fks-trading deployment/fks-api
```

### Restart a Service
```bash
kubectl rollout restart deployment/fks-api -n fks-trading
```

### Check Auto-Updater
```bash
# View CronJob
kubectl get cronjob image-auto-updater -n fks-trading

# View Deployment logs
kubectl logs -n fks-trading -l app=image-updater

# Manually trigger CronJob
kubectl create job --from=cronjob/image-auto-updater manual-update-$(date +%s) -n fks-trading
```

### Access Services
- **Web Interface**: http://fkstrading.xyz (via ingress)
- **Kubernetes Dashboard**: http://dashboard.fkstrading.xyz
- **Dashboard Token**: `k8s/dashboard-token.txt`

## 🔧 Development Workflow

1. **Make code changes** in your local repository:
   ```bash
   # Edit files in: /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo/{service}/src/
   ```

2. **Changes are automatically reflected** in running containers (if using development volumes)

3. **For services that need restart**:
   ```bash
   kubectl rollout restart deployment/fks-{service} -n fks-trading
   ```

4. **Build and push new images** (when ready):
   ```bash
   cd /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo/{service}
   docker build -t nuniesmith/fks:{service}-latest .
   docker push nuniesmith/fks:{service}-latest
   ```

5. **Auto-updater will pick up new images** within 15 minutes, or manually trigger:
   ```bash
   kubectl create job --from=cronjob/image-auto-updater manual-update -n fks-trading
   ```

## 📝 Notes

- **Secrets**: Ensure `fks-secrets` exists in namespace (contains DB passwords, API keys)
- **PostgreSQL**: May take a few minutes to be ready on first startup
- **Image Pull Policy**: Set to `IfNotPresent` to use local images when available
- **Volume Mounts**: Only work for services running on the same node (minikube single-node)

## 🐛 Troubleshooting

### Pods in CreateContainerConfigError
```bash
# Check if secrets exist
kubectl get secret fks-secrets -n fks-trading

# Create if missing
kubectl create secret generic fks-secrets \
  --from-literal=postgres-user=fks_user \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32) \
  --from-literal=django-secret-key=$(openssl rand -base64 64) \
  --from-literal=openai-api-key="" \
  -n fks-trading
```

### Images Not Updating
```bash
# Check auto-updater logs
kubectl logs -n fks-trading -l app=image-updater

# Manually update a deployment
kubectl set image deployment/fks-api api=nuniesmith/fks:api-latest -n fks-trading
kubectl rollout restart deployment/fks-api -n fks-trading
```

### Volume Mount Issues
```bash
# Verify volume mounts
kubectl describe pod -n fks-trading -l app=fks-api | grep -A 5 "Mounts"

# Re-add volumes
bash k8s/scripts/add-dev-volumes.sh fks-trading /mnt/c/Users/jordan/Nextcloud/code/repos/fks/repo
```

