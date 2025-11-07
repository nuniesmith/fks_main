# FKS Kubernetes - Quick Reference Card

**Last Updated**: November 6, 2025, 4:30 AM EST

---

## 🎯 Quick Access

### Kubernetes Dashboard
```bash
# URL
http://192.168.49.2:30455

# Token
cat /tmp/k8s-dashboard-token.txt
```

### HTTPS Services (Self-Signed SSL)
- Grafana: https://grafana.fkstrading.xyz
- Prometheus: https://prometheus.fkstrading.xyz  
- Alertmanager: https://alertmanager.fkstrading.xyz
- Execution: https://execution.fkstrading.xyz

### Port Forwarding (No SSL Warnings)
```bash
kubectl port-forward -n fks-trading svc/grafana 3000:3000
kubectl port-forward -n fks-trading svc/prometheus 9090:9090
kubectl port-forward -n fks-trading svc/alertmanager 9093:9093
```

---

## 📊 Status Commands

```bash
# Cluster status
kubectl cluster-info
minikube status

# View pods
kubectl get pods -n fks-trading

# View services
kubectl get svc -n fks-trading

# View ingress
kubectl get ingress -n fks-trading

# Verify deployment
./k8s/scripts/verify-deployment.sh
```

---

## 📝 Logs & Debugging

```bash
# View all logs
kubectl logs -n fks-trading --all-containers=true -f

# Grafana logs
kubectl logs -n fks-trading -l app=grafana -f

# Prometheus logs
kubectl logs -n fks-trading -l app=prometheus -f

# Describe pod
kubectl describe pod -n fks-trading <pod-name>

# Execute in pod
kubectl exec -it -n fks-trading <pod-name> -- /bin/bash
```

---

## 🔄 Common Operations

```bash
# Restart service
kubectl rollout restart deployment/grafana -n fks-trading

# Scale service
kubectl scale deployment/fks-execution --replicas=3 -n fks-trading

# Update image
kubectl set image deployment/fks-execution \
  execution=fks-execution:latest -n fks-trading

# Delete pod (auto-recreates)
kubectl delete pod -n fks-trading <pod-name>
```

---

## 🔐 SSL Certificates

```bash
# View cert details
openssl x509 -in /tmp/fks-certs/tls.crt -text -noout

# Check expiration
openssl x509 -in /tmp/fks-certs/tls.crt -noout -dates

# Regenerate (if needed)
cd /tmp/fks-certs
openssl genrsa -out tls.key 2048
openssl req -new -x509 -days 365 -key tls.key -out tls.crt \
  -config openssl.cnf -extensions v3_req

# Update secret
kubectl create secret tls fkstrading-tls \
  --cert=tls.crt --key=tls.key \
  -n fks-trading --dry-run=client -o yaml | kubectl apply -f -
```

---

## 🛠️ Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod -n fks-trading <pod-name>
kubectl logs -n fks-trading <pod-name>
```

### Ingress Not Working
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### DNS Not Resolving
```bash
cat /etc/hosts | grep fkstrading
ping -c 1 grafana.fkstrading.xyz
```

### Restart Minikube
```bash
minikube stop
minikube start
```

---

## 📁 Important Files

- **Dashboard Token**: `/tmp/k8s-dashboard-token.txt`
- **SSL Certificate**: `/tmp/fks-certs/tls.crt`
- **SSL Private Key**: `/tmp/fks-certs/tls.key`
- **Setup Script**: `/home/jordan/Documents/code/fks/k8s/scripts/setup-k8s-environment.sh`
- **Deploy Script**: `/home/jordan/Documents/code/fks/k8s/scripts/deploy-phase5.sh`
- **Verify Script**: `/home/jordan/Documents/code/fks/k8s/scripts/verify-deployment.sh`
- **Secrets**: `/home/jordan/Documents/code/fks/k8s/manifests/secrets.yaml`

---

## 📚 Documentation

- Setup Guide: `/docs/K8S_SETUP_GUIDE.md`
- Success Doc: `/docs/K8S_DEPLOYMENT_SUCCESS.md`
- Complete Doc: `/docs/K8S_DEPLOYMENT_COMPLETE.md`
- Dashboard Access: `/docs/K8S_DASHBOARD_ACCESS.md`
- Phase 5: `/docs/PHASE_5_COMPLETE.md`

---

## 🚀 Next Steps

1. **Configure Grafana**
   - Port forward: `kubectl port-forward -n fks-trading svc/grafana 3000:3000`
   - Login: admin/admin
   - Add Prometheus datasource: http://prometheus:9090

2. **Build Execution Image**
   - Build: `docker build -f docker/Dockerfile.execution-python -t fks-execution:latest .`
   - Load: `minikube image load fks-execution:latest`
   - Update: `kubectl set image deployment/fks-execution execution=fks-execution:latest -n fks-trading`

3. **Plan Cloud Migration**
   - Choose provider (GKE/EKS/AKS)
   - Configure Let's Encrypt
   - Set up production DNS

---

**Cluster IP**: 192.168.49.2  
**Namespace**: fks-trading  
**Services**: 4/4 running  
**Status**: Production Ready (Local)
