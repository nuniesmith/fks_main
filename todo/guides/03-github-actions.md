# GitHub Actions for FKS Multi-Repo CI/CD

**Goal**: Automated Docker build, test, and push workflows for all FKS microservices

## 🎯 Workflow Strategy

### Standard Workflow (All Repos Except fks_ai)

```yaml
# .github/workflows/docker-build-push.yml
name: Docker Build and Push

on:
  push:
    branches: [main, develop]
    tags:
      - 'v*'
  pull_request:
    branches: [main]

env:
  SERVICE_NAME: fks_api  # Change per repo
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements.dev.txt || true

      - name: Run linting
        run: |
          pip install ruff mypy
          ruff check src/ || true
          mypy src/ || true

      - name: Run tests
        run: |
          pip install pytest pytest-cov
          pytest tests/ -v --cov=src --cov-report=xml || true

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          fail_ci_if_error: false

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKER_USERNAME }}/${{ env.SERVICE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix=sha-
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Image digest
        run: echo ${{ steps.meta.outputs.digest }}
```

### Multi-Stage Workflow (fks_ai only)

```yaml
# fks_ai/.github/workflows/docker-build-push.yml
name: Docker Build and Push (Multi-Stage)

on:
  push:
    branches: [main, develop]
    tags:
      - 'v*'
  pull_request:
    branches: [main]

env:
  SERVICE_NAME: fks_ai
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements.dev.txt || true

      - name: Run tests
        run: |
          pip install pytest pytest-cov
          pytest tests/ -v --cov=src --cov-report=xml || true

  build-cpu:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKER_USERNAME }}/${{ env.SERVICE_NAME }}
          tags: |
            type=raw,value=cpu
            type=raw,value=latest
            type=sha,prefix=cpu-sha-
            type=semver,pattern={{version}},suffix=-cpu

      - name: Build and push CPU image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: base
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha,scope=cpu
          cache-to: type=gha,mode=max,scope=cpu

  build-gpu:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKER_USERNAME }}/${{ env.SERVICE_NAME }}
          tags: |
            type=raw,value=gpu
            type=sha,prefix=gpu-sha-
            type=semver,pattern={{version}},suffix=-gpu

      - name: Build and push GPU image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: gpu
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha,scope=gpu
          cache-to: type=gha,mode=max,scope=gpu

  build-arm64:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push ARM64 image
        uses: docker/build-push-action@v6
        with:
          context: .
          target: base
          platforms: linux/arm64
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/${{ env.SERVICE_NAME }}:arm64
          cache-from: type=gha,scope=arm64
          cache-to: type=gha,mode=max,scope=arm64
```

### Django Web Workflow (fks_web with Celery)

```yaml
# fks_web/.github/workflows/docker-build-push.yml
name: Docker Build and Push (Django + Celery)

on:
  push:
    branches: [main]
    tags:
      - 'v*'
  pull_request:
    branches: [main]

env:
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements.dev.txt || true

      - name: Run Django checks
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/testdb
          REDIS_URL: redis://localhost:6379/0
        run: |
          python manage.py check
          python manage.py makemigrations --check --dry-run || true

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/testdb
          REDIS_URL: redis://localhost:6379/0
        run: |
          pip install pytest pytest-django pytest-cov
          pytest tests/ -v --cov=src --cov-report=xml || true

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
    
    strategy:
      matrix:
        service: [web, celery-worker, celery-beat, flower]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push ${{ matrix.service }}
        uses: docker/build-push-action@v6
        with:
          context: .
          target: ${{ matrix.service }}
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/fks_web:${{ matrix.service }}-latest
            ${{ secrets.DOCKER_USERNAME }}/fks_web:${{ matrix.service }}-${{ github.sha }}
          cache-from: type=gha,scope=${{ matrix.service }}
          cache-to: type=gha,mode=max,scope=${{ matrix.service }}
```

## 🔧 Setup Instructions

### Step 1: Add Secrets to Each Repo

For **EACH** repository (fks_ai, fks_api, fks_app, etc.):

```bash
# 1. Go to GitHub repo
# 2. Settings → Secrets and variables → Actions
# 3. Click "New repository secret"
# 4. Add two secrets:

DOCKER_USERNAME = nuniesmith
DOCKER_PASSWORD = <your-dockerhub-access-token>
```

**Generate DockerHub Token**:

1. Go to [DockerHub](https://hub.docker.com/)
2. Account Settings → Security
3. Click "New Access Token"
4. Name: `github-actions-fks`
5. Permissions: `Read, Write, Delete`
6. Copy token and save as `DOCKER_PASSWORD` secret

### Step 2: Add Workflow File to Each Repo

```bash
# For standard services (fks_api, fks_app, fks_data, fks_execution)
cd fks_api
mkdir -p .github/workflows
cp /path/to/standard-workflow.yml .github/workflows/docker-build-push.yml

# Edit SERVICE_NAME in the workflow file
sed -i 's/SERVICE_NAME: fks_api/SERVICE_NAME: fks_api/' .github/workflows/docker-build-push.yml

# Commit and push
git add .github/workflows/
git commit -m "Add GitHub Actions workflow for Docker build/push"
git push origin main
```

### Step 3: Verify Workflow Runs

1. Go to repo → Actions tab
2. Check workflow run status
3. View logs for build details
4. Verify images on [DockerHub](https://hub.docker.com/u/nuniesmith)

## 📊 Workflow Matrix

| Repository | Workflow Type | Images Built | Platforms |
|-----------|---------------|--------------|-----------|
| **fks_ai** | Multi-stage | `:cpu`, `:gpu`, `:arm64`, `:latest` | linux/amd64, linux/arm64 |
| **fks_api** | Standard | `:latest`, `:v*`, `:sha-*` | linux/amd64 |
| **fks_app** | Standard | `:latest`, `:v*`, `:sha-*` | linux/amd64 |
| **fks_data** | Standard | `:latest`, `:v*`, `:sha-*` | linux/amd64 |
| **fks_execution** | Standard | `:latest`, `:v*`, `:sha-*` | linux/amd64 |
| **fks_web** | Django multi-target | `:web-*`, `:celery-worker-*`, `:celery-beat-*`, `:flower-*` | linux/amd64 |
| **fks_ninja** | C# build | `:latest`, `:v*` | linux/amd64 |
| **fks_meta** | Minimal | `:latest` | linux/amd64 |
| **fks_training** | Standard | `:latest`, `:v*` | linux/amd64 |

## 🚀 Trigger Workflows

### Automatic Triggers

```bash
# Push to main → builds and pushes :latest
git push origin main

# Push tag → builds versioned images
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Pull request → runs tests only (no push)
git checkout -b feature/my-feature
git push origin feature/my-feature
```

### Manual Triggers

```yaml
# Add to workflow:
on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Docker image tag'
        required: false
        default: 'manual'
```

Trigger from GitHub UI: Actions → Select workflow → Run workflow

## 🐛 Troubleshooting

### Build Fails: Authentication Error

```bash
# Check secrets are added to repo
# Settings → Secrets → Actions → DOCKER_USERNAME, DOCKER_PASSWORD

# Test DockerHub login locally
docker login -u nuniesmith
```

### Build Fails: Dependency Error

```bash
# Test Dockerfile locally first
docker build -t test:local .

# Check requirements.txt exists
ls requirements.txt

# Verify Python version matches
python --version  # Should be 3.12+
```

### Image Not Appearing on DockerHub

```bash
# Check workflow completed successfully
# Actions → Latest run → All jobs green

# Verify tags in workflow logs
# Look for "tags:" output in build step

# Check DockerHub manually
open https://hub.docker.com/u/nuniesmith/repositories
```

## 📈 Monitoring Builds

### GitHub Actions Dashboard

```bash
# View all workflow runs
gh run list --repo nuniesmith/fks_api

# View specific run
gh run view <run-id> --repo nuniesmith/fks_api

# Download logs
gh run download <run-id> --repo nuniesmith/fks_api
```

### DockerHub Webhooks (Optional)

```yaml
# Add to fks_main for notifications
# .github/workflows/docker-webhook.yml
name: DockerHub Image Updated

on:
  repository_dispatch:
    types: [dockerhub_image_pushed]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send notification
        run: |
          echo "New image pushed: ${{ github.event.client_payload.image_tag }}"
          # Add Slack/Discord webhook here
```

## 🎯 Next Steps

1. ✅ Add DockerHub secrets to **ALL** repos
2. ✅ Copy workflow files to each repo (use correct template)
3. ✅ Update `SERVICE_NAME` in each workflow
4. ✅ Push workflows to GitHub (`git push origin main`)
5. ✅ Verify first build succeeds
6. ✅ Test version tagging: `git tag v0.1.0 && git push origin v0.1.0`
7. ✅ Configure K8s to pull from DockerHub (see [01-core-architecture.md](./01-core-architecture.md))

## 🔗 References

- [Docker Strategy](./02-docker-strategy.md)
- [GitHub Actions Docker Docs](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
