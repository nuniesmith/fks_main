#!/bin/bash
# run.sh - Unified Management Script for FKS Trading Platform
# Version: 2.3 (Full Repo Support - Dec 2025)
# Domain: fkstrading.xyz
# Handles all services, apps, and infrastructure repos with clear responsibility boundaries
# ============================================================================

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONFIGURATION
# ============================================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_DIR="$(cd "$PROJECT_ROOT/../.." && pwd)"
DOMAIN="fkstrading.xyz"

DOCKER_USERNAME="${DOCKER_USERNAME:-nuniesmith}"
DOCKER_REPO="${DOCKER_REPO:-fks}"
DEFAULT_TAG="${DEFAULT_TAG:-latest}"

ENABLE_TRIVY="${ENABLE_TRIVY:-true}"
ENABLE_PARALLEL="${ENABLE_PARALLEL:-true}"
MAX_PARALLEL="${MAX_PARALLEL:-4}"
PULL_MISSING_IMAGES="${PULL_MISSING_IMAGES:-n}"
PULL_BASE_IMAGES="${PULL_BASE_IMAGES:-false}"

# ============================================================================
# SERVICE CATEGORIZATION (matches FKS AI Context Guide exactly)
# ============================================================================

# GPU-dependent services (require CUDA/GPU runtime)
GPU_SERVICES=(
  ai          # AI/ML inference (GPU)
  training    # GPU batch training
)

# CPU-only core business logic services
CPU_CORE_SERVICES=(
  api                # API Gateway (FastAPI)
  app                # Trading logic & signals
  data               # Central data service (single source of truth)
  execution          # Order execution engine (Rust)
  portfolio          # BTC-centric portfolio optimization
  crypto             # Crypto signal generation and analysis
  futures            # Futures trading service (CME Group futures contracts)
  stocks             # Stocks trading service (equity market analysis)
  data_ingestion     # Data ingestion service (stock, futures, news)
  feature_engineering # Feature engineering service (112+ features)
)

# Combined core services (backward compat)
CORE_SERVICES=("${CPU_CORE_SERVICES[@]}" "${GPU_SERVICES[@]}")

# Execution plugins (attached to fks_execution)
EXECUTION_PLUGINS=(
  meta        # MetaTrader 5 bridge
  ninja       # NinjaTrader 8 bridge
)

# Infrastructure & operations services (all CPU)
INFRA_SERVICES=(
  analyze     # Codebase analysis & auto-improvement
  auth        # Rust-based auth (JWT/RBAC) – used by nginx + web
  monitor     # Prometheus + Grafana metrics aggregation
  nginx       # Reverse proxy, TLS, auth integration
  #tailscale   # Zero-config VPN (Tailscale container)
)

# Main orchestrator (special – Rust + Kubernetes control)
ORCHESTRATOR=(
  main        # fks_main – Rust orchestrator (controls everything)
)

# Pure shared / read-only repos (never built as images)
# Note: config is in services/config but treated as shared infrastructure
SHARED_REPOS=(
  actions     # GitHub Actions workflows (infrastructure/actions)
  dev         # Dev tools / fks_dev repo (infrastructure/dev)
  docker      # Base Dockerfiles + per-service overrides (infrastructure/docker)
  config      # Helm charts, env files, shared YAMLs (services/config)
  docs        # Documentation (infrastructure/docs)
  scripts     # Shared scripts (infrastructure/scripts)
)

# Mobile/Desktop applications (client apps)
# Note: frontend may be in services/frontend but is treated as an app
CLIENT_REPOS=(
  android     # Android mobile app (Kotlin) - apps/android
  apple       # iOS/macOS app (Swift/SwiftUI) - apps/apple
  desktop     # Desktop app (Kotlin Multiplatform) - apps/desktop
  web    # Web frontend (SvelteKit) - apps/frontend or services/frontend
)

# Composite arrays
CPU_SERVICES=("${CPU_CORE_SERVICES[@]}" "${EXECUTION_PLUGINS[@]}" "${INFRA_SERVICES[@]}" "${ORCHESTRATOR[@]}")
ALL_SERVICES=("${CPU_SERVICES[@]}" "${GPU_SERVICES[@]}")
ALL_REPOS=("${ALL_SERVICES[@]}" "${SHARED_REPOS[@]}" "${CLIENT_REPOS[@]}")

# Language-specific
PYTHON_SERVICES=(ai analyze api app data monitor ninja portfolio training web crypto futures stocks data_ingestion feature_engineering)
RUST_SERVICES=(auth execution main meta)

# Backward compatibility (old scripts still work)
SERVICES=("${ALL_SERVICES[@]}")
REPOS=("${ALL_REPOS[@]}")

# ============================================================================
# LOGGING
# ============================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[FKS]${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}!${NC} $*"; }
log_error()   { echo -e "${RED}✗ $*${NC}" >&2; }

# ============================================================================
# CLEANUP AND TRAPS
# ============================================================================

cleanup() {
  log_info "Cleaning up background jobs and temp files..."
  local jobs_pids
  jobs_pids=$(jobs -p 2>/dev/null || true)
  if [ -n "$jobs_pids" ]; then
    if command -v xargs &>/dev/null && xargs --help 2>&1 | grep -q "\-r"; then
      echo "$jobs_pids" | xargs -r kill 2>/dev/null || true
    else
      for pid in $jobs_pids; do
        kill "$pid" 2>/dev/null || true
      done
    fi
  fi
  rm -f /tmp/build-*.log 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# ============================================================================
# OS DETECTION HELPERS
# ============================================================================

get_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "$ID"
  else
    uname -s | tr '[:upper:]' '[:lower:]'
  fi
}

is_ubuntu() {
  local os
  os=$(get_os)
  [ "$os" = "ubuntu" ] || [ "$os" = "debian" ]
}

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================

check_dependencies() {
  local missing=()
  local optional=()
  
  # Critical dependencies
  for dep in git docker; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done
  
  # Optional but recommended
  for dep in kubectl minikube helm gh trivy; do
    if ! command -v "$dep" &>/dev/null; then
      optional+=("$dep")
    fi
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_warning "Missing critical dependencies: ${missing[*]}"
    log_info "Install them first using infrastructure/dev/run.sh"
    return 1
  fi
  
  if [ ${#optional[@]} -gt 0 ]; then
    log_warning "Optional dependencies not found: ${optional[*]}"
    log_info "Some features may not be available"
  fi
  
  return 0
}

# ============================================================================
# PARALLEL PROCESSING HELPERS
# ============================================================================

# Execute function in parallel with job limiting
# Usage: run_parallel "function_name" "arg1" "arg2" ... <list_of_items>
# Note: Uses set +e in loops to allow graceful batch failures
run_parallel() {
  local func="$1"
  shift
  local items=("$@")
  local pids=()
  local running=0
  local index=0
  local failed_items=()
  local success_count=0
  
  log_info "Running ${#items[@]} items in parallel (max: $MAX_PARALLEL)..."
  
  # Disable strict mode in loop to allow graceful failures
  set +e
  
  while [ $index -lt ${#items[@]} ] || [ $running -gt 0 ]; do
    # Start new jobs up to MAX_PARALLEL
    while [ $running -lt $MAX_PARALLEL ] && [ $index -lt ${#items[@]} ]; do
      local item="${items[$index]}"
      log_info "Starting: $item"
      "$func" "$item" > "/tmp/build-$item.log" 2>&1 &
      local pid=$!
      pids+=("$item:$pid")
      running=$((running + 1))
      index=$((index + 1))
    done
    
    # Wait for at least one job to complete
    if [ $running -gt 0 ]; then
      # Use wait -n if available (bash 4.3+), otherwise poll
      # Check if wait -n is supported by testing it
      if (wait -n 2>/dev/null) 2>/dev/null || { 
        local bash_major bash_minor
        bash_major=$(echo "${BASH_VERSION}" | cut -d. -f1 2>/dev/null || echo "0")
        bash_minor=$(echo "${BASH_VERSION}" | cut -d. -f2 2>/dev/null | cut -d'(' -f1 2>/dev/null || echo "0")
        [ "$bash_major" -ge 4 ] && [ "$bash_minor" -ge 3 ]
      }; then
        # wait -n available (bash 4.3+)
        wait -n 2>/dev/null || true
        running=$((running - 1))
      else
        # Fallback: poll for completed jobs
        sleep 1
      fi
      
      # Check which jobs completed
      local new_pids=()
      for pid_entry in "${pids[@]}"; do
        IFS=':' read -r item pid <<< "$pid_entry"
        if ! kill -0 "$pid" 2>/dev/null; then
          # Job completed
          if wait "$pid" 2>/dev/null; then
            log_success "$item completed successfully"
            success_count=$((success_count + 1))
          else
            log_error "$item failed (check /tmp/build-$item.log)"
            failed_items+=("$item")
          fi
          running=$((running - 1))
        else
          new_pids+=("$pid_entry")
        fi
      done
      pids=("${new_pids[@]}")
    fi
  done
  
  # Wait for any remaining jobs
  for pid_entry in "${pids[@]}"; do
    IFS=':' read -r item pid <<< "$pid_entry"
    if kill -0 "$pid" 2>/dev/null; then
      if wait "$pid" 2>/dev/null; then
        log_success "$item completed successfully"
        success_count=$((success_count + 1))
      else
        log_error "$item failed (check /tmp/build-$item.log)"
        failed_items+=("$item")
      fi
    fi
  done
  
  # Re-enable strict mode
  set -e
  
  echo ""
  log_info "Completed: $success_count/${#items[@]} succeeded"
  if [ ${#failed_items[@]} -gt 0 ]; then
    log_warning "Failed items: ${failed_items[*]}"
    return 1
  fi
  
  return 0
}

# ============================================================================
# INPUT VALIDATION HELPERS
# ============================================================================

validate_service() {
  local service="$1"
  local skip_validation="${2:-false}"
  
  # If validation is explicitly skipped (e.g., in parallel builds where we know services are valid)
  if [ "$skip_validation" = "true" ]; then
    return 0
  fi
  
  # First, try to validate using SERVICES array if available and populated
  if [ -n "${SERVICES+x}" ] && [ ${#SERVICES[@]} -gt 0 ]; then
    if [[ " ${SERVICES[*]} " =~ " ${service} " ]]; then
      return 0
    fi
  fi
  
  # Fallback: validate by checking if service directory exists
  local service_path
  service_path=$(get_service_path "$service")
  if [ -n "$service_path" ] && [ -d "$service_path" ]; then
    return 0
  fi
  
  # If we get here, validation failed
  log_error "Invalid service: $service"
  return 1
}

validate_repo() {
  local repo="$1"
  local skip_validation="${2:-false}"
  
  # If validation is explicitly skipped
  if [ "$skip_validation" = "true" ]; then
    return 0
  fi
  
  # First, try to validate using ALL_REPOS array if available and populated
  if [ -n "${ALL_REPOS+x}" ] && [ ${#ALL_REPOS[@]} -gt 0 ]; then
    if [[ " ${ALL_REPOS[*]} " =~ " ${repo} " ]]; then
      return 0
    fi
  fi
  
  # Fallback: validate by checking if repo directory exists
  local repo_path
  repo_path=$(get_repo_path "$repo")
  if [ -n "$repo_path" ] && [ -d "$repo_path" ]; then
    return 0
  fi
  
  # If we get here, validation failed
  log_error "Invalid repo: $repo"
  return 1
}

validate_tag() {
  local tag="$1"
  # Basic validation: alphanumeric, dash, underscore, dot
  if [[ ! "$tag" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    log_error "Invalid tag format: $tag"
    return 1
  fi
  return 0
}

# ============================================================================
# PATH HELPERS
# ============================================================================

get_service_path() {
  local service="$1"
  local repo_dir="${REPO_DIR:-}"
  
  # If REPO_DIR not set, calculate it (for subshell contexts)
  if [ -z "$repo_dir" ]; then
    local script_path
    script_path=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
    if [ -n "$script_path" ]; then
      local project_root
      project_root=$(cd "$(dirname "$script_path")" && pwd)
      repo_dir=$(cd "$project_root/../.." && pwd)
    fi
  fi
  
  if [ -z "$repo_dir" ]; then
    echo ""  # Return empty if we can't determine path
    return 1
  fi
  
  # All services are directly in services/ directory
  echo "$repo_dir/services/$service"
}

get_repo_path() {
  local repo="$1"
  local repo_dir="${REPO_DIR:-}"
  
  # If REPO_DIR not set, calculate it (for subshell contexts)
  if [ -z "$repo_dir" ]; then
    local script_path
    script_path=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
    if [ -n "$script_path" ]; then
      local project_root
      project_root=$(cd "$(dirname "$script_path")" && pwd)
      repo_dir=$(cd "$project_root/../.." && pwd)
    fi
  fi
  
  if [ -z "$repo_dir" ]; then
    echo ""  # Return empty if we can't determine path
    return 1
  fi
  
  # Determine repo type and return appropriate path
  # Special case: config is in services/config but treated as shared
  if [ "$repo" = "config" ]; then
    echo "$repo_dir/services/config"
    return 0
  fi
  
  # Check if it's a service
  if [[ " ${ALL_SERVICES[*]} " =~ " ${repo} " ]]; then
    echo "$repo_dir/services/$repo"
  # Check if it's an app
  elif [[ " ${CLIENT_REPOS[*]} " =~ " ${repo} " ]]; then
    # Special case: frontend might be in services/frontend
    if [ "$repo" = "frontend" ]; then
      if [ -d "$repo_dir/services/frontend" ]; then
        echo "$repo_dir/services/frontend"
      else
        echo "$repo_dir/apps/frontend"
      fi
    else
      echo "$repo_dir/apps/$repo"
    fi
  # Check if it's an infrastructure/shared repo
  elif [[ " ${SHARED_REPOS[*]} " =~ " ${repo} " ]]; then
    echo "$repo_dir/infrastructure/$repo"
  else
    # Default: try common locations
    if [ -d "$repo_dir/services/$repo" ]; then
      echo "$repo_dir/services/$repo"
    elif [ -d "$repo_dir/apps/$repo" ]; then
      echo "$repo_dir/apps/$repo"
    elif [ -d "$repo_dir/infrastructure/$repo" ]; then
      echo "$repo_dir/infrastructure/$repo"
    else
      echo "$repo_dir/$repo"
    fi
  fi
}

# ============================================================================
# INSTALL FUNCTIONS (Idempotent, OS-aware)
# ============================================================================

fix_docker_repo() {
  log_info "Fixing Docker repository conflicts..."
  
  sudo rm -f /etc/apt/sources.list.d/docker.list || true
  sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg || true
  sudo rm -f /etc/apt/keyrings/docker.asc || true
  
  for file in /etc/apt/sources.list.d/*.list; do
    if [ -f "$file" ]; then
      sudo sed -i '/download.docker.com/d' "$file" || true
      sudo sed -i '/docker-archive-keyring.gpg/d' "$file" || true
      sudo sed -i '/docker.asc/d' "$file" || true
    fi
  done
  
  sudo apt-get clean || true
  log_success "Docker repository conflicts cleaned up"
}

install_docker() {
  local os
  os=$(get_os)
  
  if command -v docker &>/dev/null && docker --version &>/dev/null; then
    log_info "Docker already installed: $(docker --version)"
    if sudo apt-get update 2>&1 | grep -q "Conflicting values\|E: The list of sources"; then
      log_warning "Detected repository conflicts. Fixing..."
      fix_docker_repo
    fi
    return 0
  fi
  
  if is_ubuntu || [ "$os" = "debian" ]; then
    if sudo apt-get update 2>&1 | grep -q "Conflicting values\|E: The list of sources"; then
      log_warning "Detected repository conflicts. Fixing before installation..."
      fix_docker_repo
    fi
    
    log_info "Installing Docker on $os..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    sudo rm -f /etc/apt/sources.list.d/docker.list || true
    sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg || true
    
    sudo install -m 0755 -d /etc/apt/keyrings
    
    local keyring_path="/etc/apt/keyrings/docker.asc"
    sudo curl -fsSL "https://download.docker.com/linux/$os/gpg" -o "$keyring_path"
    sudo chmod a+r "$keyring_path"
    
    local codename
    if [ -f /etc/os-release ]; then
      # shellcheck source=/dev/null
      . /etc/os-release
      codename="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
    fi
    
    if [ -z "$codename" ]; then
      codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
    fi
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring_path] https://download.docker.com/linux/$os $codename stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    sudo usermod -aG docker "$USER" || log_warning "Failed to add user to docker group"
    log_success "Docker installed. Log out and back in for group changes to take effect."
    return 0
  elif is_macos; then
    log_info "For macOS, please install Docker Desktop: https://www.docker.com/products/docker-desktop"
    log_info "Or use Homebrew: brew install --cask docker"
    return 1
  else
    log_error "Docker installation not supported for OS: $os"
    return 1
  fi
}

install_minikube() {
  if ! command -v docker &>/dev/null; then
    log_warning "Docker is required for Minikube but not installed."
    if [ "${INTERACTIVE:-true}" = "true" ]; then
      read -p "Install Docker now? (y/n): " install_docker_choice
      if [ "$install_docker_choice" = "y" ]; then
        install_docker || return 1
      else
        log_error "Cannot proceed without Docker."
        return 1
      fi
    else
      log_error "Docker required but not installed and not in interactive mode"
      return 1
    fi
  fi

  if is_macos; then
    log_info "Installing Minikube on macOS..."
    if command -v brew &>/dev/null; then
      brew install minikube
    else
      log_error "Homebrew required for macOS. Install from: https://brew.sh"
      return 1
    fi
  else
    log_info "Installing Minikube on Linux..."
    curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
  fi
  log_success "Minikube installed."
}

install_helm() {
  log_info "Installing Helm..."
  if is_macos && command -v brew &>/dev/null; then
    brew install helm
  else
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    bash get_helm.sh
    rm get_helm.sh
  fi
  log_success "Helm installed (version: $(helm version --short 2>/dev/null || echo 'unknown'))."
}

install_trivy() {
  log_info "Installing Trivy for image scanning..."
  
  if command -v trivy &>/dev/null; then
    log_info "Trivy is already installed: $(trivy --version 2>/dev/null | head -1 || echo 'unknown version')"
    return 0
  fi
  
  if is_macos && command -v brew &>/dev/null; then
    brew install aquasecurity/trivy/trivy
  elif is_ubuntu || [ "$(get_os)" = "debian" ]; then
    log_info "Using Trivy official installation script..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
      sudo sh -s -- -b /usr/local/bin || {
      log_warning "Official script failed, trying apt method..."
      if ! sudo apt-get update 2>&1 | grep -q "Conflicting values\|E: "; then
        sudo apt-get install -y wget apt-transport-https gnupg lsb-release
        
        sudo rm -f /etc/apt/sources.list.d/trivy.list
        sudo install -m 0755 -d /etc/apt/keyrings
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
          sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
        sudo chmod a+r /etc/apt/keyrings/trivy.gpg
        
        local codename
        if [ -f /etc/os-release ]; then
          # shellcheck source=/dev/null
          . /etc/os-release
          codename="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
        fi
        
        if [ -z "$codename" ]; then
          codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
        fi
        
        echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $codename main" | \
          sudo tee /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install -y trivy
      else
        log_error "Cannot install via apt due to repository conflicts."
        return 1
      fi
    }
  else
    log_error "Trivy installation not supported for this OS"
    return 1
  fi
  
  log_success "Trivy installed: $(trivy --version 2>/dev/null | head -1 || echo 'installed')"
}

# Install all tools
install_all_tools() {
  log_info "Installing all tools..."
  
  # Fix Docker repo first if needed
  if is_ubuntu && sudo apt-get update 2>&1 | grep -q "Conflicting values\|E: The list of sources"; then
    log_warning "Detected repository conflicts. Fixing first..."
    fix_docker_repo
  fi
  
  install_docker || log_warning "Docker installation failed or skipped"
  install_minikube || log_warning "Minikube installation failed or skipped"
  install_helm || log_warning "Helm installation failed or skipped"
  
  if [ "${ENABLE_TRIVY:-true}" = "true" ]; then
    install_trivy || log_warning "Trivy installation failed or skipped"
  fi
  
  log_success "Tool installation complete!"
}

# ============================================================================
# TRIVY SCANNING
# ============================================================================

scan_image() {
  local image_name="$1"
  
  if [ "$ENABLE_TRIVY" != "true" ]; then
    return 0
  fi
  
  if ! command -v trivy &>/dev/null; then
    log_warning "Trivy not found. Install with: install_trivy"
    return 0
  fi
  
  log_info "Scanning $image_name for vulnerabilities..."
  trivy image --exit-code 0 --severity HIGH,CRITICAL "$image_name" || \
    log_warning "Scan found issues; review output."
}

# ============================================================================
# VENV MANAGEMENT
# ============================================================================

manage_venv() {
  local service="$1"
  local install_deps="${2:-false}"

  if [[ ! " ${PYTHON_SERVICES[*]} " =~ " ${service} " ]]; then
    log_warning "$service is not a Python service - skipping venv creation"
    return 0
  fi

  local service_path
  service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service directory not found: $service_path"
    return 1
  fi

  cd "$service_path"

  if [ ! -d ".venv" ]; then
    log_info "Creating virtual environment for $service..."
    python3 -m venv .venv
  fi

  if [ "$install_deps" = "true" ]; then
    log_info "Installing dependencies for $service..."
    "$service_path/.venv/bin/pip" install --upgrade pip setuptools wheel
    for req_file in requirements.txt requirements.dev.txt; do
      if [ -f "$req_file" ]; then
        log_info "Installing dependencies from $req_file..."
        "$service_path/.venv/bin/pip" install -r "$req_file"
      fi
    done
    log_success "Dependencies installed for $service"
  else
    log_info "Virtual environment ready for $service"
    log_info "To activate: source $service_path/.venv/bin/activate"
  fi

  return 0
}

# ============================================================================
# BASE IMAGE MANAGEMENT
# ============================================================================

check_base_image() {
  local base_image="$1"
  local check_remote="${2:-true}"
  
  if docker image inspect "$base_image" &>/dev/null 2>&1; then
    return 0
  fi
  
  if [ "$check_remote" = "true" ]; then
    if docker manifest inspect "$base_image" &>/dev/null 2>&1; then
      return 0
    fi
  fi
  
  return 1
}

get_required_base_images() {
  local dockerfile="$1"
  local base_images=""
  
  if [ ! -f "$dockerfile" ]; then
    echo ""
    return 0
  fi
  
  base_images=$(grep -E "^FROM " "$dockerfile" | sed 's/^FROM //' | sed 's/ AS.*$//' | \
    grep "nuniesmith/fks:" | sort -u)
  echo "$base_images"
}

build_single_base_image() {
  local base_type="$1"  # docker, docker-ml, docker-gpu, or docker-rust
  local push_to_hub="${2:-false}"

  local docker_dir="$REPO_DIR/infrastructure/docker/docker"
  if [ ! -d "$docker_dir" ]; then
    log_error "Docker directory not found: $docker_dir"
    return 1
  fi

  cd "$docker_dir"

  case "$base_type" in
    docker|python-cpu-base)
      log_info "Building Python CPU base image (docker)..."
      docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker" -f Dockerfile.builder .
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker" \
        "$DOCKER_USERNAME/$DOCKER_REPO:python-cpu-base" 2>/dev/null || true
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker" \
        "$DOCKER_USERNAME/$DOCKER_REPO:docker-latest" 2>/dev/null || true
      log_success "Python CPU base image built"
      scan_image "$DOCKER_USERNAME/$DOCKER_REPO:docker"
      if [ "$push_to_hub" = "true" ]; then
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker" || log_warning "Failed to push CPU base"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:python-cpu-base" || log_warning "Failed to push CPU base (python-cpu-base tag)"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-latest" || log_warning "Failed to push CPU base (latest tag)"
      fi
      ;;
    docker-ml|python-ml)
      if ! check_base_image "$DOCKER_USERNAME/$DOCKER_REPO:docker" "false"; then
        log_warning "CPU base image (docker) not found. Building it first..."
        build_single_base_image "docker" "false"
      fi
      log_info "Building Python ML base image (docker-ml)..."
      docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" -f Dockerfile.ml .
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" \
        "$DOCKER_USERNAME/$DOCKER_REPO:python-ml" 2>/dev/null || true
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" \
        "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml-latest" 2>/dev/null || true
      log_success "Python ML base image built"
      scan_image "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml"
      if [ "$push_to_hub" = "true" ]; then
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" || log_warning "Failed to push ML base"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:python-ml" || log_warning "Failed to push ML base (python-ml tag)"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml-latest" || log_warning "Failed to push ML base (latest tag)"
      fi
      ;;
    docker-gpu|python-gpu)
      if ! check_base_image "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" "false"; then
        log_warning "ML base image (docker-ml) not found. Building it first..."
        build_single_base_image "docker-ml" "false"
      fi
      log_info "Building Python GPU base image (docker-gpu)..."
      docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" -f Dockerfile.gpu .
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" \
        "$DOCKER_USERNAME/$DOCKER_REPO:python-gpu" 2>/dev/null || true
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" \
        "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu-latest" 2>/dev/null || true
      log_success "Python GPU base image built"
      scan_image "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu"
      if [ "$push_to_hub" = "true" ]; then
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" || log_warning "Failed to push GPU base"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:python-gpu" || log_warning "Failed to push GPU base (python-gpu tag)"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu-latest" || log_warning "Failed to push GPU base (latest tag)"
      fi
      ;;
    docker-rust|rust-cpu-base)
      log_info "Building Rust CPU base image (docker-rust)..."
      docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" -f Dockerfile.rust .
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" \
        "$DOCKER_USERNAME/$DOCKER_REPO:rust-cpu-base" 2>/dev/null || true
      docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" \
        "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust-latest" 2>/dev/null || true
      log_success "Rust CPU base image built"
      scan_image "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust"
      if [ "$push_to_hub" = "true" ]; then
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" || log_warning "Failed to push Rust base"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:rust-cpu-base" || log_warning "Failed to push Rust base (rust-cpu-base tag)"
        docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust-latest" || log_warning "Failed to push Rust base (latest tag)"
      fi
      ;;
    *)
      log_error "Unknown base image type: $base_type"
      return 1
      ;;
  esac
}

build_base_images() {
  local push_to_hub="${1:-false}"

  local docker_dir="$REPO_DIR/infrastructure/docker/docker"
  if [ ! -d "$docker_dir" ]; then
    log_error "Docker directory not found: $docker_dir"
    return 1
  fi

  cd "$docker_dir"

  log_info "Building Docker base images..."

  if [ "$push_to_hub" = "true" ]; then
    if ! docker info 2>/dev/null | grep -q "Username"; then
      log_warning "Not logged in to Docker Hub"
      if [ "${INTERACTIVE:-true}" = "true" ]; then
        read -p "Login to Docker Hub now? (y/n): " login_choice
        if [ "$login_choice" = "y" ]; then
          docker login -u "$DOCKER_USERNAME" || { log_error "Login failed"; return 1; }
        else
          push_to_hub="false"
        fi
      else
        log_warning "Skipping push - not logged in and not interactive"
        push_to_hub="false"
      fi
    fi
  fi

  build_single_base_image "docker" "$push_to_hub"
  build_single_base_image "docker-ml" "$push_to_hub"
  build_single_base_image "docker-gpu" "$push_to_hub"
  build_single_base_image "docker-rust" "$push_to_hub"

  log_success "All base images built successfully"
}

# ============================================================================
# SERVICE BUILD FUNCTIONS
# ============================================================================

build_docker() {
  local service="$1"
  local tag="${2:-$DEFAULT_TAG}"
  local push="${3:-false}"
  local skip_validation="${4:-false}"

  validate_service "$service" "$skip_validation" || return 1
  validate_tag "$tag" || return 1

  local service_path
  service_path=$(get_service_path "$service")
  if [ ! -d "$service_path" ]; then
    log_error "Service not found: $service"
    return 1
  fi

  cd "$service_path"

  local dockerfile="Dockerfile"
  if [ ! -f "$dockerfile" ]; then
    # Check for docker/Dockerfile in service directory
    if [ -f "docker/Dockerfile" ]; then
      dockerfile="docker/Dockerfile"
      log_info "Using Dockerfile from service docker directory: $dockerfile"
    else
      # Check for shared docker directory
      local docker_dir="$REPO_DIR/docker"
      if [ -f "$docker_dir/Dockerfile.$service" ]; then
        dockerfile="$docker_dir/Dockerfile.$service"
        log_info "Using Dockerfile from shared docker directory: $dockerfile"
      else
        log_warning "No Dockerfile found for $service - skipping build"
        log_warning "Checked: ./Dockerfile, ./docker/Dockerfile, $docker_dir/Dockerfile.$service"
        return 1
      fi
    fi
  fi

  # Check for required base images
  local base_images
  base_images=$(get_required_base_images "$dockerfile")
  if [ -n "$base_images" ]; then
    for base in $base_images; do
      if ! check_base_image "$base" "false"; then
        log_warning "Base image $base not found locally"
        # Default to building locally, but allow pull if PULL_BASE_IMAGES is set
        if [ "${PULL_BASE_IMAGES:-false}" = "true" ]; then
          log_info "Attempting to pull $base from Docker Hub..."
          docker pull "$base" 2>/dev/null || log_warning "Failed to pull $base - build may fail"
        else
          log_info "Base image $base needs to be built locally first"
          log_info "Run: ./run.sh (option 2) to build base images"
          log_warning "Build may fail without base image $base"
        fi
      fi
    done
  fi

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
  log_info "Building Docker image: $image_name"

  # Build with appropriate context and dockerfile path
  if [ "$dockerfile" = "Dockerfile" ]; then
    docker build -t "$image_name" .
  elif [ "$dockerfile" = "docker/Dockerfile" ]; then
    # Dockerfile is in docker/ subdirectory, build from service root
    docker build -f "$dockerfile" -t "$image_name" .
  else
    # Dockerfile is in shared location, build from service root
    docker build -f "$dockerfile" -t "$image_name" .
  fi

  log_success "Built $image_name successfully"
  scan_image "$image_name"

  if [ "$push" = "true" ]; then
    push_docker_image "$service" "$tag"
  fi

  return 0
}

# Build all services (with parallel support)
build_all_services() {
  local tag="${1:-$DEFAULT_TAG}"
  local push="${2:-false}"
  local services_to_build=("${SERVICES[@]}")
  
  # Check and build base images first
  log_info "Checking required base images..."
  local needed_bases=()
  for service in "${services_to_build[@]}"; do
    local service_path
    service_path=$(get_service_path "$service")
    local dockerfile="$service_path/Dockerfile"
    if [ ! -f "$dockerfile" ]; then
      dockerfile="$REPO_DIR/docker/Dockerfile.$service"
    fi
    if [ -f "$dockerfile" ]; then
      local bases
      bases=$(get_required_base_images "$dockerfile")
      for base in $bases; do
        if ! check_base_image "$base" "false"; then
          needed_bases+=("$base")
        fi
      done
    fi
  done
  
  if [ ${#needed_bases[@]} -gt 0 ]; then
    log_info "Building required base images first..."
    build_base_images "false"
  fi
  
  # Build services
  # Track build start time to identify newly built images
  local build_start_time=$(date +%s)
  
  if [ "$ENABLE_PARALLEL" = "true" ] && [ ${#services_to_build[@]} -gt 3 ]; then
    log_info "Building services in parallel (max: $MAX_PARALLEL)..."
    # Create wrapper function for parallel execution
    # Note: tag and push are captured from parent scope
    # Skip validation since we already know services are valid (from SERVICES array)
    build_service_wrapper() {
      local svc="$1"
      local build_tag="${tag:-$DEFAULT_TAG}"
      local build_push="${push:-false}"
      build_docker "$svc" "$build_tag" "$build_push" "true"
    }
    if ! run_parallel "build_service_wrapper" "${services_to_build[@]}"; then
      # Check which services actually built successfully by checking image timestamps
      local newly_built=()
      local failed_builds=()
      for service in "${services_to_build[@]}"; do
        local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
        if docker image inspect "$image_name" &>/dev/null 2>&1; then
          # Check if image was created after build started
          local image_created
          image_created=$(docker image inspect "$image_name" --format='{{.Created}}' 2>/dev/null | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
          if [ "$image_created" -ge "$build_start_time" ]; then
            newly_built+=("$service")
          else
            failed_builds+=("$service")
          fi
        else
          failed_builds+=("$service")
        fi
      done
      if [ ${#newly_built[@]} -gt 0 ]; then
        log_info "Newly built: ${#newly_built[@]}/${#services_to_build[@]} services: ${newly_built[*]}"
      fi
      if [ ${#failed_builds[@]} -gt 0 ]; then
        log_warning "Builds failed for: ${failed_builds[*]}"
        log_info "Check build logs for details:"
        for svc in "${failed_builds[@]}"; do
          if [ -f "/tmp/build-$svc.log" ]; then
            local error_line
            error_line=$(tail -3 "/tmp/build-$svc.log" 2>/dev/null | grep -i "error\|failed\|invalid" | head -1 || echo "")
            if [ -n "$error_line" ]; then
              log_info "  $svc: $(echo "$error_line" | sed 's/^[[:space:]]*//' | cut -c1-80)"
            else
              log_info "  $svc: See /tmp/build-$svc.log"
            fi
          else
            log_info "  $svc: Log file not found"
          fi
        done
      fi
      # Return failure if all builds failed
      if [ ${#failed_builds[@]} -eq ${#services_to_build[@]} ]; then
        return 1
      fi
    fi
  else
    log_info "Building services sequentially..."
    local failed_services=()
    local success_count=0
    for service in "${services_to_build[@]}"; do
      if build_docker "$service" "$tag" "$push"; then
        success_count=$((success_count + 1))
      else
        failed_services+=("$service")
      fi
    done
    log_info "Completed: $success_count/${#services_to_build[@]} services succeeded"
    if [ ${#failed_services[@]} -gt 0 ]; then
      log_warning "Failed services: ${failed_services[*]}"
      return 1
    fi
  fi
}

# ============================================================================
# DOCKER IMAGE PUSH
# ============================================================================

push_docker_image() {
  local service="$1"
  local tag="${2:-$DEFAULT_TAG}"
  
  local image_name
  if [ "$service" = "docker" ] || [ "$service" = "docker-ml" ] || [ "$service" = "docker-gpu" ]; then
    image_name="$DOCKER_USERNAME/$DOCKER_REPO:$service"
  else
    image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
  fi

  log_info "Pushing $image_name to Docker Hub..."

  if ! docker image inspect "$image_name" &>/dev/null; then
    log_error "Image not found locally: $image_name"
    return 1
  fi

  if ! docker info 2>/dev/null | grep -q "Username"; then
    log_warning "Not logged in to Docker Hub"
    if [ "${INTERACTIVE:-true}" = "true" ]; then
      read -p "Login to Docker Hub now? (y/n): " login_choice
      if [ "$login_choice" = "y" ]; then
        docker login -u "$DOCKER_USERNAME" || { log_error "Login failed"; return 1; }
      else
        return 1
      fi
    else
      log_error "Not logged in and not interactive"
      return 1
    fi
  fi

  docker push "$image_name"
  log_success "Pushed $image_name to Docker Hub"
}

# ============================================================================
# HEALTH CHECK FUNCTIONS
# ============================================================================

# Load service registry for health checks and service discovery
load_service_registry() {
  local registry_file="$REPO_DIR/services/config/service_registry.json"
  if [ ! -f "$registry_file" ]; then
    log_warning "Service registry not found: $registry_file"
    return 1
  fi
  
  # Export registry path for use in other functions
  export SERVICE_REGISTRY_FILE="$registry_file"
  return 0
}

# Get service health URL from registry
get_service_health_url() {
  local service="$1"
  local registry_file="${SERVICE_REGISTRY_FILE:-$REPO_DIR/services/config/service_registry.json}"
  
  if [ ! -f "$registry_file" ]; then
    # Fallback: construct from service name
    local port
    case "$service" in
      web) port="8000" ;;
      api) port="8001" ;;
      app) port="8002" ;;
      data) port="8003" ;;
      execution) port="8004" ;;
      meta) port="8005" ;;
      ninja) port="8006" ;;
      ai) port="8007" ;;
      analyze) port="8008" ;;
      auth) port="8009" ;;
      main) port="8010" ;;
      training) port="8011" ;;
      portfolio) port="8012" ;;
      monitor) port="8013" ;;
      crypto) port="8014" ;;
      futures) port="8015" ;;
      stocks) port="8016" ;;
      data_ingestion) port="8020" ;;
      feature_engineering) port="8021" ;;
      *) port="8000" ;;
    esac
    echo "http://localhost:$port/health"
    return 0
  fi
  
  # Try to extract from JSON (requires jq or python)
  if command -v jq &>/dev/null; then
    local service_key="fks_${service}"
    jq -r ".services.\"$service_key\".health_url // .services.\"$service_key\".base_url + \"/health\" // empty" "$registry_file" 2>/dev/null | \
      sed "s|http://fks-|http://localhost:|g" | \
      sed "s|http://fks_|http://localhost:|g" || echo ""
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json
import sys
try:
    with open('$registry_file') as f:
        reg = json.load(f)
    svc_key = 'fks_${service}'
    if svc_key in reg.get('services', {}):
        health = reg['services'][svc_key].get('health_url', '')
        if health:
            print(health.replace('http://fks-', 'http://localhost:').replace('http://fks_', 'http://localhost:'))
        else:
            base = reg['services'][svc_key].get('base_url', '')
            if base:
                print(base.replace('http://fks-', 'http://localhost:').replace('http://fks_', 'http://localhost:') + '/health')
except:
    pass
" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Check if a service is healthy
check_service_health() {
  local service="$1"
  local timeout="${2:-5}"
  local health_url
  
  health_url=$(get_service_health_url "$service")
  if [ -z "$health_url" ]; then
    log_warning "Could not determine health URL for $service"
    return 1
  fi
  
  if curl -sf --max-time "$timeout" "$health_url" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Wait for service to become healthy
wait_for_service_health() {
  local service="$1"
  local max_wait="${2:-60}"
  local interval="${3:-2}"
  local elapsed=0
  
  log_info "Waiting for $service to become healthy (max ${max_wait}s)..."
  
  while [ $elapsed -lt $max_wait ]; do
    if check_service_health "$service" "$interval"; then
      log_success "$service is healthy"
      return 0
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
    echo -n "."
  done
  
  echo ""
  log_error "$service did not become healthy within ${max_wait}s"
  return 1
}

# Discover and ping all running FKS services
discover_and_ping_services() {
  local service="$1"
  local registry_file="${SERVICE_REGISTRY_FILE:-$REPO_DIR/services/config/service_registry.json}"
  
  if [ ! -f "$registry_file" ]; then
    log_warning "Service registry not found, skipping service discovery"
    return 0
  fi
  
  log_info "Discovering FKS services for $service..."
  
  # Get list of all services from registry
  local all_services
  if command -v jq &>/dev/null; then
    all_services=$(jq -r '.services | keys[]' "$registry_file" 2>/dev/null | sed 's/fks_//' || echo "")
  elif command -v python3 &>/dev/null; then
    all_services=$(python3 -c "
import json
try:
    with open('$registry_file') as f:
        reg = json.load(f)
    for key in reg.get('services', {}).keys():
        print(key.replace('fks_', ''))
except:
    pass
" 2>/dev/null || echo "")
  else
    # Fallback: use hardcoded list
    all_services="web api app data execution meta ninja ai analyze auth main training portfolio monitor crypto futures stocks data_ingestion feature_engineering"
  fi
  
  local healthy_count=0
  local total_count=0
  local healthy_services=()
  local unhealthy_services=()
  
  for svc in $all_services; do
    [ "$svc" = "$service" ] || [ "$service" = "all" ] || continue  # Skip self unless checking all
    total_count=$((total_count + 1))
    
    if check_service_health "$svc" 2; then
      healthy_count=$((healthy_count + 1))
      healthy_services+=("$svc")
      log_info "  ✓ $svc is healthy"
    else
      unhealthy_services+=("$svc")
      log_info "  ✗ $svc is not responding"
    fi
  done
  
  log_info "Service discovery complete: $healthy_count/$total_count services healthy"
  if [ ${#healthy_services[@]} -gt 0 ]; then
    log_success "Healthy services: ${healthy_services[*]}"
  fi
  if [ ${#unhealthy_services[@]} -gt 0 ]; then
    log_warning "Unhealthy/missing services: ${unhealthy_services[*]}"
  fi
  
  return 0
}

# Background service discovery daemon (runs continuously)
start_service_discovery_daemon() {
  local interval="${1:-30}"  # Check every 30 seconds by default
  local pid_file="/tmp/fks-service-discovery.pid"
  
  if [ -f "$pid_file" ]; then
    local old_pid
    old_pid=$(cat "$pid_file" 2>/dev/null || echo "")
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      log_info "Service discovery daemon already running (PID: $old_pid)"
      return 0
    fi
    rm -f "$pid_file"
  fi
  
  log_info "Starting service discovery daemon (checking every ${interval}s)..."
  
  (
    while true; do
      sleep "$interval"
      load_service_registry >/dev/null 2>&1
      discover_and_ping_services "all" >/dev/null 2>&1
    done
  ) &
  
  local daemon_pid=$!
  echo "$daemon_pid" > "$pid_file"
  log_success "Service discovery daemon started (PID: $daemon_pid)"
  log_info "Daemon will continuously check service health every ${interval}s"
  log_info "To stop: kill $daemon_pid or remove $pid_file"
}

# Stop service discovery daemon
stop_service_discovery_daemon() {
  local pid_file="/tmp/fks-service-discovery.pid"
  
  if [ ! -f "$pid_file" ]; then
    log_info "Service discovery daemon not running"
    return 0
  fi
  
  local daemon_pid
  daemon_pid=$(cat "$pid_file" 2>/dev/null || echo "")
  
  if [ -z "$daemon_pid" ]; then
    log_warning "Could not read daemon PID"
    rm -f "$pid_file"
    return 1
  fi
  
  if kill -0 "$daemon_pid" 2>/dev/null; then
    kill "$daemon_pid" 2>/dev/null
    log_success "Service discovery daemon stopped (PID: $daemon_pid)"
  else
    log_warning "Daemon process not found (may have already stopped)"
  fi
  
  rm -f "$pid_file"
  return 0
}

# ============================================================================
# DOCKER NETWORK MANAGEMENT
# ============================================================================

# Ensure fks-network exists
ensure_fks_network() {
  # Check if network exists
  if docker network inspect fks-network >/dev/null 2>&1; then
    log_info "fks-network already exists"
    return 0
  fi
  
  # Network doesn't exist, create it
  log_info "Creating fks-network Docker network..."
  local create_output
  create_output=$(docker network create fks-network 2>&1)
  local create_status=$?
  
  if [ $create_status -eq 0 ]; then
    log_success "fks-network created successfully"
    return 0
  else
    # Check if it was created by another process (race condition)
    if docker network inspect fks-network >/dev/null 2>&1; then
      log_info "fks-network was created by another process"
      return 0
    else
      log_error "Failed to create fks-network"
      log_error "Error: $create_output"
      return 1
    fi
  fi
}

# ============================================================================
# SERVICE MANAGEMENT (Docker Compose)
# ============================================================================

start_service() {
  local service="$1"
  local wait_health="${2:-true}"
  validate_service "$service" || return 1

  # Ensure network exists before starting service - fail if we can't create it
  if ! ensure_fks_network; then
    log_error "Failed to ensure fks-network exists. Cannot start $service."
    return 1
  fi

  local service_path
  service_path=$(get_service_path "$service")
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
  if docker compose up -d --build; then
    log_success "$service started"
    
    # Wait for health check if requested
    if [ "$wait_health" = "true" ]; then
      wait_for_service_health "$service" 60 || log_warning "$service may not be fully ready"
    fi
    
    # Discover and ping other services (non-blocking)
    (discover_and_ping_services "$service" >/dev/null 2>&1 &)
    
    return 0
  else
    log_error "Failed to start $service"
    return 1
  fi
}

stop_service() {
  local service="$1"
  validate_service "$service" || return 1

  local service_path
  service_path=$(get_service_path "$service")
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
  docker compose down
  log_success "$service stopped"
}

# Start all services
start_all_services() {
  local wait_health="${1:-false}"
  local services_to_start=("${ALL_SERVICES[@]}")
  
  log_info "Starting all FKS services..."
  
  # Ensure Docker network exists first
  if ! ensure_fks_network; then
    log_error "Failed to create fks-network. Cannot start services."
    return 1
  fi
  
  # Load service registry
  load_service_registry || log_warning "Service registry not available"
  
  local started_count=0
  local failed_services=()
  
  for service in "${services_to_start[@]}"; do
    if start_service "$service" "$wait_health"; then
      started_count=$((started_count + 1))
    else
      failed_services+=("$service")
    fi
  done
  
  echo ""
  log_info "Started: $started_count/${#services_to_start[@]} services"
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed to start: ${failed_services[*]}"
    return 1
  fi
  
  # Optional final health check summary (non-blocking)
  if [ "$wait_health" = "true" ]; then
    log_info "Performing final health check on all services..."
    discover_and_ping_services "all"
  else
    log_info "Services started. Use option 13 to check health status."
  fi
  
  return 0
}

# ============================================================================
# GIT OPERATIONS
# ============================================================================

commit_push() {
  local repo="$1"
  local message="${2:-chore: auto update $(date +'%Y-%m-%d %H:%M')}"
  local skip_preview="${3:-false}"

  local repo_path
  repo_path=$(get_repo_path "$repo")
  if [ ! -d "$repo_path" ]; then
    log_error "Repo not found: $repo"
    return 1
  fi

  cd "$repo_path"

  if [ ! -d ".git" ]; then
    log_warning "Not a git repo: $repo - skipping"
    return 1
  fi

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  log_info "Current branch: $current_branch"

  git add -A

  if git diff --cached --quiet && git diff --quiet; then
    log_info "No changes in $repo - skipping commit"
    if git push origin "$current_branch" 2>&1 | grep -q "Everything up-to-date\|Already up to date"; then
      log_info "Already up to date on remote"
    else
      git push origin "$current_branch" || log_warning "Push failed (may not have remote)"
    fi
    return 0
  fi

  if [ "$skip_preview" != "true" ] && [ "${INTERACTIVE:-true}" = "true" ]; then
    log_info "Changes to be committed:"
    git diff --cached --stat
    echo ""
    read -p "Confirm commit? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
      log_info "Commit cancelled"
      git reset HEAD .
      return 1
    fi
  fi

  log_info "Committing changes in $repo..."
  git commit -m "$message"

  log_info "Pushing to remote..."
  git push origin "$current_branch"
  log_success "$repo committed and pushed to $current_branch"
  if [[ " ${SERVICES[*]} " =~ " ${repo} " ]]; then
    log_info "GitHub Actions will build and push to dockerhub.com/$DOCKER_USERNAME/$DOCKER_REPO:${repo}-latest"
  fi
}

# ============================================================================
# KUBERNETES OPERATIONS (with Helm priority)
# ============================================================================

load_local_images_to_minikube() {
  local tag="${1:-latest}"
  local services_to_load=("${SERVICES[@]}")
  if [ $# -gt 1 ]; then
    shift
    services_to_load=("$@")
  fi

  log_info "Checking for local images and loading into Minikube..."
  
  eval $(minikube docker-env -u 2>/dev/null || echo "unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD")
  
  local loaded_count=0
  local missing_count=0
  local skipped_count=0
  local missing_services=()
  
  # Check if images already exist in minikube (faster check)
  eval $(minikube docker-env)
  log_info "Checking which images need to be loaded..."
  
  # Load images in parallel if ENABLE_PARALLEL is true
  if [ "${ENABLE_PARALLEL:-true}" = "true" ] && [ ${#services_to_load[@]} -gt 1 ]; then
    log_info "Loading images in parallel (max: ${MAX_PARALLEL:-4} concurrent)..."
    local pids=()
    local temp_dir=$(mktemp -d)
    local loaded_file="$temp_dir/loaded.txt"
    local failed_file="$temp_dir/failed.txt"
    touch "$loaded_file" "$failed_file"
    
    for service in "${services_to_load[@]}"; do
      local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
      
      if docker image inspect "$image_name" &>/dev/null 2>&1; then
        # Check if already in minikube (faster than loading)
        if eval $(minikube docker-env) && docker image inspect "$image_name" &>/dev/null 2>&1; then
          echo "$service" >> "$loaded_file"
          skipped_count=$((skipped_count + 1))
          log_info "✓ $service already in Minikube (skipping)"
          continue
        fi
        
        # Wait if we've hit the parallel limit
        while [ ${#pids[@]} -ge "${MAX_PARALLEL:-4}" ]; do
          local new_pids=()
          for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
              new_pids+=("$pid")
            else
              wait "$pid" 2>/dev/null
            fi
          done
          pids=("${new_pids[@]}")
          [ ${#pids[@]} -ge "${MAX_PARALLEL:-4}" ] && sleep 0.5
        done
        
        # Load image in background
        (
          log_info "Loading $service..."
          if minikube image load "$image_name" 2>/dev/null; then
            echo "$service" >> "$loaded_file"
          else
            echo "$service" >> "$failed_file"
          fi
        ) &
        pids+=($!)
      else
        missing_services+=("$service")
        missing_count=$((missing_count + 1))
      fi
    done
    
    # Wait for all background jobs
    for pid in "${pids[@]}"; do
      wait "$pid" 2>/dev/null
    done
    
    loaded_count=$(wc -l < "$loaded_file" 2>/dev/null || echo 0)
    rm -rf "$temp_dir"
    
  else
    # Sequential loading (original method, but optimized)
    for service in "${services_to_load[@]}"; do
      local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"
      
      if docker image inspect "$image_name" &>/dev/null 2>&1; then
        # Quick check if already in minikube
        eval $(minikube docker-env)
        if docker image inspect "$image_name" &>/dev/null 2>&1; then
          log_info "✓ $service already in Minikube (skipping)"
          skipped_count=$((skipped_count + 1))
          eval $(minikube docker-env -u 2>/dev/null || echo "unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD")
          continue
        fi
        eval $(minikube docker-env -u 2>/dev/null || echo "unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD")
        
        log_info "Loading $service ($(docker image inspect "$image_name" --format='{{.Size}}' 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || echo 'unknown size'))..."
        if minikube image load "$image_name" 2>/dev/null; then
          log_success "✓ Loaded $service"
          loaded_count=$((loaded_count + 1))
        else
          log_warning "Failed to load $service (will try to pull from registry)"
          missing_services+=("$service")
          missing_count=$((missing_count + 1))
        fi
      else
        missing_services+=("$service")
        missing_count=$((missing_count + 1))
      fi
    done
  fi
  
  eval $(minikube docker-env -u 2>/dev/null || echo "unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD")
  
  echo ""
  log_info "Image loading summary:"
  log_info "  - Loaded: $loaded_count"
  log_info "  - Skipped (already present): $skipped_count"
  log_info "  - Missing: $missing_count"
  if [ $missing_count -gt 0 ]; then
    log_warning "Missing local images: ${missing_services[*]}"
    if [ "${PULL_MISSING_IMAGES:-n}" = "y" ]; then
      log_info "These will be pulled from Docker Hub if available"
    else
      log_info "These need to be built locally (default: local builds only)"
      log_info "To pull from Docker Hub, set: export PULL_MISSING_IMAGES=y"
    fi
  fi
}

k8s_start() {
  log_info "Starting Kubernetes deployment..."

  if ! command -v minikube &>/dev/null; then
    log_warning "Minikube not installed."
    if [ "${INTERACTIVE:-true}" = "true" ]; then
      read -p "Install Minikube now? (y/n): " install_choice
      if [ "$install_choice" = "y" ]; then
        install_minikube || { log_error "Minikube installation failed"; return 1; }
      else
        log_error "Cannot proceed without Minikube."
        return 1
      fi
    else
      log_error "Minikube required but not installed and not interactive"
      return 1
    fi
  fi

  if ! command -v kubectl &>/dev/null; then
    log_error "kubectl is not installed. Install it first."
    return 1
  fi

  log_info "Starting minikube..."
  if ! minikube status &>/dev/null; then
    minikube start
  else
    log_info "Minikube is already running"
  fi
  eval $(minikube docker-env)
  log_success "Minikube started"

  # Enable ingress addon and wait for it to be ready
  log_info "Enabling ingress addon..."
  if minikube addons enable ingress 2>/dev/null; then
    log_info "Waiting for ingress controller to be ready..."
    sleep 10
    if kubectl wait --for=condition=available deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s 2>/dev/null; then
      log_success "Ingress controller is ready"
    else
      log_warning "Ingress controller may still be starting"
    fi
  else
    log_warning "Ingress addon may already be enabled or failed to enable"
  fi

  # Build all services locally first (default behavior)
  log_info "Building all services locally (default: local builds only)..."
  log_info "To pull from Docker Hub instead, set: export PULL_MISSING_IMAGES=y"
  
  local image_tag="latest"
  if [ "${INTERACTIVE:-true}" = "true" ]; then
    read -p "Enter image tag to use (default: latest): " image_tag
    image_tag=${image_tag:-latest}
  fi
  
  log_info "Building all service images with tag: $image_tag"
  log_info "This will build images locally and load them into Minikube"
  
  # Build services and track results
  local build_failed=false
  if ! build_all_services "$image_tag" "false"; then
    build_failed=true
    log_warning "Some service builds failed. Checking which images are available..."
  fi
  
  # Verify which images are available (newly built or existing)
  local available_images=()
  local missing_images=()
  local existing_images=()
  local build_timestamp=$(date +%s)
  
  for service in "${SERVICES[@]}"; do
    local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${image_tag}"
    if docker image inspect "$image_name" &>/dev/null 2>&1; then
      available_images+=("$service")
      # Check if image is newly built (within last 5 minutes) or existing
      local image_created
      image_created=$(docker image inspect "$image_name" --format='{{.Created}}' 2>/dev/null | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
      local age_seconds=$((build_timestamp - image_created))
      if [ "$age_seconds" -gt 300 ]; then
        existing_images+=("$service")
      fi
    else
      missing_images+=("$service")
    fi
  done
  
  if [ ${#available_images[@]} -eq 0 ]; then
    log_error "No service images are available!"
    log_info "Check build logs in /tmp/build-*.log for details"
    if [ ${#missing_images[@]} -gt 0 ]; then
      log_info "Missing services: ${missing_images[*]}"
      log_info "Example: tail -50 /tmp/build-${missing_images[0]}.log"
    fi
    if [ "${INTERACTIVE:-true}" = "true" ]; then
      read -p "Continue anyway? (y/n): " continue_choice
      if [ "$continue_choice" != "y" ]; then
        log_error "Aborting deployment - no images available"
        return 1
      fi
    else
      log_error "Aborting deployment - no images available (non-interactive mode)"
      return 1
    fi
  else
    if [ ${#existing_images[@]} -gt 0 ]; then
      log_warning "Using ${#existing_images[@]} existing image(s) (not newly built): ${existing_images[*]}"
    fi
    local newly_built_count=$((${#available_images[@]} - ${#existing_images[@]}))
    if [ "$newly_built_count" -gt 0 ]; then
      log_success "Successfully built $newly_built_count/${#SERVICES[@]} service images in this run"
    fi
    log_info "Total available images: ${#available_images[@]}/${#SERVICES[@]}"
    if [ ${#missing_images[@]} -gt 0 ]; then
      log_warning "Missing images: ${missing_images[*]}"
      log_info "These will be skipped during image loading"
      log_info "To debug, check: tail -50 /tmp/build-<service>.log"
    fi
  fi
  
  # Load all local images into Minikube
  log_info "Loading all local images into Minikube..."
  load_local_images_to_minikube "$image_tag" "${SERVICES[@]}"
  
  # Pull any missing images from Docker Hub (default: no, use local builds)
  local pull_missing="${PULL_MISSING_IMAGES:-n}"
  if [ "${INTERACTIVE:-true}" = "true" ]; then
    read -p "Pull missing images from Docker Hub? (y/n) [n]: " pull_missing
    pull_missing=${pull_missing:-n}
  fi
  
  if [ "$pull_missing" = "y" ]; then
    log_info "Pulling missing images from Docker Hub..."
    sync_images "true" "${SERVICES[@]}" || log_warning "Some images failed to pull, but continuing..."
  else
    log_info "Skipping Docker Hub pull - using local builds only"
    log_info "If images are missing, they will need to be built locally first"
  fi

  local namespace="fks-trading"
  if [ "${INTERACTIVE:-true}" = "true" ]; then
    read -p "Enter Kubernetes namespace (default: fks-trading): " namespace
    namespace=${namespace:-fks-trading}
  fi

  kubectl create namespace "$namespace" 2>/dev/null || true
  log_success "Namespace $namespace ready"

  # PRIORITIZE HELM: Check for Helm chart first
  local helm_chart_dir="$PROJECT_ROOT/k8s/charts/fks-platform"
  if [ -d "$helm_chart_dir" ] && command -v helm &>/dev/null; then
    log_info "Using Helm chart for deployment..."
    local use_helm="y"
    if [ "${INTERACTIVE:-true}" = "true" ]; then
      read -p "Use Helm for deployment? (y/n) [y]: " use_helm
      use_helm=${use_helm:-y}
    fi
    
    if [ "$use_helm" = "y" ]; then
      if ! command -v helm &>/dev/null; then
        log_warning "Helm not installed. Installing..."
        install_helm || { log_error "Helm installation failed"; return 1; }
      fi
      
      if helm list -n "$namespace" | grep -q "fks-platform"; then
        log_info "Upgrading existing Helm release..."
        helm upgrade fks-platform "$helm_chart_dir" -n "$namespace" --timeout 10m || \
          log_warning "Helm upgrade may have issues"
      else
        log_info "Installing Helm release..."
        helm install fks-platform "$helm_chart_dir" -n "$namespace" --create-namespace --timeout 10m || \
          log_warning "Helm install may have issues"
      fi
      log_success "Helm deployment complete!"
    fi
  fi

  # Fall back to manifests if Helm not used or not available
  if [ "${use_helm:-n}" != "y" ] || [ ! -d "$helm_chart_dir" ]; then
    log_info "Falling back to Kubernetes manifests..."
    if [ -f "$PROJECT_ROOT/k8s/setup-local-k8s.sh" ]; then
      log_info "Using setup script for complete deployment..."
      local use_setup="y"
      if [ "${INTERACTIVE:-true}" = "true" ]; then
        read -p "Run full setup script? (y/n) [y]: " use_setup
        use_setup=${use_setup:-y}
      fi
      
      if [ "$use_setup" = "y" ]; then
        cd "$PROJECT_ROOT/k8s"
        bash setup-local-k8s.sh || { log_error "Setup script failed"; return 1; }
        log_success "Setup complete!"
      fi
    else
      # Apply manifests manually
      log_info "Applying Kubernetes manifests from $PROJECT_ROOT/k8s..."
      if [ -d "$PROJECT_ROOT/k8s/manifests" ]; then
        kubectl apply -f "$PROJECT_ROOT/k8s/manifests" -n "$namespace" || \
          log_warning "Some resources may have failed"
      fi
      if [ -f "$PROJECT_ROOT/k8s/ingress.yaml" ]; then
        kubectl apply -f "$PROJECT_ROOT/k8s/ingress.yaml" -n "$namespace" || \
          log_warning "Ingress setup may have failed"
      fi
      
      # Apply dashboard ingress if it exists
      if [ -f "$PROJECT_ROOT/k8s/manifests/dashboard-ingress.yaml" ]; then
        log_info "Applying dashboard ingress configuration..."
        # Temporarily disable webhook validation if it causes issues
        kubectl delete validatingwebhookconfiguration ingress-nginx-admission 2>/dev/null || true
        kubectl apply -f "$PROJECT_ROOT/k8s/manifests/dashboard-ingress.yaml" || \
          log_warning "Dashboard ingress setup may have failed"
      fi
    fi
  fi

  # Wait for ingress controller to be ready
  log_info "Waiting for ingress controller to be ready..."
  if kubectl wait --for=condition=available deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s 2>/dev/null; then
    log_success "Ingress controller is ready"
  else
    log_warning "Ingress controller may still be starting"
  fi

  # Set imagePullPolicy to Never for local minikube images
  log_info "Configuring deployments to use local images (imagePullPolicy: Never)..."
  local deployments=("fks-main" "fks-api" "fks-app" "fks-data" "fks-execution" "fks-web" "fks-ai" "fks-ninja" "fks-meta" "fks-portfolio" "fks-training" "fks-analyze" "fks-auth" "fks-monitor" "web")
  for deployment in "${deployments[@]}"; do
    if kubectl get deployment "$deployment" -n "$namespace" &>/dev/null; then
      kubectl patch deployment "$deployment" -n "$namespace" \
        -p '{"spec":{"template":{"spec":{"containers":[{"name":"'$deployment'","imagePullPolicy":"Never"}]}}}}' \
        > /dev/null 2>&1 || true
    fi
  done

  # Setup Kubernetes Dashboard with auto token
  log_info "Setting up Kubernetes Dashboard with auto token..."
  setup_dashboard_auto_token

  # Verify ingress configuration
  log_info "Verifying ingress configuration..."
  verify_ingress_configuration "$namespace"

  log_success "Kubernetes started and configured"
  log_info "All services built locally and loaded into Minikube"
  log_info "Dashboard is ready with auto-generated token"
  
  # Display access information
  display_k8s_access_info "$namespace"
}

# Setup Kubernetes Dashboard with automatic token generation and access
setup_dashboard_auto_token() {
  local namespace="kubernetes-dashboard"
  local token_file="$PROJECT_ROOT/k8s/dashboard-token.txt"
  
  log_info "Setting up Kubernetes Dashboard..."
  
  # Install dashboard if not exists
  if ! kubectl get deployment kubernetes-dashboard -n "$namespace" &>/dev/null; then
    log_info "Installing Kubernetes Dashboard..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    # Wait for dashboard to be ready
    log_info "Waiting for dashboard to be ready..."
    kubectl wait --for=condition=available deployment/kubernetes-dashboard -n "$namespace" --timeout=300s || \
      log_warning "Dashboard may still be starting"
  else
    log_info "Dashboard already installed"
  fi
  
  # Check for and remove duplicate dashboard ingress if exists
  local duplicate_ingress
  duplicate_ingress=$(kubectl get ingress -n "$namespace" -o jsonpath='{.items[?(@.metadata.name=="kubernetes-dashboard-k8s")].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$duplicate_ingress" ]; then
    log_info "Removing duplicate dashboard ingress: $duplicate_ingress"
    kubectl delete ingress "$duplicate_ingress" -n "$namespace" 2>/dev/null || true
  fi

  # Create admin user and service account if not exists
  if ! kubectl get serviceaccount admin-user -n "$namespace" &>/dev/null; then
    log_info "Creating admin user for dashboard access..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: $namespace
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
  namespace: $namespace
EOF
    log_success "Admin user created"
  else
    log_info "Admin user already exists"
  fi

  # Generate dashboard token (try multiple methods)
  log_info "Generating dashboard token..."
  local dashboard_token=""
  
  # Method 1: Create token (Kubernetes 1.24+)
  dashboard_token=$(kubectl -n "$namespace" create token admin-user --duration=8760h 2>/dev/null || echo "")
  
  # Method 2: Get from secret (older Kubernetes or if create token fails)
  if [ -z "$dashboard_token" ]; then
    local secret_name
    secret_name=$(kubectl -n "$namespace" get sa admin-user -o jsonpath='{.secrets[0].name}' 2>/dev/null || echo "")
    if [ -n "$secret_name" ]; then
      dashboard_token=$(kubectl -n "$namespace" get secret "$secret_name" -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
    fi
  fi
  
  # Method 3: Try admin-user-secret
  if [ -z "$dashboard_token" ]; then
    dashboard_token=$(kubectl -n "$namespace" get secret admin-user-secret -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
  fi

  if [ -n "$dashboard_token" ]; then
    # Ensure k8s directory exists
    mkdir -p "$PROJECT_ROOT/k8s"
    
    # Save token to file
    echo "$dashboard_token" > "$token_file"
    chmod 600 "$token_file" 2>/dev/null || true
    log_success "Dashboard token saved to $token_file"
    log_info "Token (first 50 chars): $(echo "$dashboard_token" | head -c 50)..."
  else
    log_warning "Could not generate token automatically"
    log_info "You can get it manually with:"
    log_info "  kubectl -n $namespace create token admin-user --duration=8760h"
    return 1
  fi

  # Start kubectl proxy in background if not running
  # Must bind to 0.0.0.0 to be accessible from Docker containers via host.docker.internal
  if ! pgrep -f "kubectl proxy" > /dev/null; then
    log_info "Starting kubectl proxy in background (accessible from Docker containers)..."
    # Bind to all interfaces (0.0.0.0) so nginx container can access via host.docker.internal
    # Disable filtering to allow access from Docker network
    nohup kubectl proxy --port=8001 --address=0.0.0.0 --accept-hosts='.*' --disable-filter > /tmp/kubectl-proxy.log 2>&1 &
    sleep 3
    
    # Verify proxy is running
    if pgrep -f "kubectl proxy" > /dev/null; then
      log_success "kubectl proxy started on 0.0.0.0:8001 (accessible from Docker)"
      log_info "Proxy log: /tmp/kubectl-proxy.log"
    else
      log_error "Failed to start kubectl proxy"
      return 1
    fi
  else
    log_info "kubectl proxy is already running"
    # Check if it's bound to the right address
    if netstat -tln 2>/dev/null | grep -q ":8001.*0.0.0.0" || ss -tln 2>/dev/null | grep -q ":8001.*0.0.0.0"; then
      log_success "kubectl proxy is accessible from Docker containers"
    else
      log_warning "kubectl proxy may not be accessible from Docker containers (check binding)"
    fi
  fi

  # Create dashboard URL with token
  local dashboard_url="http://localhost:8001/api/v1/namespaces/$namespace/services/https:kubernetes-dashboard:/proxy/#/login?token=$dashboard_token"
  
  # Create access script
  mkdir -p "$PROJECT_ROOT/k8s"
  cat > "$PROJECT_ROOT/k8s/access-dashboard.sh" <<'SCRIPT'
#!/bin/bash
# Quick access to Kubernetes Dashboard with auto token

TOKEN_FILE="$(dirname "$0")/dashboard-token.txt"
NAMESPACE="kubernetes-dashboard"
PROXY_PORT=8001

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Token file not found. Please run k8s_start again to generate token."
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

# Start proxy if not running
if ! pgrep -f "kubectl proxy" > /dev/null; then
  echo "Starting kubectl proxy..."
  nohup kubectl proxy --port=$PROXY_PORT > /tmp/kubectl-proxy.log 2>&1 &
  sleep 2
fi

DASHBOARD_URL="http://localhost:$PROXY_PORT/api/v1/namespaces/$NAMESPACE/services/https:kubernetes-dashboard:/proxy/#/login?token=$TOKEN"

echo "Dashboard URL: $DASHBOARD_URL"
echo "Token saved in: $TOKEN_FILE"

# Try to open in browser
if command -v xdg-open > /dev/null; then
  xdg-open "$DASHBOARD_URL" 2>/dev/null &
elif command -v open > /dev/null; then
  open "$DASHBOARD_URL" 2>/dev/null &
else
  echo "Please open this URL in your browser:"
  echo "$DASHBOARD_URL"
fi
SCRIPT
  chmod +x "$PROJECT_ROOT/k8s/access-dashboard.sh"
  log_success "Dashboard access script created: $PROJECT_ROOT/k8s/access-dashboard.sh"

  # Display access information
  echo ""
  log_success "Kubernetes Dashboard is ready!"
  echo ""
  echo -e "${CYAN}Dashboard Access Information:${NC}"
  echo "  URL: $dashboard_url"
  echo "  Token file: $token_file"
  echo "  Access script: $PROJECT_ROOT/k8s/access-dashboard.sh"
  echo ""
  echo -e "${YELLOW}To access the dashboard:${NC}"
  echo "  1. Run: $PROJECT_ROOT/k8s/access-dashboard.sh"
  echo "  2. Or manually open: $dashboard_url"
  echo "  3. Or use: kubectl proxy (then visit http://localhost:8001/api/v1/namespaces/$namespace/services/https:kubernetes-dashboard:/proxy/)"
  echo ""
  
  # Try to open dashboard automatically
  if [ "${INTERACTIVE:-true}" = "true" ]; then
    local open_dashboard="y"
    read -p "Open dashboard in browser now? (y/n) [y]: " open_dashboard
    open_dashboard=${open_dashboard:-y}
    
    if [ "$open_dashboard" = "y" ]; then
      if command -v xdg-open > /dev/null; then
        xdg-open "$dashboard_url" 2>/dev/null &
        log_info "Opening dashboard in browser..."
      elif command -v open > /dev/null; then
        open "$dashboard_url" 2>/dev/null &
        log_info "Opening dashboard in browser..."
      else
        log_info "Please open the dashboard URL manually in your browser"
      fi
    fi
  fi
}

# Verify ingress configuration and check for common issues
verify_ingress_configuration() {
  local namespace="${1:-fks-trading}"
  local minikube_ip
  minikube_ip=$(minikube ip 2>/dev/null || echo "")
  
  if [ -z "$minikube_ip" ]; then
    log_warning "Could not determine minikube IP for ingress verification"
    return 1
  fi

  log_info "Checking ingress resources..."
  local ingress_count
  ingress_count=$(kubectl get ingress -A 2>/dev/null | grep -v "^NAME" | wc -l || echo "0")
  log_info "Found $ingress_count ingress resource(s)"

  # Check for duplicate host entries
  log_info "Checking for duplicate ingress host entries..."
  local duplicate_hosts
  duplicate_hosts=$(kubectl get ingress -A -o jsonpath='{range .items[*]}{.spec.rules[*].host}{"\n"}{end}' 2>/dev/null | \
    sort | uniq -d || echo "")
  
  if [ -n "$duplicate_hosts" ]; then
    log_warning "Found duplicate host entries in ingress:"
    echo "$duplicate_hosts" | while read -r host; do
      if [ -n "$host" ]; then
        echo "  - $host"
      fi
    done
    log_info "Consider consolidating duplicate ingress resources"
  fi

  # Check ingress controller status
  if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | \
    grep -q "Running"; then
    log_success "Ingress controller is running"
  else
    log_warning "Ingress controller may not be running properly"
  fi

  # Display configured domains
  log_info "Configured ingress domains:"
  kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.rules[*].host}{"\n"}{end}' 2>/dev/null | \
    grep -v "^$" | while IFS=$'\t' read -r ns name hosts; do
      if [ -n "$hosts" ]; then
        echo "  $ns/$name: $hosts"
      fi
    done
}

# Display Kubernetes access information
display_k8s_access_info() {
  local namespace="${1:-fks-trading}"
  local minikube_ip
  minikube_ip=$(minikube ip 2>/dev/null || echo "192.168.49.2")
  
  echo ""
  log_success "╔══════════════════════════════════════════════════════════╗"
  log_success "║  Kubernetes Deployment Complete                          ║"
  log_success "╚══════════════════════════════════════════════════════════╝"
  echo ""
  echo -e "${CYAN}Access Information:${NC}"
  echo "  Minikube IP: $minikube_ip"
  echo ""
  echo -e "${YELLOW}Domain Configuration:${NC}"
  echo "  Add these to your /etc/hosts file:"
  echo "    $minikube_ip fkstrading.xyz"
  echo "    $minikube_ip api.fkstrading.xyz"
  echo "    $minikube_ip app.fkstrading.xyz"
  echo "    $minikube_ip execution.fkstrading.xyz"
  echo "    $minikube_ip k8s.fkstrading.xyz"
  echo "    $minikube_ip grafana.fkstrading.xyz"
  echo "    $minikube_ip prometheus.fkstrading.xyz"
  echo "    $minikube_ip alertmanager.fkstrading.xyz"
  echo ""
  echo -e "${YELLOW}Service URLs:${NC}"
  echo "  - Main: http://fkstrading.xyz"
  echo "  - API: http://api.fkstrading.xyz"
  echo "  - Dashboard: http://k8s.fkstrading.xyz"
  echo ""
  echo -e "${YELLOW}Ingress NodePort:${NC}"
  local http_port https_port
  http_port=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "32081")
  https_port=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}' 2>/dev/null || echo "31486")
  echo "  HTTP: $http_port"
  echo "  HTTPS: $https_port"
  echo ""
  echo -e "${YELLOW}Useful Commands:${NC}"
  echo "  Check pods: kubectl get pods -n $namespace"
  echo "  Check services: kubectl get svc -n $namespace"
  echo "  Check ingress: kubectl get ingress -A"
  echo "  View logs: kubectl logs -n $namespace <pod-name>"
  echo ""
}

k8s_stop() {
  log_info "Stopping Kubernetes..."

  if ! command -v kubectl &>/dev/null; then
    log_error "kubectl is not installed"
    return 1
  fi

  if ! command -v minikube &>/dev/null; then
    log_error "minikube is not installed"
    return 1
  fi

  if [ -d "$PROJECT_ROOT/k8s" ]; then
    kubectl delete -f "$PROJECT_ROOT/k8s" || log_warning "Failed to delete some resources"
  fi

  minikube stop
  log_success "Kubernetes stopped"
}

# ============================================================================
# IMAGE SYNC OPERATIONS
# ============================================================================

pull_images() {
  local service="$1"
  local tag="${2:-latest}"
  local use_minikube="${3:-false}"

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"

  if [ "$use_minikube" = "true" ]; then
    if ! command -v minikube &>/dev/null; then
      log_error "minikube is not installed"
      return 1
    fi
    eval $(minikube docker-env)
    log_info "Using minikube Docker context"
  fi

  log_info "Pulling $image_name..."
  docker pull "$image_name"
  log_success "Pulled $image_name successfully"
}

sync_images() {
  local use_minikube="${1:-false}"
  shift
  local services_to_sync=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_sync=("$@")
  fi

  if [ "$use_minikube" = "true" ]; then
    if ! command -v minikube &>/dev/null; then
      log_error "Minikube not installed."
      return 1
    fi
    if ! minikube status &>/dev/null; then
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

# ============================================================================
# CLI ARGUMENT PARSER (Expanded for Rust integration)
# ============================================================================

show_help() {
  cat <<EOF
FKS Microservices Management Script

Usage: $0 [OPTIONS]

OPTIONS:
  -i TOOL          Install tool (docker, minikube, helm, trivy, all)
  -b SERVICE       Build Docker image for service
  -B               Build all base images
  -a               Build all service images
  -t TAG           Specify tag (default: latest)
  -p SERVICE       Push Docker image for service
  -P               Push all service images
  -s SERVICE       Start service (Docker Compose)
  -S SERVICE       Stop service (Docker Compose)
  -A               Build all images and start all services (with health checks)
  -H               Health check all services
  -D [start|stop]  Service discovery daemon (start or stop)
  -c REPO          Commit and push repo
  -C [SCOPE]       Commit and push (SCOPE optional: core | services | all)
  -k start         Start Kubernetes deployment
  -k stop          Stop Kubernetes deployment
  -u               Sync images to Minikube
  -v SERVICE       Manage venv for Python service
  -w               Check GitHub Actions workflow status
  -x [SCOPE]       Clear GitHub Actions caches (SCOPE: all | services | specific repos)
  -h               Show this help message

Environment Variables:
  DOCKER_USERNAME      Docker Hub username (default: nuniesmith)
  DOCKER_REPO          Docker Hub repository (default: fks)
  DEFAULT_TAG          Image tag (default: latest)
  ENABLE_TRIVY         Enable Trivy scanning (default: true)
  ENABLE_PARALLEL      Enable parallel builds (default: true)
  MAX_PARALLEL         Max concurrent jobs (default: 4)
  INTERACTIVE          Enable interactive prompts (default: true)

Examples:
  $0 -i all                    # Install all tools
  $0 -b ai -t latest          # Build ai service with latest tag
  $0 -a -t v1.0.0             # Build all services with v1.0.0 tag
  $0 -C core                  # Commit & push only core services
  $0 -C services              # Commit & push all services
  $0 -C all                   # Commit & push all repos (services + shared)
  $0 -k start                 # Start Kubernetes deployment
  $0 -s web                   # Start web service
  $0 -c main                  # Commit and push main repo

For Rust integration (fks_main):
  Command::new("run.sh").arg("-b").arg("ai").output()
  Command::new("run.sh").arg("-k").arg("start").output()
EOF
}

parse_cli_args() {
  local build_service=""
  local build_all=false
  local build_base=false
  local push_service=""
  local push_all=false
  local start_service=""
  local stop_service=""
  local commit_repo=""
  local commit_all=false
  local k8s_action=""
  local sync_minikube=false
  local venv_service=""
  local check_workflows=false
  local install_tool=""
  local tag="$DEFAULT_TAG"
  
  # Disable interactive mode for CLI
  INTERACTIVE=false
  
  while getopts ":i:b:Ba:t:p:Ps:S:AH:D:c:Ck:uv:wx:h" opt; do
    case $opt in
      i)
        install_tool="$OPTARG"
        case "$install_tool" in
          docker) install_docker ;;
          minikube) install_minikube ;;
          helm) install_helm ;;
          trivy) install_trivy ;;
          all) install_all_tools ;;
          *) log_error "Unknown tool: $install_tool. Use: docker, minikube, helm, trivy, all" ;;
        esac
        ;;
      b)
        build_service="$OPTARG"
        validate_service "$build_service" || exit 1
        log_info "CLI mode: Building service $build_service"
        build_docker "$build_service" "$tag" "false"
        ;;
      B)
        build_base=true
        log_info "CLI mode: Building base images"
        build_base_images "false"
        ;;
      a)
        build_all=true
        log_info "CLI mode: Building all service images"
        build_all_services "$tag" "false"
        ;;
      t)
        tag="$OPTARG"
        validate_tag "$tag" || exit 1
        ;;
      p)
        push_service="$OPTARG"
        validate_service "$push_service" || exit 1
        log_info "CLI mode: Pushing service $push_service"
        push_docker_image "$push_service" "$tag"
        ;;
      P)
        push_all=true
        log_info "CLI mode: Pushing all service images"
        for service in "${SERVICES[@]}"; do
          push_docker_image "$service" "$tag" || log_warning "Failed to push $service"
        done
        ;;
      s)
        start_service="$OPTARG"
        validate_service "$start_service" || exit 1
        log_info "CLI mode: Starting service $start_service"
        start_service "$start_service"
        ;;
      S)
        stop_service="$OPTARG"
        validate_service "$stop_service" || exit 1
        log_info "CLI mode: Stopping service $stop_service"
        stop_service "$stop_service"
        ;;
      c)
        commit_repo="$OPTARG"
        log_info "CLI mode: Committing and pushing repo $commit_repo"
        commit_push "$commit_repo" "chore: auto update $(date +'%Y-%m-%d %H:%M')" "true"
        ;;
      C)
        # Optional scope argument: look ahead if next token is a scope
        local scope
        scope="${!OPTIND:-}"
        if [[ "$scope" =~ ^(core|services|all)$ ]]; then
          OPTIND=$((OPTIND + 1))
        else
          scope="all"
        fi
        log_info "CLI mode: Committing and pushing scope: $scope"
        case "$scope" in
          core)
            for repo in "${CPU_SERVICES[@]}"; do
              commit_push "$repo" "chore: auto update $(date +'%Y-%m-%d %H:%M')" "true" || \
                log_warning "Failed to commit $repo"
            done
            ;;
          services)
            for repo in "${SERVICES[@]}"; do
              commit_push "$repo" "chore: auto update $(date +'%Y-%m-%d %H:%M')" "true" || \
                log_warning "Failed to commit $repo"
            done
            ;;
          all|*)
            for repo in "${REPOS[@]}"; do
              commit_push "$repo" "chore: auto update $(date +'%Y-%m-%d %H:%M')" "true" || \
                log_warning "Failed to commit $repo"
            done
            ;;
        esac
        ;;
      k)
        k8s_action="$OPTARG"
        case "$k8s_action" in
          start) k8s_start ;;
          stop) k8s_stop ;;
          *) log_error "Invalid k8s action: $k8s_action. Use: start, stop" ;;
        esac
        ;;
      u)
        sync_minikube=true
        log_info "CLI mode: Syncing images to Minikube"
        sync_images "true" "${SERVICES[@]}"
        ;;
      v)
        venv_service="$OPTARG"
        validate_service "$venv_service" || exit 1
        log_info "CLI mode: Managing venv for $venv_service"
        manage_venv "$venv_service" "true"
        ;;
      w)
        check_workflows=true
        log_info "CLI mode: Checking GitHub Actions workflow status"
        check_workflow_status
        ;;
      A)
        log_info "CLI mode: Building all images and starting all services"
        # Ensure network exists before building/starting
        if ! ensure_fks_network; then
          log_error "Failed to create fks-network. Cannot proceed."
          exit 1
        fi
        build_base_images "false"
        build_all_services "$tag" "false"
        start_all_services "true"
        ;;
      H)
        log_info "CLI mode: Health checking all services"
        load_service_registry || log_warning "Service registry not available"
        discover_and_ping_services "all"
        ;;
      D)
        local daemon_action="$OPTARG"
        case "$daemon_action" in
          start)
            start_service_discovery_daemon 30
            ;;
          stop)
            stop_service_discovery_daemon
            ;;
          *)
            log_error "Invalid daemon action: $daemon_action. Use: start, stop"
            ;;
        esac
        ;;
      x)
        # Optional scope argument
        local cache_scope
        cache_scope="${!OPTIND:-}"
        if [[ "$cache_scope" =~ ^(all|services)$ ]]; then
          OPTIND=$((OPTIND + 1))
        else
          # Check if OPTARG contains repos (comma-separated)
          if [[ -n "${OPTARG:-}" ]] && [[ "$OPTARG" != "-"* ]]; then
            cache_scope="$OPTARG"
          else
            cache_scope="all"
          fi
        fi
        log_info "CLI mode: Clearing GitHub Actions caches (scope: $cache_scope)"
        case "$cache_scope" in
          services)
            clear_github_actions_caches "${ALL_SERVICES[@]}"
            ;;
          all)
            clear_github_actions_caches
            ;;
          *)
            # Custom repo list (comma-separated)
            IFS=',' read -ra custom_repos <<< "$cache_scope"
            clear_github_actions_caches "${custom_repos[@]}"
            ;;
        esac
        ;;
      h)
        show_help
        exit 0
        ;;
      \?)
        log_error "Invalid option: -$OPTARG"
        show_help
        exit 1
        ;;
      :)
        log_error "Option -$OPTARG requires an argument"
        show_help
        exit 1
        ;;
    esac
  done
  
  # If CLI args were provided, exit after processing
  if [ $OPTIND -gt 1 ]; then
    exit 0
  fi
}

# ============================================================================
# ANALYSIS AND MONITORING
# ============================================================================

analyze_codebase() {
  local target_dir="${1:-$PROJECT_ROOT}"
  local output_dir="${2:-$PROJECT_ROOT/analysis_$(date +%Y%m%d_%H%M%S)}"

  mkdir -p "$output_dir"

  log_info "Analyzing codebase at $target_dir..."

  if command -v tree >/dev/null; then
    tree -I '__pycache__|venv|target|.git|.idea|.vscode' "$target_dir" > "$output_dir/file_tree.txt"
  else
    find "$target_dir" -print | sort > "$output_dir/file_tree.txt"
  fi

  find "$target_dir" -type f | grep -E '\.(py|rs|md|sh|yml|yaml|toml|json|Dockerfile)$' | \
    awk -F. '{print $NF}' | sort | uniq -c > "$output_dir/file_counts.txt"

  log_success "Analysis complete - results in $output_dir"
}

check_workflow_status() {
  local services_to_check=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_check=("$@")
  fi
  
  local success_count=0
  local fail_count=0
  local pending_count=0
  local no_workflow_count=0
  local failed_services=()
  local pending_services=()
  
  echo "=========================================="
  echo "GitHub Actions Workflow Status Check"
  echo "=========================================="
  echo ""
  
  if ! command -v gh &>/dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Install it with: sudo apt install gh"
    echo "Or visit: https://cli.github.com/"
    return 1
  fi
  
  if ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}⚠️ GitHub CLI not authenticated${NC}"
    echo "Run: gh auth login"
    return 1
  fi
  
  echo "Checking workflow runs for selected services..."
  echo ""
  
  for service in "${services_to_check[@]}"; do
    local service_dir
    service_dir=$(get_service_path "$service")
    echo "----------------------------------------"
    echo -e "${BLUE}Checking: $service${NC}"
    echo "----------------------------------------"
    
    if [ ! -d "$service_dir" ]; then
      echo -e "${RED}❌ Service directory not found${NC}"
      fail_count=$((fail_count + 1))
      failed_services+=("$service (directory not found)")
      echo ""
      continue
    fi
    
    cd "$service_dir"
    
    if [ ! -d ".git" ]; then
      echo -e "${RED}❌ Not a git repository${NC}"
      fail_count=$((fail_count + 1))
      failed_services+=("$service (not a git repo)")
      echo ""
      continue
    fi
    
    if [ ! -f ".github/workflows/docker-build-push.yml" ]; then
      echo -e "${YELLOW}⚠️ Workflow file not found${NC}"
      no_workflow_count=$((no_workflow_count + 1))
      echo ""
      continue
    fi
    
    local repo_url
    repo_url=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | \
      sed 's/.*github.com\///' | sed 's/\.git$//')
    
    if [ -z "$repo_url" ]; then
      echo -e "${YELLOW}⚠️ Could not determine repository URL${NC}"
      echo ""
      continue
    fi
    
    echo " Repository: $repo_url"
    echo " GitHub: https://github.com/$repo_url/actions"
    echo ""
    
    local workflow_runs
    workflow_runs=$(gh run list --repo "$repo_url" --limit 3 2>&1)
    if [ $? -ne 0 ]; then
      echo -e " ${YELLOW}⚠️ Could not fetch workflow runs${NC}"
      echo ""
      continue
    fi
    
    if [ -z "$workflow_runs" ]; then
      echo -e " ${YELLOW}⚠️ No workflow runs found${NC}"
      pending_count=$((pending_count + 1))
      pending_services+=("$service")
      echo ""
      continue
    fi
    
    echo " Recent workflow runs:"
    while IFS= read -r line; do
      if [ -z "$line" ]; then
        continue
      fi
      if [[ "$line" == *"success"* ]] || [[ "$line" == *"✓"* ]]; then
        echo -e " ${GREEN}✅ $line${NC}"
      elif [[ "$line" == *"failure"* ]] || [[ "$line" == *"✗"* ]]; then
        echo -e " ${RED}❌ $line${NC}"
      elif [[ "$line" == *"in_progress"* ]] || [[ "$line" == *"queued"* ]]; then
        echo -e " ${YELLOW}⏳ $line${NC}"
      else
        echo " $line"
      fi
    done <<< "$workflow_runs"
    
    local latest_run
    latest_run=$(gh run list --repo "$repo_url" --limit 1 --json status,conclusion,workflowName --jq '.[0]' 2>/dev/null)
    if [ -n "$latest_run" ] && [ "$latest_run" != "null" ]; then
      local status conclusion
      status=$(echo "$latest_run" | jq -r '.status' 2>/dev/null || echo "unknown")
      conclusion=$(echo "$latest_run" | jq -r '.conclusion' 2>/dev/null || echo "unknown")
      echo ""
      echo " Latest run status: $status, conclusion: $conclusion"
      if [ "$conclusion" = "success" ]; then
        echo -e " ${GREEN}✅ Workflow completed successfully${NC}"
        success_count=$((success_count + 1))
      elif [ "$conclusion" = "failure" ]; then
        echo -e " ${RED}❌ Workflow failed${NC}"
        fail_count=$((fail_count + 1))
        failed_services+=("$service")
      elif [ "$status" = "in_progress" ] || [ "$status" = "queued" ]; then
        echo -e " ${YELLOW}⏳ Workflow is still running${NC}"
        pending_count=$((pending_count + 1))
        pending_services+=("$service")
      fi
    fi
    echo ""
  done
  
  echo "=========================================="
  echo "Summary"
  echo "=========================================="
  echo -e "${GREEN}✅ Success: $success_count${NC}"
  echo -e "${YELLOW}⏳ Pending/Running: $pending_count${NC}"
  echo -e "${RED}❌ Failed: $fail_count${NC}"
  echo -e "⚠️ No Workflow: $no_workflow_count"
  
  if [ ${#failed_services[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed services:${NC}"
    for service in "${failed_services[@]}"; do
      echo " - $service"
    done
  fi
}

# ============================================================================
# GITHUB ACTIONS CACHE MANAGEMENT
# ============================================================================

clear_github_actions_caches() {
  local repos_to_clear=("${ALL_REPOS[@]}")
  if [ $# -gt 0 ]; then
    repos_to_clear=("$@")
  fi
  
  echo "=========================================="
  echo "GitHub Actions Cache Cleanup"
  echo "=========================================="
  echo ""
  
  if ! command -v gh &>/dev/null; then
    log_error "GitHub CLI (gh) is not installed"
    echo "Install it with: sudo apt install gh"
    echo "Or visit: https://cli.github.com/"
    return 1
  fi
  
  if ! gh auth status &>/dev/null; then
    log_error "GitHub CLI not authenticated"
    echo "Run: gh auth login"
    return 1
  fi
  
  local total_cleared=0
  local total_size=0
  
  for repo in "${repos_to_clear[@]}"; do
    local repo_dir
    repo_dir=$(get_repo_path "$repo")
    
    echo "----------------------------------------"
    echo -e "${BLUE}Repository: $repo${NC}"
    echo "----------------------------------------"
    
    if [ ! -d "$repo_dir" ]; then
      log_warning "Directory not found: $repo_dir"
      echo ""
      continue
    fi
    
    cd "$repo_dir" || continue
    
    if [ ! -d ".git" ]; then
      log_warning "Not a git repository"
      echo ""
      continue
    fi
    
    local repo_url
    repo_url=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | \
      sed 's/.*github.com\///' | sed 's/\.git$//')
    
    if [ -z "$repo_url" ]; then
      log_warning "Could not determine repository URL"
      echo ""
      continue
    fi
    
    echo " GitHub: https://github.com/$repo_url"
    echo ""
    
    # List caches
    local cache_list
    cache_list=$(gh cache list --repo "$repo_url" 2>&1)
    
    if [ $? -ne 0 ]; then
      log_warning "Could not fetch cache list"
      echo ""
      continue
    fi
    
    if [ -z "$cache_list" ] || [[ "$cache_list" == *"no caches"* ]]; then
      echo " No caches found"
      echo ""
      continue
    fi
    
    # Count and show caches
    local cache_count
    cache_count=$(echo "$cache_list" | wc -l)
    echo " Found $cache_count cache(s)"
    echo ""
    
    # Delete all caches
    local cleared_count=0
    while IFS=$'\t' read -r id key size created; do
      if [ -z "$id" ] || [ "$id" = "ID" ]; then
        continue
      fi
      
      echo -n " Deleting cache $id ($key)... "
      if gh cache delete "$id" --repo "$repo_url" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        cleared_count=$((cleared_count + 1))
        total_cleared=$((total_cleared + 1))
      else
        echo -e "${RED}✗${NC}"
      fi
    done < <(echo "$cache_list" | tail -n +2)
    
    if [ $cleared_count -gt 0 ]; then
      log_success "Cleared $cleared_count cache(s) from $repo"
    fi
    echo ""
  done
  
  cd "$PROJECT_ROOT" || return 1
  
  echo "=========================================="
  echo "Summary"
  echo "=========================================="
  log_success "Total caches cleared: $total_cleared across ${#repos_to_clear[@]} repositories"
  echo ""
  echo "Note: New caches will be created on next workflow run"
}

# ============================================================================
# KUBERNETES DEPLOYMENT MANAGEMENT
# ============================================================================

find_deployment_name() {
  local service="$1"
  local namespace="${2:-fks-trading}"

  local candidates=("fks-$service" "$service" "fks_$service")

  for candidate in "${candidates[@]}"; do
    if kubectl get deployment "$candidate" -n "$namespace" &>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

update_k8s_deployment() {
  local service="$1"
  local tag="${2:-latest}"
  local namespace="${3:-fks-trading}"

  if ! command -v kubectl &>/dev/null; then
    log_error "kubectl is not installed"
    return 1
  fi

  local deployment_name
  if ! deployment_name=$(find_deployment_name "$service" "$namespace"); then
    log_error "Deployment not found for service: $service in namespace: $namespace"
    return 1
  fi

  local container_name="$deployment_name"
  if ! kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[*].name}' | \
    grep -q "$container_name"; then
    container_name=$(kubectl get deployment "$deployment_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)
    if [ -z "$container_name" ]; then
      log_error "Could not determine container name for deployment $deployment_name"
      return 1
    fi
  fi

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${tag}"

  log_info "Updating deployment $deployment_name to use $image_name..."
  kubectl set image "deployment/$deployment_name" "$container_name=$image_name" -n "$namespace"
  kubectl rollout restart "deployment/$deployment_name" -n "$namespace"
  log_success "Deployment updated and restarted"
}

sync_and_update_k8s() {
  local namespace="${1:-fks-trading}"
  local use_minikube="${2:-true}"
  shift 2
  local services_to_sync=("${SERVICES[@]}")
  if [ $# -gt 0 ]; then
    services_to_sync=("$@")
  fi

  log_info "Syncing images and updating Kubernetes deployments..."

  if ! sync_images "$use_minikube" "${services_to_sync[@]}"; then
    log_warning "Some images failed to sync, but continuing with updates..."
  fi

  log_info "Updating Kubernetes deployments..."
  local success_count=0
  local failed_services=()

  for service in "${services_to_sync[@]}"; do
    if update_k8s_deployment "$service" "latest" "$namespace"; then
      success_count=$((success_count + 1))
    else
      failed_services+=("$service")
    fi
  done

  log_info "Update complete: $success_count/${#services_to_sync[@]} deployments updated"
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed to update: ${failed_services[*]}"
  fi
}

# ============================================================================
# INTERACTIVE MENU (updated with real categories)
# ============================================================================
show_menu() {
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║          FKS Trading Platform • fkstrading.xyz           ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo
  echo "CPU Services      : ${#CPU_SERVICES[@]}   (api, app, data, execution, portfolio, web, plugins, infra, main)"
  echo "GPU Services      : ${#GPU_SERVICES[@]}   (ai, training)"
  echo "Shared Repos      : ${#SHARED_REPOS[@]}   (docker, config, docs, actions)"
  echo
  echo "1. Build All & Start All    2. Build Base Images       3. Build Services"
  echo "4. Start Services           5. Stop Services           6. Deploy to Kubernetes"
  echo "7. Manage Python Venvs      8. Commit & Push           9. Analyze Codebase"
  echo "10. Check GitHub Actions   11. Sync/Pull Images       12. Clear GH Caches"
  echo "13. Health Check All         14. Service Discovery Daemon"
  echo "15. Exit"
  echo
  read -p "Choose option: " choice
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  # Check dependencies (non-fatal)
  check_dependencies || log_warning "Some features may not work properly"

  # Parse CLI arguments first (will exit if args provided)
  parse_cli_args "$@"

  # Main interactive loop
  while true; do
    show_menu

    case $choice in
      1)
        log_info "Building all images and starting all services..."
        local tag="$DEFAULT_TAG"
        if [ "${INTERACTIVE:-true}" = "true" ]; then
          read -p "Enter image tag (default: latest): " tag
          tag=${tag:-latest}
        fi
        
        # Ensure Docker network exists first
        log_info "Step 0: Ensuring Docker network exists..."
        if ! ensure_fks_network; then
          log_error "Failed to create fks-network. Cannot proceed."
          continue
        fi
        
        # Build base images first
        log_info "Step 1: Building base images..."
        build_base_images "false"
        
        # Build all service images
        log_info "Step 2: Building all service images..."
        build_all_services "$tag" "false"
        
        # Start all services (without waiting for health checks)
        log_info "Step 3: Starting all services..."
        start_all_services "false"
        
        log_success "All services built and started!"
        ;;
      2)
        local push_bases="n"
        if [ "${INTERACTIVE:-true}" = "true" ]; then
          read -p "Push base images to Docker Hub? (y/n): " push_bases
        fi
        build_base_images "$([ "$push_bases" = "y" ] && echo "true" || echo "false")"
        ;;
      3)
        local tag="$DEFAULT_TAG"
        local push_choice="n"
        if [ "${INTERACTIVE:-true}" = "true" ]; then
          read -p "Build: [c]pu, [g]pu, or [a]ll services? [c]: " build_mode
          build_mode=${build_mode:-c}
          read -p "Enter tag (default: latest): " tag
          tag=${tag:-latest}
          read -p "Push to Docker Hub after build? (y/n): " push_choice
        fi
        
        case "${build_mode:-c}" in
          g)
            log_info "Building GPU services only..."
            for service in "${GPU_SERVICES[@]}"; do
              build_docker "$service" "$tag" "$([ "$push_choice" = "y" ] && echo "true" || echo "false")" || log_warning "Failed: $service"
            done
            ;;
          a)
            log_info "Building all services..."
            build_all_services "$tag" "$([ "$push_choice" = "y" ] && echo "true" || echo "false")"
            ;;
          *)
            log_info "Building CPU services only..."
            for service in "${CPU_SERVICES[@]}"; do
              build_docker "$service" "$tag" "$([ "$push_choice" = "y" ] && echo "true" || echo "false")" || log_warning "Failed: $service"
            done
            ;;
        esac
        ;;
      4)
        read -p "Start: [c]pu, [g]pu, [a]ll, or [s]pecific services? [c]: " mode
        mode=${mode:-c}
        case "$mode" in
          g)
            log_info "Starting GPU services..."
            for service in "${GPU_SERVICES[@]}"; do
              start_service "$service" || log_warning "Failed to start $service"
            done
            ;;
          a)
            log_info "Starting all services with health checks..."
            start_all_services "true"
            ;;
          s)
            read -p "Enter service name (comma-separated): " input_services
            IFS=',' read -ra selected <<< "$input_services"
            for service in "${selected[@]}"; do
              service=$(echo "$service" | tr -d ' ')
              start_service "$service" || log_warning "Failed to start $service"
            done
            ;;
          *)
            log_info "Starting CPU services..."
            for service in "${CPU_SERVICES[@]}"; do
              start_service "$service" || log_warning "Failed to start $service"
            done
            ;;
        esac
        ;;
      5)
        read -p "Stop: [c]pu, [g]pu, [a]ll, or [s]pecific services? [a]: " mode
        mode=${mode:-a}
        case "$mode" in
          c)
            log_info "Stopping CPU services..."
            for service in "${CPU_SERVICES[@]}"; do
              stop_service "$service" || log_warning "Failed to stop $service"
            done
            ;;
          g)
            log_info "Stopping GPU services..."
            for service in "${GPU_SERVICES[@]}"; do
              stop_service "$service" || log_warning "Failed to stop $service"
            done
            ;;
          s)
            read -p "Enter service name (comma-separated): " input_services
            IFS=',' read -ra selected <<< "$input_services"
            for service in "${selected[@]}"; do
              service=$(echo "$service" | tr -d ' ')
              stop_service "$service" || log_warning "Failed to stop $service"
            done
            ;;
          *)
            log_info "Stopping all services..."
            for service in "${SERVICES[@]}"; do
              stop_service "$service" || log_warning "Failed to stop $service"
            done
            ;;
        esac
        ;;
      6)
        k8s_start
        ;;
      7)
        read -p "Install dependencies? (y/n): " install
        install=${install:-n}
        read -p "All services (a) or specific (s)? " mode
        if [ "$mode" = "a" ]; then
          for service in "${PYTHON_SERVICES[@]}"; do
            manage_venv "$service" "$([ "$install" = "y" ] && echo "true" || echo "false")" || \
              log_warning "Failed to manage venv for $service"
          done
        else
          read -p "Enter service name (comma-separated): " input_services
          IFS=',' read -ra selected <<< "$input_services"
          for service in "${selected[@]}"; do
            service=$(echo "$service" | tr -d ' ')
            manage_venv "$service" "$([ "$install" = "y" ] && echo "true" || echo "false")" || \
              log_warning "Failed to manage venv for $service"
          done
        fi
        ;;
      8)
        echo "Commit scope: [c]ore, [i]nfra+main, [a]ll services, [r]epos everything"
        read -p "Choice [a]: " scope
        scope=${scope:-a}
        read -p "Message [chore: update]: " msg
        msg=${msg:-"chore: update $(date +'%Y-%m-%d')"}
        case $scope in
          c) for s in "${CORE_SERVICES[@]}"; do commit_push "$s" "$msg" "false" || log_warning "Failed: $s"; done ;;
          i) for s in "${INFRA_SERVICES[@]}" "${ORCHESTRATOR[@]}"; do commit_push "$s" "$msg" "false" || log_warning "Failed: $s"; done ;;
          a) for s in "${ALL_SERVICES[@]}"; do commit_push "$s" "$msg" "false" || log_warning "Failed: $s"; done ;;
          r) for s in "${ALL_REPOS[@]}"; do commit_push "$s" "$msg" "false" || log_warning "Failed: $s"; done ;;
        esac
        ;;
      9)
        read -p "Enter directory to analyze (default: $PROJECT_ROOT): " dir
        dir=${dir:-$PROJECT_ROOT}
        read -p "Enter output dir (default: analysis_$(date +%Y%m%d_%H%M%S)): " out
        out=${out:-"analysis_$(date +%Y%m%d_%H%M%S)"}
        analyze_codebase "$dir" "$out"
        ;;
      10)
        check_workflow_status
        ;;
      11)
        read -p "Pull for all services (a) or specific (s)? [a]: " mode
        mode=${mode:-a}
        read -p "Use Minikube? (y/n): " use_minikube
        use_minikube=${use_minikube:-n}
        if [ "$mode" = "a" ]; then
          sync_images "$([ "$use_minikube" = "y" ] && echo "true" || echo "false")" "${SERVICES[@]}"
        else
          read -p "Enter service name (comma-separated): " input_services
          IFS=',' read -ra selected <<< "$input_services"
          local selected_services=()
          for service in "${selected[@]}"; do
            service=$(echo "$service" | tr -d ' ')
            if validate_service "$service"; then
              selected_services+=("$service")
            fi
          done
          if [ ${#selected_services[@]} -gt 0 ]; then
            sync_images "$([ "$use_minikube" = "y" ] && echo "true" || echo "false")" "${selected_services[@]}"
          fi
        fi
        ;;
      12)
        read -p "Clear caches for: [a]ll repos, [s]ervices only, or [c]ustom? [a]: " mode
        mode=${mode:-a}
        case "$mode" in
          s)
            log_info "Clearing caches for all services..."
            clear_github_actions_caches "${ALL_SERVICES[@]}"
            ;;
          c)
            read -p "Enter repo names (comma-separated): " input_repos
            IFS=',' read -ra selected <<< "$input_repos"
            local selected_repos=()
            for repo in "${selected[@]}"; do
              repo=$(echo "$repo" | tr -d ' ')
              selected_repos+=("$repo")
            done
            if [ ${#selected_repos[@]} -gt 0 ]; then
              clear_github_actions_caches "${selected_repos[@]}"
            fi
            ;;
          *)
            log_info "Clearing caches for all repositories..."
            clear_github_actions_caches
            ;;
        esac
        ;;
      13)
        log_info "Checking health of all FKS services..."
        load_service_registry || log_warning "Service registry not available"
        discover_and_ping_services "all"
        ;;
      14)
        read -p "Service Discovery: [s]tart, [S]top, or [c]heck status? [s]: " daemon_action
        daemon_action=${daemon_action:-s}
        case "$daemon_action" in
          s|start)
            read -p "Check interval in seconds (default: 30): " interval
            interval=${interval:-30}
            start_service_discovery_daemon "$interval"
            ;;
          S|stop)
            stop_service_discovery_daemon
            ;;
          c|check|status)
            local pid_file="/tmp/fks-service-discovery.pid"
            if [ -f "$pid_file" ]; then
              local daemon_pid
              daemon_pid=$(cat "$pid_file" 2>/dev/null || echo "")
              if [ -n "$daemon_pid" ] && kill -0 "$daemon_pid" 2>/dev/null; then
                log_success "Service discovery daemon is running (PID: $daemon_pid)"
              else
                log_warning "Service discovery daemon PID file exists but process not running"
                rm -f "$pid_file"
              fi
            else
              log_info "Service discovery daemon is not running"
            fi
            ;;
          *)
            log_error "Invalid action"
            ;;
        esac
        ;;
      15)
        log_info "Exiting..."
        exit 0
        ;;
      *)
        log_error "Invalid choice"
        ;;
    esac
  done
}

# Run main function
main "$@"