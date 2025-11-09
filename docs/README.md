# FKS Main Documentation
## Central Documentation Hub

**Last Updated**: 2025-01-XX  
**Purpose**: Centralized documentation for FKS Trading Platform

---

## 📁 Directory Structure

```
repo/main/docs/
├── guides/                    # Architecture and implementation guides
├── ci-cd/                     # CI/CD documentation
├── project-management/        # Project management docs
├── templates/                # Issue templates and review templates
└── [other docs]              # Various documentation files
```

---

## 📚 Documentation by Category

### Architecture Guides (`guides/`)
- `00-MASTER-README.md` - Multi-repo overview
- `01-core-architecture.md` - System design & K8s
- `02-docker-strategy.md` - Docker workflows
- `03-github-actions.md` - CI/CD automation
- `04-ai-trading-agents.md` - AI agents
- `05-execution-pipeline.md` - Execution engine
- `06-portfolio-rebalancing.md` - Portfolio management
- `07-cvar-risk-management.md` - Risk management
- `08-monorepo-split-guide.md` - Multi-repo migration
- `09-solo-dev-workflow.md` - Development workflow
- `10-fintech-security-compliance.md` - Security
- `11-project-improvement-areas.md` - Improvements
- `12-standard-schema-design.md` - Schema design

### CI/CD Documentation (`ci-cd/`)
- `CI_CD_QUICKSTART.md` - Quick start guide
- `CI_CD_IMPLEMENTATION_SUMMARY.md` - Implementation summary
- `SECRETS_SETUP.md` - Secrets configuration
- `BRANCH_PROTECTION.md` - Branch protection guide
- `TASK_3_DOCKERHUB_SECRETS_SETUP.md` - DockerHub setup

### Project Management (`project-management/`)
- `AI_AGENT_GUIDE.md` - AI agent instructions
- `ORGANIZATION_SUMMARY.md` - Organization structure
- `QUICK_START.md` - Quick start guide
- `NEXT_STEPS.md` - Current next steps
- `PLAN.md` - Current FKS plan
- `copilot-instructions.md` - Copilot instructions

### Templates (`templates/`)
- `ISSUE_TEMPLATE/` - GitHub issue templates
- `ISSUE_TEMPLATE.md` - Issue template
- `WEEKLY_REVIEW_TEMPLATE.md` - Weekly review template

---

## 🔗 Related

- **Phase Plans**: See `todo/` directory for active phase planning files
- **Tasks**: See `todo/tasks/` for prioritized task definitions
- **Archive**: See `todo/.archive/` for archived documentation

---

## 📖 Quick Navigation

### For Developers
1. Start with `guides/00-MASTER-README.md`
2. Review `guides/01-core-architecture.md` for system design
3. Check `project-management/QUICK_START.md` for setup

### For CI/CD Setup
1. Read `ci-cd/CI_CD_QUICKSTART.md`
2. Configure secrets: `ci-cd/SECRETS_SETUP.md`
3. Set up branch protection: `ci-cd/BRANCH_PROTECTION.md`

### For AI Agents
1. Read `project-management/AI_AGENT_GUIDE.md`
2. Reference `guides/04-ai-trading-agents.md` for implementation

---

**Note**: Phase and task planning files remain in `todo/` directory for active development tracking.
