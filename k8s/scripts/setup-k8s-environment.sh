#!/bin/bash
# FKS Trading Platform - Complete K8s Environment Setup
# Sets up minikube, dashboard, SSL certs, and deploys FKS platform

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="fkstrading.xyz"
NAMESPACE="fks-trading"
CERT_DIR="/tmp/fks-certs"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          FKS Trading Platform - K8s Environment Setup                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Step 1: Install kubectl
install_kubectl() {
    print_section "Step 1: Installing kubectl"
    
    if command -v kubectl &> /dev/null; then
        echo -e "${GREEN}✓ kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
        return
    fi
    
    echo "Downloading kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    echo "Installing kubectl..."
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    echo -e "${GREEN}✓ kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
}

# Step 2: Install minikube
install_minikube() {
    print_section "Step 2: Installing minikube"
    
    if command -v minikube &> /dev/null; then
        echo -e "${GREEN}✓ minikube already installed: $(minikube version --short)${NC}"
        return
    fi
    
    echo "Downloading minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    
    echo "Installing minikube..."
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    echo -e "${GREEN}✓ minikube installed: $(minikube version --short)${NC}"
}

# Step 3: Start minikube cluster
start_minikube() {
    print_section "Step 3: Starting minikube cluster"
    
    if minikube status &> /dev/null; then
        echo -e "${YELLOW}minikube already running${NC}"
        minikube status
        return
    fi
    
    echo "Starting minikube with Docker driver..."
    echo "  - CPUs: 4"
    echo "  - Memory: 8192MB"
    echo "  - Disk: 50GB"
    
    minikube start \
        --driver=docker \
        --cpus=4 \
        --memory=8192 \
        --disk-size=50g \
        --kubernetes-version=stable
    
    echo -e "${GREEN}✓ minikube cluster started${NC}"
    
    # Enable addons
    echo "Enabling minikube addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    minikube addons enable dashboard
    
    echo -e "${GREEN}✓ Addons enabled (ingress, metrics-server, dashboard)${NC}"
    
    # Verify cluster
    kubectl cluster-info
}

# Step 4: Install K8s dashboard
install_dashboard() {
    print_section "Step 4: Installing Kubernetes Dashboard"
    
    # Deploy dashboard
    echo "Deploying Kubernetes Dashboard..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Wait for dashboard to be ready
    echo "Waiting for dashboard pods..."
    kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s
    
    # Create admin user
    echo "Creating admin service account..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user-secret
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
type: kubernetes.io/service-account-token
EOF
    
    # Get token
    echo "Retrieving dashboard token..."
    sleep 5
    TOKEN=$(kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d)
    
    # Save token
    echo "$TOKEN" > /tmp/k8s-dashboard-token.txt
    
    # Expose dashboard via NodePort
    kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'
    
    NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
    MINIKUBE_IP=$(minikube ip)
    
    echo -e "${GREEN}✓ Dashboard deployed${NC}"
    echo ""
    echo -e "${GREEN}Dashboard Access:${NC}"
    echo -e "  URL: http://${MINIKUBE_IP}:${NODEPORT}"
    echo -e "  Token saved to: /tmp/k8s-dashboard-token.txt"
    echo ""
    echo -e "${YELLOW}Dashboard Token (copy this):${NC}"
    echo "$TOKEN"
}

# Step 5: Generate self-signed SSL certificates
generate_ssl_certs() {
    print_section "Step 5: Generating Self-Signed SSL Certificates"
    
    mkdir -p "$CERT_DIR"
    
    echo "Generating private key..."
    openssl genrsa -out "$CERT_DIR/tls.key" 2048
    
    echo "Generating certificate signing request..."
    cat > "$CERT_DIR/openssl.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=CA
ST=Ontario
L=Toronto
O=FKS Trading
OU=Development
CN=*.${DOMAIN}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = grafana.${DOMAIN}
DNS.4 = prometheus.${DOMAIN}
DNS.5 = alertmanager.${DOMAIN}
DNS.6 = api.${DOMAIN}
DNS.7 = app.${DOMAIN}
DNS.8 = execution.${DOMAIN}
EOF
    
    echo "Generating self-signed certificate (valid 365 days)..."
    openssl req -new -x509 -days 365 \
        -key "$CERT_DIR/tls.key" \
        -out "$CERT_DIR/tls.crt" \
        -config "$CERT_DIR/openssl.cnf" \
        -extensions v3_req
    
    echo -e "${GREEN}✓ SSL certificates generated${NC}"
    echo -e "  Certificate: $CERT_DIR/tls.crt"
    echo -e "  Private Key: $CERT_DIR/tls.key"
    
    # Verify certificate
    echo ""
    echo "Certificate details:"
    openssl x509 -in "$CERT_DIR/tls.crt" -text -noout | grep -E "(Subject:|DNS:|Not Before|Not After)"
}

# Step 6: Create TLS secret in K8s
create_tls_secret() {
    print_section "Step 6: Creating TLS Secret in Kubernetes"
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Delete existing secret if present
    kubectl delete secret fkstrading-tls -n $NAMESPACE --ignore-not-found=true
    
    # Create new TLS secret
    kubectl create secret tls fkstrading-tls \
        --cert="$CERT_DIR/tls.crt" \
        --key="$CERT_DIR/tls.key" \
        -n $NAMESPACE
    
    echo -e "${GREEN}✓ TLS secret created in namespace: $NAMESPACE${NC}"
}

# Step 7: Configure /etc/hosts
configure_hosts() {
    print_section "Step 7: Configuring /etc/hosts"
    
    MINIKUBE_IP=$(minikube ip)
    
    echo "Adding entries to /etc/hosts for ${DOMAIN}..."
    
    # Create hosts entries
    HOSTS_ENTRIES="
# FKS Trading Platform (minikube)
$MINIKUBE_IP ${DOMAIN}
$MINIKUBE_IP grafana.${DOMAIN}
$MINIKUBE_IP prometheus.${DOMAIN}
$MINIKUBE_IP alertmanager.${DOMAIN}
$MINIKUBE_IP api.${DOMAIN}
$MINIKUBE_IP app.${DOMAIN}
$MINIKUBE_IP execution.${DOMAIN}
"
    
    # Check if entries already exist
    if grep -q "# FKS Trading Platform" /etc/hosts; then
        echo -e "${YELLOW}Entries already exist in /etc/hosts${NC}"
    else
        echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
        echo -e "${GREEN}✓ /etc/hosts updated${NC}"
    fi
    
    echo ""
    echo "Configured domains:"
    echo "  - https://${DOMAIN}"
    echo "  - https://grafana.${DOMAIN}"
    echo "  - https://prometheus.${DOMAIN}"
    echo "  - https://alertmanager.${DOMAIN}"
    echo "  - https://execution.${DOMAIN}"
}

# Step 8: Display summary
display_summary() {
    print_section "Setup Complete - Summary"
    
    MINIKUBE_IP=$(minikube ip)
    NODEPORT=$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}✓ Kubernetes Environment Ready${NC}"
    echo ""
    echo -e "${BLUE}Cluster Information:${NC}"
    echo "  Minikube IP: $MINIKUBE_IP"
    echo "  Kubernetes Version: $(kubectl version --short 2>/dev/null | grep Server | cut -d' ' -f3 || echo 'N/A')"
    echo ""
    
    echo -e "${BLUE}Dashboard Access:${NC}"
    echo "  URL: http://${MINIKUBE_IP}:${NODEPORT}"
    echo "  Token: /tmp/k8s-dashboard-token.txt"
    echo ""
    
    echo -e "${BLUE}SSL Certificates:${NC}"
    echo "  Certificate: $CERT_DIR/tls.crt"
    echo "  Private Key: $CERT_DIR/tls.key"
    echo "  Secret: fkstrading-tls (namespace: $NAMESPACE)"
    echo ""
    
    echo -e "${BLUE}Domains Configured:${NC}"
    echo "  - https://${DOMAIN}"
    echo "  - https://grafana.${DOMAIN}"
    echo "  - https://prometheus.${DOMAIN}"
    echo "  - https://alertmanager.${DOMAIN}"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Deploy FKS Platform:"
    echo "     cd /home/jordan/Documents/code/fks"
    echo "     ./k8s/scripts/deploy-phase5.sh"
    echo ""
    echo "  2. Access Dashboard:"
    echo "     cat /tmp/k8s-dashboard-token.txt"
    echo "     Open: http://${MINIKUBE_IP}:${NODEPORT}"
    echo ""
    echo "  3. Port forward services:"
    echo "     kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
    echo "     kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
}

# Main execution
main() {
    install_kubectl
    install_minikube
    start_minikube
    install_dashboard
    generate_ssl_certs
    create_tls_secret
    configure_hosts
    display_summary
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ K8s Environment Setup Complete!                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Run
main "$@"
