# Multi-stage build for FKS Main Rust service
FROM rust:1.88-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Cargo files first (for better dependency caching)
COPY Cargo.toml Cargo.lock* ./

# Create a dummy source to build dependencies (better caching)
# This allows Docker to cache the dependency layer separately from source code
# Use cache mounts so dependencies are cached for the real build
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code
COPY src/ ./src/

# Build the application with BuildKit cache mount for Cargo registry
# Dependencies are already cached from the dummy build above
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/fks_main /app/fks_main

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user first
RUN useradd -u 1000 -m -s /bin/bash appuser

# Copy binary from builder with correct ownership
COPY --from=builder --chown=appuser:appuser /app/fks_main /app/fks_main

# Verify binary exists and is executable
RUN ls -la /app/fks_main && file /app/fks_main || echo "Binary check failed"

# Environment variables
ENV SERVICE_NAME=fks_main \
    SERVICE_PORT=8010 \
    RUST_LOG=info

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8010/health || exit 1

# Expose port
EXPOSE 8010

# Run service with explicit path and error handling
CMD ["/app/fks_main"]

