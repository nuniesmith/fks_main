# FKS Trading Platform - fkstrading.xyz Production Setup

**Domain**: fkstrading.xyz  
**Status**: ✅ Ingress configured, awaiting DNS  
**Last Updated**: November 3, 2025

---

## 🎯 Quick Summary

Your Kubernetes cluster is configured to serve the FKS Trading Platform at:

- **Main**: https://fkstrading.xyz
- **API**: https://api.fkstrading.xyz  
- **App**: https://app.fkstrading.xyz
- **Data**: https://data.fkstrading.xyz
- **Execution**: https://execution.fkstrading.xyz
- **Grafana**: https://grafana.fkstrading.xyz
- **Prometheus**: https://prometheus.fkstrading.xyz

**Current Cluster IP**: `192.168.49.2` (minikube - for production, use LoadBalancer IP)

---

## 📋 DNS Configuration Checklist

### Option 1: Production Cloud Deployment

**Step 1**: Get your LoadBalancer IP
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

**Step 2**: Add DNS A records at your registrar:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | `<YOUR_LB_IP>` | 300 |
| A | api | `<YOUR_LB_IP>` | 300 |
| A | app | `<YOUR_LB_IP>` | 300 |
| A | data | `<YOUR_LB_IP>` | 300 |
| A | execution | `<YOUR_LB_IP>` | 300 |
| A | grafana | `<YOUR_LB_IP>` | 300 |
| A | prometheus | `<YOUR_LB_IP>` | 300 |

**Or use wildcard** (recommended):
```
A    @    <YOUR_LB_IP>    300
A    *    <YOUR_LB_IP>    300
```

### Option 2: Local Development (minikube)

```bash
# Get IP
minikube ip  # 192.168.49.2

# Add to /etc/hosts
sudo bash -c 'cat >> /etc/hosts << EOF
192.168.49.2 fkstrading.xyz
192.168.49.2 api.fkstrading.xyz
192.168.49.2 app.fkstrading.xyz
192.168.49.2 data.fkstrading.xyz
192.168.49.2 execution.fkstrading.xyz
192.168.49.2 grafana.fkstrading.xyz
192.168.49.2 prometheus.fkstrading.xyz
EOF'
```

---

## 🔐 TLS Certificate Setup

The Ingress is configured for automatic TLS via **cert-manager**.

### Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
```

### Create Let's Encrypt Issuer

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com  # CHANGE THIS
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Verify Certificate

```bash
# Wait 2-5 minutes after DNS propagation
kubectl get certificate -n fks-trading

# Check status
kubectl describe certificate fkstrading-tls -n fks-trading
```

---

## ✅ Testing

### 1. Test DNS Resolution

```bash
dig fkstrading.xyz +short
dig api.fkstrading.xyz +short
```

### 2. Test HTTP Access

```bash
# Main service
curl http://fkstrading.xyz/health/

# API
curl http://api.fkstrading.xyz/health/

# Execution
curl http://execution.fkstrading.xyz/health

# Grafana
curl http://grafana.fkstrading.xyz/api/health
```

### 3. Test HTTPS (after cert-manager)

```bash
curl https://fkstrading.xyz/health/
curl https://api.fkstrading.xyz/health/
```

---

## 📊 Current Ingress Status

```bash
kubectl get ingress -n fks-trading
```

**Expected Output**:
```
NAME                          HOSTS
fks-platform-ingress          fkstrading.xyz
fks-platform-ingress-multi    fkstrading.xyz,api.fkstrading.xyz,app.fkstrading.xyz + 4 more...
```

---

## 🚀 Next Steps

1. ✅ **Ingress configured** with fkstrading.xyz
2. ⏳ **Configure DNS** at your registrar (see above)
3. ⏳ **Install cert-manager** for TLS
4. ⏳ **Wait for DNS propagation** (5-10 min)
5. ⏳ **Verify HTTPS** access to all services

---

## 📚 Related Docs

- [Full Domain Setup Guide](DOMAIN_SETUP_GUIDE.md) - Comprehensive guide
- [Phase 8.1 Summary](PHASE_8_1_COMPLETE_SUMMARY.md) - Deployment status
- [Ingress Access Guide](../INGRESS_ACCESS_GUIDE.md) - Local access patterns

---

**For local testing**: Use `/etc/hosts` method above  
**For production**: Configure DNS A records and cert-manager
