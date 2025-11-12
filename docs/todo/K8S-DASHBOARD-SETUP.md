# Kubernetes Dashboard Setup Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Setup and access Kubernetes Dashboard for FKS platform management

---

## 🚀 Quick Setup

### Step 1: Install Dashboard

```bash
cd repo/main
./scripts/setup-k8s-dashboard.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, cluster access)
2. ✅ Install Kubernetes Dashboard (v2.7.0)
3. ✅ Create admin user with cluster-admin privileges
4. ✅ Generate and save access token
5. ✅ Display access instructions

---

## 📊 Access Methods

### Method 1: kubectl proxy (Recommended for Local Access)

```bash
# Start proxy in background
kubectl proxy &

# Access dashboard
# URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Steps**:
1. Run `kubectl proxy` (keep it running)
2. Open the URL above in your browser
3. Choose "Token" authentication
4. Paste token from `repo/main/k8s/dashboard-token.txt`

**Stop proxy**:
```bash
pkill -f "kubectl proxy"
```

### Method 2: Port-Forwarding

```bash
# Port-forward dashboard service
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443

# Access dashboard
# URL: https://localhost:8443
```

**Steps**:
1. Run the port-forward command (keep it running)
2. Open https://localhost:8443 in your browser
3. Accept self-signed certificate warning
4. Choose "Token" authentication
5. Paste token from `repo/main/k8s/dashboard-token.txt`

### Method 3: NodePort (Minikube)

```bash
# Expose dashboard via NodePort
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Get NodePort
NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)

# Access dashboard
# URL: http://${MINIKUBE_IP}:${NODEPORT}
```

**Steps**:
1. Run the commands above
2. Open the URL in your browser
3. Choose "Token" authentication
4. Paste token from `repo/main/k8s/dashboard-token.txt`

### Method 4: Ingress (Domain Access)

If you want to access dashboard via your domain (e.g., dashboard.fkstrading.xyz):

```bash
# Apply ingress configuration
kubectl apply -f repo/main/k8s/manifests/dashboard-ingress.yaml

# Access dashboard
# URL: http://dashboard.fkstrading.xyz
```

**Note**: Requires NGINX Ingress Controller and domain DNS configuration.

---

## 🔑 Getting the Token

### Automatic (via script)

The setup script automatically saves the token to:
```
repo/main/k8s/dashboard-token.txt
```

### Manual

```bash
# Get token from secret
kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d

# Or get token from service account
kubectl -n kubernetes-dashboard create token admin-user
```

---

## 🧪 Verify Dashboard Installation

```bash
# Check dashboard namespace
kubectl get namespace kubernetes-dashboard

# Check dashboard pods
kubectl get pods -n kubernetes-dashboard

# Check dashboard service
kubectl get svc -n kubernetes-dashboard

# Check admin user
kubectl get serviceaccount admin-user -n kubernetes-dashboard
```

---

## 🔧 Troubleshooting

### Dashboard Not Accessible

1. **Check dashboard pods are running**:
   ```bash
   kubectl get pods -n kubernetes-dashboard
   ```

2. **Check dashboard service**:
   ```bash
   kubectl get svc -n kubernetes-dashboard
   ```

3. **Check dashboard logs**:
   ```bash
   kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
   ```

### Token Not Working

1. **Regenerate token**:
   ```bash
   # Delete old secret
   kubectl delete secret admin-user-secret -n kubernetes-dashboard
   
   # Recreate secret
   kubectl apply -f repo/main/k8s/manifests/dashboard-admin-user.yaml
   
   # Wait a few seconds, then get token
   kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
   ```

2. **Check service account**:
   ```bash
   kubectl get serviceaccount admin-user -n kubernetes-dashboard
   kubectl get clusterrolebinding admin-user
   ```

### Proxy Not Working

1. **Check if proxy is running**:
   ```bash
   ps aux | grep "kubectl proxy"
   ```

2. **Check proxy logs**:
   ```bash
   # Start proxy in foreground to see errors
   kubectl proxy
   ```

3. **Check firewall**:
   ```bash
   # Ensure port 8001 is not blocked
   netstat -an | grep 8001
   ```

---

## 📋 Dashboard Features

### What You Can Do

- ✅ View all namespaces and resources
- ✅ View pod logs and events
- ✅ View service endpoints
- ✅ View resource usage (CPU, memory)
- ✅ View and manage deployments
- ✅ View and manage services
- ✅ View and manage ingress
- ✅ View and manage secrets and configmaps
- ✅ View cluster nodes
- ✅ View cluster events

### FKS Platform Resources

Once dashboard is accessible, you can:
- Monitor FKS platform pods in `fks-trading` namespace
- View logs for all FKS services
- Check resource usage and scaling
- Monitor ingress and service endpoints
- View and manage secrets

---

## 🚀 Quick Commands

### Start Dashboard Access

```bash
# Method 1: kubectl proxy (recommended)
kubectl proxy &

# Method 2: Port-forwarding
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443
```

### Get Token

```bash
# From saved file
cat repo/main/k8s/dashboard-token.txt

# Or get fresh token
kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

### Check Dashboard Status

```bash
# Check pods
kubectl get pods -n kubernetes-dashboard

# Check service
kubectl get svc -n kubernetes-dashboard

# Check ingress (if configured)
kubectl get ingress -n kubernetes-dashboard
```

### View Logs

```bash
# Dashboard logs
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard

# Admin user secret
kubectl describe secret admin-user-secret -n kubernetes-dashboard
```

---

## 📚 Related Documentation

- `K8S_DASHBOARD_ACCESS.md` - Original dashboard access guide
- `BITCOIN-FKSTRADING-DEPLOYMENT-READY.md` - FKS platform deployment
- `BITCOIN-K8S-QUICK-START.md` - Kubernetes quick start

---

## 🎉 Summary

### Setup Complete
- ✅ Kubernetes Dashboard installed
- ✅ Admin user created with cluster-admin privileges
- ✅ Access token generated and saved
- ✅ Multiple access methods configured

### Access Methods
- ✅ kubectl proxy (local access)
- ✅ Port-forwarding (local HTTPS access)
- ✅ NodePort (minikube access)
- ✅ Ingress (domain access - optional)

### Token Location
- ✅ Saved to: `repo/main/k8s/dashboard-token.txt`

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/setup-k8s-dashboard.sh` and then `kubectl proxy &`!

---

**Happy Monitoring!** 🚀

