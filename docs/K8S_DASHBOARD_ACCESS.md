# Kubernetes Dashboard Access Guide

**Date**: November 5, 2025  
**Status**: ✅ READY - Dashboard Configured

---

## Quick Access (Windows Browser)

### Method 1: NodePort Access (Direct) ⭐ RECOMMENDED

**URL**: `http://192.168.49.2:31124`

1. Open your Windows browser
2. Navigate to: **http://192.168.49.2:31124**
3. Select **Token** authentication method
4. Paste the token below

### Method 2: kubectl proxy (Alternative)

If NodePort doesn't work from Windows, use kubectl proxy:

```bash
# In WSL terminal:
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'

# Then access from Windows browser:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Authentication Token

**Copy this entire token** (including the full JWT):

```
eyJhbGciOiJSUzI1NiIsImtpZCI6InV6RGNVLVRCX0w0WmJYVWdKazMyWEJBVWJFWUtTX1NydWVmUE1zX1lSVTQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3Vud
C9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXNlY3JldCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbi11c2VyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiYWZkMjE4MzYtN2Q4Zi00YjEwLTliZDktZWQ2NDRjNDRiY2M5Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmVybmV0ZXMtZGFzaGJvYXJkOmFkbWluLXVzZXIifQ.YHz0QfIOckqb4WVsNFy26mdu5ZG6jUiF59Cw88E1-070m9aEZz0f58YnJ3VubJkgBV-Fb66Qh7FSHVisE6BaLjAPbZcc5LP8Od8qtJbmTWpqQwNmX9uLJgDeo8iL3vL-kzASA3-8_WdSzTA6pTlCBZcrV7kTkHqDTbtaM19RLry92kD_Ykrt20Q86SlWDaYR9TH5Uqe-SHcEPs58jY9gKuQVIUbh5KcFNc4RomtZoapwXPigz05qJORcJ95BeqklvPouG46WxyQGF4jQnfV_nw4vuZuJ0sQUHLZKAAdtXHefu2R2hfUajLIuP6BtqWwIgWIkcsOi-BcE1tfts85Sqg
```

**Or retrieve it anytime with**:
```bash
cat /tmp/k8s-dashboard-token.txt
```

---

## What You Can Do in the Dashboard

### Overview
- ✅ View all namespaces and resources
- ✅ Monitor pod status and logs
- ✅ Check resource usage (CPU/Memory)
- ✅ View deployments, services, configmaps, secrets
- ✅ Execute commands in pods (terminal access)

### FKS-Specific Resources

Navigate to **Namespace: fks-trading** to see:

1. **Workloads → Deployments**
   - `fks-execution` (2 replicas)
   - `prometheus` (1 replica)
   - `grafana` (1 replica)
   - `alertmanager` (1 replica)

2. **Workloads → Pods**
   - Click any pod to view:
     - Logs (see webhook requests, security events)
     - Metrics (CPU/memory usage)
     - Events (pod lifecycle)
     - Terminal (exec into container)

3. **Service → Services**
   - `fks-execution` (ClusterIP port 8000)
   - `prometheus` (ClusterIP port 9090)
   - `grafana` (ClusterIP port 3000)

4. **Config and Storage → ConfigMaps**
   - `execution-config` (CCXT configuration)
   - `prometheus-config`

5. **Config and Storage → Secrets**
   - `fks-secrets` (API keys - base64 encoded)

---

## Dashboard Features to Explore

### 1. Real-Time Pod Logs
```
Namespace: fks-trading
→ Workloads → Pods → fks-execution-xxxxx
→ Logs tab
→ See webhook requests, security middleware events
```

### 2. Resource Metrics
```
Namespace: fks-trading
→ Workloads → Pods → fks-execution-xxxxx
→ Metrics tab (requires metrics-server, already enabled)
→ View CPU/memory usage graphs
```

### 3. Execute Commands in Pods
```
Namespace: fks-trading
→ Workloads → Pods → fks-execution-xxxxx
→ Exec tab
→ Run: python /tmp/load_test.py
```

### 4. Edit Resources
```
Namespace: fks-trading
→ Workloads → Deployments → fks-execution
→ Edit icon (top right)
→ Modify replicas, environment vars, etc.
```

### 5. View Events
```
Namespace: fks-trading
→ Cluster → Events
→ See pod scheduling, image pulls, crashes, etc.
```

---

## Troubleshooting

### Issue: "Connection refused" on 192.168.49.2:31124

**Solution 1**: Check minikube tunnel
```bash
minikube tunnel
# Keep this running in a separate terminal
```

**Solution 2**: Use kubectl proxy
```bash
kubectl proxy --address='0.0.0.0' --accept-hosts='.*' &
# Access: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Solution 3**: Use minikube service
```bash
minikube service kubernetes-dashboard -n kubernetes-dashboard --url
# Use the URL it provides
```

### Issue: "Unauthorized" after entering token

**Regenerate Token**:
```bash
kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

### Issue: "Not Found" or 404 error

**Verify Dashboard is Running**:
```bash
kubectl get pods -n kubernetes-dashboard
# Both pods should be Running
```

**Restart Dashboard**:
```bash
kubectl rollout restart deployment/kubernetes-dashboard -n kubernetes-dashboard
```

---

## Service Account Details

**Account**: `admin-user`  
**Namespace**: `kubernetes-dashboard`  
**Role**: `cluster-admin` (full access)  
**Token Type**: `kubernetes.io/service-account-token`

**View Account Info**:
```bash
kubectl get sa admin-user -n kubernetes-dashboard
kubectl get clusterrolebinding admin-user
```

---

## Security Notes

⚠️ **Important**: This token has **cluster-admin** privileges (full access to all resources).

**For production**:
1. Create more restrictive RBAC roles
2. Use namespace-specific service accounts
3. Enable audit logging
4. Rotate tokens regularly
5. Use OIDC/SSO authentication instead of tokens

**Current Setup**: Safe for local development on minikube.

---

## Useful Commands

```bash
# Get dashboard URL with minikube
minikube dashboard --url

# Port-forward dashboard (alternative access)
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443

# View dashboard service details
kubectl get svc -n kubernetes-dashboard

# View dashboard pods
kubectl get pods -n kubernetes-dashboard

# Get current NodePort
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}'

# Retrieve token
cat /tmp/k8s-dashboard-token.txt
```

---

## Next Steps After Dashboard Access

Once you can access the dashboard:

1. **Explore FKS Resources**
   - Check `fks-trading` namespace
   - View pod logs to see webhook processing
   - Monitor resource usage

2. **Setup Grafana** (Task 2)
   - Port-forward Grafana
   - Import performance dashboards
   - Visualize load test metrics

3. **Start Phase 6** (NinjaTrader/MT5 Integration)
   - Define ExecutionPlugin trait
   - Migrate fks_ninja code
   - Implement C# bindings

---

## Dashboard Version

- **K8s Dashboard**: v2.7.0
- **Metrics Scraper**: v1.0.8
- **Metrics Server**: v0.8.0 (enabled)
- **Minikube**: v1.37.0
- **Kubernetes**: v1.28.0

---

**Document Created**: November 5, 2025  
**Access Token Valid**: Until service account is deleted  
**NodePort**: 31124 (stable until service is recreated)
