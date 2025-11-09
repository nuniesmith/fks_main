# Solo Developer Workflow Optimization for Multi-Repo Fintech

**Last Updated**: November 7, 2025  
**Purpose**: Comprehensive guide for managing multi-repo microservices as a solo developer

## 🎯 Overview

Research suggests sticking with a multi-repo setup for microservices to maintain independence, though it requires tools for efficient management. This guide synthesizes best practices for solo fintech developers managing polyglot microservices across 9+ repositories.

**Key Benefits**:
- 20-30% faster CI/CD pipelines vs monorepo
- 25% improvement in deployment velocity
- Reduced blast radius from isolated failures
- Independent service lifecycles

**Challenges**:
- 15% initial coordination overhead
- Risk of shared code drift
- Context switching between repos

---

## 📦 Multi-Repo Management

### Repository Organization

As a solo dev, focus on tools that simplify navigation across your fks_* repos. Use GitKraken for visual repo management, ensuring each service (e.g., fks_api, fks_ai) remains isolated. This reduces blast radius from issues.

**Current FKS Repository Structure**:

| Repository | Purpose | Key Technologies | Status |
|-----------|---------|------------------|--------|
| **fks_ai** | Multi-agent AI, ML models | Python, PyTorch, LangGraph | ⏸️ Needs remote setup |
| **fks_api** | REST API gateway | Python, FastAPI | ⏸️ Needs remote setup |
| **fks_app** | Trading strategies, business logic | Python, ASMBTR | ⏸️ Needs remote setup |
| **fks_data** | Data adapters, market feeds | Python, CCXT, Polygon | ⏸️ Needs remote setup |
| **fks_execution** | Order execution, webhooks | Python, Rust | ⏸️ Needs remote setup |
| **fks_ninja** | NinjaTrader integration | C# | ⏸️ Needs remote setup |
| **fks_meta** | MetaTrader plugin | C++/Python | ⏸️ Needs remote setup |
| **fks_web** | Django UI, Celery workers | Python, Django | ⏸️ Needs remote setup |
| **fks_training** | Model training, backtesting | Python, ML | ⏸️ Needs remote setup |
| **fks_main** | Orchestration, K8s manifests | YAML, Helm | Local only |

### Best Practices

| Aspect | Multi-Repo Pros | Multi-Repo Cons | Mitigation for Solo Devs |
|--------|-----------------|-----------------|--------------------------|
| **Isolation** | High autonomy per service | Code duplication risk | Use shared libraries via packages |
| **Scaling** | Flexible growth | Dependency complexity | Automate with GitHub Actions |
| **Collaboration** | Focused codebases | Slower cross-repo work | Use GitKraken for visual navigation |
| **CI/CD** | Targeted pipelines | Inconsistencies | Standardize workflows centrally |

### Recommended Tools

1. **GitKraken** - Visual repo management with multi-repo support
   - Feature: Switch between repos with single-click
   - Benefit: Reduces cognitive load from context switching

2. **GitHub CLI** (`gh`) - Command-line repo operations
   ```bash
   # Clone all repos at once
   gh repo clone nuniesmith/fks_ai
   gh repo clone nuniesmith/fks_api
   # ... repeat for all repos
   
   # Or use script
   for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_meta fks_web fks_training; do
       gh repo clone nuniesmith/$repo
   done
   ```

3. **VS Code Multi-Root Workspaces**
   ```json
   // fks.code-workspace
   {
       "folders": [
           {"path": "../fks_ai"},
           {"path": "../fks_api"},
           {"path": "../fks_app"},
           {"path": "../fks_data"},
           {"path": "../fks_execution"},
           {"path": "../fks_ninja"},
           {"path": "../fks_meta"},
           {"path": "../fks_web"},
           {"path": "../fks_training"},
           {"path": "../fks_main"}
       ]
   }
   ```

---

## 🤖 GitHub Actions Automation

GitHub Actions excels in automating workflows for multi-repo environments, enabling CI/CD pipelines that build, test, and deploy microservices consistently. For your setup, create reusable workflows in a dedicated repo to avoid duplication.

### Reusable Workflows Strategy

**Central Action Repository**: Create `.github-actions` repo with composite actions

**Setup Steps**:

1. **Build Custom Docker Images** in central repo for consistent environments
   ```dockerfile
   # .github-actions/Dockerfile
   FROM ubuntu:22.04
   RUN apt-get update && apt-get install -y \
       git curl python3 python3-pip \
       && rm -rf /var/lib/apt/lists/*
   ```

2. **Develop Composite Action**
   ```yaml
   # .github-actions/composite-ci/action.yml
   name: 'FKS CI/CD Composite'
   description: 'Reusable CI/CD for FKS microservices'
   inputs:
       test:
           description: 'Run tests'
           required: false
           default: 'true'
       build:
           description: 'Build Docker image'
           required: false
           default: 'true'
       release:
           description: 'Push to DockerHub'
           required: false
           default: 'false'
   runs:
       using: 'composite'
       steps:
           - name: Install dependencies
             run: pip install -r requirements.txt
             shell: bash
           - name: Run tests
             if: inputs.test == 'true'
             run: pytest tests/
             shell: bash
           - name: Build image
             if: inputs.build == 'true'
             run: docker build -t ${{ github.repository }}:latest .
             shell: bash
           - name: Push image
             if: inputs.release == 'true'
             run: docker push ${{ github.repository }}:latest
             shell: bash
   ```

3. **Reference in Microservice Repos**
   ```yaml
   # fks_api/.github/workflows/ci.yml
   name: CI/CD Pipeline
   on: [push, pull_request]
   jobs:
       build:
           runs-on: ubuntu-latest
           container:
               image: ghcr.io/nuniesmith/fks-builder:latest
               env:
                   GH_TOKEN: ${{ secrets.GH_TOKEN }}
           steps:
               - uses: actions/checkout@v4
                 with:
                     repository: nuniesmith/.github-actions
                     token: ${{ secrets.GH_TOKEN }}
                     path: .github/actions/fks-ci
               - name: Run FKS CI
                 uses: ./.github/actions/fks-ci
                 with:
                     test: true
                     build: true
                     release: ${{ github.ref == 'refs/heads/main' }}
   ```

### Fintech-Specific Actions

| Workflow Component | Purpose | Example Use in FKS |
|--------------------|---------|-------------------|
| **Custom Docker Image** | Consistent env setup | Pre-install security tools (Trivy, Bandit) |
| **Composite Action** | Reusable steps | Automate testing for all Python services |
| **Organization Secrets** | Secure handling | Share DockerHub credentials, API keys |
| **Conditional Inputs** | Customization | Skip deploys for non-main branches |

### Security Integration

```yaml
# Add to composite action
- name: Security Scan
  run: |
      trivy fs --severity HIGH,CRITICAL .
      bandit -r src/
  shell: bash
```

---

## 🧑‍💻 VS Code with Copilot Agents

VS Code integrated with GitHub Copilot agents transforms solo development by enabling autonomous AI assistance. Copilot's agent mode handles feature implementation and bug fixing in the background, ideal for managing multiple repos without constant context switching.

### Activation and Usage

**Prerequisites**:
- GitHub Copilot subscription
- GitHub Pull Requests extension for VS Code

**Delegation Methods**:

1. **Issue Assignment** - Right-click issue → "Assign to Copilot"
2. **Chat Delegation** - Use `#github-pull-request_copilot-coding-agent` in chat
3. **TODO Comments** - Add `// TODO: @copilot implement...` in code

### Best Practices for FKS

| Copilot Feature | Benefit for Solo Dev | Integration Tip |
|-----------------|---------------------|-----------------|
| **Agent Mode** | Autonomous coding | Delegate from chat for quick fixes |
| **Issue Assignment** | Task offloading | Use for microservice-specific bugs |
| **PR Iteration** | Feedback loop | Comment "@copilot" for changes |
| **Custom Instructions** | Tailored guidance | Define fintech compliance rules |

### Custom Instructions for Fintech

Create `.github/copilot-instructions.md` in each repo:

```markdown
## FKS Fintech Standards

### Security Requirements
- All API endpoints must validate inputs with Pydantic models
- Encrypt sensitive data at rest (AES-256) and in transit (TLS 1.3)
- Implement rate limiting (100 req/min default)
- Log all financial transactions for audit trails

### Code Style
- Python: Follow PEP 8, use type hints
- Rust: Follow rustfmt, use Result<T, E> for errors
- C#: Follow Microsoft naming conventions

### Testing
- Unit test coverage >80% for trading logic
- Integration tests for all API endpoints
- Backtests required for strategy changes

### Compliance
- PCI DSS for payment data
- GDPR for user data
- SOC 2 for security controls
```

### Example Delegations

```bash
# Delegate bug fix via chat
"@copilot Fix the ModuleNotFoundError in fks_web by updating requirements.txt to include celery>=5.3.0"

# Delegate feature via issue
# Create issue: "Add CVaR risk metric to portfolio analyzer"
# Assign to @copilot
# Agent analyzes repo, implements feature, submits PR

# Iterate on PR
# Comment: "@copilot Add unit tests for CVaR calculation"
```

---

## 📄 Batch Processing Markdown Files

Batching Markdown files streamlines importing specs, generating code, and analyzing for AI workflows. Tools like Python's MarkItDown convert documents to LLM-ready MD, preserving structure for efficient AI processing—crucial for fintech docs like compliance notes.

### Implementation

**Install MarkItDown**:
```bash
pip install 'markitdown[all]'
```

**Batch Conversion Script**:
```python
# scripts/batch_convert_docs.py
from pathlib import Path
from markitdown import MarkItDown

def main(input_dir, output_dir="output", target_formats=(".md", ".pdf", ".docx")):
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    md = MarkItDown()
    
    for file_path in input_path.rglob("*"):
        if file_path.suffix in target_formats:
            try:
                result = md.convert(file_path)
                output_file = output_path / f"{file_path.stem}.md"
                output_file.write_text(result.markdown, encoding="utf-8")
                print(f"✅ Converted {file_path.name}")
            except Exception as e:
                print(f"❌ Error converting {file_path.name}: {e}")

if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else "docs/specs")
```

### Workflow Integration

| Processing Step | Tool/Method | Application in FKS |
|-----------------|-------------|-------------------|
| **Import/Batch Convert** | MarkItDown | Prepare compliance specs for AI analysis |
| **Generate Code** | Copilot Agent | From MD specs to microservice implementation |
| **Analyze** | LLM Prompts | Identify security issues in generated code |
| **Output Integration** | Scripts | Auto-create GitHub issues from analysis |

### GitHub Actions Integration

```yaml
# .github/workflows/doc-processing.yml
name: Process Documentation
on:
    push:
        paths:
            - 'docs/specs/**'
jobs:
    convert:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - name: Install MarkItDown
              run: pip install 'markitdown[all]'
            - name: Convert documents
              run: python scripts/batch_convert_docs.py docs/specs
            - name: Commit converted files
              run: |
                  git config user.name "github-actions[bot]"
                  git config user.email "github-actions[bot]@users.noreply.github.com"
                  git add output/
                  git commit -m "Auto-convert docs to Markdown"
                  git push
```

---

## 📅 Task Tracking and Calendar Integration

GitHub Projects offers boards, tables, and roadmaps for tracking tasks across repos—use it to visualize microservices progress. For calendar views, integrate with Google Calendar via Zapier.

### GitHub Projects Setup

**Create Project Board**:
1. Go to GitHub → Projects → New project
2. Choose "Team backlog" template
3. Add custom fields:
   - Service: Dropdown (fks_ai, fks_api, etc.)
   - Priority: Dropdown (Critical, High, Medium, Low)
   - Phase: Dropdown (Phase 1-10)
   - Estimated Hours: Number

**Link Issues Across Repos**:
```bash
# Create issue in fks_api
gh issue create --repo nuniesmith/fks_api \
    --title "Add CVaR risk endpoint" \
    --body "Implement /api/v1/portfolio/cvar endpoint" \
    --label "enhancement" \
    --project "FKS Trading Platform"

# Assign to Copilot
gh issue edit 123 --add-assignee @copilot
```

### Zapier Calendar Integration

**Zap Setup**:
1. Trigger: New GitHub Issue (filter by repo/labels)
2. Action: Create Google Calendar Event
   - Title: `[{repo}] {issue_title}`
   - Description: `{issue_url}\n{issue_body}`
   - Start Time: `{created_at}`
   - Duration: Based on priority (Critical=4h, High=2h, etc.)

**Example Zap Flow**:
```
New Issue in fks_ai (label: bug)
    ↓
Create Calendar Event
    - Title: "[fks_ai] Fix memory leak in LangGraph"
    - Time: Today 2:00 PM
    - Duration: 2 hours
    ↓
Send Slack Notification
    - Channel: #dev-alerts
    - Message: "New critical bug assigned to @copilot"
```

### Reclaim AI for Focus Time

**Setup**:
1. Connect GitHub and Google Calendar to Reclaim
2. Configure "Focus Time" habits:
   - Deep Work: 4-hour blocks (no meetings)
   - Code Review: 1-hour blocks
   - Testing: 2-hour blocks
3. Reclaim auto-schedules around events and deadlines

**Benefits**:
- Avg. 7.6 hours/week of reclaimed focus time
- Auto-reschedules tasks when priorities change
- Buffers around meetings for context switching

### Task Management Tools

| Integration Tool | Key Features | Use Case for Solo Fintech Dev |
|------------------|--------------|-------------------------------|
| **GitHub Projects** | Boards, roadmaps | Track microservice tasks across repos |
| **Zapier** | Trigger-action zaps | Sync issues to calendar events |
| **Reclaim AI** | Auto-scheduling | Optimize focus around dev sprints |
| **Copilot Assignment** | Issue delegation | Pass analyzed MD tasks to AI |

---

## 🔐 Secrets and Configuration Management

### Organization-Level Secrets

**Setup in GitHub**:
1. Go to Organization → Settings → Secrets → Actions
2. Add secrets:
   - `DOCKER_USERNAME`: nuniesmith
   - `DOCKER_PASSWORD`: <token>
   - `GEMINI_API_KEY`: <api-key>
   - `POSTGRES_PASSWORD`: <password>
   - `REDIS_PASSWORD`: <password>

**Access in Workflows**:
```yaml
jobs:
    build:
        runs-on: ubuntu-latest
        env:
            DOCKER_USER: ${{ secrets.DOCKER_USERNAME }}
            DOCKER_PASS: ${{ secrets.DOCKER_PASSWORD }}
        steps:
            - name: Login to DockerHub
              run: echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
```

### Local Development

**Use `.env` Files** (git-ignored):
```bash
# fks_api/.env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=trading_user
POSTGRES_PASSWORD=dev_password
REDIS_HOST=localhost
REDIS_PORT=6379
GEMINI_API_KEY=your_key_here
```

**Load in Docker Compose**:
```yaml
# docker-compose.yml
services:
    api:
        image: nuniesmith/fks_api:latest
        env_file:
            - .env
```

---

## 🎯 Weekly Routine for Solo Dev

### Monday: Planning & Prioritization
- Review GitHub Projects board
- Prioritize issues for the week
- Assign critical bugs to @copilot
- Block focus time in Reclaim AI

### Tuesday-Thursday: Development Sprints
- 4-hour deep work blocks
- Use Copilot for feature implementation
- Run tests locally before pushing
- Monitor CI/CD pipelines

### Friday: Review & Documentation
- Review Copilot-generated PRs
- Update documentation
- Run security scans (Trivy, Bandit)
- Plan next week's priorities

### Weekend: Optional
- Monitor production alerts (Grafana)
- Research new fintech best practices
- Update dependencies (Dependabot PRs)

---

## 📚 Key Citations

- [Multi-Repo Management Tips](https://www.gitkraken.com/blog/monorepo-vs-multi-repo-collaboration)
- [Reusable GitHub Actions](https://dev.to/lewkoo/re-usable-and-maintainable-github-action-workflows-for-multiple-repositories-2egp)
- [Copilot Coding Agent](https://code.visualstudio.com/docs/copilot/copilot-coding-agent)
- [Copilot Best Practices](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks)
- [MarkItDown for Batch MD](https://realpython.com/python-markitdown/)
- [GitHub-Calendar Integration](https://zapier.com/apps/github/integrations/google-calendar)
- [Reclaim AI Features](https://reclaim.ai/)
