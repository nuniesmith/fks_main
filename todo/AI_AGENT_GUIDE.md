# AI Agent Guide - FKS Project Organization

**Last Updated**: November 7, 2025  
**Purpose**: Guide for AI agents working on FKS project tasks

## 🎯 Overview

This guide explains how AI agents should interact with the FKS project structure, use the RAG system for analysis, and work with the multi-repo architecture.

## 📁 Project Structure

### Repository Organization

```
/home/jordan/Documents/code/fks/
├── repo/                    # Multi-repo structure
│   ├── core/               # Core services (api, app, data, execution, web, main, monitor, auth)
│   ├── gpu/                # GPU-accelerated services (ai, training)
│   ├── plugin/             # Platform plugins (ninja, meta)
│   └── tools/              # Development tools
│       └── analyze/        # RAG analysis service
├── todo/                   # Project documentation and task management
│   ├── guides/            # Architecture and implementation guides
│   ├── tasks/             # Task definitions and tracking
│   └── docs/              # Additional documentation
└── scripts/                # Utility scripts
```

### Key Directories for AI Agents

| Directory | Purpose | When to Use |
|-----------|---------|-------------|
| `todo/guides/` | Architecture and implementation guides | Reference when implementing features |
| `todo/tasks/` | Task definitions and tracking | Check for current tasks and priorities |
| `repo/tools/analyze/` | RAG analysis service | Send documents for analysis |
| `repo/core/` | Core microservices | Work on service-specific features |
| `repo/gpu/` | AI/ML services | Work on AI features, training |

## 🤖 Using the RAG Analysis System

### Quick Start

The RAG system is available via the CLI tool at `./repo/tools/analyze/analyze`:

```bash
# Analyze a single document
cd /home/jordan/Documents/code/fks
./repo/tools/analyze/analyze document todo/01-core-architecture.md --type project_management

# Analyze entire todo directory
./repo/tools/analyze/analyze directory todo/ --type documentation

# Query the RAG system
./repo/tools/analyze/analyze query "What are the current priorities for the FKS project?"

# Check job status
./repo/tools/analyze/analyze status <job_id>

# Get results
./repo/tools/analyze/analyze results <job_id>
```

### Starting the Analyze Service

Before using the CLI, ensure the analyze service is running:

```bash
cd repo/tools/analyze
docker-compose up -d
# OR
./start.sh
```

The service runs on `http://localhost:8008` by default.

### Analysis Types

- **project_management**: Analyze tasks, issues, and project status
- **standardization**: Review code structure and suggest improvements
- **documentation**: Generate documentation and diagrams

### Workflow for AI Agents

1. **Before Starting a Task**:
   ```bash
   # Query RAG system for context
   ./repo/tools/analyze/analyze query "What is the current status of [feature]?" --type project_management
   ```

2. **When Analyzing Code**:
   ```bash
   # Send relevant files to RAG system
   ./repo/tools/analyze/analyze document repo/core/api/src/main.py --type standardization
   ```

3. **After Completing Work**:
   ```bash
   # Analyze your changes
   ./repo/tools/analyze/analyze directory repo/core/api/src/ --type standardization
   ```

## 📚 Documentation Organization

### Guide Files (todo/guides/)

These files contain architecture and implementation details:

- `00-MASTER-README.md` - Overview of all repos
- `01-core-architecture.md` - K8s deployment and system architecture
- `02-docker-strategy.md` - Docker build and push workflows
- `03-github-actions.md` - CI/CD automation
- `04-ai-trading-agents.md` - AI agent implementation guide
- `05-execution-pipeline.md` - Execution engine details
- `06-portfolio-rebalancing.md` - RL-based portfolio management
- `07-cvar-risk-management.md` - CVaR risk management
- `08-monorepo-split-guide.md` - Multi-repo migration guide
- `09-solo-dev-workflow.md` - Solo developer workflow
- `10-fintech-security-compliance.md` - Security and compliance
- `11-project-improvement-areas.md` - Areas for improvement
- `12-standard-schema-design.md` - Database schema standards

### Task Files (todo/tasks/)

Task definitions organized by priority and category:

- `P0-critical/` - Critical blockers and security issues
- `P1-high/` - High-priority features and improvements
- `P2-medium/` - Medium-priority enhancements
- `P3-low/` - Nice-to-have features

## 🔄 Working with Multi-Repo Structure

### Repository Categories

1. **Core Services** (`repo/core/`):
   - `api/` - REST API gateway
   - `app/` - Trading strategies and business logic
   - `data/` - Data adapters (CCXT, Polygon, Binance)
   - `execution/` - Execution engine (webhooks, CCXT, security)
   - `web/` - Django web UI
   - `main/` - Main orchestrator (K8s, monitoring, docs)
   - `monitor/` - Monitoring service
   - `auth/` - Authentication service

2. **GPU Services** (`repo/gpu/`):
   - `ai/` - AI/ML services (LangGraph, TimeCopilot, RAG)
   - `training/` - Model training and backtesting

3. **Plugins** (`repo/plugin/`):
   - `ninja/` - NinjaTrader C# plugin
   - `meta/` - MetaTrader plugin

4. **Tools** (`repo/tools/`):
   - `analyze/` - RAG analysis service

### Finding Relevant Code

When working on a task:

1. **Check the guide** in `todo/guides/` for architecture details
2. **Identify the service** from the task description
3. **Locate the service** in `repo/core/`, `repo/gpu/`, or `repo/plugin/`
4. **Use RAG system** to understand context:
   ```bash
   ./repo/tools/analyze/analyze query "How does [feature] work in [service]?"
   ```

## 📝 Task Workflow

### 1. Understanding the Task

```bash
# Query RAG system for task context
./repo/tools/analyze/analyze query "[task description]" --type project_management
```

### 2. Finding Relevant Files

```bash
# Search for relevant code
grep -r "keyword" repo/core/api/src/
```

### 3. Analyzing Code

```bash
# Send relevant files to RAG system
./repo/tools/analyze/analyze document repo/core/api/src/feature.py --type standardization
```

### 4. Implementing Changes

- Follow patterns from existing code
- Reference guides in `todo/guides/`
- Maintain consistency with multi-repo structure

### 5. Testing

```bash
# Run tests for the service
cd repo/core/api
pytest tests/ -v
```

### 6. Documenting Changes

- Update relevant guide files if architecture changes
- Add comments for complex logic
- Update task status in `todo/tasks/`

## 🎯 Best Practices for AI Agents

### 1. Always Check Context First

Before making changes:
- Query RAG system for related work
- Read relevant guide files
- Understand the service architecture

### 2. Follow Multi-Repo Patterns

- Each service is independent
- Shared code should be in `shared/` directories
- Follow Docker and CI/CD patterns from guides

### 3. Use RAG System for Analysis

- Send documents before major changes
- Query for similar implementations
- Analyze code quality and standardization

### 4. Maintain Documentation

- Update guides when architecture changes
- Document new patterns and decisions
- Keep task files up to date

### 5. Test Before Committing

- Run service-specific tests
- Check for linting errors
- Verify Docker builds

## 🔗 Quick Reference

### Common Commands

```bash
# Start analyze service
cd repo/tools/analyze && docker-compose up -d

# Analyze document
./repo/tools/analyze/analyze document <file> --type project_management

# Query RAG system
./repo/tools/analyze/analyze query "<question>"

# Check service health
curl http://localhost:8008/health

# List all jobs
./repo/tools/analyze/analyze list
```

### Service URLs

- Analyze Service: `http://localhost:8008`
- API Service: `http://localhost:8001`
- Web Service: `http://localhost:8000`

### Key Files

- Master README: `todo/00-MASTER-README.md`
- Core Architecture: `todo/01-core-architecture.md`
- Docker Strategy: `todo/02-docker-strategy.md`
- GitHub Actions: `todo/03-github-actions.md`

## 🆘 Troubleshooting

### Analyze Service Not Running

```bash
# Check if service is running
curl http://localhost:8008/health

# Start service
cd repo/tools/analyze
docker-compose up -d
```

### RAG Query Fails

- Ensure service is running
- Check service logs: `docker-compose logs -f`
- Verify API key is set (if using Google AI)

### Can't Find Relevant Code

1. Use RAG system to search:
   ```bash
   ./repo/tools/analyze/analyze query "Where is [feature] implemented?"
   ```

2. Check guide files for architecture details

3. Search across repos:
   ```bash
   grep -r "keyword" repo/
   ```

## 📚 Additional Resources

- [Master README](00-MASTER-README.md) - Overview of all repos
- [Solo Dev Workflow](09-solo-dev-workflow.md) - Development workflow
- [Core Architecture](01-core-architecture.md) - System architecture
- [Docker Strategy](02-docker-strategy.md) - Docker workflows

---

**For questions or issues**: Check the relevant guide file or query the RAG system.

