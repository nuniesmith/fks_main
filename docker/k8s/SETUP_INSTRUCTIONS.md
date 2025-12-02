# Setting Up fks_k8s GitHub Repository

## Quick Setup

Run the setup script:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s
chmod +x setup_git_repo.sh
./setup_git_repo.sh
```

This will:
1. Initialize git repository (if not already initialized)
2. Add all files (respecting .gitignore)
3. Create initial commit
4. Set branch to `main`
5. Add GitHub remote: `https://github.com/nuniesmith/fks_k8s.git`

## Manual Setup

If you prefer to do it manually:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s

# Initialize git
git init

# Add all files
git add -A

# Create initial commit
git commit -m "Initial commit: FKS Kubernetes configuration and manifests"

# Set branch to main
git branch -M main

# Add remote
git remote add origin https://github.com/nuniesmith/fks_k8s.git

# Push to GitHub
git push -u origin main
```

## What Gets Committed

The `.gitignore` file excludes:
- `dashboard-token.txt` (sensitive token)
- `*.token`, `*.key`, `*.crt`, `*.pem` (certificates and keys)
- `secrets.yaml` (actual secrets - use `secrets.yaml.template` instead)
- `.env` files
- Temporary and IDE files

## After Setup

1. Verify the repository on GitHub: https://github.com/nuniesmith/fks_k8s
2. Update the README if needed
3. Add any additional documentation
4. Set up GitHub Actions for CI/CD (optional)

## Troubleshooting

### Error: "Repository not found"
- Ensure the GitHub repo exists at https://github.com/nuniesmith/fks_k8s
- Check you have push access

### Error: "Permission denied"
- Verify GitHub credentials: `git config --global user.name` and `git config --global user.email`
- Use SSH instead: `git remote set-url origin git@github.com:nuniesmith/fks_k8s.git`

### First Push Issues
- For empty repos, you may need: `git push -u origin main --force`

---

**Repository**: https://github.com/nuniesmith/fks_k8s

