# FKS Architecture and Implementation Guides

This directory contains comprehensive guides for the FKS Trading Platform architecture, implementation patterns, and best practices.

## 📚 Guide Index

### Core Architecture
- **[00-MASTER-README.md](00-MASTER-README.md)** - Overview of all FKS repositories and quick navigation
- **[01-core-architecture.md](01-core-architecture.md)** - Kubernetes deployment, system architecture, and service topology
- **[02-docker-strategy.md](02-docker-strategy.md)** - Docker build, push, and tagging strategies
- **[03-github-actions.md](03-github-actions.md)** - CI/CD automation and GitHub Actions workflows

### Feature Implementation
- **[04-ai-trading-agents.md](04-ai-trading-agents.md)** - AI-driven trading agents with LLM integration
- **[05-execution-pipeline.md](05-execution-pipeline.md)** - CCXT integration, webhooks, and security
- **[06-portfolio-rebalancing.md](06-portfolio-rebalancing.md)** - RL-based portfolio rebalancing
- **[07-cvar-risk-management.md](07-cvar-risk-management.md)** - CVaR risk management for safe RL

### Development and Operations
- **[08-monorepo-split-guide.md](08-monorepo-split-guide.md)** - Multi-repo migration guide
- **[09-solo-dev-workflow.md](09-solo-dev-workflow.md)** - Solo developer workflow optimization
- **[10-fintech-security-compliance.md](10-fintech-security-compliance.md)** - Security and compliance best practices
- **[11-project-improvement-areas.md](11-project-improvement-areas.md)** - Areas for improvement
- **[12-standard-schema-design.md](12-standard-schema-design.md)** - Database schema standards

## 🎯 Quick Navigation

### By Priority
- **🔥 CRITICAL**: [01-core-architecture.md](01-core-architecture.md), [02-docker-strategy.md](02-docker-strategy.md), [03-github-actions.md](03-github-actions.md)
- **⭐ HIGH VALUE**: [04-ai-trading-agents.md](04-ai-trading-agents.md), [05-execution-pipeline.md](05-execution-pipeline.md)
- **🚀 ADVANCED**: [06-portfolio-rebalancing.md](06-portfolio-rebalancing.md), [07-cvar-risk-management.md](07-cvar-risk-management.md)

### By Topic
- **Architecture**: [00-MASTER-README.md](00-MASTER-README.md), [01-core-architecture.md](01-core-architecture.md)
- **DevOps**: [02-docker-strategy.md](02-docker-strategy.md), [03-github-actions.md](03-github-actions.md), [08-monorepo-split-guide.md](08-monorepo-split-guide.md)
- **AI/ML**: [04-ai-trading-agents.md](04-ai-trading-agents.md), [06-portfolio-rebalancing.md](06-portfolio-rebalancing.md), [07-cvar-risk-management.md](07-cvar-risk-management.md)
- **Trading**: [05-execution-pipeline.md](05-execution-pipeline.md), [06-portfolio-rebalancing.md](06-portfolio-rebalancing.md)
- **Security**: [10-fintech-security-compliance.md](10-fintech-security-compliance.md)
- **Development**: [09-solo-dev-workflow.md](09-solo-dev-workflow.md), [11-project-improvement-areas.md](11-project-improvement-areas.md)

## 📖 Usage

These guides are designed for:
- **AI Agents**: Reference when implementing features or analyzing code
- **Developers**: Understanding architecture and patterns
- **DevOps**: Setting up CI/CD and deployment
- **Project Management**: Understanding system capabilities and limitations

## 🔄 Keeping Guides Updated

Guides should be updated when:
- Architecture changes significantly
- New patterns or best practices are established
- Services are added or removed
- Major refactoring occurs

---

**Last Updated**: November 7, 2025

