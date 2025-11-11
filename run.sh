#!/bin/bash
# run.sh - Unified Management Script for FKS Microservices
# Placed at project root (fks_main repo)
# Handles 14 services across 14 repos
# Interactive mode for all/specific services
# Manages venvs for Python services
# Integrates with GitHub Actions for Docker builds/pushes to nuniesmith/fks
# Supports Docker Compose and basic K8s ops
# Added GitHub Actions workflow status checker
# Added Minikube and Docker installation for Ubuntu if not available
# Don't exit on error in main loop - we want to handle errors gracefully
# Use 'set -e' in individual functions where appropriate
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project configuration
# Handle both direct execution and symlink execution
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# Services are in the parent directory (repo/main/run.sh -> repo/)
REPO_DIR="$(cd "$PROJECT_ROOT/.." && pwd)"
DOCKER_USERNAME="nuniesmith"
DOCKER_REPO="fks"
DEFAULT_TAG="latest"

# List of all services
SERVICES=(
  "ai" "analyze" "api" "app" "auth" "data" "execution"
  "main" "meta" "monitor" "portfolio" "ninja" "training" "web"
)

# Python-based services (for venv management)
PYTHON_SERVICES=(
  "ai" "analyze" "api" "app" "data" "main" "monitor"
  "portfolio" "training" "web"
)

# Logging helpers
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on Ubuntu
is_ubuntu() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
      return 0
    fi
  fi
  return 1
}

# Install Docker if not available (for Ubuntu)
install_docker() {
  if ! is_ubuntu; then
    log_error "Docker installation is only supported for Ubuntu in this script."
    return 1
  fi

  log_info "Installing Docker on Ubuntu..."
  sudo apt-get update || { log_error "apt update failed"; return 1; }
  sudo apt-get install -y ca-certificates curl || { log_error "Prerequisite packages failed"; return 1; }
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || { log_error "GPG key download failed"; return 1; }
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update || { log_error "apt update failed after adding repo"; return 1; }
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { log_error "Docker installation failed"; return 1; }
  sudo usermod -aG docker $USER || log_warning "Failed to add user to docker group; may need manual sudo for docker commands."
  log_success "Docker installed. Log out and back in for group changes to take effect."
  return 0
}

# Install Minikube if not available (for Ubuntu)
install_minikube() {
  if ! is_ubuntu; then
    log_error "Minikube installation is only supported for Ubuntu in this script."
    return 1
  fi

  # Check for Docker first, as it's a prerequisite
  if ! command -v docker &> /dev/null; then
    log_warning "Docker is required for Minikube but not installed."
    read -p "Install Docker now? (y/n): " install_docker_choice
    if [ "$install_docker_choice" = "y" ]; then
      install_docker || return 1
    else
      log_error "Cannot proceed without Docker."
      return 1
    fi
  fi

  log_info "Installing Minikube on Ubuntu..."
  curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 || { log_error "Download failed"; return 1; }
  sudo install minikube-linux-amd64 /usr/local/bin/minikube || { log_error "Installation failed"; return 1; }
  rm minikube-linux-amd64
  log_success "Minikube installed."
  return 0
}

# Get service path
get_service_path() {
  local service="$1"
  echo "$REPO_DIR/$service"
}

# Manage venv for a Python service
manage_venv() {
  local service="$1"
  local install_deps="${2:-false}"

  # Check if service is Python-based
  if [[ ! " ${PYTHON_SERVICES[*]} " =~ " ${service} " ]]; then
    log_warning "$service is not a Python service - skipping venv creation"
    return 0
  fi

  local service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service directory not found: $service_path"
    return 1
  fi

  cd "$service_path"

  if [ ! -d ".venv" ]; then
    log_info "Creating virtual environment for $service..."
    python3 -m venv .venv || { log_error "Failed to create venv"; return 1; }
  fi

  if [ "$install_deps" = true ]; then
    log_info "Installing dependencies for $service..."
    "$service_path/.venv/bin/pip" install --upgrade pip setuptools wheel || { log_error "Failed to upgrade pip"; return 1; }
    for req_file in requirements.txt requirements.dev.txt; do
      if [ -f "$req_file" ]; then
        log_info "Installing dependencies from $req_file..."
        "$service_path/.venv/bin/pip" install -r "$req_file" || { log_error "Failed to install deps from $req_file"; return 1; }
      fi
    done
    log_success "Dependencies installed for $service"
  else
    log_info "Virtual environment ready for $service"
    log_info "To activate: source $service_path/.venv/bin/activate"
  fi

  return 0
}

# Build Docker image for service
build_docker() {
  local service="$1"
  local tag="${2:-$DEFAULT_TAG}"

  local service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service not found: $service"
    return 1
  fi

  cd "$service_path"

  if [ ! -f "Dockerfile" ]; then
    log_warning "No Dockerfile found for $service - skipping build"
    return 1
  fi

  # Use same naming convention as GitHub Actions: nuniesmith/fks:service-tag
  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
  log_info "Building Docker image: $image_name"

  docker build -t "$image_name" . || { log_error "Build failed for $service"; return 1; }
  log_success "Built $image_name successfully"

  return 0
}

# Start service (Docker Compose)
start_service() {
  local service="$1"

  local service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service not found: $service"
    return 1
  fi

  cd "$service_path"

  if [ ! -f "docker-compose.yml" ]; then
    log_warning "No docker-compose.yml for $service - skipping"
    return 1
  fi

  log_info "Starting $service..."
  docker compose up -d --build || { log_error "Failed to start $service"; return 1; }
  log_success "$service started"

  return 0
}

# Stop service
stop_service() {
  local service="$1"

  local service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service not found: $service"
    return 1
  fi

  cd "$service_path"

  if [ ! -f "docker-compose.yml" ]; then
    log_warning "No docker-compose.yml for $service - skipping"
    return 1
  fi

  log_info "Stopping $service..."
  docker compose down || { log_error "Failed to stop $service"; return 1; }
  log_success "$service stopped"

  return 0
}

# Commit and push changes (triggers GitHub Actions for Docker build/push)
commit_push() {
  local service="$1"
  local message="${2:-chore: auto update $(date +'%Y-%m-%d %H:%M')}"

  local service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service not found: $service"
    return 1
  fi

  cd "$service_path"

  if [ ! -d ".git" ]; then
    log_warning "Not a git repo: $service - skipping"
    return 1
  fi

  # Get current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  log_info "Current branch: $current_branch"

  git add -A

  if git diff --cached --quiet; then
    log_info "No changes in $service - skipping commit"
    return 0
  fi

  log_info "Committing changes in $service..."
  git commit -m "$message" || { log_error "Commit failed"; return 1; }

  log_info "Pushing to remote (triggers GitHub Actions build/push)..."
  # Push to current branch (supports both main and master)
  git push origin "$current_branch" || { log_error "Push failed"; return 1; }

  log_success "$service committed and pushed to $current_branch"
  log_info "GitHub Actions will build and push to dockerhub.com/nuniesmith/fks:${service}-latest"

  return 0
}

# Analyze codebase (simplified from provided script)
analyze_codebase() {
  local target_dir="${1:-$PROJECT_ROOT}"
  local output_dir="${2:-$PROJECT_ROOT/analysis_$(date +%Y%m%d_%H%M%S)}"

  mkdir -p "$output_dir"

  log_info "Analyzing codebase at $target_dir..."

  # File tree
  if command -v tree >/dev/null; then
    tree -I '__pycache__|venv|target|.git|.idea|.vscode' "$target_dir" > "$output_dir/file_tree.txt"
  else
    find "$target_dir" -print | sort > "$output_dir/file_tree.txt"
  fi

  # File counts
  find "$target_dir" -type f | grep -E '\.(py|rs|md|sh|yml|yaml|toml|json|Dockerfile)$' | \
    awk -F. '{print $NF}' | sort | uniq -c > "$output_dir/file_counts.txt"

  log_success "Analysis complete - results in $output_dir"
}

# Check GitHub Actions workflow status
check_workflow_status() {
  local services_to_check=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_check=("$@")
  fi
  SUCCESS_COUNT=0
  FAIL_COUNT=0
  PENDING_COUNT=0
  NO_WORKFLOW_COUNT=0
  FAILED_SERVICES=()
  PENDING_SERVICES=()
  echo "=========================================="
  echo "GitHub Actions Workflow Status Check"
  echo "=========================================="
  echo ""
  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Install it with: sudo apt install gh"
    echo "Or visit: https://cli.github.com/"
    echo ""
    echo "Alternative: Check manually at:"
    for SERVICE in "${services_to_check[@]}"; do
      echo " https://github.com/nuniesmith/fks_$SERVICE/actions"
    done
    return 1
  fi
  # Check if authenticated
  if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️ GitHub CLI not authenticated${NC}"
    echo "Run: gh auth login"
    echo ""
    echo "Alternative: Check manually at:"
    for SERVICE in "${services_to_check[@]}"; do
      echo " https://github.com/nuniesmith/fks_$SERVICE/actions"
    done
    return 1
  fi
  echo "Checking workflow runs for selected services..."
  echo ""
  for SERVICE in "${services_to_check[@]}"; do
    SERVICE_DIR=$(get_service_path "$SERVICE")
    echo "----------------------------------------"
    echo -e "${BLUE}Checking: $SERVICE${NC}"
    echo "----------------------------------------"
    # Check if directory exists
    if [ ! -d "$SERVICE_DIR" ]; then
      echo -e "${RED}❌ Service directory not found${NC}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      FAILED_SERVICES+=("$SERVICE (directory not found)")
      echo ""
      continue
    fi
    cd "$SERVICE_DIR"
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
      echo -e "${RED}❌ Not a git repository${NC}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      FAILED_SERVICES+=("$SERVICE (not a git repo)")
      echo ""
      continue
    fi
    # Check if workflow file exists
    if [ ! -f ".github/workflows/docker-build-push.yml" ]; then
      echo -e "${YELLOW}⚠️ Workflow file not found${NC}"
      NO_WORKFLOW_COUNT=$((NO_WORKFLOW_COUNT + 1))
      echo ""
      continue
    fi
    # Get repository name
    REPO_URL=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com\///' | sed 's/\.git$//')
    if [ -z "$REPO_URL" ]; then
      echo -e "${YELLOW}⚠️ Could not determine repository URL${NC}"
      echo " Remote: $(git remote -v | head -1)"
      echo ""
      continue
    fi
    echo " Repository: $REPO_URL"
    echo " GitHub: https://github.com/$REPO_URL/actions"
    echo ""
    # Check workflow runs
    WORKFLOW_RUNS=$(gh run list --repo "$REPO_URL" --limit 3 2>&1)
    if [ $? -ne 0 ]; then
      echo -e " ${YELLOW}⚠️ Could not fetch workflow runs${NC}"
      echo " Error: $WORKFLOW_RUNS"
      echo ""
      continue
    fi
    if [ -z "$WORKFLOW_RUNS" ] || [ "$WORKFLOW_RUNS" = "" ]; then
      echo -e " ${YELLOW}⚠️ No workflow runs found${NC}"
      PENDING_COUNT=$((PENDING_COUNT + 1))
      PENDING_SERVICES+=("$SERVICE")
      echo ""
      continue
    fi
    # Parse workflow runs (use process substitution to avoid subshell)
    echo " Recent workflow runs:"
    while IFS= read -r line; do
      if [ -z "$line" ]; then
        continue
      fi
      if [[ "$line" == *"success"* ]] || [[ "$line" == *"✓"* ]] || [[ "$line" == *"completed"*"success"* ]]; then
        echo -e " ${GREEN}✅ $line${NC}"
      elif [[ "$line" == *"failure"* ]] || [[ "$line" == *"✗"* ]] || [[ "$line" == *"completed"*"failure"* ]]; then
        echo -e " ${RED}❌ $line${NC}"
        # Don't count here - count based on latest run status below
      elif [[ "$line" == *"in_progress"* ]] || [[ "$line" == *"queued"* ]] || [[ "$line" == *"pending"* ]]; then
        echo -e " ${YELLOW}⏳ $line${NC}"
        # Don't count here - count based on latest run status below
      else
        echo " $line"
      fi
    done <<< "$WORKFLOW_RUNS"
    # Check latest run status
    LATEST_RUN=$(gh run list --repo "$REPO_URL" --limit 1 --json status,conclusion,workflowName,createdAt --jq '.[0]' 2>/dev/null)
    if [ -n "$LATEST_RUN" ] && [ "$LATEST_RUN" != "null" ]; then
      STATUS=$(echo "$LATEST_RUN" | jq -r '.status' 2>/dev/null || echo "unknown")
      CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.conclusion' 2>/dev/null || echo "unknown")
      WORKFLOW_NAME=$(echo "$LATEST_RUN" | jq -r '.workflowName' 2>/dev/null || echo "unknown")
      echo ""
      echo " Latest run:"
      echo " Workflow: $WORKFLOW_NAME"
      echo " Status: $STATUS"
      echo " Conclusion: $CONCLUSION"
      if [ "$CONCLUSION" = "success" ]; then
        echo -e " ${GREEN}✅ Workflow completed successfully${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      elif [ "$CONCLUSION" = "failure" ]; then
        echo -e " ${RED}❌ Workflow failed${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_SERVICES+=("$SERVICE")
        echo " Check logs: https://github.com/$REPO_URL/actions"
      elif [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ] || [ "$STATUS" = "pending" ]; then
        echo -e " ${YELLOW}⏳ Workflow is still running${NC}"
        PENDING_COUNT=$((PENDING_COUNT + 1))
        PENDING_SERVICES+=("$SERVICE")
      elif [ "$CONCLUSION" = "null" ] && [ "$STATUS" != "completed" ]; then
        echo -e " ${YELLOW}⏳ Workflow is still running (status: $STATUS)${NC}"
        PENDING_COUNT=$((PENDING_COUNT + 1))
        PENDING_SERVICES+=("$SERVICE")
      else
        echo -e " ${YELLOW}⚠️ Unknown status: $STATUS / $CONCLUSION${NC}"
        PENDING_COUNT=$((PENDING_COUNT + 1))
        PENDING_SERVICES+=("$SERVICE")
      fi
    else
      echo -e " ${YELLOW}⚠️ No workflow runs found${NC}"
      NO_WORKFLOW_COUNT=$((NO_WORKFLOW_COUNT + 1))
      PENDING_SERVICES+=("$SERVICE")
    fi
    echo ""
  done
  echo "=========================================="
  echo "Summary"
  echo "=========================================="
  echo -e "${GREEN}✅ Success: $SUCCESS_COUNT${NC}"
  echo -e "${YELLOW}⏳ Pending/Running: $PENDING_COUNT${NC}"
  echo -e "${RED}❌ Failed: $FAIL_COUNT${NC}"
  echo -e "⚠️ No Workflow: $NO_WORKFLOW_COUNT"
  if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed services:${NC}"
    for service in "${FAILED_SERVICES[@]}"; do
      echo " - $service"
    done
    echo ""
    echo "Check logs at:"
    for service in "${FAILED_SERVICES[@]}"; do
      SERVICE_NAME=$(echo "$service" | cut -d' ' -f1)
      echo " https://github.com/nuniesmith/fks_$SERVICE_NAME/actions"
    done
  fi
  if [ ${#PENDING_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Pending services:${NC}"
    for service in "${PENDING_SERVICES[@]}"; do
      echo " - $service"
    done
  fi
  echo ""
  echo "=========================================="
  echo "Manual Check Links"
  echo "=========================================="
  for SERVICE in "${services_to_check[@]}"; do
    echo " $SERVICE: https://github.com/nuniesmith/fks_$SERVICE/actions"
  done
  echo ""
}

# Pull images from Docker Hub
pull_images() {
  local service="$1"
  local tag="${2:-latest}"
  local use_minikube="${3:-false}"

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"

  # Set docker context if using minikube
  if [ "$use_minikube" = "true" ]; then
    if ! command -v minikube &> /dev/null; then
      log_error "minikube is not installed"
      return 1
    fi
    eval $(minikube docker-env)
    log_info "Using minikube Docker context"
  fi

  log_info "Pulling $image_name..."
  if docker pull "$image_name"; then
    log_success "Pulled $image_name successfully"
    return 0
  else
    log_error "Failed to pull $image_name"
    return 1
  fi
}

# Sync images (pull latest from Docker Hub)
sync_images() {
  local use_minikube="${1:-false}"
  shift
  local services_to_sync=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_sync=("$@")
  fi

  if [ "$use_minikube" = "true" ]; then
    if ! command -v minikube &> /dev/null; then
      log_warning "Minikube not installed."
      read -p "Install Minikube now? (y/n): " install_choice
      if [ "$install_choice" = "y" ]; then
        install_minikube || return 1
      else
        return 1
      fi
    fi
    if ! minikube status &> /dev/null; then
      log_error "minikube is not running. Start it first with: minikube start"
      return 1
    fi
    eval $(minikube docker-env)
    log_info "Using minikube Docker context for image sync"
  fi

  log_info "Syncing images from Docker Hub..."
  local success_count=0
  local failed_services=()

  for service in "${services_to_sync[@]}"; do
    if pull_images "$service" "latest" "$use_minikube"; then
      success_count=$((success_count + 1))
    else
      failed_services+=("$service")
    fi
  done

  echo ""
  log_info "Sync complete: $success_count/${#services_to_sync[@]} services synced"
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed to sync: ${failed_services[*]}"
    return 1
  fi

  return 0
}

# Find deployment name for a service
find_deployment_name() {
  local service="$1"
  local namespace="${2:-fks-trading}"

  # Try different naming conventions
  local candidates=(
    "fks-$service"
    "$service"
    "fks_$service"
  )

  for candidate in "${candidates[@]}"; do
    if kubectl get deployment "$candidate" -n "$namespace" &> /dev/null; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

# Update Kubernetes deployment to use new image
update_k8s_deployment() {
  local service="$1"
  local tag="${2:-latest}"
  local namespace="${3:-fks-trading}"

  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    return 1
  fi

  # Find the deployment name
  local deployment_name
  if deployment_name=$(find_deployment_name "$service" "$namespace"); then
    log_info "Found deployment: $deployment_name"
  else
    log_error "Deployment not found for service: $service in namespace: $namespace"
    log_info "Available deployments in namespace $namespace:"
    kubectl get deployments -n "$namespace" -o name 2>/dev/null | sed 's|deployment.apps/||' | sed 's/^/  - /' || log_warning "Could not list deployments"
    return 1
  fi

  # Container name typically matches deployment name in Helm charts
  local container_name="$deployment_name"

  # Verify container exists in deployment
  if ! kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[*].name}' | grep -q "$container_name"; then
    # Try to get the first container name
    container_name=$(kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)
    if [ -z "$container_name" ]; then
      log_error "Could not determine container name for deployment $deployment_name"
      return 1
    fi
    log_info "Using container name: $container_name"
  fi

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"

  log_info "Updating deployment $deployment_name (container: $container_name) in namespace $namespace to use $image_name..."

  # Set image and trigger rollout
  if kubectl set image "deployment/$deployment_name" "$container_name=$image_name" -n "$namespace"; then
    log_success "Image updated for $deployment_name"
    
    # Trigger rollout restart to ensure new image is pulled
    log_info "Restarting deployment to pick up new image..."
    if kubectl rollout restart "deployment/$deployment_name" -n "$namespace"; then
      log_success "Deployment restart triggered for $deployment_name"
      return 0
    else
      log_error "Failed to restart deployment $deployment_name"
      return 1
    fi
  else
    log_error "Failed to update image for $deployment_name"
    return 1
  fi
}

# Sync images and update Kubernetes deployments
sync_and_update_k8s() {
  local namespace="${1:-fks-trading}"
  local use_minikube="${2:-true}"
  shift 2
  local services_to_sync=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_sync=("$@")
  fi

  log_info "Syncing images and updating Kubernetes deployments..."
  echo ""

  # First, sync images
  if ! sync_images "$use_minikube" "${services_to_sync[@]}"; then
    log_warning "Some images failed to sync, but continuing with updates..."
  fi

  echo ""
  log_info "Updating Kubernetes deployments..."

  # Then update deployments
  local success_count=0
  local failed_services=()

  for service in "${services_to_sync[@]}"; do
    if update_k8s_deployment "$service" "latest" "$namespace"; then
      success_count=$((success_count + 1))
    else
      failed_services+=("$service")
    fi
  done

  echo ""
  log_info "Update complete: $success_count/${#services_to_sync[@]} deployments updated"
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed to update: ${failed_services[*]}"
  fi

  echo ""
  log_info "Waiting for rollouts to complete..."
  sleep 3

  # Show rollout status
  for service in "${services_to_sync[@]}"; do
    local deployment_name
    if deployment_name=$(find_deployment_name "$service" "$namespace"); then
      log_info "Checking rollout status for $deployment_name..."
      kubectl rollout status "deployment/$deployment_name" -n "$namespace" --timeout=60s || log_warning "Rollout status check timeout for $deployment_name"
    else
      log_warning "Skipping rollout status check for $service (deployment not found)"
    fi
  done

  echo ""
  log_success "Sync and update complete!"
  log_info "View pod status with: kubectl get pods -n $namespace"
}

# Kubernetes basic operations (from provided scripts)
k8s_start() {
  log_info "Starting Kubernetes deployment..."

  # Check if minikube is available, install if not
  if ! command -v minikube &> /dev/null; then
    log_warning "Minikube not installed."
    read -p "Install Minikube now (Ubuntu only)? (y/n): " install_choice
    if [ "$install_choice" = "y" ]; then
      install_minikube || { log_error "Minikube installation failed"; return 1; }
    else
      log_error "Cannot proceed without Minikube."
      return 1
    fi
  fi

  # Check if kubectl is available
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed. Install it first."
    return 1
  fi

  # Start minikube
  minikube start || { log_error "Minikube start failed"; return 1; }
  eval $(minikube docker-env)

  # Ask if user wants to build images locally or pull from Docker Hub
  read -p "Build images locally (b) or pull from Docker Hub (p)? [p]: " build_choice
  build_choice=${build_choice:-p}

  if [ "$build_choice" = "b" ]; then
    log_info "Building all images locally for minikube..."
    for service in "${SERVICES[@]}"; do
      build_docker "$service" || log_warning "Failed to build $service"
    done
  else
    log_info "Pulling images from Docker Hub..."
    sync_images "true" "${SERVICES[@]}"
  fi

  # Ask for namespace
  read -p "Enter Kubernetes namespace (default: fks-trading): " namespace
  namespace=${namespace:-fks-trading}

  # Create namespace if it doesn't exist
  kubectl create namespace "$namespace" 2>/dev/null || true

  # Apply manifests (assuming they exist in k8s/ dir)
  if [ -d "$PROJECT_ROOT/k8s" ]; then
    log_info "Applying Kubernetes manifests from $PROJECT_ROOT/k8s..."
    kubectl apply -f "$PROJECT_ROOT/k8s" -n "$namespace" || { log_error "Failed to apply k8s manifests"; return 1; }
  else
    log_warning "No k8s manifests found in $PROJECT_ROOT/k8s"
  fi

  log_success "Kubernetes started"
  log_info "To sync images later, use menu option 11 (Sync Images from Docker Hub)"
}

k8s_stop() {
  log_info "Stopping Kubernetes..."

  # Check if kubectl is available
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    return 1
  fi

  # Check if minikube is available
  if ! command -v minikube &> /dev/null; then
    log_error "minikube is not installed"
    return 1
  fi

  # Delete resources
  if [ -d "$PROJECT_ROOT/k8s" ]; then
    kubectl delete -f "$PROJECT_ROOT/k8s" || log_warning "Failed to delete some resources"
  fi

  # Stop minikube
  minikube stop || { log_error "Failed to stop minikube"; return 1; }

  log_success "Kubernetes stopped"
}

# Interactive menu
show_menu() {
  echo -e "${CYAN}=== FKS Microservices Manager ===${NC}"
  echo "1. Manage Venvs (Python services)"
  echo "2. Build Docker Images"
  echo "3. Start Services (Docker Compose)"
  echo "4. Stop Services"
  echo "5. Commit & Push (Triggers GitHub Actions)"
  echo "6. Analyze Codebase"
  echo "7. Check GitHub Actions Status"
  echo "8. Kubernetes Start"
  echo "9. Kubernetes Stop"
  echo "10. Pull Images from Docker Hub (Local)"
  echo "11. Pull Images from Docker Hub (Minikube)"
  echo "12. Sync Images & Update Kubernetes Deployments"
  echo "13. Exit"
  echo ""
  read -p "Enter choice: " choice
}

# Handle all or specific services
handle_all_or_specific() {
  local action_func="$1"
  shift
  local extra_args=("$@")

  read -p "All services (a) or specific (s)? " mode
  if [ "$mode" = "a" ]; then
    local failed_services=()
    local success_count=0
    for service in "${SERVICES[@]}"; do
      log_info "Processing $service..."
      if "$action_func" "$service" "${extra_args[@]}" 2>&1; then
        success_count=$((success_count + 1))
      else
        failed_services+=("$service")
      fi
    done
    echo ""
    log_info "Completed: $success_count/${#SERVICES[@]} services succeeded"
    if [ ${#failed_services[@]} -gt 0 ]; then
      log_warning "Failed services: ${failed_services[*]}"
    fi
  else
    read -p "Enter service name (comma-separated for multiple): " input_services
    IFS=',' read -ra selected <<< "$input_services"
    local selected_services=()
    for service in "${selected[@]}"; do
      service=$(echo "$service" | tr -d ' ')  # Trim spaces
      if [[ " ${SERVICES[*]} " =~ " ${service} " ]]; then
        selected_services+=("$service")
      else
        log_error "Invalid service: $service"
      fi
    done
    if [ ${#selected_services[@]} -gt 0 ]; then
      for service in "${selected_services[@]}"; do
        "$action_func" "$service" "${extra_args[@]}" || log_error "Failed to process $service"
      done
    fi
  fi
}

# Main loop
while true; do
  show_menu

  case $choice in
    1)
      read -p "Install dependencies? (y/n): " install
      install=${install:-n}
      handle_all_or_specific manage_venv $([ "$install" = "y" ] && echo true || echo false)
      ;;
    2)
      read -p "Enter tag (default: latest): " tag
      tag=${tag:-latest}
      handle_all_or_specific build_docker "$tag"
      ;;
    3)
      handle_all_or_specific start_service
      ;;
    4)
      handle_all_or_specific stop_service
      ;;
    5)
      read -p "Enter commit message (default: chore: auto update): " message
      message=${message:-"chore: auto update"}
      handle_all_or_specific commit_push "$message"
      ;;
    6)
      read -p "Enter directory to analyze (default: $PROJECT_ROOT): " dir
      dir=${dir:-$PROJECT_ROOT}
      read -p "Enter output dir (default: analysis_$(date +%Y%m%d_%H%M%S)): " out
      out=${out:-"analysis_$(date +%Y%m%d_%H%M%S)"}
      analyze_codebase "$dir" "$out"
      ;;
    7)
      handle_all_or_specific check_workflow_status
      ;;
    8)
      k8s_start
      ;;
    9)
      k8s_stop
      ;;
    10)
      read -p "Pull for all services (a) or specific (s)? [a]: " mode
      mode=${mode:-a}
      if [ "$mode" = "a" ]; then
        sync_images "false" "${SERVICES[@]}"
      else
        read -p "Enter service name (comma-separated): " input_services
        IFS=',' read -ra selected <<< "$input_services"
        selected_services=()
        for service in "${selected[@]}"; do
          service=$(echo "$service" | tr -d ' ')
          if [[ " ${SERVICES[*]} " =~ " ${service} " ]]; then
            selected_services+=("$service")
          else
            log_error "Invalid service: $service"
          fi
        done
        if [ ${#selected_services[@]} -gt 0 ]; then
          sync_images "false" "${selected_services[@]}"
        fi
      fi
      ;;
    11)
      if ! command -v minikube &> /dev/null; then
        log_warning "Minikube not installed."
        read -p "Install Minikube now? (y/n): " install_choice
        if [ "$install_choice" = "y" ]; then
          install_minikube || continue
        else
          continue
        fi
      fi
      if ! minikube status &> /dev/null; then
        log_error "minikube is not running. Start it first with option 8"
      else
        read -p "Pull for all services (a) or specific (s)? [a]: " mode
        mode=${mode:-a}
        if [ "$mode" = "a" ]; then
          sync_images "true" "${SERVICES[@]}"
        else
          read -p "Enter service name (comma-separated): " input_services
          IFS=',' read -ra selected <<< "$input_services"
          selected_services=()
          for service in "${selected[@]}"; do
            service=$(echo "$service" | tr -d ' ')
            if [[ " ${SERVICES[*]} " =~ " ${service} " ]]; then
              selected_services+=("$service")
            else
              log_error "Invalid service: $service"
            fi
          done
          if [ ${#selected_services[@]} -gt 0 ]; then
            sync_images "true" "${selected_services[@]}"
          fi
        fi
      fi
      ;;
    12)
      if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
      elif ! command -v minikube &> /dev/null; then
        log_warning "Minikube not installed."
        read -p "Install Minikube now? (y/n): " install_choice
        if [ "$install_choice" = "y" ]; then
          install_minikube || continue
        else
          continue
        fi
      elif ! minikube status &> /dev/null; then
        log_error "minikube is not running. Start it first with option 8"
      else
        read -p "Enter Kubernetes namespace (default: fks-trading): " namespace
        namespace=${namespace:-fks-trading}
        read -p "Sync all services (a) or specific (s)? [a]: " mode
        mode=${mode:-a}
        if [ "$mode" = "a" ]; then
          sync_and_update_k8s "$namespace" "true" "${SERVICES[@]}"
        else
          read -p "Enter service name (comma-separated): " input_services
          IFS=',' read -ra selected <<< "$input_services"
          selected_services=()
          for service in "${selected[@]}"; do
            service=$(echo "$service" | tr -d ' ')
            if [[ " ${SERVICES[*]} " =~ " ${service} " ]]; then
              selected_services+=("$service")
            else
              log_error "Invalid service: $service"
            fi
          done
          if [ ${#selected_services[@]} -gt 0 ]; then
            sync_and_update_k8s "$namespace" "true" "${selected_services[@]}"
          fi
        fi
      fi
      ;;
    13)
      log_info "Exiting..."
      exit 0
      ;;
    *)
      log_error "Invalid choice"
      ;;
  esac
done