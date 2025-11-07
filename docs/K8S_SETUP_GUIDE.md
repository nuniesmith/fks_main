# FKS Trading Platform - Complete K8s Setup Guide

**Date**: November 6, 2025  
**Status**: ✅ READY - Production Setup with Self-Signed SSL

---

## 🎯 Quick Start (One Command)

```bash
cd /home/jordan/Documents/code/fks
chmod +x k8s/scripts/setup-k8s-environment.sh
./k8s/scripts/setup-k8s-environment.sh
```

This script will:
1. ✅ Install kubectl and minikube
2. ✅ Start minikube cluster (4 CPUs, 8GB RAM)
3. ✅ Deploy Kubernetes Dashboard with admin token
4. ✅ Generate self-signed SSL certificates for `*.fkstrading.xyz`
5. ✅ Create TLS secret in K8s
6. ✅ Configure `/etc/hosts` for local DNS
7. ✅ Display access information

**Estimated Time**: 5-10 minutes

---

## 📋 What Gets Set Up

### 1. Minikube Cluster
- **Driver**: Docker
- **CPUs**: 4 cores
- **Memory**: 8GB RAM
- **Disk**: 50GB
- **Addons**: ingress, metrics-server, dashboard

### 2. Kubernetes Dashboard
- **Version**: v2.7.0
- **Access**: NodePort (http://192.168.49.2:XXXXX)
- **Auth**: Service account token with cluster-admin
- **Token Location**: `/tmp/k8s-dashboard-token.txt`

### 3. SSL Certificates (Self-Signed)
- **Domain**: `*.fkstrading.xyz`
- **Validity**: 365 days
- **SANs**: 
  - fkstrading.xyz
  - *.fkstrading.xyz
  - grafana.fkstrading.xyz
  - prometheus.fkstrading.xyz
  - alertmanager.fkstrading.xyz
  - execution.fkstrading.xyz
  - api.fkstrading.xyz
  - app.fkstrading.xyz
- **Location**: `/tmp/fks-certs/`
- **K8s Secret**: `fkstrading-tls` (namespace: fks-trading)

### 4. DNS Configuration
Entries added to `/etc/hosts`:
```
192.168.49.2 fkstrading.xyz
192.168.49.2 grafana.fkstrading.xyz
192.168.49.2 prometheus.fkstrading.xyz
192.168.49.2 alertmanager.fkstrading.xyz
192.168.49.2 api.fkstrading.xyz
192.168.49.2 app.fkstrading.xyz
192.168.49.2 execution.fkstrading.xyz
```

---

## 🚀 After Setup - Deploy FKS Platform

Once the environment is ready, deploy Phase 5:

```bash
cd /home/jordan/Documents/code/fks

# Copy and configure secrets
cp k8s/manifests/secrets.yaml.template k8s/manifests/secrets.yaml
nano k8s/manifests/secrets.yaml  # Fill in API keys

# Deploy FKS Platform
chmod +x k8s/scripts/deploy-phase5.sh
./k8s/scripts/deploy-phase5.sh
```

This deploys:
- ✅ Execution service (2 replicas with HPA)
- ✅ Prometheus (50Gi storage)
- ✅ Grafana (10Gi storage)
- ✅ Alertmanager (Slack integration)
- ✅ Ingress with SSL

---

## 🌐 Access Services

### Kubernetes Dashboard

```bash
# Get token
cat /tmp/k8s-dashboard-token.txt

# Get dashboard URL
MINIKUBE_IP=$(minikube ip)
NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
echo "Dashboard: http://${MINIKUBE_IP}:${NODEPORT}"

# Open in browser and paste token
```

### FKS Services (After Phase 5 Deployment)

**Option 1: HTTPS via Ingress** (recommended)
```bash
# Access services via HTTPS with self-signed certs
# (Browser will warn about self-signed cert - this is expected)
https://grafana.fkstrading.xyz
https://prometheus.fkstrading.xyz
https://alertmanager.fkstrading.xyz
https://execution.fkstrading.xyz/health
```

**Option 2: Port Forwarding** (no SSL warnings)
```bash
# Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:3000
# Access: http://localhost:3000

# Prometheus
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
# Access: http://localhost:9090

# Execution Service
kubectl port-forward -n fks-trading svc/fks-execution 8000:8000
# Access: http://localhost:8000/health
```

---

## 🔐 SSL Certificate Details

### View Certificate Info
```bash
# View certificate details
openssl x509 -in /tmp/fks-certs/tls.crt -text -noout

# Check expiration
openssl x509 -in /tmp/fks-certs/tls.crt -noout -dates

# Verify SANs
openssl x509 -in /tmp/fks-certs/tls.crt -text -noout | grep DNS
```

### Trust Self-Signed Certificate (Optional)

**Linux (Chrome/Firefox)**:
```bash
# Copy to system trust store
sudo cp /tmp/fks-certs/tls.crt /usr/local/share/ca-certificates/fkstrading.crt
sudo update-ca-certificates
```

**Firefox Only**:
1. Visit https://grafana.fkstrading.xyz
2. Click "Advanced" → "Accept the Risk and Continue"
3. Certificate will be trusted for this domain

### Migrate to Let's Encrypt (Later)

When ready for production with real domain:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Update ingress to use cert-manager
# (Ingress already configured - just update DNS to point to your public IP)
```

---

## 🛠️ Troubleshooting

### Minikube Won't Start

```bash
# Check Docker
docker ps

# Clean and restart
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# If Docker driver fails, try VirtualBox
minikube start --driver=virtualbox --cpus=4 --memory=8192
```

### Dashboard Not Accessible

```bash
# Check dashboard pods
kubectl get pods -n kubernetes-dashboard

# Restart dashboard
kubectl rollout restart deployment/kubernetes-dashboard -n kubernetes-dashboard

# Re-expose NodePort
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Get new URL
MINIKUBE_IP=$(minikube ip)
NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
echo "http://${MINIKUBE_IP}:${NODEPORT}"
```

### SSL Certificate Errors

```bash
# Verify TLS secret exists
kubectl get secret fkstrading-tls -n fks-trading

# Recreate if needed
kubectl delete secret fkstrading-tls -n fks-trading
kubectl create secret tls fkstrading-tls \
    --cert=/tmp/fks-certs/tls.crt \
    --key=/tmp/fks-certs/tls.key \
    -n fks-trading

# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

### DNS Not Resolving

```bash
# Check /etc/hosts
cat /etc/hosts | grep fkstrading

# Re-add entries
MINIKUBE_IP=$(minikube ip)
sudo bash -c "cat >> /etc/hosts <<EOF

# FKS Trading Platform (minikube)
$MINIKUBE_IP fkstrading.xyz
$MINIKUBE_IP grafana.fkstrading.xyz
$MINIKUBE_IP prometheus.fkstrading.xyz
$MINIKUBE_IP alertmanager.fkstrading.xyz
$MINIKUBE_IP execution.fkstrading.xyz
EOF"

# Test DNS
ping -c 1 grafana.fkstrading.xyz
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Enable ingress addon if missing
minikube addons enable ingress

# Verify ingress resources
kubectl get ingress -n fks-trading

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

---

## 📊 Verification Checklist

After running setup script:

- [ ] Minikube running: `minikube status`
- [ ] Kubectl works: `kubectl cluster-info`
- [ ] Dashboard accessible: `http://$(minikube ip):XXXXX`
- [ ] Dashboard token saved: `cat /tmp/k8s-dashboard-token.txt`
- [ ] SSL certs generated: `ls -lh /tmp/fks-certs/`
- [ ] TLS secret created: `kubectl get secret fkstrading-tls -n fks-trading`
- [ ] /etc/hosts configured: `cat /etc/hosts | grep fkstrading`
- [ ] Domains resolve: `ping -c 1 grafana.fkstrading.xyz`

After deploying Phase 5:

- [ ] All pods running: `kubectl get pods -n fks-trading`
- [ ] Services exposed: `kubectl get svc -n fks-trading`
- [ ] Ingress configured: `kubectl get ingress -n fks-trading`
- [ ] Grafana accessible: `https://grafana.fkstrading.xyz`
- [ ] Prometheus accessible: `https://prometheus.fkstrading.xyz`
- [ ] Execution health check: `curl -k https://execution.fkstrading.xyz/health`

---

## 🔄 Useful Commands

### Cluster Management
```bash
# Start minikube
minikube start

# Stop minikube
minikube stop

# Delete cluster (clean slate)
minikube delete

# SSH into minikube node
minikube ssh

# Get cluster info
kubectl cluster-info
kubectl get nodes
```

### Dashboard Management
```bash
# Open dashboard (auto port-forward)
minikube dashboard

# Get dashboard token
kubectl get secret admin-user-secret -n kubernetes-dashboard \
  -o jsonpath='{.data.token}' | base64 -d

# Access dashboard via proxy
kubectl proxy
# Then: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### SSL/TLS Management
```bash
# Regenerate certificates
cd /tmp/fks-certs
openssl genrsa -out tls.key 2048
openssl req -new -x509 -days 365 -key tls.key -out tls.crt

# Update K8s secret
kubectl create secret tls fkstrading-tls \
    --cert=tls.crt --key=tls.key \
    -n fks-trading --dry-run=client -o yaml | kubectl apply -f -
```

### Logs and Debugging
```bash
# View all pods
kubectl get pods -A

# View pod logs
kubectl logs -n fks-trading <pod-name> -f

# Describe pod (events, errors)
kubectl describe pod -n fks-trading <pod-name>

# Execute in pod
kubectl exec -it -n fks-trading <pod-name> -- /bin/bash

# View ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
```

---

## 📚 Next Steps

1. ✅ **Environment Setup Complete** (this guide)
2. 🔄 **Deploy Phase 5**: `./k8s/scripts/deploy-phase5.sh`
3. 📊 **Configure Grafana**: Import dashboards, set up datasources
4. 🔔 **Configure Alerts**: Update Alertmanager with Slack webhook
5. 🧪 **Test Pipeline**: Send test webhooks to execution service
6. 📈 **Monitor Performance**: Use Grafana dashboards
7. 🚀 **Production Migration**: Switch to Let's Encrypt, cloud K8s

---

## 🎯 Project Context

**Current Phase**: Phase 5 Complete (Monitoring & Deployment)  
**Next Phase**: Phase 6 (NinjaTrader/MT5 Integration)

**Completed**:
- ✅ Phase 1: Codebase cleanup
- ✅ Phase 2: AI enhancements (TimeCopilot, Lag-Llama)
- ✅ Phase 3: CCXT integration, webhooks, security
- ✅ Phase 4: Prometheus metrics, Grafana dashboards
- ✅ Phase 5: K8s deployment, monitoring stack

**Documentation**:
- `/docs/PHASE_3_COMPLETE.md` - Execution pipeline (168 tests passing)
- `/docs/PHASE_4_3_COMPLETE.md` - Monitoring validation (8/8 checks)
- `/docs/PHASE_5_COMPLETE.md` - K8s deployment manifests
- `/docs/FKSTRADING_XYZ_SETUP.md` - Domain configuration
- `/docs/K8S_DASHBOARD_ACCESS.md` - Dashboard token details

---

**Created**: November 6, 2025  
**Last Updated**: November 6, 2025  
**Author**: FKS Platform Team  
**Status**: ✅ Production Ready (Local)
