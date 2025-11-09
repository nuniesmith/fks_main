# FKS Automation Guide

## Overview

This guide covers automation strategies to reduce toil and improve reliability.

## Deployment Automation

### Automated Deployments

Script: `scripts/deployment/deploy.sh`

```bash
./scripts/deployment/deploy.sh fks_api production
```

**Features**:
- Builds Docker image
- Pushes to registry
- Deploys to Kubernetes
- Verifies health

### CI/CD Integration

All services use GitHub Actions for:
- Automated testing
- Docker image building
- Image pushing to Docker Hub
- Deployment (optional)

## Migration Automation

### Database Migrations

Script: `scripts/migrations/run_migrations.sh`

```bash
./scripts/migrations/run_migrations.sh fks_data
```

**Best Practices**:
- Version all migrations
- Test in staging first
- Rollback plan ready
- Backup before migration

## Backup Automation

### Automated Backups

Script: `scripts/backup/backup.sh`

Runs daily via cron:
```bash
0 2 * * * /path/to/backup.sh
```

**Backup Strategy**:
- Daily full backups
- Weekly retention
- Test restore regularly

## On-Call Management

### Rotation

Configuration: `config/oncall.json`

**Features**:
- Weekly rotation
- Escalation policies
- Service priority levels

### Alerting

- PagerDuty integration (recommended)
- Email notifications
- Slack integration

## Toil Reduction

### Tracking

Configuration: `config/toil_tracking.json`

**Target**: <50% of time on toil

**Categories**:
- Manual deployments → Automate
- Manual migrations → Automate
- Incident response → Improve runbooks
- Manual testing → Already automated

### Automation Priorities

1. **High Impact, Low Effort**:
   - Deployment automation
   - Backup automation

2. **High Impact, High Effort**:
   - Migration automation
   - Incident response automation

3. **Low Impact, Low Effort**:
   - Log rotation
   - Cleanup scripts

## Best Practices

1. **Automate Repetitive Tasks**: If done >3 times, automate
2. **Version Control**: All scripts in git
3. **Documentation**: Document all automation
4. **Testing**: Test automation in staging
5. **Monitoring**: Monitor automated processes

## Tools

- **CI/CD**: GitHub Actions
- **Orchestration**: Kubernetes
- **Monitoring**: Prometheus, Grafana
- **Alerting**: PagerDuty (recommended)

---

**Last Updated**: 2025-11-08
