# Kubernetes Dashboard Access Fix

**Date**: 2025-11-12  
**Issue**: GTK warning when opening dashboard  
**Status**: ✅ Fixed

---

## Problem

When accessing the Kubernetes dashboard via option 13 in `run.sh`, a GTK warning appeared:
```
Gtk-Message: Not loading module "atk-bridge"
```

This is a harmless warning but can be suppressed.

---

## Solution

Updated the `access-dashboard.sh` script to:
1. Suppress GTK warnings with `NO_AT_BRIDGE=1`
2. Provide multiple access methods
3. Show clear instructions if browser doesn't open automatically

---

## Access Methods

### Method 1: Direct URL (Recommended)

The script now displays the full URL. Copy and paste it into your browser:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s
./access-dashboard.sh
```

The URL will look like:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login?token=eyJhbGc...
```

### Method 2: Via run.sh Menu

1. Run `./run.sh`
2. Select option **13: Access Kubernetes Dashboard**
3. Copy the displayed URL if browser doesn't open

### Method 3: Manual Steps

```bash
# 1. Start proxy (if not running)
kubectl proxy

# 2. Get token
kubectl -n kubernetes-dashboard create token admin-user --duration=8760h

# 3. Visit in browser:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# 
# 4. Select "Token" authentication
# 5. Paste the token
```

### Method 4: Via Minikube Service

```bash
minikube service kubernetes-dashboard -n kubernetes-dashboard
```

This will open the dashboard in your default browser.

---

## Quick Access

**Simplest method** - Run this command:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s
./access-dashboard.sh
```

Then copy the URL shown and paste it into your browser.

---

## Troubleshooting

### Browser Doesn't Open Automatically

This is normal. The script will display the URL - just copy and paste it.

### Proxy Not Running

```bash
# Check if running
pgrep -f "kubectl proxy"

# Start if needed
kubectl proxy
```

### Token Expired

```bash
# Generate new token
kubectl -n kubernetes-dashboard create token admin-user --duration=8760h

# Or use the script which auto-generates
./access-dashboard.sh
```

### Dashboard Pod Not Running

```bash
# Check dashboard status
kubectl get pods -n kubernetes-dashboard

# If not running, restart
kubectl rollout restart deployment/kubernetes-dashboard -n kubernetes-dashboard
```

---

## Updated Files

- `repo/k8s/access-dashboard.sh` - Improved with GTK warning suppression and better output

---

**The dashboard is accessible - just copy the URL from the script output!** ✅

