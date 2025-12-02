#!/bin/bash
# Setup and push script for fks_k8s GitHub repository
# This initializes git, adds files, commits, and pushes to GitHub

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_REPO="https://github.com/nuniesmith/fks_k8s.git"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Setting up and pushing fks_k8s GitHub repository${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

cd "$K8S_DIR"

# Check if already a git repo
if [ -d ".git" ]; then
    echo -e "${YELLOW}Git repository already initialized${NC}"
else
    echo "Initializing git repository..."
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

# Add all files
echo "Staging files..."
git add -A

# Check if there are changes to commit
if git diff --cached --quiet && git diff --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo "Committing files..."
    git commit -m "Initial commit: FKS Kubernetes configuration and manifests" || echo -e "${YELLOW}No changes to commit${NC}"
    echo -e "${GREEN}✓ Files committed${NC}"
fi

# Set branch to main
current_branch=$(git branch --show-current 2>/dev/null || echo "master")
if [ "$current_branch" != "main" ]; then
    echo "Setting branch to main..."
    git branch -M main 2>/dev/null || true
    echo -e "${GREEN}✓ Branch set to main${NC}"
fi

# Add remote
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "Adding remote: $GITHUB_REPO"
    git remote add origin "$GITHUB_REPO"
    echo -e "${GREEN}✓ Remote added${NC}"
else
    remote_url=$(git remote get-url origin)
    echo "Remote already configured: $remote_url"
    
    # Update if different
    if [ "$remote_url" != "$GITHUB_REPO" ] && [ "$remote_url" != "${GITHUB_REPO%.git}" ]; then
        echo "Updating remote URL..."
        git remote set-url origin "$GITHUB_REPO"
        echo -e "${GREEN}✓ Remote URL updated${NC}"
    fi
fi

# Push to GitHub
echo ""
echo "Pushing to GitHub..."
if git push -u origin main 2>&1; then
    echo -e "${GREEN}✓ Successfully pushed to GitHub${NC}"
else
    echo -e "${YELLOW}⚠ Push failed or already up to date${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Repository setup complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

