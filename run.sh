#!/bin/bash
# run.sh - Focused Docker/Compose management for FKS Trading Platform
# Version: 3.0-refactored (Dec 2025)
# Domain: fkstrading.xyz

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# PATHS & CONFIG
# ============================================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"                            # infrastructure/main (Rust orchestrator crate)
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"           # monorepo root (services/, infrastructure/, clients/)

DOMAIN="fkstrading.xyz"

DOCKER_USERNAME="${DOCKER_USERNAME:-nuniesmith}"
DOCKER_REPO="${DOCKER_REPO:-fks}"
DEFAULT_TAG="${DEFAULT_TAG:-latest}"

ENABLE_TRIVY="${ENABLE_TRIVY:-true}"
PULL_BASE_IMAGES="${PULL_BASE_IMAGES:-false}"

# Base image dockerfiles location
BASE_DOCKER_DIR="$REPO_DIR/infrastructure/docker/docker"

# ============================================================================
# FIND COMPOSE FILE (supports common names)
# ============================================================================
# First check for root-level compose file, then fall back to infrastructure/config
COMPOSE_FILE_candidates=(
  "$REPO_DIR/docker-compose.yml"
  "$REPO_DIR/docker-compose.yaml"
  "$REPO_DIR/compose.yml"
  "$REPO_DIR/compose.yaml"
  "$REPO_DIR/infrastructure/config/docker-compose.yml"
  "$PROJECT_ROOT/docker-compose.yml"
)

COMPOSE_FILE=""
for f in "${COMPOSE_FILE_candidates[@]}"; do
  if [[ -f "$f" ]]; then
    COMPOSE_FILE="$f"
    break
  fi
done

# If no compose file found, we can still run orchestrator commands
if [[ -z "$COMPOSE_FILE" ]]; then
  log_warning "No docker-compose file found – compose commands will fail but orchestrator works"
  COMPOSE="echo 'No compose file'"
  ALL_SERVICES=()
else
  COMPOSE="docker compose -f \"$COMPOSE_FILE\""
  # Dynamically get all services from compose file
  mapfile -t ALL_SERVICES < <(eval $COMPOSE config --services 2>/dev/null | sort || true)
fi

# GPU services – keep explicit if you need special treatment (optional)
GPU_SERVICES=(ai training)  # adjust if needed

# ============================================================================
# LOGGING
# ============================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[FKS]${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}!${NC} $*"; }
log_error()   { echo -e "${RED}✗ $*${NC}" >&2; }

# ============================================================================
# DEPENDENCIES
# ============================================================================
check_deps() {
  local missing=false
  for cmd in docker git; do
    command -v "$cmd" >/dev/null || { log_warning "Missing $cmd"; missing=true; }
  done
  if [[ "$missing" == "true" ]]; then
    exit 1
  fi
}
check_deps

# ============================================================================
# TRIVY SCAN (optional)
# ============================================================================
scan_image() {
  local image="$1"
  if [[ "$ENABLE_TRIVY" != "true" ]] || ! command -v trivy &>/dev/null; then
    return 0
  fi
  log_info "Scanning $image ..."
  trivy image --exit-code 0 --severity HIGH,CRITICAL "$image" || log_warning "Vulnerabilities found in $image"
}

# ============================================================================
# BASE IMAGES (docker, docker-ml, docker-gpu, docker-rust)
# ============================================================================
build_base_images() {
  local push="${1:-false}"
  [[ ! -d "$BASE_DOCKER_DIR" ]] && log_error "Base docker dir not found: $BASE_DOCKER_DIR" && return 1

  cd "$BASE_DOCKER_DIR"

  log_info "Building base images (push=$push)..."

  # CPU base
  docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker" -f Dockerfile.builder .
  docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker" "$DOCKER_USERNAME/$DOCKER_REPO:python-cpu-base"

  # ML base (depends on CPU)
  docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" -f Dockerfile.ml .
  docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" "$DOCKER_USERNAME/$DOCKER_REPO:python-ml"

  # GPU base (depends on ML)
  docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" -f Dockerfile.gpu .
  docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" "$DOCKER_USERNAME/$DOCKER_REPO:python-gpu"

  # Rust base
  docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" -f Dockerfile.rust .
  docker tag "$DOCKER_USERNAME/$DOCKER_REPO:docker-rust" "$DOCKER_USERNAME/$DOCKER_REPO:rust-cpu-base"

  local bases=(docker docker-ml docker-gpu docker-rust)
  for base in "${bases[@]}"; do
    scan_image "$DOCKER_USERNAME/$DOCKER_REPO:$base"
    [[ "$push" == "true" ]] && docker push "$DOCKER_USERNAME/$DOCKER_REPO:$base"
  done

  log_success "All base images built"
}

# ============================================================================
# SERVICE BUILD / PUSH using docker compose (parallel + correct tagging)
# ============================================================================
build_services() {
  local tag="${1:-$DEFAULT_TAG}"
  local push="${2:-false}"
  shift 2
  local services=("${@:-${ALL_SERVICES[@]}}")

  export TAG="$tag"

  # Build bases first (local bases are preferred over remote)
  build_base_images "false"

  log_info "Building ${#services[@]} services with tag suffix '$tag' (parallel)..."
  (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE build --parallel "${services[@]}")

  if [[ "$ENABLE_TRIVY" == "true" ]]; then
    for svc in "${services[@]}"; do
      scan_image "$DOCKER_USERNAME/$DOCKER_REPO:${svc}-${tag}"
    done
  fi

  if [[ "$push" == "true" ]]; then
    log_info "Pushing ${#services[@]} services..."
    (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE push "${services[@]}")
  fi

  log_success "Build+push complete (tag=$tag)"
}

# ============================================================================
# START / STOP / RESTART
# ============================================================================
start_services() {
  local services=("${@:-${ALL_SERVICES[@]}}")
  log_info "Starting ${#services[@]} services..."
  (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE up -d "${services[@]}")
  log_success "Services started"
}

stop_services() {
  log_info "Stopping all services..."
  (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE down)
  log_success "All services stopped"
}

restart_services() {
  local services=("${@:-${ALL_SERVICES[@]}}")
  log_info "Restarting ${#services[@]} services..."
  (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE restart "${services[@]}")
}

# ============================================================================
# PREFlight (Rust orchestrator proxy – fully non-interactive)
# ============================================================================
run_orchestrator() {
  if [[ -x "$PROJECT_ROOT/target/debug/fks_main" ]]; then
    "$PROJECT_ROOT/target/debug/fks_main" "$@"
  elif [[ -x "$PROJECT_ROOT/target/release/fks_main" ]]; then
    "$PROJECT_ROOT/target/release/fks_main" "$@"
  elif command -v cargo &>/dev/null && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
    cargo run --bin fks_main --manifest-path "$PROJECT_ROOT/Cargo.toml" -- "$@"
  else
    log_error "Rust orchestrator not found. Build it first with: cargo build --bin fks_main"
    return 1
  fi
}

# ============================================================================
# HELP
# ============================================================================
show_help() {
  cat <<EOF
Usage: ./run.sh <command> [options...] [services...]

Commands:
  preflight --full --quiet ...          Run orchestrator preflight (non-interactive)
  build [--tag <tag>] [--push] [svc...] Build services (default: all)
  start [svc...]                        Start services (default: all)
  stop                                  Stop + remove all containers/networks
  restart [svc...]                      Restart services
  base [--push]                         Build/push only base images
  logs [svc...]                         Tail logs
  ps                                    Show running services
  help                                  This help

Examples:
  ./run.sh preflight --full --non-interactive --quiet
  TAG=v1.2.3 ./run.sh build --push
  ./run.sh build --tag latest ai app execution
  ./run.sh start
  ./run.sh restart ai training
EOF
}

# ============================================================================
# MAIN CLI ROUTER (fully non-interactive when args given)
# ============================================================================
if [[ $# -eq 0 ]]; then
  # No args → simple interactive menu (optional, you can remove if you never use it)
  echo "No command given → interactive mode disabled in this refactor."
  show_help
  exit 0
fi

case "$1" in
  preflight)
    shift
    run_orchestrator preflight "$@"
    ;;
  build)
    shift
    tag="$DEFAULT_TAG"
    push=false
    services=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --tag) tag="$2"; shift 2 ;;
        --push) push=true; shift ;;
        *) services+=("$1"); shift ;;
      esac
    done
    build_services "$tag" "$push" "${services[@]}"
    ;;
  start)
    shift
    start_services "$@"
    ;;
  stop)
    stop_services
    ;;
  restart)
    shift
    restart_services "$@"
    ;;
  base)
    shift
    push=false
    [[ "$1" == "--push" ]] && push=true
    build_base_images "$push"
    ;;
  logs)
    shift
    (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE logs -f "$@")
    ;;
  ps)
    (cd "$(dirname "$COMPOSE_FILE")" && $COMPOSE ps)
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    log_error "Unknown command: $1"
    show_help
    exit 1
    ;;
esac

exit 0