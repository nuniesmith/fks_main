#!/bin/bash
# Entrypoint script for fks-main service
# Captures early exits and provides debugging

set -e

echo "=== FKS Main Service Entrypoint ===" >&2
echo "Binary: /app/fks_main" >&2
echo "Environment:" >&2
env | grep -E "SERVICE_|MONITOR_|K8S_|DOMAIN_|TLS_|RUST_" | sort >&2
echo "" >&2

# Check if binary exists
if [ ! -f "/app/fks_main" ]; then
    echo "ERROR: Binary /app/fks_main not found!" >&2
    exit 1
fi

# Check if binary is executable
if [ ! -x "/app/fks_main" ]; then
    echo "ERROR: Binary /app/fks_main is not executable!" >&2
    exit 1
fi

echo "Starting fks_main..." >&2
echo "" >&2

# Run the binary directly (not with exec) to see if it produces output
/app/fks_main 2>&1
EXIT_CODE=$?
echo "Binary exited with code: $EXIT_CODE" >&2
exit $EXIT_CODE

