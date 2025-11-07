# Task 3: DockerHub Secrets Setup Guide

**Status**: In Progress  
**Estimated Time**: 20-30 minutes  
**Prerequisites**: Task 2 complete (all repos initialized with GitHub remotes)

## 🎯 Objective

Configure DockerHub credentials as GitHub secrets in all 9 FKS repositories to enable automated Docker image builds and pushes via GitHub Actions.

## 📋 Repositories Requiring Secrets

| Repository | GitHub URL | DockerHub Image |
|------------|-----------|-----------------|
| fks_ai | https://github.com/nuniesmith/fks_ai | `nuniesmith/fks_ai:cpu`, `:gpu`, `:arm64` |
| fks_api | https://github.com/nuniesmith/fks_api | `nuniesmith/fks_api:latest` |
| fks_app | https://github.com/nuniesmith/fks_app | `nuniesmith/fks_app:latest` |
| fks_data | https://github.com/nuniesmith/fks_data | `nuniesmith/fks_data:latest` |
| fks_execution | https://github.com/nuniesmith/fks_execution | `nuniesmith/fks_execution:latest` |
| fks_ninja | https://github.com/nuniesmith/fks_ninja | `nuniesmith/fks_ninja:latest` |
| fks_web | https://github.com/nuniesmith/fks_web | `nuniesmith/fks_web:latest` |
| fks_training | https://github.com/nuniesmith/fks_training | `nuniesmith/fks_training:latest` |
| fks_auth | https://github.com/nuniesmith/fks_auth | `nuniesmith/fks_auth:latest` |

## 🔑 Step 1: Generate DockerHub Access Token (5 minutes)

### 1.1 Navigate to DockerHub Security Settings

Open in your browser:
```
https://hub.docker.com/settings/security
```

Login with your DockerHub credentials if prompted.

### 1.2 Create New Access Token

1. Click **"New Access Token"** button
2. Fill in the form:
   - **Token Description**: `github-actions-fks`
   - **Access Permissions**: Select **"Read, Write, Delete"**
3. Click **"Generate"**
4. **⚠️ CRITICAL**: Copy the token immediately and save it securely
   - Token format: `dckr_pat_XXXXXXXXXXXXXXXXXXXXXXXXXXXX`
   - You won't be able to see it again!

### 1.3 Test Token (Optional)

Test the token locally before adding to GitHub:

```bash
echo "YOUR_TOKEN_HERE" | docker login -u nuniesmith --password-stdin

# If successful, you should see:
# Login Succeeded

# Logout after testing
docker logout
```

## 🔐 Step 2: Add Secrets to GitHub Repositories (15-20 minutes)

You need to add **2 secrets** to **each of the 9 repositories**.

### Method A: Manual via GitHub Web UI (Recommended for First Time)

For **each repository**, follow these steps:

#### Step 2.1: Navigate to Repository Secrets

Example for fks_ai:
```
https://github.com/nuniesmith/fks_ai/settings/secrets/actions
```

Or navigate manually:
1. Go to repository: `https://github.com/nuniesmith/fks_ai`
2. Click **Settings** tab (top right)
3. In left sidebar, click **Secrets and variables** → **Actions**

#### Step 2.2: Add DOCKER_USERNAME Secret

1. Click **"New repository secret"** button
2. Fill in:
   - **Name**: `DOCKER_USERNAME`
   - **Secret**: `nuniesmith`
3. Click **"Add secret"**

#### Step 2.3: Add DOCKER_PASSWORD Secret

1. Click **"New repository secret"** button again
2. Fill in:
   - **Name**: `DOCKER_PASSWORD`
   - **Secret**: Paste your DockerHub access token from Step 1.2
3. Click **"Add secret"**

#### Step 2.4: Verify Secrets

After adding both secrets, you should see:
- `DOCKER_USERNAME` - Updated X seconds ago
- `DOCKER_PASSWORD` - Updated X seconds ago

#### Step 2.5: Repeat for All Repositories

Complete URLs for all 9 repos:

```bash
# Copy these URLs and open in browser tabs:
https://github.com/nuniesmith/fks_ai/settings/secrets/actions
https://github.com/nuniesmith/fks_api/settings/secrets/actions
https://github.com/nuniesmith/fks_app/settings/secrets/actions
https://github.com/nuniesmith/fks_data/settings/secrets/actions
https://github.com/nuniesmith/fks_execution/settings/secrets/actions
https://github.com/nuniesmith/fks_ninja/settings/secrets/actions
https://github.com/nuniesmith/fks_web/settings/secrets/actions
https://github.com/nuniesmith/fks_training/settings/secrets/actions
https://github.com/nuniesmith/fks_auth/settings/secrets/actions
```

### Method B: Automated via GitHub CLI (Advanced)

If you have GitHub CLI (`gh`) installed:

```bash
# Install gh if needed (Ubuntu/Debian)
# sudo apt install gh
# gh auth login

# Set variables
DOCKER_USERNAME="nuniesmith"
DOCKER_TOKEN="dckr_pat_YOUR_TOKEN_HERE"  # Replace with your token

# Add secrets to all repos
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_web fks_training fks_auth; do
  echo "Adding secrets to nuniesmith/$repo..."
  
  gh secret set DOCKER_USERNAME \
    --repo nuniesmith/$repo \
    --body "$DOCKER_USERNAME"
  
  gh secret set DOCKER_PASSWORD \
    --repo nuniesmith/$repo \
    --body "$DOCKER_TOKEN"
  
  echo "✅ Secrets added to $repo"
done

echo "🎉 All secrets configured!"
```

## ✅ Step 3: Verification (5 minutes)

### 3.1 Verify via GitHub Web UI

For each repository, check:
```
https://github.com/nuniesmith/fks_ai/settings/secrets/actions
```

You should see:
- ✅ `DOCKER_USERNAME` (visible name, hidden value)
- ✅ `DOCKER_PASSWORD` (visible name, hidden value)

### 3.2 Verification Checklist

Mark as complete:

- [ ] fks_ai - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_api - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_app - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_data - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_execution - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_ninja - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_web - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_training - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓
- [ ] fks_auth - DOCKER_USERNAME ✓, DOCKER_PASSWORD ✓

### 3.3 Test Secret Access (After Task 4)

Once GitHub Actions workflows are added (Task 4), you can test secret access by triggering a workflow:

```bash
# Push a test commit to trigger workflow
cd /home/jordan/Documents/code/fks/fks_ai
git commit --allow-empty -m "Test workflow trigger"
git push origin main

# Check workflow run
# Go to: https://github.com/nuniesmith/fks_ai/actions
# Verify "Docker Build and Push" workflow runs without authentication errors
```

## 🔒 Security Best Practices

### ✅ DO:
- Use access tokens instead of your DockerHub password
- Set token permissions to minimum required (Read, Write, Delete for CI/CD)
- Store tokens securely (password manager)
- Rotate tokens periodically (every 90-180 days)
- Use separate tokens for different purposes

### ❌ DON'T:
- Share tokens in public channels or repositories
- Commit tokens to git repositories
- Use your DockerHub password directly
- Give tokens excessive permissions
- Reuse tokens across multiple organizations

## 🐛 Troubleshooting

### Issue 1: "Secrets" Tab Not Visible

**Symptom**: No "Secrets and variables" option in Settings sidebar

**Cause**: Insufficient repository permissions

**Solution**: 
- Ensure you're the repository owner or have admin access
- Check organization permissions if repo is in an organization

### Issue 2: Workflow Fails with "unauthorized" Error

**Symptom**: GitHub Actions logs show Docker login failures

**Cause**: Incorrect credentials or expired token

**Solution**:
1. Regenerate DockerHub access token
2. Update `DOCKER_PASSWORD` secret in affected repository
3. Re-run failed workflow

### Issue 3: Token Not Working After Adding

**Symptom**: Docker login fails even with correct token

**Cause**: Token permissions insufficient or token expired

**Solution**:
1. Verify token has "Read, Write, Delete" permissions
2. Check token expiration date (if set)
3. Try generating a new token with full permissions

### Issue 4: Secrets Not Available in Workflow

**Symptom**: Workflow logs show empty secret values

**Cause**: Secret names don't match workflow file references

**Solution**:
- Ensure exact match: `DOCKER_USERNAME` and `DOCKER_PASSWORD` (case-sensitive)
- Check workflow file uses `${{ secrets.DOCKER_USERNAME }}` syntax
- Verify secrets are in the same repository as workflow

## 📊 Progress Tracking

**Task 3 Completion Status**:
- [ ] DockerHub access token generated
- [ ] Secrets added to fks_ai (1/9)
- [ ] Secrets added to fks_api (2/9)
- [ ] Secrets added to fks_app (3/9)
- [ ] Secrets added to fks_data (4/9)
- [ ] Secrets added to fks_execution (5/9)
- [ ] Secrets added to fks_ninja (6/9)
- [ ] Secrets added to fks_web (7/9)
- [ ] Secrets added to fks_training (8/9)
- [ ] Secrets added to fks_auth (9/9)
- [ ] Verification completed

## 🎯 Next Steps

Once Task 3 is complete, proceed to:

**Task 4: Implement GitHub Actions Workflows**
- Add `.github/workflows/docker-build-push.yml` to each repo
- Customize workflows based on service type (standard vs multi-stage)
- Test automated builds on first push

See: `.github/copilot-docs/03-github-actions.md` for workflow templates

## 📚 References

- **DockerHub Security**: https://docs.docker.com/docker-hub/access-tokens/
- **GitHub Actions Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **GitHub CLI Secrets**: https://cli.github.com/manual/gh_secret_set
- **Docker Login Action**: https://github.com/docker/login-action

---

**Last Updated**: November 7, 2025  
**Task Owner**: Jordan (nuniesmith)  
**Estimated Completion**: 20-30 minutes
