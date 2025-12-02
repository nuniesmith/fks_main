#!/bin/bash
# Entrypoint for fks_main Rust service

set -e

echo "Starting fks_main service..."

# Run the binary
exec /app/fks_main

