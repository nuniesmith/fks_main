# FKS Trading Platform - Domain Setup Guide
## Domain: fkstrading.xyz

**Last Updated**: November 3, 2025  
**Status**: ✅ Ingress configured, DNS setup required

---

## 🌐 Overview

The FKS Trading Platform is configured to use your domain `fkstrading.xyz` with subdomain routing for all services.

### Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Main** | https://fkstrading.xyz | Main orchestrator/health dashboard |
| **API** | https://api.fkstrading.xyz | API gateway with JWT auth |
| **App** | https://app.fkstrading.xyz | Trading strategies/signals |
| **Data** | https://data.fkstrading.xyz | Market data collection |
| **Execution** | https://execution.fkstrading.xyz | Rust execution engine |
| **Grafana** | https://grafana.fkstrading.xyz | Monitoring dashboards |
| **Prometheus** | https://prometheus.fkstrading.xyz | Metrics collection |

---

## 📋 DNS Configuration Required

### Step 1: Get Your Kubernetes Cluster IP

For **production** (cloud provider):
```bash
# Get LoadBalancer external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

For **local development** (minikube):
```bash
# Get minikube IP
minikube ip
# Example output: 192.168.49.2
```

### Step 2: Configure DNS Records

Add the following DNS records in your domain registrar (e.g., Cloudflare, Route53, GoDaddy):

**For Production (Replace `<YOUR_CLUSTER_IP>` with actual IP):**
```
Type    Host              Value                  TTL
A       @                 <YOUR_CLUSTER_IP>      300
A       api               <YOUR_CLUSTER_IP>      300
A       app               <YOUR_CLUSTER_IP>      300
A       data              <YOUR_CLUSTER_IP>      300
A       execution         <YOUR_CLUSTER_IP>      300
A       grafana           <YOUR_CLUSTER_IP>      300
A       prometheus        <YOUR_CLUSTER_IP>      300
```

**For Local Development (minikube):**
```
Type    Host              Value           TTL
A       @                 192.168.49.2    300
A       api               192.168.49.2    300
A       app               192.168.49.2    300
A       data              192.168.49.2    300
A       execution         192.168.49.2    300
A       grafana           192.168.49.2    300
A       prometheus        192.168.49.2    300
```

**Alternative: Wildcard DNS (Recommended)**
```
Type    Host    Value                  TTL
A       @       <YOUR_CLUSTER_IP>      300
A       *       <YOUR_CLUSTER_IP>      300
```

### Step 3: Local Testing (Optional - /etc/hosts)

For local testing before DNS propagation:

```bash
# Get minikube IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts (macOS/Linux)
sudo bash -c "cat >> /etc/hosts << EOF
$MINIKUBE_IP fkstrading.xyz
$MINIKUBE_IP api.fkstrading.xyz
$MINIKUBE_IP app.fkstrading.xyz
$MINIKUBE_IP data.fkstrading.xyz
$MINIKUBE_IP execution.fkstrading.xyz
$MINIKUBE_IP grafana.fkstrading.xyz
$MINIKUBE_IP prometheus.fkstrading.xyz
EOF"
```

**Windows (run as Administrator in PowerShell):**
```powershell
$ip = (minikube ip)
Add-Content C:\Windows\System32\drivers\etc\hosts "$ip fkstrading.xyz"
Add-Content C:\Windows\System32\drivers\etc\hosts "$ip api.fkstrading.xyz"
# ... repeat for all subdomains
```

---

## 🔐 TLS/SSL Setup

The Ingress is configured with **cert-manager** for automatic TLS certificates.

### Prerequisites

1. **Install cert-manager** (if not already installed):
```bash
# Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Verify installation
kubectl get pods -n cert-manager
```

2. **Create ClusterIssuer for Let's Encrypt**:
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

3. **Verify Certificate Issuance**:
```bash
# Check certificate status
kubectl get certificate -n fks-trading

# Check certificate details
kubectl describe certificate fkstrading-tls -n fks-trading
```

### Certificate Status

After DNS propagation (~5-10 minutes), cert-manager will automatically:
1. Detect the Ingress annotation `cert-manager.io/cluster-issuer: "letsencrypt-prod"`
2. Create a Certificate resource
3. Issue an ACME challenge (HTTP-01)
4. Obtain a TLS certificate from Let's Encrypt
5. Store it in the Secret `fkstrading-tls`

---

## ✅ Testing Access

### 1. Check DNS Propagation

```bash
# Test DNS resolution
dig fkstrading.xyz +short
dig api.fkstrading.xyz +short

# Alternative (nslookup)
nslookup fkstrading.xyz
```

### 2. Test HTTP Access (Before TLS)

```bash
# Main service health check
curl http://fkstrading.xyz/health/

# Execution service
curl http://execution.fkstrading.xyz/health

# API service
curl http://api.fkstrading.xyz/health/

# Grafana
curl http://grafana.fkstrading.xyz/api/health

# Prometheus
curl http://prometheus.fkstrading.xyz/-/healthy
```

### 3. Test HTTPS Access (After TLS Setup)

```bash
# Main service (HTTPS)
curl https://fkstrading.xyz/health/

# Verify TLS certificate
curl -vI https://fkstrading.xyz 2>&1 | grep -E "SSL|certificate"

# Check certificate expiration
echo | openssl s_client -servername fkstrading.xyz -connect fkstrading.xyz:443 2>/dev/null | openssl x509 -noout -dates
```

### 4. Browser Testing

Open in your browser:
- https://fkstrading.xyz/health/
- https://grafana.fkstrading.xyz (Grafana UI)
- https://prometheus.fkstrading.xyz (Prometheus UI)
- https://execution.fkstrading.xyz/health

---

## 🔧 Troubleshooting

### DNS Not Resolving

1. **Check DNS propagation**: Use https://dnschecker.org
2. **Verify DNS records**: Ensure A records point to correct IP
3. **Clear DNS cache**:
   - macOS: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
   - Linux: `sudo systemd-resolve --flush-caches`
   - Windows: `ipconfig /flushdns`

### Certificate Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate events
kubectl describe certificate fkstrading-tls -n fks-trading

# Check challenge status
kubectl get challenge -n fks-trading
```

**Common issues**:
- DNS not propagated yet (wait 5-10 minutes)
- Email not set in ClusterIssuer (update with your email)
- Rate limit hit (Let's Encrypt has limits - use staging for testing)

### 502 Bad Gateway

```bash
# Check backend pod status
kubectl get pods -n fks-trading

# Check service endpoints
kubectl get endpoints -n fks-trading

# Check Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Connection Timeout

```bash
# Verify Ingress controller is running
kubectl get pods -n ingress-nginx

# Check if LoadBalancer has external IP
kubectl get svc -n ingress-nginx

# For minikube, tunnel required:
minikube tunnel  # Run in separate terminal
```

---

## 🚀 Production Deployment Checklist

- [ ] **DNS Records**: All A records configured and propagated
- [ ] **TLS Certificates**: Let's Encrypt certificates issued successfully
- [ ] **Firewall Rules**: Ports 80/443 open on cloud provider
- [ ] **LoadBalancer**: External IP assigned to NGINX Ingress
- [ ] **Health Checks**: All services responding via HTTPS
- [ ] **Monitoring**: Grafana/Prometheus accessible
- [ ] **Rate Limiting**: Configured in Ingress annotations (if needed)
- [ ] **CDN**: Optional - Cloudflare for DDoS protection

### Rate Limiting (Optional)

Add to Ingress annotations for production:
```yaml
nginx.ingress.kubernetes.io/limit-rps: "100"
nginx.ingress.kubernetes.io/limit-connections: "50"
```

---

## 📊 Current Status

**Ingress Configuration**: ✅ Complete  
**DNS Setup**: ⏳ Requires action (see Step 2 above)  
**TLS Certificates**: ⏳ Pending (auto-issues after DNS)  
**Services**: ✅ All running and healthy

**Next Steps**:
1. Configure DNS records at your domain registrar
2. Wait for DNS propagation (5-10 minutes)
3. Verify TLS certificates issued automatically
4. Test all service URLs via HTTPS

---

## 🔗 Related Documentation

- [Ingress Access Guide](../INGRESS_ACCESS_GUIDE.md) - Local development access
- [Phase 8.1 Complete Summary](../PHASE_8_1_COMPLETE_SUMMARY.md) - Kubernetes deployment status
- [K8s Deployment Guide](../K8S_DEPLOYMENT_GUIDE.md) - Full deployment instructions
- [Phase 8 Production Scaling](../PHASE_8_PRODUCTION_SCALING.md) - Scaling roadmap

---

## 📝 Example: Cloudflare DNS Setup

If using Cloudflare:

1. Login to Cloudflare dashboard
2. Select domain `fkstrading.xyz`
3. Go to **DNS** → **Records**
4. Add A records:

```
Type    Name          IPv4 Address         Proxy Status    TTL
A       @             <YOUR_CLUSTER_IP>    DNS only        Auto
A       api           <YOUR_CLUSTER_IP>    DNS only        Auto
A       app           <YOUR_CLUSTER_IP>    DNS only        Auto
A       data          <YOUR_CLUSTER_IP>    DNS only        Auto
A       execution     <YOUR_CLUSTER_IP>    DNS only        Auto
A       grafana       <YOUR_CLUSTER_IP>    DNS only        Auto
A       prometheus    <YOUR_CLUSTER_IP>    DNS only        Auto
```

**Important**: Set **Proxy Status** to "DNS only" (gray cloud) initially for Let's Encrypt to work. Once certificates are issued, you can enable "Proxied" (orange cloud) for DDoS protection.

---

**For support**: Check logs and Kubernetes events, or refer to troubleshooting section above.
