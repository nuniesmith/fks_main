# Quick Start Guide - FKS Project Organization

**For AI Agents and Developers**

## 🚀 5-Minute Setup

### 1. Start the Analyze Service

```bash
cd repo/tools/analyze
docker-compose up -d
# OR
./start.sh
```

### 2. Test the CLI Tool

```bash
# From project root
./repo/tools/analyze/analyze query "What is the FKS project?" --type project_management
```

### 3. Check Results

```bash
# Get the job_id from the previous command, then:
./repo/tools/analyze/analyze results <job_id>
```

## 📚 Key Directories

| Directory | Purpose | When to Use |
|-----------|---------|-------------|
| `todo/guides/` | Architecture guides | Reference when implementing features |
| `todo/tasks/` | Task definitions | Check for current work |
| `todo/AI_AGENT_GUIDE.md` | AI agent instructions | Read before starting tasks |
| `repo/tools/analyze/` | RAG analysis service | Send documents for analysis |

## 🎯 Common Workflows

### Analyze a Document

```bash
./repo/tools/analyze/analyze document todo/guides/01-core-architecture.md --type project_management
```

### Analyze a Directory

```bash
./repo/tools/analyze/analyze directory repo/core/api/src/ --type standardization
```

### Query the RAG System

```bash
./repo/tools/analyze/analyze query "How does the execution pipeline work?" --type project_management
```

### Check Service Health

```bash
curl http://localhost:8008/health
```

## 📖 Next Steps

1. **Read**: [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) for complete instructions
2. **Explore**: [guides/README.md](guides/README.md) for architecture guides
3. **Check**: [tasks/README.md](tasks/README.md) for task management

---

**Need Help?** See [ORGANIZATION_SUMMARY.md](ORGANIZATION_SUMMARY.md) for detailed information.

