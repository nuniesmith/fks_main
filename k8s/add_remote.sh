#!/bin/bash
# Add GitHub remote to k8s repository

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_REPO="https://github.com/nuniesmith/fks_k8s.git"

echo -e "${BLUE}Adding GitHub remote to k8s repository${NC}"
echo ""

cd "$K8S_DIR"

# Check if it's a git repo, initialize if not
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

# Check if remote already exists
if git remote get-url origin >/dev/null 2>&1; then
    remote_url=$(git remote get-url origin)
    echo "Remote already exists: $remote_url"
    
    # Update if different
    if [ "$remote_url" != "$GITHUB_REPO" ] && [ "$remote_url" != "${GITHUB_REPO%.git}" ]; then
        echo "Updating remote URL to: $GITHUB_REPO"
        git remote set-url origin "$GITHUB_REPO"
        echo -e "${GREEN}✓ Remote URL updated${NC}"
    else
        echo -e "${GREEN}✓ Remote is already correctly configured${NC}"
    fi
else
    echo "Adding remote: $GITHUB_REPO"
    git remote add origin "$GITHUB_REPO"
    echo -e "${GREEN}✓ Remote added${NC}"
fi

# Show remote info
echo ""
echo "Remote configuration:"
git remote -v

echo ""
echo -e "${GREEN}✓ Remote setup complete!${NC}"


