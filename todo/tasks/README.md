# FKS Task Management

This directory contains task definitions organized by priority.

## 📁 Directory Structure

```
tasks/
├── P0-critical/    # Critical blockers, security issues, test failures
├── P1-high/        # High-priority features, core functionality
├── P2-medium/      # Medium-priority enhancements
└── P3-low/         # Nice-to-have features, optimizations
```

## 🎯 Priority Definitions

### P0 - Critical
- Blocks development or deployment
- Security vulnerabilities
- Data loss risks
- All tests failing
- Production outages

**Response Time**: Immediate

### P1 - High
- Core features for revenue
- Many users affected
- Technical debt causing bugs
- Performance issues

**Response Time**: This week

### P2 - Medium
- Feature enhancements
- Code quality improvements
- Documentation updates
- Non-critical optimizations

**Response Time**: This month

### P3 - Low
- Nice-to-have features
- Minor optimizations
- Code cleanup
- Future considerations

**Response Time**: Backlog

## 📝 Task File Format

Each task should be a markdown file with:

```markdown
# Task Title

**Priority**: P0/P1/P2/P3
**Status**: TODO / IN_PROGRESS / BLOCKED / DONE
**Assigned**: @agent or @developer
**Created**: YYYY-MM-DD
**Updated**: YYYY-MM-DD

## Description

Brief description of the task.

## Context

Why this task is needed, related issues, dependencies.

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Notes

Technical details, approach, relevant files.

## Related

- Guide: [link to guide]
- Issue: [link to GitHub issue]
- PR: [link to PR]
```

## 🔄 Task Lifecycle

1. **Created** - Task file created in appropriate priority directory
2. **Assigned** - Assigned to agent or developer
3. **In Progress** - Work has started
4. **Blocked** - Waiting on dependencies
5. **Done** - Task completed, move to archive or delete

## 📊 Tracking

Use GitHub Issues for detailed tracking:
- Link task files to GitHub issues
- Use labels for categorization
- Update status in both places

---

**For AI Agents**: Check this directory for current tasks before starting work.

